"""Verified Lab 3 cases; observations asserted from TaskResult.output JSON."""
import pytest
from conftest import APP_PACKAGE, require_artemis, skip_without_adb
from observations import equals, contains_text
pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_F2_01_toggle_task(artemis, auth_account, unique_name):
    observed = await artemis.run(
        'From Home open Việc cần làm, create a NEW task named {fixture}; tick its checkbox. Report exact task title, checked state, and the literal snackbar action. Do not touch existing tasks.'.replace("{fixture}", unique_name),
        {'task_title': 'literal title', 'checked': 'boolean', 'undo_label': 'literal action'},
    )
    equals(observed,'task_title',unique_name)
    equals(observed,'checked',True)
    equals(observed,'undo_label','Hoàn tác')

@require_artemis
async def test_TC_F2_02_undo_within_8s(artemis, auth_account, unique_name):
    observed = await artemis.run(
        'Create your OWN new task {fixture}, initially unchecked. Tick it and tap Hoàn tác in one immediate action burst before the 8-second snackbar expires. End with that task unchecked; never depend on a prior case.'.replace("{fixture}", unique_name),
        {'task_title': 'literal title', 'checked_after_undo': 'boolean'},
    )
    equals(observed,'task_title',unique_name)
    equals(observed,'checked_after_undo',False)

@require_artemis
async def test_TC_V1_update_existing_task(artemis, auth_account, unique_name, logcat):
    logcat.start('TC-V1')
    observed = await artemis.run(
        'Create your own task {fixture}. Open its content/edit sheet, append EDITED, press Cập nhật việc cần làm, then reload through Sync Vault manual sync (tap Xác nhận on the sync confirmation dialog if prompted). Return to Tasks and report its literal persisted title.'.replace("{fixture}", unique_name),
        {'task_title': 'literal title after reload'},
    )
    equals(observed,'task_title',unique_name+' EDITED')
    text=logcat.stop_and_text()
    assert 'editTask error' not in text and 'FATAL EXCEPTION' not in text

@require_artemis
async def test_TC_F2_05_add_task_id_consistency(artemis, auth_account, unique_name):
    observed = await artemis.run(
        'Create your own task {fixture}. Open the "Firebase Cloud & Offline Vault" card and tap Kích hoạt đồng bộ Vault ngay, confirm if prompted, wait for sync result, return to Tasks. Report that task title and occurrence count after reload.'.replace("{fixture}", unique_name),
        {'task_title': 'literal title', 'occurrence_count': 'integer'},
    )
    equals(observed,'task_title',unique_name)
    equals(observed,'occurrence_count',1)
