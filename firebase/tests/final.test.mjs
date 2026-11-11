import { after, before, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, query, onSnapshot, serverTimestamp, setDoc, updateDoc, where } from 'firebase/firestore';

const rules = readFileSync(resolve(import.meta.dirname, '../firestore.rules'), 'utf8');

let env;
const db = (uid) => uid ? env.authenticatedContext(uid).firestore() : env.unauthenticatedContext().firestore();
const plan = (uid, semester = 1, extra = {}) => ({
  uid, semester, summary: 'Study plan', status: 'pending', reason: '', createdAt: serverTimestamp(), ...extra,
});
const review = (uid, extra = {}) => ({
  status: 'approved', reason: 'Valid plan', reviewedAt: serverTimestamp(), reviewedBy: uid, ...extra,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-second-brain-final',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules,
    },
  });
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    await Promise.all([
      setDoc(doc(firestore, 'users/student'), { role: 'user' }),
      setDoc(doc(firestore, 'users/peer'), { role: 'user' }),
      setDoc(doc(firestore, 'users/staff'), { role: 'staff' }),
      setDoc(doc(firestore, 'users/admin'), { role: 'admin' }),
      setDoc(doc(firestore, 'users/legacy'), { currentSemester: 4 }),
    ]);
  });
});

after(async () => env?.cleanup());

test('role bootstrap, private profiles, and escalation protection', async () => {
  await assertFails(setDoc(doc(db('new'), 'users/new'), { role: 'admin' }));
  await assertSucceeds(setDoc(doc(db('new'), 'users/new'), { role: 'user' }));
  await assertSucceeds(updateDoc(doc(db('legacy'), 'users/legacy'), { role: 'user' }));
  await assertFails(updateDoc(doc(db('new'), 'users/new'), { role: 'staff' }));
  await assertFails(getDoc(doc(db('staff'), 'users/new')));
  await assertFails(updateDoc(doc(db('staff'), 'users/new'), { role: 'staff' }));
  await assertFails(updateDoc(doc(db('admin'), 'users/admin'), { role: 'staff' }));
  await assertSucceeds(updateDoc(doc(db('admin'), 'users/new'), { role: 'staff' }));
});

test('plans enforce ownership, shape, review and one terminal transition', async () => {
  const path = 'study_plan_submissions/student_1';
  await assertFails(setDoc(doc(db('student'), path), plan('peer')));
  await assertFails(setDoc(doc(db('student'), path), plan('student', 2)));
  await assertFails(setDoc(doc(db('student'), path), plan('student', 1, {status: 'approved'})));
  await assertFails(setDoc(doc(db('student'), path), plan('student', 1, {summary: 'x'.repeat(601)})));
  await assertSucceeds(setDoc(doc(db('student'), path), plan('student')));
  await assertFails(getDoc(doc(db('peer'), path)));
  await assertFails(getDoc(doc(db(), path)));
  await assertSucceeds(getDocs(query(collection(db('student'), 'study_plan_submissions'), where('uid', '==', 'student'))));
  await assertSucceeds(getDoc(doc(db('staff'), path)));
  await assertFails(updateDoc(doc(db('student'), path), review('student')));
  await assertFails(updateDoc(doc(db('staff'), path), review('staff', { uid: 'peer' })));
  await assertFails(updateDoc(doc(db('staff'), path), review('staff', { reason: '' })));
  await assertSucceeds(updateDoc(doc(db('staff'), path), review('staff')));
  await assertFails(updateDoc(doc(db('admin'), path), review('admin', { status: 'rejected' })));
});

test('announcements require privileged author and a valid payload', async () => {
  const payload = { title: 'Schedule', body: 'Check your course', publishedAt: serverTimestamp() };
  const path = 'announcements/demo';
  await assertFails(setDoc(doc(db('student'), path), { ...payload, authorUid: 'student' }));
  await assertFails(setDoc(doc(db('staff'), path), { ...payload, authorUid: 'admin' }));
  await assertSucceeds(setDoc(doc(db('staff'), path), { ...payload, authorUid: 'staff' }));
  await assertFails(getDoc(doc(db(), path)));
  await assertSucceeds(getDoc(doc(db('student'), path)));
  await assertFails(updateDoc(doc(db('staff'), path), { body: 'Changed' }));
});

