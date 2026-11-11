"""Verified Lab 3 cases; observations asserted from TaskResult.output JSON."""
import re

import pytest
from conftest import APP_PACKAGE, require_artemis, skip_without_adb
from observations import equals, contains_text
pytestmark = [skip_without_adb, pytest.mark.e2e]


@require_artemis
async def test_TC_F1_01_open_course_slots(artemis):
    observed = await artemis.run(
        'From Home open Lộ trình, choose PRM393, open Lịch slot. Read all three course-tab labels. Report the number of actual detailed slots and the empty-state message when zero; do not treat total-slot defaults as slot records.',
        {'tabs': 'array of course tabs', 'slot_count': 'integer', 'slot_empty_message': 'string'},
    )
    assert set(['Lịch slot','Đánh giá','Tổng quan']).issubset(set(observed['tabs']))
    assert type(observed['slot_count']) is int and observed['slot_count'] >= 0
    if observed['slot_count']==0: assert 'chưa có' in observed['slot_empty_message'].casefold()

@require_artemis
async def test_TC_F1_02_search_course(artemis):
    observed = await artemis.run(
        'From Home open Lộ trình. Tap the search field before typing PRM. '
        'Wait until the field visibly contains PRM and the list shows only matching courses. '
        'If the field still shows its placeholder, tap and type again. '
        'Leave the query in the field and report the course codes actually shown after filtering.',
        {'course_codes': 'array of course codes'},
    )
    native = observed['native_visible_text']
    assert re.search(r'^PRM[ \t]*$', native, re.MULTILINE), 'Search field does not contain PRM'
    codes = re.findall(r'^[ \t]*\d+, ([A-Z]+\d+[A-Z0-9]*)\b', native, re.MULTILINE)
    assert 'PRM393' in codes
    assert all(code.startswith('PRM') for code in codes)
    assert set(observed['course_codes']) == set(codes)

@require_artemis
async def test_TC_F1_04_ask_ai_branch(artemis):
    observed = await artemis.run(
        'From Home open Lộ trình, PRM393, Tổng quan, then Hỏi cố vấn về PRM393. Do not send the question. Read the prefilled question and final screen title.',
        {'screen_title': 'literal screen title', 'prefilled_question': 'literal text in question field'},
    )
    equals(observed,'screen_title','Cố vấn học tập')
    assert 'PRM393' in observed['prefilled_question']

@require_artemis
async def test_TC_05_prerequisite_check(artemis):
    observed = await artemis.run(
        'From Home open PRM393 course detail, Tổng quan. Read the actual prerequisite state and missing prerequisite codes. Do not invent transcript data.',
        {'prerequisite_state': 'eligible or missing', 'missing_codes': 'array'},
    )
    assert observed['prerequisite_state'] in {'eligible','missing'}
    assert isinstance(observed['missing_codes'],list)
    if observed['prerequisite_state']=='eligible': assert observed['missing_codes']==[]
    else: assert observed['missing_codes']
