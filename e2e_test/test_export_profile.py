"""Verified Lab 3 cases; observations asserted from TaskResult.output JSON."""
import pytest
from conftest import APP_PACKAGE, require_artemis, skip_without_adb
from observations import equals, contains_text
pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_10_pdf_export_consent_upload(artemis, auth_account, logcat):
    logcat.start('TC-10')
    observed = await artemis.run(
        'From Home tap the card labelled "Firebase Cloud & Offline Vault", scroll to Export & Upload PDF, tap Xuất & Tải PDF lên Cloud Storage. Verify consent appears BEFORE any upload, accept and wait for completion. Report actual status and download URL. An error is a FAILED upload, never substitute an error branch for success.',
        {'consent_before_upload': 'boolean', 'upload_status': 'success or error', 'download_url': 'literal URL or empty'},
    )
    equals(observed,'consent_before_upload',True)
    equals(observed,'upload_status','success')
    assert observed['download_url'].startswith('https://')
    assert 'FATAL EXCEPTION' not in logcat.stop_and_text()

@require_artemis
async def test_TC_11_remote_config_values_visible(artemis):
    observed = await artemis.run(
        'From Home tap the card labelled "Firebase Cloud & Offline Vault" (do not tap the arrow). '
        'On the Sync Vault screen scroll until the "Firebase Remote Config" card is fully visible near the top and read it. '
        'Report exact maintenance_mode boolean, min_app_version string and AI feature flag. Do not infer from defaults and do not claim Console before/after verification.',
        {'maintenance_mode': 'boolean', 'min_app_version': 'version string', 'feature_ai_advisor_enabled': 'boolean'},
    )
    assert type(observed['maintenance_mode']) is bool
    assert type(observed['feature_ai_advisor_enabled']) is bool
    assert isinstance(observed['min_app_version'],str) and observed['min_app_version']
    contains_text(observed,'maintenance_mode')
    contains_text(observed,'min_app_version')
