import assert from 'node:assert/strict';
import test from 'node:test';
import {
  parseFlmCurriculumHtml,
  parseFlmSyllabusHtml,
  parseFlmSyllabusListHtml,
  parseFlmExportJson,
  detectFlmHtmlType,
  mergeFlmFiles,
  parsePrerequisitesString,
  parsePrerequisiteCell,
} from './flm-parser.js';

test('parsePrerequisitesString handles FLM sentences, "*" codes and option words', () => {
  assert.deepEqual(parsePrerequisitesString('None'), []);
  assert.deepEqual(parsePrerequisitesString('Không'), []);
  assert.deepEqual(parsePrerequisitesString('Pass PRF192'), ['PRF192']);
  assert.deepEqual(parsePrerequisitesString('PRO192, DBI202'), ['PRO192', 'DBI202']);
  assert.deepEqual(parsePrerequisitesString('SWE201c or SWE202c'), ['SWE201c', 'SWE202c']);
  assert.deepEqual(parsePrerequisitesString('MAE101 or MAC101'), ['MAE101', 'MAC101']);
  assert.deepEqual(parsePrerequisitesString('SE_COM*1'), ['SE_COM*1']);
  assert.deepEqual(parsePrerequisitesString('CLO2-CLO9'), []);
  assert.deepEqual(parsePrerequisitesString('K19 - Pass PRF192'), ['PRF192']);
});

test('parsePrerequisiteCell separates hard codes from conditional prose', () => {
  assert.deepEqual(parsePrerequisiteCell('PRO192, DBI202'), {
    codes: ['PRO192', 'DBI202'],
    note: '',
  });
  assert.deepEqual(parsePrerequisiteCell('Pass PRF192'), {
    codes: ['PRF192'],
    note: '',
  });
  assert.deepEqual(parsePrerequisiteCell('SWE201c or SWE202c'), {
    codes: [],
    note: 'SWE201c or SWE202c',
  });
  assert.deepEqual(parsePrerequisiteCell('K20A: Passed JST301, K19: Passed JTS301'), {
    codes: [],
    note: 'K20A: Passed JST301, K19: Passed JTS301',
  });
  assert.deepEqual(parsePrerequisiteCell('AI concurrency: PMG20x or DPL30x'), {
    codes: [],
    note: 'AI concurrency: PMG20x or DPL30x',
  });
  assert.deepEqual(parsePrerequisiteCell('None'), { codes: [], note: '' });
});

test('parseFlmCurriculumHtml reads #table-detail and the real #gvSubs columns', () => {
  const html = `
    <table id="table-detail">
      <tr><td>CurriculumCode:</td><td>BIT_SE_K19B</td></tr>
      <tr><td>Name:</td><td>Software Engineering Major</td></tr>
      <tr><td>English Name:</td><td>Software Engineering</td></tr>
      <tr><td>Description:</td><td>Chương trình đào tạo SE</td></tr>
    </table>
    <table id="gvSubs">
      <thead>
        <tr><th>Subject Code</th><th>Subject Name</th><th>Semester</th><th>NoCredit</th><th>PreRequisite</th></tr>
      </thead>
      <tbody>
        <tr><td>PRF192</td><td><a href="/syl?id=1">Programming Fundamentals_Cơ sở lập trình</a></td><td>1</td><td>3</td><td>None</td></tr>
        <tr><td>PHE_COM*1</td><td>Physical Education 1_Giáo dục thể chất 1</td><td>1</td><td>2</td><td></td></tr>
        <tr><td>PRJ301</td><td>Java Web Application Development</td><td>4</td><td>3</td><td>PRO192, DBI202</td></tr>
      </tbody>
    </table>
  `;

  const parsed = parseFlmCurriculumHtml(html);
  assert.equal(parsed.major.code, 'BIT_SE_K19B');
  assert.equal(parsed.major.name, 'Software Engineering');
  assert.equal(parsed.major.description, 'Chương trình đào tạo SE');
  assert.equal(parsed.major.totalSemesters, 4);
  assert.equal(parsed.courses.length, 3);

  const prf = parsed.courses.find(c => c.code === 'PRF192');
  assert.equal(prf.name, 'Programming Fundamentals');
  assert.equal(prf.nameVi, 'Cơ sở lập trình');
  assert.equal(prf.semester, 1);
  assert.equal(prf.credits, 3);
  assert.equal(prf.link, '/syl?id=1');
  assert.equal(prf.syllabusStatus, 'metadata');
  assert.equal(prf.slots.length, 0);
  assert.equal(prf.labs.length, 0);
  assert.deepEqual(prf.prerequisites, []);

  const pe = parsed.courses.find(c => c.code === 'PHE_COM*1');
  assert.ok(pe);
  assert.equal(pe.credits, 2);

  const prj = parsed.courses.find(c => c.code === 'PRJ301');
  assert.equal(prj.semester, 4);
  assert.deepEqual(prj.prerequisites, ['PRO192', 'DBI202']);
  assert.equal(parsed.semesters[4].length, 1);
});

