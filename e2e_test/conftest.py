"""Pinned SDK harness. Each regression case is parametrized for three real runs.
No screenshot, result or PASS is synthesized when the model/host fails.
"""
import asyncio
import json
import os
import re
import shutil
import subprocess
import time
import xml.etree.ElementTree as ET
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
import pytest
from observations import parse_observation, terminal_observation
try:
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).parent / '.env')
except ImportError:
    pass
try:
    from artemis_client import ArtemisClient
except ImportError:
    ArtemisClient = None

APP_PACKAGE = os.getenv('APP_PACKAGE', 'com.example.prm323_lab3')
DEVICE_SERIAL = os.getenv('DEVICE_SERIAL', 'emulator-5554')
ARTEMIS_HOST = os.getenv('ARTEMIS_HOST', 'http://127.0.0.1:8000')
ADB = os.getenv('ADB', str(Path.home() / 'AppData/Local/Android/Sdk/platform-tools/adb.exe'))
EVIDENCE_DIR = Path(os.getenv('EVIDENCE_DIR') or Path(__file__).parent.parent / 'evidence/artemis')
RESULTS = []


def pytest_addoption(parser):
    parser.addoption('--runs', type=int, default=3, help='Real runs per regression case; rubric requires >=3')


def pytest_generate_tests(metafunc):
    if 'run_number' in metafunc.fixturenames:
        runs = 1 if 'EXPLORATORY' in metafunc.function.__name__ else metafunc.config.getoption('--runs')
        if runs < 1:
            raise pytest.UsageError('--runs must be positive')
        metafunc.parametrize('run_number', range(1, runs + 1), indirect=True, ids=lambda n: f'run{n}')


@pytest.fixture(autouse=True)
def run_number(request):
    return request.param


def adb(*args):
    return subprocess.run([ADB, '-s', DEVICE_SERIAL, *args], capture_output=True,
                          text=True, encoding='utf-8', errors='replace', timeout=35, check=True)


def current_ui_text():
    subprocess.run([ADB, '-s', DEVICE_SERIAL, 'shell', 'uiautomator', 'dump', '/sdcard/prm393-window.xml'],
                   capture_output=True, timeout=12, check=True)
    tree = ET.fromstring(adb('exec-out', 'cat', '/sdcard/prm393-window.xml').stdout)
    return '\n'.join(node.get('text', '') + ' ' + node.get('content-desc', '') for node in tree.iter('node')).strip()


def read_terminal_report(session_id):
    with urllib.request.urlopen(ARTEMIS_HOST.rstrip('/') + '/api/sessions/' + session_id + '/steps', timeout=15) as response:
        return terminal_observation(json.load(response), session_id)


def wait_for_app_entry(timeout=60):
    """Cold-start independently and never tap an unfocused startup window.

    Home/sign-in semantics were observed with ARTEMIS on Pixel_7_API_35.
    ADB UIAutomator reads actual readiness; a fixed sleep cannot prove it.
    """
    adb('shell', 'am', 'force-stop', APP_PACKAGE)
    adb('shell', 'am', 'start', '-n', APP_PACKAGE + '/.MainActivity')
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            labels = current_ui_text()
            assert "isn't responding" not in labels, 'Android ANR at startup; do not dismiss and count as pass'
            if ('StudyPilot' in labels and 'Trang chủ' in labels) or 'Đăng nhập bằng Google' in labels:
                return
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired, ET.ParseError):
            pass
        time.sleep(1)
    raise AssertionError('Home/sign-in not ready within 60s; no UI action was issued during startup')


@pytest.fixture
def device_state():
    return adb


@pytest.fixture
def case_id(request, run_number):
    return re.sub(r'[^A-Za-z0-9_-]', '_', request.node.name) + '_' + str(time.time_ns())


