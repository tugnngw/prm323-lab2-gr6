"""Verified Lab 3 cases; observations asserted from TaskResult.output JSON."""
import pytest
from conftest import APP_PACKAGE, require_artemis, skip_without_adb
from observations import equals, contains_text
pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_S_01_signin_cancel_message(artemis, auth_account):
    observed = await artemis.run(
        'Starting signed in, sign out. Tap "Đăng nhập với Google", then dismiss the native account picker with Back. Report the literal message shown on the sign-in screen and whether the sign-in button is still visible. Then restore the same dedicated test account and end on Home.',
        {'cancel_message': 'literal message shown', 'still_signed_out': 'boolean', 'restored': 'boolean'},
    )
    assert 'hủy' in observed['cancel_message'].lower() or 'huỷ' in observed['cancel_message'].lower()
    equals(observed,'still_signed_out',True)
    equals(observed,'restored',True)

@require_artemis
async def test_TC_S_06_remote_config_offline_defaults(artemis, restore_network):
    observed = await artemis.run(
        'From Home enable airplane mode using Android UI, reopen app and verify it renders Home or sign-in without fatal error. Cached RC flags may apply; do not infer server updates. Restore airplane mode OFF before finishing.',
        {'rendered': 'boolean', 'airplane_mode_restored': 'boolean'},
    )
    equals(observed,'rendered',True)
    equals(observed,'airplane_mode_restored',True)

@require_artemis
async def test_TC_X_06_fcm_foreground_center(artemis):
    observed = await artemis.run(
        'From Home open Trung tâm thông báo. Report actual notification count, first title if present, and literal empty message if zero. Do not claim push delivery simply because the center opens.',
        {'notification_count': 'integer', 'first_title': 'string', 'empty_message': 'string'},
    )
    assert type(observed['notification_count']) is int and observed['notification_count']>=0
    if observed['notification_count']==0: assert observed['empty_message']
    else: assert observed['first_title']

@require_artemis
async def test_TC_S_07_fcm_native_notification_settings(artemis):
    observed = await artemis.run(
        'On Android open App info for StudyPilot then its Notifications settings. Read the actual permission status without changing it; return to the app. Report native settings screen label, permission status and whether app renders afterwards.',
        {'native_screen': 'literal Android screen label', 'permission_state': 'allowed or denied', 'app_rendered': 'boolean'},
    )
    assert observed['native_screen']
    assert observed['permission_state'] in {'allowed','denied'}
    equals(observed,'app_rendered',True)

@require_artemis
async def test_TC_14_analytics_events_log(artemis, logcat):
    logcat.start('TC-14')
    observed = await artemis.run(
        'From Home open Lộ trình. Tap the search field before typing PRM. Wait until the field visibly contains PRM and the list shows only matching courses. If the field still shows its placeholder, tap and type again. Open PRM393 only after verifying the filter. Report the shown course code and final screen title. The runner checks the actual logs for search_course and course_view.',
        {'course_code': 'literal course code'},
    )
    equals(observed,'course_code','PRM393')
    text=logcat.stop_and_text()
    assert 'Logged event: search_course' in text
    assert 'Logged event: course_view' in text

@require_artemis
async def test_TC_13_fcm_token_registered(artemis, logcat):
    logcat.start('TC-13')
    observed = await artemis.run(
        'The harness has already cold-started StudyPilot with its existing session. Observe the current Home screen and report its literal title. Do not relaunch the app or change accounts or permissions. The runner checks token registration logs.',
        {'screen_title': 'literal title'},
    )
    equals(observed,'screen_title','StudyPilot')
    assert 'Registered FCM token' in logcat.stop_and_text()