test('parseFlmSyllabusHtml reads real metadata and all five detail tables', () => {
  const html = `
    <table id="table-detail">
      <tr><td>Syllabus ID:</td><td>12223</td></tr>
      <tr><td>Syllabus Name:</td><td>Programming Fundamentals_Cơ sở lập trình</td></tr>
      <tr><td>Course Name English:</td><td>Programming Fundamentals</td></tr>
      <tr><td>Subject Code:</td><td>PRF192</td></tr>
      <tr><td>NoCredit:</td><td>3</td></tr>
      <tr><td>Pre-Requisite:</td><td>None</td></tr>
      <tr><td>Description:</td><td>Understand basics computer system.</td></tr>
      <tr><td>StudentTasks:</td><td>Attend at least 80% of sessions.</td></tr>
      <tr><td>Tools:</td><td>Tools: - Internet - DevC++</td></tr>
    </table>
    <table id="gvLO">
      <tr><th>No.</th><th>CLO Name</th><th>CLO Details</th></tr>
      <tr><td>1</td><td>CLO1</td><td>Understand how a program works.</td></tr>
    </table>
    <table id="gvMaterial">
      <tr><th>No.</th><th>Material Description</th><th>Author</th><th>Publisher</th><th>Published Date</th><th>Edition</th><th>ISBN</th><th>Is Main Material</th><th>Is Hard Copy</th><th>Is Online</th><th>Note</th></tr>
      <tr><td>1</td><td>Foundations of Programming Using C</td><td>Evan Weaver</td><td>Creative Commons</td><td>2003</td><td></td><td></td><td>True</td><td>True</td><td>False</td><td></td></tr>
    </table>
    <table id="gvAssessment">
      <tr><th>No.</th><th>Category</th><th>Type</th><th>Part</th><th>Weight</th><th>Completion Criteria</th><th>Duration</th><th>CLO</th><th>Question Type</th><th>No Question</th><th>Knowledge and Skill</th><th>Grading Guide</th><th>Note</th></tr>
      <tr><td>1</td><td>Assignment</td><td>on-going</td><td>1</td><td>15.0%</td><td>&gt;0</td><td>at home</td><td>CLO2-CLO9</td><td>Option 1</td><td>1-2</td><td>problem solving</td><td>Individual work</td><td></td></tr>
    </table>
    <table id="gvCQ">
      <tr><th>No.</th><th>Session No</th><th>Name</th><th>Details</th></tr>
      <tr><td>1</td><td>1</td><td>CQ1.1</td><td>What is C programming?</td></tr>
    </table>
    <table id="gvSchedule">
      <tr><th>Session</th><th>Topic</th><th>Learning-Teaching Type</th><th>LO</th><th>ITU</th><th>Student Materials</th><th>S-Download</th><th>Student's Tasks</th><th>URLs</th></tr>
      <tr><td>1</td><td>Introduction and installing tools</td><td>Offline</td><td>CLO1</td><td>I</td><td>Textbook</td><td>PRF192_Slides_1</td><td>Read Textbook</td><td></td></tr>
    </table>
  `;

  const parsed = parseFlmSyllabusHtml(html);
  assert.equal(parsed.meta.subjectCode, 'PRF192');
  assert.equal(parsed.meta.syllabusId, '12223');
  assert.equal(parsed.meta.name, 'Programming Fundamentals');
  assert.equal(parsed.meta.nameVi, 'Cơ sở lập trình');
  assert.equal(parsed.meta.credits, 3);
  assert.equal(parsed.meta.description, 'Understand basics computer system.');
  assert.equal(parsed.meta.studentTasks, 'Attend at least 80% of sessions.');
  assert.equal(parsed.meta.tools, '- Internet - DevC++');

  assert.equal(parsed.learningOutcomes.length, 1);
  assert.equal(parsed.learningOutcomes[0].name, 'CLO1');
  assert.equal(parsed.materials.length, 1);
  assert.equal(parsed.materials[0].isMain, true);
  assert.equal(parsed.materials[0].publisher, 'Creative Commons');

  assert.equal(parsed.assessments.length, 1);
  const asm = parsed.assessments[0];
  assert.equal(asm.category, 'Assignment');
  assert.equal(asm.weight, 15);
  assert.equal(asm.completionCriteria, '>0');
  assert.equal(asm.duration, 'at home');
  assert.equal(asm.gradingCriteria, 'Individual work');

  assert.equal(parsed.slots.length, 1);
  assert.equal(parsed.slots[0].topic, 'Introduction and installing tools');
  assert.equal(parsed.slots[0].download, 'PRF192_Slides_1');
  assert.match(parsed.slots[0].cqs, /What is C programming/);
});

