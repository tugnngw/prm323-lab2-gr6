"""Verified Lab 3 cases; observations asserted from TaskResult.output JSON."""
import pytest
from conftest import APP_PACKAGE, require_artemis, skip_without_adb
from observations import equals, contains_text
pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_08_advisor_course_question(artemis):
    observed = await artemis.run(
        "From Home open Cố vấn học tập. Tap the 'Môn' level chip. Tap 'Hỏi nhanh trên thiết bị · không cần mạng' to open the quick-question sheet. Tap the 'Chọn môn' dropdown once to open its course list; 'PRM393 — Mobile Programming' is a row near the top of that list. Tap that PRM393 row directly by its visible text to select it — do not tap the dropdown field again while the list is open, and do not use element-index clicks. Then tap 'Tóm tắt môn học'. Read the resulting card and report its literal answer and source line; it must ground credits/prerequisites in Firebase and disclose missing personal data.",
        {'reply': 'literal reply text'},
    )
    assert 'PRM393' in observed['native_visible_text']
    assert 'tín chỉ' in observed['native_visible_text'].casefold()
    assert 'Nguồn:' in observed['native_visible_text']
    assert 'PRM393' in observed['reply']

@require_artemis
async def test_TC_09_empty_search_recovery(artemis):
    observed = await artemis.run(
        'From Home open Lộ trình, clear old search and search ZZZ_NO_COURSE_20261104. Verify zero course rows and empty-state text. Clear search and verify courses return. Report both counts and literal empty message.',
        {'empty_count': 'integer', 'empty_message': 'literal empty message', 'recovered_count': 'integer'},
    )
    equals(observed,'empty_count',0)
    assert 'Không tìm thấy' in observed['empty_message']
    assert type(observed['recovered_count']) is int and observed['recovered_count']>0