class ObservedClient:
    def __init__(self, client, case_id, node):
        self.client, self.case_id, self.node = client, case_id, node
        self.trace_id = None

    async def run(self, instruction, fields, timeout=390):
        folder = EVIDENCE_DIR / 'runs' / self.case_id
        folder.mkdir(parents=True, exist_ok=True)
        # Keep the synchronous ADB wait out of the asynchronous SDK polling loop.
        try:
            await asyncio.to_thread(wait_for_app_entry)
        except Exception as error:
            (folder / 'precondition-failure.json').write_text(json.dumps({
                'phase': 'native startup wait', 'error': str(error),
                'device': DEVICE_SERIAL, 'artemis_task_submitted': False,
            }, ensure_ascii=False, indent=2), encoding='utf-8')
            (folder / 'precondition-failure.png').write_bytes(subprocess.check_output(
                [ADB, '-s', DEVICE_SERIAL, 'exec-out', 'screencap', '-p'], timeout=30))
            raise
        schema = {'visible_text': 'literal text actually seen on the final screen', **fields}
        goal = (
            f'App {APP_PACKAGE}; dedicated test device {DEVICE_SERIAL}. '
            'The harness has cold-started the app and waited for Home/sign-in. Start from this observed screen; '
            'if signed out and this case does not request authentication, report the signed-out screen; do not invent data. '
            + instruction + '\nCall report_task_status with a JSON object as the explanation. '
              'Use these field names and their actual observed values: '
            + json.dumps(schema, ensure_ascii=False)
            + '. Do not report success if a step fails. Never infer uploads, grades, push delivery or server persistence from a label. '
              'Do not delete or modify records except the exact E2E fixture named in this instruction.'
        )
        started = time.monotonic()
        handle = await self.client.submit(goal, locked_app_package=APP_PACKAGE)
        self.trace_id = handle.task_id
        record = {'case': self.node.name, 'trace_id': self.trace_id, 'device': DEVICE_SERIAL,
                  'started_at': datetime.now(timezone.utc).isoformat(), 'instruction': instruction}
        (folder / 'admitted.json').write_text(json.dumps(record, ensure_ascii=False, indent=2), encoding='utf-8')
        try:
            result = await self.client.wait_for_task(self.trace_id, timeout=timeout, poll_interval=5)
        except Exception:
            await self.client.stop(self.trace_id)
            raise
        record.update(status=result.status, error=result.error, output=result.output,
                      duration_seconds=round(time.monotonic() - started, 3))
        (folder / 'result.json').write_text(json.dumps(record, ensure_ascii=False, indent=2, default=str), encoding='utf-8')
        if not result.succeeded and any(word in str(record).lower() for word in ('429', 'quota', 'resource_exhausted', 'rate_limit')):
            self.node.session.shouldstop = 'ARTEMIS infrastructure quota failure: diagnose and restore credentials/quota before rerunning.'
        elif not result.succeeded:
            # This host version omits the underlying error in TaskResult;
            # do not enqueue the remaining batch against an undiagnosed failure.
            self.node.session.shouldstop = 'ARTEMIS task failed; inspect this trace and diagnose before continuing the batch.'
        assert result.succeeded, f'ARTEMIS trace {self.trace_id}: {result.error or result.status}'
        # Independent screenshot is attached to this exact run, never overwritten.
        (folder / 'final.png').write_bytes(subprocess.check_output([ADB, '-s', DEVICE_SERIAL, 'exec-out', 'screencap', '-p'], timeout=30))
        if result.output is None:
            observation, terminal = await asyncio.to_thread(read_terminal_report, self.trace_id)
            (folder / 'terminal-report.json').write_text(json.dumps(terminal, ensure_ascii=False, indent=2), encoding='utf-8')
            record['output_source'] = 'ARTEMIS session steps: final report_task_status'
        else:
            observation = parse_observation(result.output)
            record['output_source'] = 'TaskResult.output'
        native = await asyncio.to_thread(current_ui_text)
        assert native, 'Independent final UI hierarchy is empty'
        native = re.sub(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}', '[email redacted]', native)
        observation['native_visible_text'] = native
        (folder / 'native-final-text.txt').write_text(native, encoding='utf-8')
        record['observation'] = observation
        (folder / 'result.json').write_text(json.dumps(record, ensure_ascii=False, indent=2, default=str), encoding='utf-8')
        return observation


def make_client(request, case_id, profile):
    if ArtemisClient is None:
        pytest.skip('artemis-client not installed; install pinned dependencies first')
    return ObservedClient(ArtemisClient(ARTEMIS_HOST, device_serial=DEVICE_SERIAL, default_profile=profile), case_id, request.node)


@pytest.fixture
def artemis(request, case_id):
    return make_client(request, case_id, 'flash')


@pytest.fixture
def pro_artemis(request, case_id):
    return make_client(request, case_id, 'pro')


@pytest.fixture
def auth_account():
    account = os.getenv('TEST_ACCOUNT_EMAIL', '')
    if not account or os.getenv('E2E_ALLOW_AUTH_CHANGES') != '1':
        pytest.skip('Requires a dedicated TEST_ACCOUNT_EMAIL and E2E_ALLOW_AUTH_CHANGES=1; never sign out a personal session')
    return account