test('mergeFlmFiles attaches syllabus pages to curriculum subjects', () => {
  const curriculumHtml = `
    <table id="table-detail">
      <tr><td>CurriculumCode:</td><td>BIT_SE_K19B</td></tr>
      <tr><td>English Name:</td><td>Software Engineering</td></tr>
    </table>
    <table id="gvSubs">
      <tr><th>Subject Code</th><th>Subject Name</th><th>Semester</th><th>NoCredit</th><th>PreRequisite</th></tr>
      <tr><td>PRF192</td><td>Programming Fundamentals_Cơ sở lập trình</td><td>1</td><td>3</td><td>None</td></tr>
      <tr><td>CSD201</td><td>Data Structures_Cấu trúc dữ liệu</td><td>3</td><td>3</td><td>PRF192</td></tr>
    </table>
  `;
  const syllabusHtml = `
    <table id="table-detail">
      <tr><td>Subject Code:</td><td>PRF192</td></tr>
      <tr><td>Syllabus Name:</td><td>Programming Fundamentals_Cơ sở lập trình</td></tr>
      <tr><td>NoCredit:</td><td>3</td></tr>
    </table>
    <table id="gvSchedule">
      <tr><th>Session</th><th>Topic</th></tr>
      <tr><td>1</td><td>Introduction</td></tr>
    </table>
  `;

  const merged = mergeFlmFiles([
    { name: 'curriculum.html', html: curriculumHtml },
    { name: 'PRF192.html', html: syllabusHtml },
  ]);

  assert.equal(merged.major.code, 'BIT_SE_K19B');
  assert.equal(merged.courses.length, 2);
  const prf = merged.courses.find(c => c.code === 'PRF192');
  assert.equal(prf.syllabusStatus, 'complete');
  assert.equal(prf.slots.length, 1);
  assert.equal(prf.prerequisites.length, 0);
  const csd = merged.courses.find(c => c.code === 'CSD201');
  assert.equal(csd.syllabusStatus, 'metadata');
  assert.deepEqual(csd.prerequisites, ['PRF192']);
  assert.ok(merged.warnings.some(w => w.includes('CSD201') && w.includes('chưa có đề cương')));
});

