"""Verified Lab 3 cases; observations asserted from TaskResult.output JSON."""
import pytest
from conftest import APP_PACKAGE, require_artemis, skip_without_adb
from observations import equals, contains_text
pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_01_google_signin_native(artemis, auth_account):
    observed = await artemis.run(
        'From Home sign out and sign in through the native Google picker using the configured dedicated test account already on this device. Do not enter credentials. End at Home and report the actual tab labels and whether the account picker was shown.',
        {'picker_seen': 'boolean', 'tabs': 'array of literal tab labels'},
    )
    equals(observed, 'picker_seen', True)
    assert set(['Trang chủ','Lộ trình','Việc cần làm','Ghi chú']).issubset(set(observed['tabs']))

@require_artemis
async def test_TC_02_auth_routing(artemis):
    observed = await artemis.run(
        'The harness has already cold-started the app. Observe the current screen without relaunching or changing authentication. Report signed_in for Home or signed_out for the sign-in screen and quote the visible text.',
        {'auth_state': 'signed_in or signed_out'},
    )
    assert observed['auth_state'] in {'signed_in','signed_out'}
    assert any(text in observed['visible_text'] for text in ['Chào','Đăng nhập với Google'])

@require_artemis
async def test_TC_12_logout_clears_state(artemis, auth_account):
    observed = await artemis.run(
        'Starting signed in, sign out and verify the Google sign-in button and absence of private note/task content. Then restore the same dedicated test account through the native picker and end on Home. Do not rely on a task from any previous case.',
        {'signed_out_button': 'literal intermediate sign-in button', 'private_content_after_logout': 'boolean', 'restored_home': 'boolean'},
    )
    equals(observed,'signed_out_button','Đăng nhập với Google')
    equals(observed,'private_content_after_logout',False)
    equals(observed,'restored_home',True)