test('catalog management preserves immutable code and supports archive', async () => {
  const path = 'courses/PRM393';
  const data = { code: 'PRM393', name: 'Mobile Programming', credits: 3, semester: 8, major: 'SE' };
  await assertFails(setDoc(doc(db('student'), path), data));
  await assertSucceeds(setDoc(doc(db('staff'), path), data));
  await assertSucceeds(getDoc(doc(db('student'), path)));
  await assertFails(updateDoc(doc(db('staff'), path), { code: 'PRM999' }));
  await assertSucceeds(updateDoc(doc(db('admin'), path), { archived: true }));
});

test('course import metadata and elective groups pass validation', async () => {
  const path = 'courses/BIT_SE_K19B__OPT101';
  const payload = {
    code: 'OPT101', name: 'Option One', credits: 3, semester: 5, major: 'BIT_SE_K19B',
    electiveGroups: ['SE_COM*1', 'SE_COM*2'],
    degreeLevel: 'Bachelor', timeAllocation: '30h theory', scoringScale: '10',
    minAvgMarkToPass: '5', learningTeachingMethod: 'Project based',
    note: 'Imported from FLM', decisionNo: '100/QD', approvedDate: '2026-10-19',
    slots: [], labs: [], learningOutcomes: [], courseMaterials: [],
  };
  await assertSucceeds(setDoc(doc(db('staff'), path), payload));
  await assertFails(setDoc(doc(db('staff'), path), { ...payload, code: 'WRONG' }));
  await assertFails(setDoc(doc(db('staff'), path), { ...payload, electiveGroups: 'SE_COM*1' }));
  await assertFails(setDoc(doc(db('staff'), path), { ...payload, degreeLevel: 123 }));
});

test('student listener receives staff decision without a refresh', async () => {
  const path = 'study_plan_submissions/student_3';
  await assertSucceeds(setDoc(doc(db('student'), path), plan('student', 3)));
  const ref = doc(db('student'), path);
  let unsubscribe;
  let timer;
  try {
    await new Promise((resolve, reject) => {
      timer = setTimeout(() => reject(new Error('decision listener timed out')), 10000);
      let reviewed = false;
      unsubscribe = onSnapshot(ref, (snapshot) => {
        if (snapshot.get('status') === 'pending' && !reviewed) {
          reviewed = true;
          assertSucceeds(updateDoc(doc(db('staff'), path), review('staff', {
            status: 'rejected', reason: 'Adjust workload',
          }))).catch(reject);
        }
        if (snapshot.get('status') === 'rejected' && snapshot.get('reason') === 'Adjust workload') {
          resolve();
        }
      }, reject);
    });
  } finally {
    clearTimeout(timer);
    unsubscribe?.();
  }
});

for (const name of ['tasks', 'notes', 'sync', 'notifications', 'tokens']) {
  test(`legacy ${name} is private to its owner`, async () => {
    const path = `users/student/${name}/private`;
    await assertSucceeds(setDoc(doc(db('student'), path), { example: true }));
    await assertSucceeds(getDoc(doc(db('student'), path)));
    for (const outsider of ['peer', 'staff', 'admin', null]) {
      await assertFails(getDoc(doc(db(outsider), path)));
      await assertFails(setDoc(doc(db(outsider), path), { example: false }));
    }
  });
}

test('curriculum is signed-in read only and audit log is owner-attributed append only', async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'curriculums/SE'), { name: 'Software Engineering' });
  });
  for (const role of ['student', 'staff', 'admin']) {
    const firestore = db(role);
    await assertSucceeds(getDoc(doc(firestore, 'curriculums/SE')));
    await assertFails(updateDoc(doc(firestore, 'curriculums/SE'), { name: 'Changed' }));
    const audit = doc(firestore, `audit_logs/${role}`);
    await assertSucceeds(setDoc(audit, { userId: role, action: 'test' }));
    await assertFails(getDoc(audit));
    await assertFails(updateDoc(audit, { action: 'changed' }));
    await assertFails(setDoc(doc(firestore, `audit_logs/forged-${role}`), { userId: 'peer' }));
  }
  await assertFails(getDoc(doc(db(), 'curriculums/SE')));
});

test('staff and admin cannot submit as students, students cannot read the review queue', async () => {
  for (const role of ['staff', 'admin']) {
    await assertFails(setDoc(doc(db(role), `study_plan_submissions/${role}_2`), plan(role, 2)));
    await assertSucceeds(getDocs(collection(db(role), 'study_plan_submissions')));
  }
  await assertFails(getDocs(collection(db('student'), 'study_plan_submissions')));
});