test('parseFlmSyllabusListHtml reads subject header and every syllabus option', () => {
  const html = `
    <table>
      <tr><td>Subject: </td><td><b>SE_COM*1 -- Subject 1 of Combo*_Môn 1 của Combo*</b></td></tr>
      <tr><td>Curriculum: </td><td><b>BIT_SE_K19B -- Software Engineering Major</b></td></tr>
      <tr><td>Semester: </td><td><b>5</b></td></tr>
    </table>
    <table>
      <tr><th>Subject Code</th><th>Syllabus Name</th><th>IsActive</th><th>IsApproved</th><th>DecisionNo</th></tr>
      <tr><td><b>OPT101</b></td><td><a href="/gui/role/student/SyllabusDetails?sylID=201">Option One_Phương án 1</a></td><td></td><td></td><td>100/QĐ</td></tr>
      <tr><td><b>OPT102</b></td><td><a href="/gui/role/student/SyllabusDetails?sylID=202">Option Two_Phương án 2</a></td><td></td><td></td><td>100/QĐ</td></tr>
    </table>
  `;

  assert.equal(detectFlmHtmlType(html), 'syllabus-list');
  const parsed = parseFlmSyllabusListHtml(html);
  assert.equal(parsed.subjectCode, 'SE_COM*1');
  assert.equal(parsed.subjectName, 'Subject 1 of Combo*_Môn 1 của Combo*');
  assert.equal(parsed.curriculumCode, 'BIT_SE_K19B');
  assert.equal(parsed.options.length, 2);
  assert.equal(parsed.options[0].code, 'OPT101');
  assert.equal(parsed.options[0].syllabusId, '201');
  assert.equal(parsed.options[0].link, '/gui/role/student/SyllabusDetails?sylID=201');
  assert.equal(parsed.options[1].name, 'Option Two_Phương án 2');
});

