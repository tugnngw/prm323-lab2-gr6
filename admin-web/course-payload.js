/**
 * Shapes parser output into Firestore course documents. Shared by the admin
 * SPA and the one-off FLM import script so both write identical data.
 */

export const SYLLABUS_STATUSES = ['complete', 'partial', 'metadata', 'manual'];

export function toStr(value) {
  return value === null || value === undefined ? '' : String(value);
}

export function toInt(value, fallback = 0) {
  const parsed = parseInt(String(value).replace(/[^0-9-]/g, ''), 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function toNumber(value, fallback = 0) {
  const parsed = parseFloat(String(value).replace(/[^0-9.-]/g, ''));
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function toBool(value) {
  return value === true || value === 'true' || value === 1 || value === '1';
}

export function normalizeCourse(course, majorCode) {
  const slots = (Array.isArray(course.slots) ? course.slots : []).map((slot, index) => ({
    number: toInt(slot.number, index + 1),
    title: toStr(slot.title || slot.topic),
    topic: toStr(slot.topic || slot.title),
    teachingType: toStr(slot.teachingType),
    lo: toStr(slot.lo),
    itu: toStr(slot.itu),
    materials: toStr(slot.materials),
    download: toStr(slot.download),
    tasks: toStr(slot.tasks),
    urls: toStr(slot.urls),
    cqs: toStr(slot.cqs),
  }));

  const labs = (Array.isArray(course.labs) ? course.labs : []).map((item, index) => ({
    id: toStr(item.id) || `assessment_${index + 1}`,
    title: toStr(item.title || item.category) || `Đầu điểm ${index + 1}`,
    category: toStr(item.category || item.title),
    type: toStr(item.type),
    part: toStr(item.part),
    weight: toNumber(item.weight, 0),
    completionCriteria: toStr(item.completionCriteria),
    duration: toStr(item.duration),
    clo: toStr(item.clo),
    gradingCriteria: toStr(item.gradingCriteria),
    note: toStr(item.note),
    status: toStr(item.status) || 'pending',
  }));

  const learningOutcomes = (Array.isArray(course.learningOutcomes) ? course.learningOutcomes : []).map(lo => ({
    name: toStr(lo.name),
    description: toStr(lo.description),
  }));

  const courseMaterials = (Array.isArray(course.courseMaterials) ? course.courseMaterials : []).map(material => ({
    description: toStr(material.description),
    author: toStr(material.author),
    publisher: toStr(material.publisher),
    publishedDate: toStr(material.publishedDate),
    edition: toStr(material.edition),
    isbn: toStr(material.isbn),
    isMain: toBool(material.isMain),
    note: toStr(material.note),
  }));

  const constructiveQuestions = (Array.isArray(course.constructiveQuestions) ? course.constructiveQuestions : []).map(cq => ({
    session: toStr(cq.session),
    name: toStr(cq.name),
    description: toStr(cq.description),
  }));

  const status = SYLLABUS_STATUSES.includes(course.syllabusStatus) ? course.syllabusStatus : 'metadata';
  const resourceLinks = course.resourceLinks && typeof course.resourceLinks === 'object'
    ? {
      drive: toStr(course.resourceLinks.drive),
      notion: toStr(course.resourceLinks.notion),
      github: toStr(course.resourceLinks.github),
    }
    : { drive: '', notion: '', github: '' };

  return {
    code: toStr(course.code).trim(),
    name: toStr(course.name).trim(),
    nameVi: toStr(course.nameVi).trim(),
    semester: Math.max(0, Math.min(12, toInt(course.semester, 0))),
    credits: Math.max(0, Math.min(30, toInt(course.credits, 0))),
    major: majorCode,
    prerequisites: (Array.isArray(course.prerequisites) ? course.prerequisites : []).map(toStr).filter(Boolean),
    prerequisiteNote: toStr(course.prerequisiteNote).trim(),
    overview: toStr(course.overview),
    studentTasks: toStr(course.studentTasks),
    tools: toStr(course.tools),
    degreeLevel: toStr(course.degreeLevel),
    timeAllocation: toStr(course.timeAllocation),
    scoringScale: toStr(course.scoringScale),
    minAvgMarkToPass: toStr(course.minAvgMarkToPass),
    learningTeachingMethod: toStr(course.learningTeachingMethod),
    note: toStr(course.note),
    decisionNo: toStr(course.decisionNo),
    approvedDate: toStr(course.approvedDate),
    electiveGroups: (Array.isArray(course.electiveGroups) ? course.electiveGroups : []).map(toStr).filter(Boolean),
    lecturer: toStr(course.lecturer),
    link: toStr(course.link),
    resourceLinks,
    syllabusId: toStr(course.syllabusId),
    syllabusStatus: status,
    slots,
    labs,
    learningOutcomes,
    courseMaterials,
    constructiveQuestions,
    totalSlots: Math.max(slots.length, toInt(course.totalSlots, 0)),
    completedSlots: Math.max(0, toInt(course.completedSlots, 0)),
    archived: toBool(course.archived),
  };
}