@pytest.fixture
def unique_name(case_id):
    return 'E2E-' + case_id[-24:]


@pytest.fixture
def evidence_shot(case_id):
    def save(name):
        folder = EVIDENCE_DIR / 'runs' / case_id
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / (re.sub(r'[^A-Za-z0-9_-]', '_', name) + '.png')
        path.write_bytes(subprocess.check_output([ADB, '-s', DEVICE_SERIAL, 'exec-out', 'screencap', '-p'], timeout=30))
        return path
    return save


@pytest.fixture
def logcat(case_id):
    path = EVIDENCE_DIR / 'logs' / (case_id + '.log')
    path.parent.mkdir(parents=True, exist_ok=True)
    proc, output = None, None
    class Capture:
        def start(self, _name):
            nonlocal proc, output
            if proc is not None:
                raise RuntimeError('log capture already active')
            # Clear first, so the beginning of this run is not lost after starting capture.
            adb('logcat', '-c')
            output = path.open('w', encoding='utf-8')
            proc = subprocess.Popen([ADB, '-s', DEVICE_SERIAL, 'logcat', '-v', 'time', 'flutter:I', 'AndroidRuntime:E', '*:S'], stdout=output, stderr=subprocess.DEVNULL)
        def stop_and_text(self):
            nonlocal proc, output
            if proc is not None:
                proc.terminate(); proc.wait(timeout=10); proc = None
            if output is not None:
                output.close(); output = None
            return path.read_text(encoding='utf-8', errors='replace') if path.exists() else ''
    capture = Capture()
    yield capture
    capture.stop_and_text()


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    outcome = yield
    report = outcome.get_result()
    if report.when == 'call' or (report.when == 'setup' and (report.failed or report.skipped)):
        RESULTS.append({'case': item.nodeid, 'outcome': report.outcome, 'seconds': round(report.duration, 3),
                        'reason': str(report.longrepr)[:1200] if report.failed or report.skipped else ''})


def pytest_sessionfinish(session, exitstatus):
    if session.config.option.collectonly or not RESULTS:
        return
    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    (EVIDENCE_DIR / f'results-{stamp}.json').write_text(json.dumps(RESULTS, ensure_ascii=False, indent=2), encoding='utf-8')
    groups = {}
    for row in RESULTS:
        key = re.sub(r'\[run\d+\]', '', row['case'])
        groups.setdefault(key, []).append(row)
    lines = ['# ARTEMIS actual run results', '', '| Case | Executed | Passed | Failed | Skipped | Mean seconds |', '|---|---:|---:|---:|---:|---:|']
    for case, rows in groups.items():
        executed=[r for r in rows if r['outcome']!='skipped']
        lines.append(f"| {case} | {len(executed)} | {sum(r['outcome']=='passed' for r in rows)} | {sum(r['outcome']=='failed' for r in rows)} | {sum(r['outcome']=='skipped' for r in rows)} | {sum(r['seconds'] for r in executed)/len(executed) if executed else 0:.2f} |")
    lines += ['', 'Skipped/blocked cases are not passes. A pass rate is complete only after at least 3 executed runs per case.', '', '```json', json.dumps([r for r in RESULTS if r['outcome']!='passed'], ensure_ascii=False, indent=2), '```']
    (EVIDENCE_DIR / f'results-{stamp}.md').write_text('\n'.join(lines)+'\n', encoding='utf-8')


skip_without_adb = pytest.mark.skipif(shutil.which(ADB) is None and not Path(ADB).exists(), reason='ADB not available')
require_artemis = skip_without_adb


@pytest.fixture
def restore_network():
    """Restore device connectivity even when an offline task errors or times out."""
    airplane = adb('settings', 'get', 'global', 'airplane_mode_on').stdout.strip()
    wifi = adb('settings', 'get', 'global', 'wifi_on').stdout.strip()
    data = adb('settings', 'get', 'global', 'mobile_data').stdout.strip()
    yield
    adb('cmd', 'connectivity', 'airplane-mode', 'enable' if airplane == '1' else 'disable')
    adb('svc', 'wifi', 'enable' if wifi == '1' else 'disable')
    if data in {'0', '1'}:
        adb('svc', 'data', 'enable' if data == '1' else 'disable')
