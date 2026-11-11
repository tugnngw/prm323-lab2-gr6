"""Verified Lab 3 cases; observations asserted from TaskResult.output JSON."""
import pytest
from conftest import APP_PACKAGE, require_artemis, skip_without_adb
from observations import equals, contains_text
pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_F3_01_create_note(artemis, auth_account, unique_name):
    observed = await artemis.run(
        "From Home open Ghi chú, create a note titled {fixture} with non-personal content 'Lab3 E2E fixture'. Save, return to note list, reopen it and report exact title/content. Do not touch existing notes.".replace("{fixture}", unique_name),
        {'note_title': 'literal title', 'content': 'literal note content'},
    )
    equals(observed,'note_title',unique_name)
    equals(observed,'content','Lab3 E2E fixture')

@require_artemis
async def test_TC_F3_02_offline_cache_branch(artemis, restore_network):
    observed = await artemis.run(
        'From Home open Ghi chú to warm its cache, then turn airplane mode on through Android system UI, return to Ghi chú. Report the literal loaded/empty/error message; do not attempt an offline write and do not claim server sync. Restore airplane mode OFF before finishing.',
        {'airplane_mode_restored': 'boolean', 'server_sync_claimed': 'boolean', 'notes_state': 'data or empty or error'},
    )
    equals(observed,'airplane_mode_restored',True)
    equals(observed,'server_sync_claimed',False)
    assert observed['notes_state'] in {'data','empty','error'}

@require_artemis
async def test_TC_F3_03_reconnect_sync_recovery(artemis):
    observed = await artemis.run(
        'Independently start with network enabled. Open the "Firebase Cloud & Offline Vault" card, tap Kích hoạt đồng bộ Vault ngay, tap Xác nhận on the sync confirmation dialog if prompted; wait for reload completion. Return Ghi chú and report final data/empty state and whether any sync error remains. No fixture from another case is required.',
        {'notes_state': 'data or empty', 'sync_error_visible': 'boolean'},
    )
    assert observed['notes_state'] in {'data','empty'}
    equals(observed,'sync_error_visible',False)