test('mergeFlmFiles expands elective groups, dedupes shared options and picks the exact version', () => {
  const curriculumHtml = `
    <table id="table-detail">
      <tr><td>CurriculumCode:</td><td>BIT_SE_K19B</td></tr>
      <tr><td>English Name:</td><td>Software Engineering</td></tr>
    </table>
    <table id="gvSubs">
      <tr><th>Subject Code</th><th>Subject Name</th><th>Semester</th><th>NoCredit</th><th>PreRequisite</th></tr>
      <tr><td>PRF192</td><td>Programming Fundamentals_Cơ sở lập trình</td><td>1</td><td>3</td><td>None</td></tr>
      <tr><td>DBI202</td><td>Database Systems_Hệ quản trị CSDL</td><td>2</td><td>3</td><td>MISS999</td></tr>
      <tr><td>CSD201</td><td>Data Structures_Cấu trúc dữ liệu</td><td>3</td><td>3</td><td>PRF192</td></tr>
      <tr><td>SE_COM*1</td><td>Subject 1 of Combo*</td><td>5</td><td>3</td><td></td></tr>
      <tr><td>SE_COM*2</td><td>Subject 2 of Combo*</td><td>7</td><td>3</td><td></td></tr>
    </table>
  `;

  const listHtml = (subject, options) => `
    <table>
      <tr><td>Subject: </td><td><b>${subject} -- Tên môn</b></td></tr>
      <tr><td>Curriculum: </td><td><b>BIT_SE_K19B -- Software Engineering</b></td></tr>
    </table>
    <table>
      <tr><th>Subject Code</th><th>Syllabus Name</th><th>DecisionNo</th></tr>
      ${options.map(o => `<tr><td><b>${o.code}</b></td><td><a href="/gui/role/student/SyllabusDetails?sylID=${o.sylId}">${o.name}</a></td><td>100/QĐ</td></tr>`).join('')}
    </table>
  `;

  const syllabusHtml = ({ code, sylId, name, credits = 3, extra = '' }) => `
    <table id="table-detail">
      <tr><td>Subject Code:</td><td>${code}</td></tr>
      <tr><td>Syllabus ID:</td><td>${sylId}</td></tr>
      <tr><td>Syllabus Name:</td><td>${name}_Tên tiếng Việt</td></tr>
      <tr><td>Course Name English:</td><td>${name}</td></tr>
      <tr><td>NoCredit:</td><td>${credits}</td></tr>
      <tr><td>Pre-Requisite:</td><td>K19 - Pass PRF192</td></tr>
      ${extra}
    </table>
    <table id="gvSchedule">
      <tr><th>Session</th><th>Topic</th></tr>
      <tr><td>1</td><td>Topic of ${code}</td></tr>
    </table>
  `;

  const merged = mergeFlmFiles([
    { name: 'curriculum.html', html: curriculumHtml },
    { name: 'list_PRF192.html', html: listHtml('PRF192', [{ code: 'PRF192', sylId: 1, name: 'Programming Fundamentals' }]) },
    { name: 'list_DBI202.html', html: listHtml('DBI202', [
      { code: 'DBI202', sylId: 4, name: 'Database Systems' },
      { code: 'DBI202-OLD', sylId: 5, name: 'Database Systems (old)' },
    ]) },
    { name: 'list_SE_COM1.html', html: listHtml('SE_COM*1', [
      { code: 'OPT101', sylId: 2, name: 'Option One' },
      { code: 'OPT102', sylId: 3, name: 'Option Two' },
    ]) },
    { name: 'list_SE_COM2.html', html: listHtml('SE_COM*2', [
      { code: 'OPT102', sylId: 3, name: 'Option Two' },
      { code: 'OPT103', sylId: 9, name: 'Option Three' },
    ]) },
    { name: 'PRF192.html', html: syllabusHtml({
      code: 'PRF192', sylId: 1, name: 'Programming Fundamentals',
      extra: `
        <tr><td>Degree Level:</td><td>Bachelor</td></tr>
        <tr><td>Time Allocation:</td><td>30h theory</td></tr>
        <tr><td>Scoring Scale:</td><td>10</td></tr>
        <tr><td>Min Avg Mark To Pass:</td><td>5</td></tr>
        <tr><td>Learning-Teaching Method:</td><td>Project based</td></tr>
      `,
    }) },
    { name: 'DBI202.html', html: syllabusHtml({ code: 'DBI202', sylId: 4, name: 'Database Systems' }) },
    { name: 'DBI202-OLD.html', html: syllabusHtml({ code: 'DBI202-OLD', sylId: 5, name: 'Database Systems (old)' }) },
    { name: 'OPT101.html', html: syllabusHtml({ code: 'OPT101', sylId: 2, name: 'Option One', credits: 4 }) },
    { name: 'OPT102.html', html: syllabusHtml({ code: 'OPT102', sylId: 3, name: 'Option Two', credits: 4 }) },
  ]);

  assert.equal(merged.courses.length, 6);
  assert.ok(!merged.courses.some(c => c.code === 'SE_COM*1' || c.code === 'SE_COM*2'));

  const prf = merged.courses.find(c => c.code === 'PRF192');
  assert.equal(prf.syllabusStatus, 'complete');
  assert.equal(prf.degreeLevel, 'Bachelor');
  assert.equal(prf.timeAllocation, '30h theory');
  assert.equal(prf.scoringScale, '10');
  assert.equal(prf.minAvgMarkToPass, '5');
  assert.equal(prf.learningTeachingMethod, 'Project based');
  assert.deepEqual(prf.prerequisites, ['PRF192']);

  const dbi = merged.courses.find(c => c.code === 'DBI202');
  assert.equal(dbi.syllabusStatus, 'complete');
  assert.equal(dbi.syllabusId, '4');
  assert.equal(dbi.name, 'Database Systems');
  assert.ok(!merged.courses.some(c => c.code === 'DBI202-OLD'));

  const csd = merged.courses.find(c => c.code === 'CSD201');
  assert.equal(csd.syllabusStatus, 'metadata');
  assert.ok(merged.warnings.some(w => w.includes('CSD201') && w.includes('không có trang danh sách')));

  const opt101 = merged.courses.find(c => c.code === 'OPT101');
  assert.deepEqual(opt101.electiveGroups, ['SE_COM*1']);
  assert.equal(opt101.semester, 5);
  assert.equal(opt101.credits, 4);

  const opt102 = merged.courses.find(c => c.code === 'OPT102');
  assert.deepEqual(opt102.electiveGroups, ['SE_COM*1', 'SE_COM*2']);
  assert.equal(opt102.credits, 4);

  const opt103 = merged.courses.find(c => c.code === 'OPT103');
  assert.deepEqual(opt103.electiveGroups, ['SE_COM*2']);
  assert.equal(opt103.semester, 7);
  assert.equal(opt103.syllabusStatus, 'metadata');
  assert.ok(merged.warnings.some(w => w.includes('thiếu tệp đề cương OPT103')));

  assert.ok(merged.warnings.some(w => w.includes('1 mã môn tiên quyết không có trong chương trình: MISS999')));
});

