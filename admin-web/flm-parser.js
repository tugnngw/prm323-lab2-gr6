/**
 * FLM HTML parser for the academic admin.
 *
 * A full major import needs:
 *   1 curriculum page  -> #table-detail (major metadata) + #gvSubs (subject list)
 *   N syllabus pages   -> #table-detail (subject metadata) + #gvSchedule,
 *                         #gvAssessment, #gvMaterial, #gvLO, #gvCQ
 *
 * Parsing never invents slots, assessments or learning outcomes. A subject
 * without a syllabus page is imported with syllabusStatus = "metadata".
 */

export function cleanText(str) {
  if (!str) return '';
  return String(str)
    .replace(/<br\s*\/?>/gi, ' ')
    .replace(/&nbsp;/gi, ' ')
    .replace(/\r\n|\n|\r/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function decodeHtmlEntities(str) {
  if (!str) return '';
  const named = {
    amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", nbsp: ' ',
    ndash: '–', mdash: '—', hellip: '…', rsquo: '’', lsquo: '‘',
    ldquo: '“', rdquo: '”', middot: '·', deg: '°',
  };
  const decodeOnce = value => String(value).replace(/&(#x?[0-9a-f]+|[a-z]+);/gi, (match, entity) => {
    if (entity[0] === '#') {
      const hex = entity[1].toLowerCase() === 'x';
      const code = parseInt(entity.slice(hex ? 2 : 1), hex ? 16 : 10);
      return Number.isFinite(code) ? String.fromCodePoint(code) : match;
    }
    const key = entity.toLowerCase();
    return Object.prototype.hasOwnProperty.call(named, key) ? named[key] : match;
  });
  // Some FLM exports are double-encoded (e.g. &amp;#236;).
  let current = String(str);
  for (let i = 0; i < 2; i += 1) {
    const next = decodeOnce(current);
    if (next === current) break;
    current = next;
  }
  return current;
}

function cellText(innerHtml) {
  return cleanText(decodeHtmlEntities(String(innerHtml).replace(/<[^>]+>/g, ' ')));
}

/**
 * Extracts one table by id into rows of { text, html, link, isHeader }.
 */
export function extractTable(html, tableId) {
  if (!html || typeof html !== 'string') return null;
  const tableRe = new RegExp(
    `<table\\b[^>]*\\bid\\s*=\\s*["']${tableId}["'][\\s\\S]*?<\\/table>`,
    'i'
  );
  const tableMatch = html.match(tableRe);
  if (!tableMatch) return null;

  const rows = [];
  const rowMatches = tableMatch[0].match(/<tr\b[\s\S]*?<\/tr>/gi) || [];
  for (const rowHtml of rowMatches) {
    const cells = [];
    const cellRe = /<(td|th)\b[^>]*>([\s\S]*?)<\/\1>/gi;
    let cellMatch;
    while ((cellMatch = cellRe.exec(rowHtml)) !== null) {
      const inner = cellMatch[2];
      const linkMatch = inner.match(/<a\b[^>]*\bhref\s*=\s*["']([^"']+)["']/i);
      cells.push({
        text: cellText(inner),
        html: inner,
        link: linkMatch ? decodeHtmlEntities(linkMatch[1]) : '',
        isHeader: cellMatch[1].toLowerCase() === 'th',
      });
    }
    if (cells.length > 0) rows.push(cells);
  }
  return rows;
}

function normalizeKey(value) {
  return String(value || '')
    .replace(/[:：]\s*$/, '')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');
}

/**
 * Reads a label/value table such as FLM's #table-detail.
 */
export function readDetailTable(html) {
  const rows = extractTable(html, 'table-detail') || [];
  const detail = {};
  for (const row of rows) {
    // Real FLM layout: <td>Label:</td><td>Value</td>
    if (row.length >= 2 && /[:：]\s*$/.test(row[0].text)) {
      const key = normalizeKey(row[0].text);
      const value = row[1].text;
      if (key && value && detail[key] === undefined) detail[key] = value;
    }
    // Combined layout: <td>Label: Value</td>
    for (const cell of row) {
      const match = cell.text.match(/^([A-Za-z][A-Za-z0-9 /().-]{1,60})\s*[:：]\s*(.+)$/);
      if (!match) continue;
      const key = normalizeKey(match[1]);
      const value = cellText(match[2]);
      if (key && value && detail[key] === undefined) detail[key] = value;
    }
  }
  return detail;
}

function findHeaderRow(rows, expectedKeys) {
  for (let i = 0; i < Math.min(rows.length, 3); i += 1) {
    const normalized = rows[i].map(cell => normalizeKey(cell.text));
    const hits = expectedKeys.filter(key => normalized.includes(key)).length;
    if (hits >= Math.max(2, Math.ceil(expectedKeys.length / 2))) {
      const index = {};
      normalized.forEach((key, col) => {
        if (key && index[key] === undefined) index[key] = col;
      });
      return { rowIndex: i, index };
    }
  }
  return null;
}

function valueAt(row, index, key, fallbackIndex = -1) {
  if (index && index[key] !== undefined) {
    return row[index[key]] ? row[index[key]].text : '';
  }
  if (fallbackIndex >= 0 && row[fallbackIndex]) return row[fallbackIndex].text;
  return '';
}

function cellAt(row, index, key, fallbackIndex = -1) {
  if (index && index[key] !== undefined) return row[index[key]] || null;
  if (fallbackIndex >= 0) return row[fallbackIndex] || null;
  return null;
}

/**
 * Extracts course codes from an FLM prerequisite sentence. Codes may contain
 * '*', '_' and a trailing lowercase letter (e.g. PHE_COM*1, SSL101c).
 */
export function parsePrerequisitesString(str) {
  if (!str) return [];
  const cleaned = cleanText(str);
  if (!cleaned || /^(?:None|No|N\/A|Không|-|—)$/i.test(cleaned)) return [];

  const matches = cleaned.match(/\b[A-Za-z][A-Za-z0-9_*]*\d{1,4}[a-z]?\b/g) || [];
  // K19/K18... are cohort labels in FLM prerequisite sentences, not courses.
  const blocked = /^(CLO|PLO|ITU|GPA|ISO|IELTS|TOEFL)\d*$|^K\d{2,4}$/i;
  const seen = new Set();
  const codes = [];
  for (const raw of matches) {
    const code = raw.trim();
    if (!code || blocked.test(code)) continue;
    const key = code.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    codes.push(code);
  }
  return codes;
}

/**
 * Splits a prerequisite cell into hard-checkable course codes and an optional
 * free-text note. FLM often writes cohort/track conditions ("K20A: Passed
 * JST301, K19: Passed JTS301", "PMG201c or PMG202c", "AI: PMG20x") — those must
 * not become an AND list of codes.
 */
export function parsePrerequisiteCell(str) {
  const cleaned = cleanText(str);
  const codes = parsePrerequisitesString(str);
  if (!cleaned || codes.length === 0) return { codes: [], note: '' };

  const cohortLabels = cleaned.match(/\bK\d{2,4}[A-Z]?\b/gi) || [];
  const cohortConditional =
    new Set(cohortLabels.map(label => label.toUpperCase())).size > 1 ||
    /\bK\d{2,4}[A-Z]?\s*:/i.test(cleaned);
  const alternative =
    /\b(?:or|ho[ạa]c|and|v[àa])\b|[+\/;:]|[()]/i.test(cleaned) || cohortConditional;
  const imperative = /\b(?:passed|pass|must)\b/i.test(cleaned);
  const codeLike = word => /^[A-Za-z][A-Za-z0-9_*]*\d{1,4}[a-z]?[,.;:]?$/.test(word);
  const prose = cleaned.split(/\s+/).filter(word => word && !codeLike(word)).length > 8;

  if (alternative || prose || (imperative && codes.length > 1)) {
    return { codes: [], note: cleaned };
  }
  return { codes, note: '' };
}

export function splitFlmSubjectName(fullName) {
  const full = cleanText(fullName);
  if (!full) return { name: '', nameVi: '' };
  const separator = full.indexOf('_');
  if (separator <= 0) return { name: full, nameVi: '' };
  const english = full.slice(0, separator).trim();
  const vietnamese = full.slice(separator + 1).trim();
  return { name: english || full, nameVi: vietnamese };
}

function isValidCourseCode(code) {
  return /^[A-Za-z][A-Za-z0-9_.*-]{1,23}$/.test(code);
}

function emptyCourse(code, name) {
  return {
    code,
    name,
    nameVi: '',
    semester: 0,
    credits: 0,
    prerequisites: [],
    prerequisiteNote: '',
    overview: '',
    studentTasks: '',
    tools: '',
    degreeLevel: '',
    timeAllocation: '',
    scoringScale: '',
    minAvgMarkToPass: '',
    learningTeachingMethod: '',
    note: '',
    decisionNo: '',
    approvedDate: '',
    lecturer: '',
    link: '',
    resourceLinks: {},
    syllabusId: '',
    syllabusStatus: 'metadata',
    electiveGroups: [],
    slots: [],
    labs: [],
    learningOutcomes: [],
    courseMaterials: [],
    totalSlots: 0,
    completedSlots: 0,
    archived: false,
  };
}

/**
 * Parses a curriculum page.
 */
export function parseFlmCurriculumHtml(html) {
  const result = {
    major: {
      code: '',
      name: '',
      nameEn: '',
      description: '',
      totalSemesters: 0,
      source: 'flm_html',
    },
    semesters: {},
    courses: [],
    warnings: [],
  };

  if (!html || typeof html !== 'string') {
    result.warnings.push('Tệp HTML rỗng hoặc không đọc được.');
    return result;
  }

  const detail = readDetailTable(html);
  result.major.code = detail.curriculumcode || '';
  result.major.name = detail.englishname || detail.name || '';
  result.major.nameEn = detail.englishname || detail.name || '';
  result.major.description = detail.description || '';

  const rows = extractTable(html, 'gvSubs');
  if (!rows || rows.length === 0) {
    result.warnings.push('Không tìm thấy bảng môn học #gvSubs trong tệp chương trình.');
    return result;
  }

  const header = findHeaderRow(rows, ['subjectcode', 'subjectname', 'semester', 'nocredit', 'prerequisite']);
  const startRow = header ? header.rowIndex + 1 : 0;
  const index = header ? header.index : null;

  let maxSemester = 0;
  const seen = new Set();

  for (let i = startRow; i < rows.length; i += 1) {
    const row = rows[i];
    if (!row || row.length < 2) continue;

    const rawCode = valueAt(row, index, 'subjectcode', 0);
    const code = cleanText(rawCode);
    if (!code || !isValidCourseCode(code)) continue;
    const key = code.toLowerCase();
    if (seen.has(key)) {
      result.warnings.push(`Môn ${code} xuất hiện nhiều lần trong chương trình, đã bỏ qua bản trùng.`);
      continue;
    }
    seen.add(key);

    const nameCell = cellAt(row, index, 'subjectname', 1);
    const fullName = nameCell ? nameCell.text : '';
    const { name, nameVi } = splitFlmSubjectName(fullName);

    const semesterText = valueAt(row, index, 'semester', 2);
    const semester = parseInt(semesterText, 10);
    const creditsText = valueAt(row, index, 'nocredit', 3);
    const credits = parseInt(creditsText, 10);
    const prerequisiteCell = parsePrerequisiteCell(
      valueAt(row, index, 'prerequisite', 4)
    );

    const course = emptyCourse(code, name || code);
    course.nameVi = nameVi;
    course.semester = Number.isFinite(semester) ? semester : 0;
    course.credits = Number.isFinite(credits) ? credits : 0;
    course.prerequisites = prerequisiteCell.codes;
    course.prerequisiteNote = prerequisiteCell.note;
    course.link = nameCell?.link || '';
    course.major = result.major.code;

    if (course.semester > maxSemester) maxSemester = course.semester;
    result.courses.push(course);
    if (!result.semesters[course.semester]) result.semesters[course.semester] = [];
    result.semesters[course.semester].push(course);
  }

  result.major.totalSemesters = Math.max(maxSemester, 1);
  if (!result.major.name) result.major.name = result.major.code;
  if (result.courses.length === 0) {
    result.warnings.push('Không đọc được môn học hợp lệ nào từ #gvSubs.');
  }

  return result;
}

function collectCqs(cqs, slotNumber) {
  const matching = cqs.filter(cq => String(cq.session).trim() === String(slotNumber));
  return matching
    .map(cq => [cq.name, cq.description].filter(Boolean).join(': '))
    .join(' • ');
}

/**
 * Parses one syllabus page: metadata plus all five detail tables.
 */
export function parseFlmSyllabusHtml(html) {
  const result = {
    meta: {
      subjectCode: '',
      syllabusId: '',
      name: '',
      nameVi: '',
      credits: 0,
      prerequisites: [],
      prerequisiteNote: '',
      description: '',
      studentTasks: '',
      tools: '',
      degreeLevel: '',
      timeAllocation: '',
      scoringScale: '',
      minAvgMarkToPass: '',
      learningTeachingMethod: '',
      note: '',
      decisionNo: '',
      approvedDate: '',
      source: 'flm_html',
    },
    slots: [],
    assessments: [],
    materials: [],
    learningOutcomes: [],
    constructiveQuestions: [],
    totalSlots: 0,
    warnings: [],
  };

  if (!html || typeof html !== 'string') {
    result.warnings.push('Tệp HTML rỗng hoặc không đọc được.');
    return result;
  }

  const detail = readDetailTable(html);
  const { name, nameVi } = splitFlmSubjectName(detail.syllabusname || '');
  result.meta.subjectCode = (detail.subjectcode || '').trim();
  result.meta.syllabusId = (detail.syllabusid || '').trim();
  result.meta.name = detail.coursenameenglish || name || '';
  result.meta.nameVi = nameVi;
  result.meta.credits = parseInt(detail.nocredit, 10) || 0;
  const metaPrerequisiteCell = parsePrerequisiteCell(detail.prerequisite || '');
  result.meta.prerequisites = metaPrerequisiteCell.codes;
  result.meta.prerequisiteNote = metaPrerequisiteCell.note;
  result.meta.description = detail.description || '';
  result.meta.studentTasks = detail.studenttasks || '';
  result.meta.tools = (detail.tools || detail.coursebook || detail.specifictools || '')
    .replace(/^Tools\s*:\s*/i, '');
  result.meta.degreeLevel = detail.degreelevel || '';
  result.meta.timeAllocation = detail.timeallocation || '';
  result.meta.scoringScale = detail.scoringscale || '';
  result.meta.minAvgMarkToPass = detail.minavgmarktopass || detail.mintopass || '';
  result.meta.learningTeachingMethod = detail.learningteachingmethod || '';
  result.meta.note = detail.note || '';
  result.meta.decisionNo = detail.decisionnommddyyyy || '';
  result.meta.approvedDate = detail.approveddate || '';

  // 1. Learning outcomes
  const loRows = extractTable(html, 'gvLO') || [];
  const loHeader = findHeaderRow(loRows, ['cloname', 'clodetails', 'ploname', 'plodescription']);
  for (let i = loHeader ? loHeader.rowIndex + 1 : 0; i < loRows.length; i += 1) {
    const row = loRows[i];
    const nameValue = valueAt(row, loHeader?.index, 'cloname', 1) ||
      valueAt(row, loHeader?.index, 'ploname', 1);
    const description = valueAt(row, loHeader?.index, 'clodetails', 2) ||
      valueAt(row, loHeader?.index, 'plodescription', 2);
    if (nameValue || description) {
      result.learningOutcomes.push({
        name: nameValue || `LO${result.learningOutcomes.length + 1}`,
        description,
      });
    }
  }

  // 2. Materials
  const materialRows = extractTable(html, 'gvMaterial') || [];
  const materialHeader = findHeaderRow(materialRows, [
    'materialdescription', 'author', 'publisher', 'publisheddate', 'edition',
    'isbn', 'ismainmaterial', 'ishardcopy', 'isonline', 'note',
  ]);
  for (let i = materialHeader ? materialHeader.rowIndex + 1 : 0; i < materialRows.length; i += 1) {
    const row = materialRows[i];
    const description = valueAt(row, materialHeader?.index, 'materialdescription', 1);
    if (!description) continue;
    const isMainText = valueAt(row, materialHeader?.index, 'ismainmaterial', 7);
    result.materials.push({
      description,
      author: valueAt(row, materialHeader?.index, 'author', 2),
      publisher: valueAt(row, materialHeader?.index, 'publisher', 3),
      publishedDate: valueAt(row, materialHeader?.index, 'publisheddate', 4),
      edition: valueAt(row, materialHeader?.index, 'edition', 5),
      isbn: valueAt(row, materialHeader?.index, 'isbn', 6),
      isMain: /^(true|yes|có|1)$/i.test(cleanText(isMainText)),
      note: valueAt(row, materialHeader?.index, 'note', 10),
    });
  }

  // 3. Assessments
  const assessmentRows = extractTable(html, 'gvAssessment') || [];
  const assessmentHeader = findHeaderRow(assessmentRows, [
    'category', 'type', 'part', 'weight', 'completioncriteria', 'duration',
    'clo', 'gradingguide', 'note',
  ]);
  for (let i = assessmentHeader ? assessmentHeader.rowIndex + 1 : 0; i < assessmentRows.length; i += 1) {
    const row = assessmentRows[i];
    const category = valueAt(row, assessmentHeader?.index, 'category', 1);
    if (!category) continue;
    const weightText = valueAt(row, assessmentHeader?.index, 'weight', 4);
    const weight = parseFloat(String(weightText).replace(/[^0-9.]/g, ''));
    result.assessments.push({
      id: `${category}-${valueAt(row, assessmentHeader?.index, 'part', 3)}`
        .toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_|_$/g, ''),
      title: category,
      category,
      type: valueAt(row, assessmentHeader?.index, 'type', 2),
      part: valueAt(row, assessmentHeader?.index, 'part', 3),
      weight: Number.isFinite(weight) ? weight : 0,
      completionCriteria: valueAt(row, assessmentHeader?.index, 'completioncriteria', 5),
      duration: valueAt(row, assessmentHeader?.index, 'duration', 6),
      clo: valueAt(row, assessmentHeader?.index, 'clo', 7),
      gradingCriteria: valueAt(row, assessmentHeader?.index, 'gradingguide', 11),
      note: valueAt(row, assessmentHeader?.index, 'note', 12),
      status: 'pending',
    });
  }

  // 4. Constructive questions
  const cqRows = extractTable(html, 'gvCQ') || [];
  const cqHeader = findHeaderRow(cqRows, ['sessionno', 'name', 'details']);
  for (let i = cqHeader ? cqHeader.rowIndex + 1 : 0; i < cqRows.length; i += 1) {
    const row = cqRows[i];
    const session = valueAt(row, cqHeader?.index, 'sessionno', 1);
    const nameValue = valueAt(row, cqHeader?.index, 'name', 2);
    const description = valueAt(row, cqHeader?.index, 'details', 3);
    if (session || description) {
      result.constructiveQuestions.push({ session, name: nameValue, description });
    }
  }

  // 5. Schedule
  const scheduleRows = extractTable(html, 'gvSchedule') || [];
  const scheduleHeader = findHeaderRow(scheduleRows, [
    'session', 'topic', 'learningteachingtype', 'lo', 'itu',
    'studentmaterials', 'sdownload', 'studentstasks', 'urls',
  ]);
  for (let i = scheduleHeader ? scheduleHeader.rowIndex + 1 : 0; i < scheduleRows.length; i += 1) {
    const row = scheduleRows[i];
    const sessionText = valueAt(row, scheduleHeader?.index, 'session', 0);
    const slotNumber = parseInt(sessionText, 10);
    if (!Number.isFinite(slotNumber) || slotNumber <= 0) continue;

    const topic = valueAt(row, scheduleHeader?.index, 'topic', 1);
    result.slots.push({
      number: slotNumber,
      title: `Buổi ${slotNumber}: ${topic || `Bài học ${slotNumber}`}`,
      topic,
      teachingType: valueAt(row, scheduleHeader?.index, 'learningteachingtype', 2),
      lo: valueAt(row, scheduleHeader?.index, 'lo', 3),
      itu: valueAt(row, scheduleHeader?.index, 'itu', 4),
      materials: valueAt(row, scheduleHeader?.index, 'studentmaterials', 5),
      download: valueAt(row, scheduleHeader?.index, 'sdownload', 6),
      tasks: valueAt(row, scheduleHeader?.index, 'studentstasks', 7),
      urls: valueAt(row, scheduleHeader?.index, 'urls', 8),
      cqs: collectCqs(result.constructiveQuestions, slotNumber),
    });
  }

  result.slots.sort((a, b) => a.number - b.number);
  result.totalSlots = result.slots.length;

  if (!result.meta.subjectCode) {
    result.warnings.push('Không tìm thấy "Subject Code" trong #table-detail của đề cương.');
  }
  if (result.slots.length === 0) {
    result.warnings.push('Không tìm thấy lịch học #gvSchedule trong đề cương.');
  }

  return result;
}

/**
 * Parses a subject's syllabus-list page (the page reached from a curriculum
 * row). A regular subject has one option; an elective/level group has many.
 */
export function parseFlmSyllabusListHtml(html) {
  const result = {
    subjectCode: '',
    subjectName: '',
    curriculumCode: '',
    curriculumName: '',
    options: [],
    warnings: [],
  };
  if (!html || typeof html !== 'string') {
    result.warnings.push('Tệp HTML rỗng hoặc không đọc được.');
    return result;
  }

  const subjectMatch = html.match(
    /<td\b[^>]*>\s*Subject\s*:?\s*<\/td>\s*<td\b[^>]*>([\s\S]*?)<\/td>/i
  );
  if (subjectMatch) {
    const text = cellText(subjectMatch[1]);
    const parts = text.split(/\s*--\s*/);
    result.subjectCode = cleanText(parts.shift() || '');
    result.subjectName = cleanText(parts.join(' -- '));
  }

  const curriculumMatch = html.match(
    /<td\b[^>]*>\s*Curriculum\s*:?\s*<\/td>\s*<td\b[^>]*>([\s\S]*?)<\/td>/i
  );
  if (curriculumMatch) {
    const text = cellText(curriculumMatch[1]);
    const parts = text.split(/\s*--\s*/);
    result.curriculumCode = cleanText(parts.shift() || '');
    result.curriculumName = cleanText(parts.join(' -- '));
  }

  const seen = new Set();
  const rowMatches = html.match(/<tr\b[\s\S]*?<\/tr>/gi) || [];
  for (const rowHtml of rowMatches) {
    const linkMatch = rowHtml.match(
      /<a\b[^>]*href\s*=\s*["']([^"']*SyllabusDetails\?sylID=\d+[^"']*)["']/i
    );
    if (!linkMatch) continue;
    const cells = [];
    const cellRe = /<(td|th)\b[^>]*>([\s\S]*?)<\/\1>/gi;
    let cellMatch;
    while ((cellMatch = cellRe.exec(rowHtml)) !== null) {
      cells.push(cellText(cellMatch[2]));
    }
    const code = cleanText(cells[0] || '');
    if (!code) continue;
    const syllabusId = (linkMatch[1].match(/sylID=(\d+)/i) || [])[1] || '';
    const key = `${code.toLowerCase()}|${syllabusId}`;
    if (seen.has(key)) continue;
    seen.add(key);
    result.options.push({
      code,
      name: cleanText(cells[1] || ''),
      decision: cleanText(cells[cells.length - 1] || ''),
      syllabusId,
      link: decodeHtmlEntities(linkMatch[1]),
    });
  }

  if (!result.subjectCode) {
    result.warnings.push('Không đọc được "Subject" trong trang danh sách đề cương.');
  }
  if (result.options.length === 0) {
    result.warnings.push('Không tìm thấy đề cương nào trong trang danh sách môn.');
  }
  return result;
}

export function detectFlmHtmlType(html) {
  if (!html || typeof html !== 'string') return 'unknown';
  if (/id\s*=\s*["']gvSubs["']/i.test(html)) return 'curriculum';
  if (
    /SyllabusDetails\?sylID=\d+/i.test(html) &&
    /<td\b[^>]*>\s*Subject\s*:?\s*<\/td>/i.test(html)
  ) {
    return 'syllabus-list';
  }
  if (
    /id\s*=\s*["']gvSchedule["']/i.test(html) ||
    /id\s*=\s*["']gvAssessment["']/i.test(html) ||
    /Subject\s*Code\s*[:：]/i.test(html)
  ) {
    return 'syllabus';
  }
  if (/Curriculum\s*Code\s*[:：]/i.test(html)) return 'curriculum';
  return 'unknown';
}

function applySyllabus(course, syllabus) {
  const meta = syllabus.meta;
  course.name = meta.name || course.name || course.code;
  course.nameVi = meta.nameVi || course.nameVi || '';
  course.credits = meta.credits || course.credits || 0;
  if (course.prerequisites.length === 0 && meta.prerequisites.length > 0) {
    course.prerequisites = meta.prerequisites;
  }
  if (!course.prerequisiteNote && meta.prerequisiteNote) {
    course.prerequisiteNote = meta.prerequisiteNote;
  }
  course.overview = meta.description || course.overview || '';
  course.studentTasks = meta.studentTasks || '';
  course.tools = meta.tools || '';
  course.degreeLevel = meta.degreeLevel || '';
  course.timeAllocation = meta.timeAllocation || '';
  course.scoringScale = meta.scoringScale || '';
  course.minAvgMarkToPass = meta.minAvgMarkToPass || '';
  course.learningTeachingMethod = meta.learningTeachingMethod || '';
  course.note = meta.note || '';
  course.decisionNo = meta.decisionNo || '';
  course.approvedDate = meta.approvedDate || '';
  course.syllabusId = meta.syllabusId || '';
  course.slots = syllabus.slots;
  course.labs = syllabus.assessments;
  course.learningOutcomes = syllabus.learningOutcomes;
  course.courseMaterials = syllabus.materials;
  course.constructiveQuestions = syllabus.constructiveQuestions;
  course.totalSlots = syllabus.totalSlots;
  course.syllabusStatus = (syllabus.slots.length > 0 ||
    syllabus.assessments.length > 0 ||
    syllabus.learningOutcomes.length > 0 ||
    syllabus.materials.length > 0)
    ? 'complete'
    : 'partial';
}

/**
 * Merges one curriculum page, its subject-list pages and any number of
 * syllabus pages. Elective/level groups (a curriculum row whose list contains
 * many subjects) are expanded into real subject documents, while duplicate
 * options shared by several groups are kept once and tagged with every group.
 * files: [{ name, html }]
 */
export function mergeFlmFiles(files) {
  const warnings = [];
  const fileInfo = [];
  let curriculum = null;
  const syllabi = [];
  const lists = [];

  for (const file of files || []) {
    const type = detectFlmHtmlType(file.html);
    fileInfo.push({ name: file.name, type });

    if (type === 'curriculum') {
      const parsed = parseFlmCurriculumHtml(file.html);
      parsed.warnings.forEach(w => warnings.push(`${file.name}: ${w}`));
      if (!curriculum) {
        curriculum = parsed;
      } else {
        warnings.push(`${file.name}: đã bỏ qua vì chỉ nhập một tệp chương trình mỗi lần.`);
      }
    } else if (type === 'syllabus-list') {
      const parsed = parseFlmSyllabusListHtml(file.html);
      parsed.warnings.forEach(w => warnings.push(`${file.name}: ${w}`));
      parsed.fileName = file.name;
      lists.push(parsed);
    } else if (type === 'syllabus') {
      const parsed = parseFlmSyllabusHtml(file.html);
      parsed.warnings.forEach(w => warnings.push(`${file.name}: ${w}`));
      parsed.fileName = file.name;
      syllabi.push(parsed);
    } else {
      warnings.push(`${file.name}: không nhận diện được mẫu HTML FLM (thiếu #gvSubs, danh sách môn hoặc #gvSchedule).`);
    }
  }

  const major = curriculum
    ? { ...curriculum.major }
    : { code: '', name: '', nameEn: '', description: '', totalSemesters: 0, source: 'flm_html' };

  const syllabusByCode = new Map();
  const syllabusBySylId = new Map();
  for (const syllabus of syllabi) {
    const code = (syllabus.meta.subjectCode || '').trim();
    if (!code) {
      warnings.push(`${syllabus.fileName}: đề cương không có Subject Code, bỏ qua.`);
      continue;
    }
    if (syllabus.meta.syllabusId) {
      syllabusBySylId.set(String(syllabus.meta.syllabusId), syllabus);
    }
    if (syllabusByCode.has(code.toLowerCase())) {
      warnings.push(`${syllabus.fileName}: trùng đề cương môn ${code}, dùng tệp sau.`);
    }
    syllabusByCode.set(code.toLowerCase(), syllabus);
  }

  const courseMap = new Map();
  const addCourse = course => {
    course.electiveGroups = course.electiveGroups || [];
    const key = course.code.toLowerCase();
    const existing = courseMap.get(key);
    if (!existing) {
      courseMap.set(key, course);
      return course;
    }
    const groups = [...new Set([...(existing.electiveGroups || []), ...(course.electiveGroups || [])])];
    if (existing.syllabusStatus === 'metadata' && course.syllabusStatus !== 'metadata') {
      course.electiveGroups = groups;
      courseMap.set(key, course);
      return course;
    }
    existing.electiveGroups = groups;
    return existing;
  };

  if (lists.length > 0) {
    const listByCode = new Map();
    for (const list of lists) {
      const code = (list.subjectCode || '').trim().toLowerCase();
      if (!code) {
        warnings.push(`${list.fileName}: trang danh sách không có mã môn, bỏ qua.`);
        continue;
      }
      const existing = listByCode.get(code);
      if (existing) {
        if (list.options.length > existing.options.length) listByCode.set(code, list);
        warnings.push(`${list.fileName}: trùng trang danh sách ${list.subjectCode}, dùng bản đầy đủ hơn.`);
        continue;
      }
      listByCode.set(code, list);
    }

    const usedLists = new Set();
    for (const curriculumCourse of curriculum ? curriculum.courses : []) {
      const list = listByCode.get(curriculumCourse.code.toLowerCase());
      const base = {
        ...curriculumCourse,
        electiveGroups: [],
        syllabusStatus: 'metadata',
      };

      if (!list) {
        addCourse(base);
        warnings.push(`${curriculumCourse.code}: không có trang danh sách đề cương, chỉ lưu thông tin chung.`);
        continue;
      }
      usedLists.add(list.subjectCode.toLowerCase());

      const exact = list.options.find(
        option => option.code.toLowerCase() === curriculumCourse.code.toLowerCase()
      );
      if (exact) {
        const syllabus = syllabusBySylId.get(exact.syllabusId) ||
          syllabusByCode.get(exact.code.toLowerCase());
        if (syllabus) applySyllabus(base, syllabus);
        else if (list.options.length === 0) {
          warnings.push(`${curriculumCourse.code}: trang danh sách không có đề cương.`);
        } else {
          warnings.push(`${curriculumCourse.code}: thiếu tệp đề cương ${exact.code} (sylID ${exact.syllabusId || '?'}).`);
        }
        base.link = exact.link || base.link;
        addCourse(base);
        continue;
      }

      if (list.options.length === 0) {
        addCourse(base);
        warnings.push(`${curriculumCourse.code}: không có lựa chọn nào trong trang danh sách.`);
        continue;
      }

      for (const option of list.options) {
        const optionCourse = emptyCourse(option.code, '');
        const listName = splitFlmSubjectName(option.name);
        optionCourse.name = listName.name || option.code;
        optionCourse.nameVi = listName.nameVi || '';
        optionCourse.semester = curriculumCourse.semester;
        optionCourse.credits = curriculumCourse.credits;
        optionCourse.prerequisites = [...curriculumCourse.prerequisites];
        optionCourse.prerequisiteNote = curriculumCourse.prerequisiteNote || '';
        optionCourse.electiveGroups = [curriculumCourse.code];
        optionCourse.major = major.code;
        optionCourse.link = option.link;

        const syllabus = syllabusBySylId.get(option.syllabusId) ||
          syllabusByCode.get(option.code.toLowerCase());
        if (syllabus) {
          applySyllabus(optionCourse, syllabus);
        } else {
          optionCourse.syllabusStatus = 'metadata';
          warnings.push(`${curriculumCourse.code}: thiếu tệp đề cương ${option.code} (sylID ${option.syllabusId || '?'}).`);
        }
        addCourse(optionCourse);
      }
    }

    for (const [code, list] of listByCode.entries()) {
      if (!usedLists.has(code)) {
        warnings.push(`${list.fileName}: danh sách môn ${list.subjectCode} không có trong chương trình, bỏ qua.`);
      }
    }
  } else {
    // Legacy path: curriculum + syllabus files only (no list pages).
    if (curriculum) {
      curriculum.courses.forEach(course => addCourse({
        ...course,
        electiveGroups: [],
        syllabusStatus: 'metadata',
      }));
    }
    for (const [key, syllabus] of syllabusByCode.entries()) {
      let course = courseMap.get(key);
      if (!course) {
        const code = syllabus.meta.subjectCode;
        course = addCourse(emptyCourse(code, syllabus.meta.name || code));
        course.nameVi = syllabus.meta.nameVi;
        course.semester = 0;
        course.credits = syllabus.meta.credits || 0;
        course.prerequisites = syllabus.meta.prerequisites || [];
        course.prerequisiteNote = syllabus.meta.prerequisiteNote || '';
        course.major = major.code;
        warnings.push(`Môn ${code} có đề cương nhưng không có trong chương trình; đã thêm với học kỳ 0.`);
      }
      applySyllabus(course, syllabus);
      course.major = course.major || major.code;
    }
  }

  const courses = [...courseMap.values()];
  const missingPrereqs = new Set();
  for (const course of courses) {
    for (const prereqCode of course.prerequisites) {
      if (!courseMap.has(prereqCode.toLowerCase())) missingPrereqs.add(prereqCode);
    }
  }
  if (missingPrereqs.size > 0) {
    warnings.push(
      `${missingPrereqs.size} mã môn tiên quyết không có trong chương trình: ${[...missingPrereqs].join(', ')}.`
    );
  }

  const missingSyllabus = courses.filter(c => c.syllabusStatus === 'metadata');
  if (missingSyllabus.length > 0) {
    warnings.push(
      `${missingSyllabus.length} môn chưa có đề cương: ${missingSyllabus.map(c => c.code).join(', ')}.`
    );
  }

  const maxSemester = Math.max(0, ...courses.map(c => c.semester || 0));
  major.totalSemesters = Math.max(parseInt(major.totalSemesters, 10) || 0, maxSemester, 1);
  if (!major.code) {
    warnings.push('Chưa xác định được mã chuyên ngành. Hãy nhập mã và tên chuyên ngành trước khi lưu.');
  }

  return { major, courses, warnings, files: fileInfo };
}

// ============================================================================
// Desktop JSON export support (kept for pasting old exports; not used by the
// file importer). Markdown strings are converted to structured data.
// ============================================================================

export function parseMarkdownSchedule(scheduleMd, cqsMd = '') {
  if (!scheduleMd || typeof scheduleMd !== 'string') return [];
  const cqs = parseMarkdownCQs(cqsMd);
  const slots = [];
  const slotBlocks = scheduleMd.split(/(?=###\s*Slot\s*\d+)/i);

  for (const block of slotBlocks) {
    const headerMatch = block.match(/###\s*Slot\s*(\d+)/i);
    if (!headerMatch) continue;
    const num = parseInt(headerMatch[1], 10);
    if (isNaN(num)) continue;

    const topicMatch = block.match(/-\s*\*\*Topic:\*\*\s*([^\r\n]+)/i);
    const materialsMatch = block.match(/-\s*\*\*Materials:\*\*\s*([^\r\n]+)/i);
    const tasksMatch = block.match(/-\s*\*\*Tasks:\*\*\s*([^\r\n]+)/i);

    const topic = topicMatch ? cleanText(topicMatch[1].replace(/<br>/gi, ' ')) : '';
    const materials = materialsMatch ? cleanText(materialsMatch[1].replace(/<br>/gi, ' ')) : '';
    const tasks = tasksMatch ? cleanText(tasksMatch[1].replace(/<br>/gi, ' ')) : '';

    const cq = cqs.find(q => q.session === String(num));

    slots.push({
      number: num,
      title: `Buổi ${num}: ${topic || 'Bài học ' + num}`,
      topic,
      materials,
      tasks,
      cqs: cq ? `${cq.name ? cq.name + ': ' : ''}${cq.description}` : '',
    });
  }
  slots.sort((a, b) => a.number - b.number);
  return slots;
}

export function parseMarkdownCQs(cqsMd) {
  if (!cqsMd || typeof cqsMd !== 'string') return [];
  const cqs = [];
  const lines = cqsMd.split(/\r?\n/);
  for (const line of lines) {
    const match = line.match(/-\s*\*\*Slot\s*(\d+)\s*-\s*([^:]+):\*\*\s*(.*)/i);
    if (match) {
      cqs.push({
        session: match[1].trim(),
        name: cleanText(match[2]),
        description: cleanText(match[3]),
      });
    }
  }
  return cqs;
}

export function parseMarkdownAssessments(asmMd) {
  if (!asmMd || typeof asmMd !== 'string') return [];
  const assessments = [];
  const blocks = asmMd.split(/(?=###\s+[^\r\n]+)/);

  for (const block of blocks) {
    const headerMatch = block.match(/###\s+([^(]+)(?:\(([^)]+)\))?/i);
    if (!headerMatch) continue;
    const category = cleanText(headerMatch[1]);
    const weightStr = headerMatch[2] ? cleanText(headerMatch[2]) : '';
    const weightNum = parseFloat(weightStr.replace(/[^0-9.]/g, '')) || 0;

    const durMatch = block.match(/-\s*\*\*Thời gian:\*\*\s*([^\r\n]+)/i);
    const critMatch = block.match(/-\s*\*\*Hướng dẫn\/Tiêu chí:\*\*\s*([^\r\n]+)/i);

    const duration = durMatch ? cleanText(durMatch[1]) : '';
    const criteria = critMatch ? cleanText(critMatch[1].replace(/<br>/gi, ' ')) : '';

    if (category) {
      assessments.push({
        id: category.toLowerCase().replace(/[^a-z0-9]/g, '_'),
        title: category,
        category,
        weight: weightNum,
        duration,
        gradingCriteria: criteria,
        status: 'pending',
      });
    }
  }
  return assessments;
}

export function parseMarkdownMaterials(matMd) {
  if (!matMd || typeof matMd !== 'string') return [];
  const materials = [];
  const items = matMd.split(/(?=-\s*\*\*[^*]+\*\*)/);

  for (const item of items) {
    const titleMatch = item.match(/-\s*\*\*([^*]+)\*\*/);
    if (!titleMatch) continue;
    const desc = cleanText(titleMatch[1]);
    const authorMatch = item.match(/\*Tác giả:\*\s*([^\r\n]+)/i);
    const mainMatch = item.match(/\*Giáo trình chính:\*\s*(Có|true|yes)/i);

    if (desc) {
      materials.push({
        description: desc,
        author: authorMatch ? cleanText(authorMatch[1]) : '',
        isMain: !!mainMatch,
      });
    }
  }
  return materials;
}

export function parseMarkdownLOs(losMd) {
  if (!losMd || typeof losMd !== 'string') return [];
  const los = [];
  const lines = losMd.split(/\r?\n/);
  for (const line of lines) {
    const match = line.match(/-\s*\*\*([^*:]+):\*\*\s*(.*)/);
    if (match) {
      los.push({
        name: cleanText(match[1]),
        description: cleanText(match[2]),
      });
    }
  }
  return los;
}

export function parseFlmExportJson(jsonStr) {
  try {
    const data = typeof jsonStr === 'string' ? JSON.parse(jsonStr) : jsonStr;

    const resolveCourseDetails = (c) => {
      let slots = Array.isArray(c.slots) ? c.slots : [];
      if (slots.length === 0 && (typeof c.schedule === 'string' || typeof c.scheduleRaw === 'string')) {
        slots = parseMarkdownSchedule(c.schedule || c.scheduleRaw, c.cqs || c.cqsRaw || '');
      }

      let labs = Array.isArray(c.labs) ? c.labs : (Array.isArray(c.assessments) ? c.assessments : []);
      if (labs.length === 0) {
        const rawAsm = typeof c.assessments === 'string' ? c.assessments : (typeof c.labs === 'string' ? c.labs : '');
        if (rawAsm) labs = parseMarkdownAssessments(rawAsm);
      }

      let los = Array.isArray(c.learningOutcomes) ? c.learningOutcomes : (Array.isArray(c.los) ? c.los : []);
      if (los.length === 0) {
        const rawLo = typeof c.los === 'string' ? c.los : (typeof c.learningOutcomes === 'string' ? c.learningOutcomes : '');
        if (rawLo) los = parseMarkdownLOs(rawLo);
      }

      let materials = Array.isArray(c.courseMaterials) ? c.courseMaterials : (Array.isArray(c.materials) ? c.materials : []);
      if (materials.length === 0) {
        const rawMat = typeof c.materials === 'string' ? c.materials : (typeof c.courseMaterials === 'string' ? c.courseMaterials : '');
        if (rawMat) materials = parseMarkdownMaterials(rawMat);
      }

      const totalSlots = parseInt(c.totalSlots, 10) || (slots.length > 0 ? slots.length : 0);

      return {
        slots,
        labs,
        learningOutcomes: los,
        courseMaterials: materials,
        totalSlots,
        materialsRaw: typeof c.materials === 'string' ? c.materials : (c.materialsRaw || ''),
        losRaw: typeof c.los === 'string' ? c.los : (c.losRaw || ''),
        cqsRaw: typeof c.cqs === 'string' ? c.cqs : (c.cqsRaw || ''),
      };
    };

    if (Array.isArray(data.courses)) {
      const courses = data.courses.map(c => {
        const details = resolveCourseDetails(c);
        return {
          code: (c.code || c.ma || '').trim(),
          name: (c.name || c.ten || '').trim(),
          semester: parseInt(c.semester, 10) || 1,
          major: c.major || data.major?.code || '',
          credits: parseInt(c.credits, 10) || 0,
          totalSlots: details.totalSlots,
          lecturer: c.lecturer || '',
          prerequisites: Array.isArray(c.prerequisites) ? c.prerequisites : [],
          prerequisiteNote: c.prerequisiteNote || '',
          resourceLinks: c.resourceLinks || {},
          overview: c.overview || '',
          slots: details.slots,
          labs: details.labs,
          learningOutcomes: details.learningOutcomes,
          courseMaterials: details.courseMaterials,
          materialsRaw: details.materialsRaw,
          losRaw: details.losRaw,
          cqsRaw: details.cqsRaw,
        };
      });
      return { courses, major: data.major || null };
    }

    if (Array.isArray(data)) {
      const courses = [];
      for (const sem of data) {
        const semNumMatch = (sem.ky || '').match(/\d+/);
        const semNum = semNumMatch ? parseInt(semNumMatch[0], 10) : 1;
        const subjects = sem.mon || sem.subjects || [];
        for (const sub of subjects) {
          const details = resolveCourseDetails(sub);
          courses.push({
            code: (sub.ma || sub.code || '').trim(),
            name: (sub.ten || sub.name || '').trim(),
            semester: semNum,
            major: sub.major || '',
            credits: parseInt(sub.credits, 10) || 0,
            totalSlots: details.totalSlots,
            lecturer: sub.lecturer || '',
            prerequisites: Array.isArray(sub.prerequisites) ? sub.prerequisites : [],
            prerequisiteNote: sub.prerequisiteNote || '',
            resourceLinks: sub.resourceLinks || {},
            overview: sub.overview || '',
            slots: details.slots,
            labs: details.labs,
            learningOutcomes: details.learningOutcomes,
            courseMaterials: details.courseMaterials,
            materialsRaw: details.materialsRaw,
            losRaw: details.losRaw,
            cqsRaw: details.cqsRaw,
          });
        }
      }
      return { courses, major: { code: '', name: '' } };
    }

    return { courses: [], major: null };
  } catch (e) {
    throw new Error('Định dạng JSON không hợp lệ: ' + e.message);
  }
}