test('major-scoped courses support composite ids, "*" codes and semesters 0-12', async () => {
  const scoped = 'courses/BIT_SE_K19B__PRM393';
  const data = {
    code: 'PRM393', name: 'Mobile Programming', credits: 3, semester: 8,
    major: 'BIT_SE_K19B', slots: [], labs: [], learningOutcomes: [],
    courseMaterials: [], prerequisites: [], totalSlots: 0, completedSlots: 0,
    overview: '',
  };
  await assertSucceeds(setDoc(doc(db('staff'), scoped), data));
  await assertSucceeds(getDoc(doc(db('student'), scoped)));

  const pe = 'courses/BIT_SE_K19B__PHE_COM*1';
  await assertSucceeds(setDoc(doc(db('staff'), pe), {
    ...data, code: 'PHE_COM*1', name: 'Physical Education 1', credits: 2, semester: 0,
  }));

  await assertFails(setDoc(doc(db('staff'), 'courses/WRONG__PRM393'), data));
  await assertFails(setDoc(doc(db('student'), 'courses/BIT_SE_K19B__PRM393'), data));

  await assertSucceeds(setDoc(doc(db('staff'), 'majors/BIT_SE_K19B'), {
    code: 'BIT_SE_K19B', name: 'Software Engineering', totalSemesters: 9,
    description: '', archived: false,
  }));
  await assertSucceeds(updateDoc(doc(db('staff'), 'majors/BIT_SE_K19B'), { archived: true }));
  await assertFails(setDoc(doc(db('staff'), 'curriculums/legacy'), { name: 'Legacy' }));
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'curriculums/legacy'), { name: 'Legacy' });
  });
  await assertSucceeds(deleteDoc(doc(db('staff'), 'curriculums/legacy')));

  const domainOnly = env.authenticatedContext('domain-user', {
    email: 'academic.staff@fe.edu.vn',
  }).firestore();
  await assertFails(setDoc(doc(domainOnly, 'courses/SE_DOMAIN__PRM393'), {
    ...data, major: 'SE_DOMAIN',
  }));
});

test('experience notes: students submit pending, staff approve, approved notes are public', async () => {
  const courseId = 'BIT_SE_K19B__PRM393';
  await assertSucceeds(setDoc(doc(db('staff'), `courses/${courseId}`), {
    code: 'PRM393', name: 'Mobile Programming', credits: 3, semester: 8,
    major: 'BIT_SE_K19B', slots: [], labs: [], learningOutcomes: [],
    courseMaterials: [], prerequisites: [], totalSlots: 0, completedSlots: 0,
    overview: '',
  }));

  const note = (uid, extra = {}) => ({
    courseDocId: courseId,
    courseCode: 'PRM393',
    courseName: 'Mobile Programming',
    major: 'BIT_SE_K19B',
    uid,
    authorName: 'Student ' + uid,
    title: 'Kinh nghiem hoc PRM393',
    content: 'Thay Tung day rat de hieu, nen hoc ky nay de qua mon.',
    lecturerTip: 'Chon thay Tung',
    examTip: 'On PE theo de mau',
    rating: 5,
    status: 'pending',
    createdAt: serverTimestamp(),
    ...extra,
  });
  const path = 'experience_notes/note-1';

  await assertFails(setDoc(doc(db('student'), path), note('peer')));
  await assertFails(setDoc(doc(db('student'), path), note('student', { status: 'approved' })));
  await assertFails(setDoc(doc(db('student'), path), note('student', { content: 'too short' })));
  await assertFails(setDoc(doc(db('student'), path), note('student', { courseDocId: 'MISSING__PRM393' })));
  await assertSucceeds(setDoc(doc(db('student'), path), note('student')));
  await assertFails(getDoc(doc(db('peer'), path)));
  await assertSucceeds(getDoc(doc(db('staff'), path)));

  const decision = (uid, status = 'approved', extra = {}) => ({
    status, reason: 'Noi dung huu ich', reviewedBy: uid, reviewedAt: serverTimestamp(), ...extra,
  });
  await assertFails(updateDoc(doc(db('student'), path), decision('student')));
  await assertFails(updateDoc(doc(db('staff'), path), decision('staff', 'approved', { reason: '' })));
  await assertFails(updateDoc(doc(db('staff'), path), decision('staff', 'approved', { reviewedBy: 'student' })));
  await assertSucceeds(updateDoc(doc(db('staff'), path), decision('staff')));
  await assertSucceeds(getDoc(doc(db('peer'), path)));
  await assertFails(updateDoc(doc(db('admin'), path), decision('admin', 'rejected')));

  const second = 'experience_notes/note-2';
  await assertSucceeds(setDoc(doc(db('student'), second), note('student')));
  await assertFails(deleteDoc(doc(db('peer'), second)));
  await assertSucceeds(deleteDoc(doc(db('student'), second)));
});