test('parseFlmExportJson parses both nested array format and courses object format', () => {
  const jsonA = JSON.stringify({
    courses: [
      { code: 'PRM323', name: 'Mobile Programming', semester: 5, credits: 3 },
    ],
  });
  const resA = parseFlmExportJson(jsonA);
  assert.equal(resA.courses.length, 1);
  assert.equal(resA.courses[0].code, 'PRM323');

  const jsonB = JSON.stringify([
    {
      ky: 'Kỳ 5',
      mon: [
        { ma: 'SWP391', ten: 'Software Project', totalSlots: 30 },
      ],
    },
  ]);
  const resB = parseFlmExportJson(jsonB);
  assert.equal(resB.courses.length, 1);
  assert.equal(resB.courses[0].code, 'SWP391');
  assert.equal(resB.courses[0].semester, 5);
});

test('parseFlmExportJson parses Desktop FLM scraper Markdown strings into structured slots and labs', () => {
  const desktopExport = JSON.stringify([
    {
      ky: 'Kỳ 5',
      mon: [
        {
          ma: 'PRM393',
          ten: 'Mobile Programming with Flutter',
          schedule: '### Slot 1\n- **Topic:** Kiến trúc Flutter\n- **Materials:** Slide 1\n- **Tasks:** Cài đặt Flutter\n### Slot 2\n- **Topic:** Dart Null Safety\n- **Materials:** Dart Docs\n',
          assessments: '### Practical Exam (25%)\n- **Thời gian:** 90 phút\n- **Hướng dẫn/Tiêu chí:** Làm bài thực hành trên máy\n### Final Exam (30%)\n- **Thời gian:** 60 phút\n',
          materials: '- **Flutter in Action**\n  - *Tác giả:* Eric Windmill\n  - *Giáo trình chính:* Có\n',
          los: '- **LO1:** Lập trình ứng dụng di động đa nền tảng.\n',
          cqs: '- **Slot 1 - Q1:** Tại sao Flutter sử dụng ngôn ngữ Dart?\n',
        },
      ],
    },
  ]);

  const res = parseFlmExportJson(desktopExport);
  assert.equal(res.courses.length, 1);
  const course = res.courses[0];
  assert.equal(course.code, 'PRM393');
  assert.equal(course.semester, 5);
  assert.equal(course.slots.length, 2);
  assert.equal(course.slots[0].number, 1);
  assert.equal(course.slots[0].topic, 'Kiến trúc Flutter');
  assert.match(course.slots[0].cqs, /Tại sao Flutter sử dụng ngôn ngữ Dart/);
  assert.equal(course.labs.length, 2);
  assert.equal(course.labs[0].title, 'Practical Exam');
  assert.equal(course.labs[0].weight, 25);
  assert.equal(course.courseMaterials.length, 1);
  assert.equal(course.courseMaterials[0].description, 'Flutter in Action');
  assert.equal(course.courseMaterials[0].isMain, true);
  assert.equal(course.learningOutcomes.length, 1);
  assert.equal(course.learningOutcomes[0].name, 'LO1');
});
