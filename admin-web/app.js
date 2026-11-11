import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-app.js';
import {
  getAuth,
  signInWithPopup,
  GoogleAuthProvider,
  signOut,
  onAuthStateChanged,
  connectAuthEmulator,
} from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-auth.js';
import {
  getFirestore,
  collection,
  doc,
  getDoc,
  getDocs,
  updateDoc,
  deleteDoc,
  addDoc,
  setDoc,
  onSnapshot,
  query,
  where,
  orderBy,
  writeBatch,
  serverTimestamp,
  getCountFromServer,
  connectFirestoreEmulator,
} from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-firestore.js';

import {
  getAnalytics,
  logEvent,
  setUserId as setAnalyticsUserId,
} from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-analytics.js';
import {
  getRemoteConfig,
  fetchAndActivate,
  getValue,
} from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-remote-config.js';
import {
  initializeAppCheck,
  ReCaptchaV3Provider,
} from 'https://www.gstatic.com/firebasejs/11.0.2/firebase-app-check.js';

import { mergeFlmFiles, detectFlmHtmlType } from './flm-parser.js';
import { normalizeCourse } from './course-payload.js';

const firebaseConfig = {
  apiKey: 'AIzaSyDV1qOOU77kxoE_eOrDZgKf2Sqr_qWwvr4',
  authDomain: 'prm323-lab2-gr6.firebaseapp.com',
  projectId: 'prm323-lab2-gr6',
  storageBucket: 'prm323-lab2-gr6.firebasestorage.app',
  messagingSenderId: '510519082861',
  appId: '1:510519082861:android:4cf5b64c4e2e4487c46464',
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const googleProvider = new GoogleAuthProvider();

// ── App Check (optional until a reCAPTCHA v3 key is registered) ──
// The web app registration in Firebase Console provides the site key; keep it
// in index.html as <meta name="recaptcha-site-key" content="...">.
const recaptchaSiteKey = document
  .querySelector('meta[name="recaptcha-site-key"]')
  ?.getAttribute('content')
  ?.trim();
if (recaptchaSiteKey) {
  try {
    initializeAppCheck(app, {
      provider: new ReCaptchaV3Provider(recaptchaSiteKey),
      isTokenAutoRefreshEnabled: true,
    });
  } catch (error) {
    console.warn('App Check init failed', error);
  }
} else {
  console.info('App Check skipped: no reCAPTCHA site key configured.');
}

// ── Analytics (needs a registered Web App with measurementId) ──
let analytics = null;
try {
  if (firebaseConfig.measurementId) analytics = getAnalytics(app);
} catch (error) {
  console.warn('Analytics unavailable', error);
}

function track(eventName, params = {}) {
  if (!analytics) return;
  try {
    logEvent(analytics, eventName, params);
  } catch (error) {
    console.warn('logEvent failed', eventName, error);
  }
}

// ── Remote Config: `maintenance_mode` drives the staff banner ──
const remoteConfig = getRemoteConfig(app);
remoteConfig.settings.minimumFetchIntervalMillis = 300000;

async function applyRemoteConfig() {
  try {
    await fetchAndActivate(remoteConfig);
    const maintenance = getValue(remoteConfig, 'maintenance_mode').asBoolean();
    const banner = $('maintenance-banner');
    if (banner) banner.style.display = maintenance ? 'flex' : 'none';
    return maintenance;
  } catch (error) {
    console.warn('Remote Config fetch failed; keeping defaults', error);
    return false;
  }
}

if (window.location.search.includes('emulator=true')) {
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  connectFirestoreEmulator(db, '127.0.0.1', 8080);
  console.info('Connected to Firebase Local Emulators (auth 9099, firestore 8080).');
}

const COURSE_CODE_RE = /^[A-Za-z][A-Za-z0-9_.*-]{1,23}$/;
const MAJOR_CODE_RE = /^[A-Za-z0-9_.-]{2,30}$/;
const SYLLABUS_STATUSES = ['complete', 'partial', 'metadata', 'manual'];
const NOTE_STATUSES = ['pending', 'approved', 'rejected'];

const state = {
  currentUser: null,
  activeView: 'dashboard',
  unsubscribers: [],
  majors: [],
  courses: [],
  notes: [],
  announcements: [],
  noteStatusFilter: 'pending',
  currentReviewNoteId: null,
  currentReviewNote: null,
  majorDraft: null,
  editingMajorCode: null,
  courseEditDraft: null,
  editingCourseIndex: null,
  importFiles: [],
  importResult: null,
  chartNotes: null,
  chartCourses: null,
  countErrorShown: false,
};

const $ = id => document.getElementById(id);

function toStr(value) {
  return value === null || value === undefined ? '' : String(value);
}

function esc(value) {
  return toStr(value).replace(/[&<>"']/g, ch => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;',
  }[ch]));
}

function toInt(value, fallback = 0) {
  const parsed = parseInt(String(value).replace(/[^0-9-]/g, ''), 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function toNumber(value, fallback = 0) {
  const parsed = parseFloat(String(value).replace(/[^0-9.-]/g, ''));
  return Number.isFinite(parsed) ? parsed : fallback;
}

function toBool(value) {
  return value === true || value === 'true' || value === 1 || value === '1';
}

function truncate(value, max = 90) {
  const text = toStr(value).trim();
  if (text.length <= max) return text;
  return `${text.slice(0, max)}…`;
}

function deepClone(value) {
  return JSON.parse(JSON.stringify(value));
}

function stripUndefined(value) {
  if (Array.isArray(value)) return value.map(stripUndefined);
  if (value && typeof value === 'object') {
    if (typeof value._methodName === 'string') return value;
    const out = {};
    Object.entries(value).forEach(([key, item]) => {
      if (item !== undefined) out[key] = stripUndefined(item);
    });
    return out;
  }
  return value;
}

function showToast(message, type = 'info', durationMs = 3800) {
  const container = $('toast-container');
  if (!container) return;
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.innerHTML = `
    <span class="material-symbols-outlined">${type === 'success' ? 'check_circle' : type === 'error' ? 'error' : 'info'}</span>
    <span>${esc(message)}</span>
  `;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(10px)';
    toast.style.transition = 'all 0.25s ease';
    setTimeout(() => toast.remove(), 250);
  }, durationMs);
}

function formatDate(timestamp) {
  if (!timestamp) return 'Chưa có';
  let date;
  if (typeof timestamp.toDate === 'function') {
    date = timestamp.toDate();
  } else if (timestamp instanceof Date) {
    date = timestamp;
  } else if (timestamp.seconds) {
    date = new Date(timestamp.seconds * 1000);
  } else {
    date = new Date(timestamp);
  }
  if (Number.isNaN(date.getTime())) return 'Chưa có';
  const pad = n => String(n).padStart(2, '0');
  return `${pad(date.getDate())}/${pad(date.getMonth() + 1)}/${date.getFullYear()} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function setBusy(visible, text = 'Đang xử lý...') {
  const overlay = $('app-loading');
  if (!overlay) return;
  overlay.style.display = visible ? 'flex' : 'none';
  const label = $('app-loading-text');
  if (label) label.textContent = text;
}

function openModal(id) {
  const modal = $(id);
  if (modal) modal.classList.add('open');
}

function closeModal(id) {
  const modal = $(id);
  if (modal) modal.classList.remove('open');
}

let appDialogState = null;

/**
 * Styled replacement for window.confirm/window.prompt.
 * - Without `expected`: resolves true (confirm) or false (cancel).
 * - With `expected`: shows an input and resolves the typed text when it
 *   matches, otherwise null. Wrong text keeps the dialog open with an error.
 */
function showAppDialog({
  title = 'Xác nhận',
  message = '',
  confirmLabel = 'Xác nhận',
  cancelLabel = 'Hủy',
  danger = false,
  expected = null,
  inputHint = '',
} = {}) {
  return new Promise(resolve => {
    appDialogState = { resolve, expected };
    $('app-dialog-title').textContent = title;
    $('app-dialog-message').textContent = message;
    const ok = $('app-dialog-ok');
    ok.textContent = confirmLabel;
    ok.classList.toggle('btn-danger', danger);
    ok.classList.toggle('btn-primary', !danger);
    $('app-dialog-cancel').textContent = cancelLabel;

    const input = $('app-dialog-input');
    const inputWrap = $('app-dialog-input-wrap');
    input.value = '';
    if (expected) {
      inputWrap.style.display = 'block';
      input.placeholder = inputHint || `Nhập ${expected}`;
    } else {
      inputWrap.style.display = 'none';
      input.placeholder = '';
    }
    $('app-dialog-error').style.display = 'none';

    openModal('modal-app-dialog');
    setTimeout(() => (expected ? input : ok).focus(), 40);
  });
}

function settleAppDialog(confirmed) {
  const state = appDialogState;
  if (!state) return;
  const input = $('app-dialog-input');
  if (confirmed && state.expected) {
    const typed = (input.value || '').trim();
    if (typed !== state.expected) {
      const error = $('app-dialog-error');
      error.textContent = `Vui lòng nhập đúng "${state.expected}" để tiếp tục.`;
      error.style.display = 'block';
      input.focus();
      return;
    }
  }
  appDialogState = null;
  closeModal('modal-app-dialog');
  if (state.expected) {
    state.resolve(confirmed ? (input.value || '').trim() : null);
  } else {
    state.resolve(Boolean(confirmed));
  }
}

$('app-dialog-ok')?.addEventListener('click', () => settleAppDialog(true));
$('app-dialog-cancel')?.addEventListener('click', () => settleAppDialog(false));
$('app-dialog-input')?.addEventListener('keydown', event => {
  if (event.key === 'Enter') {
    event.preventDefault();
    settleAppDialog(true);
  }
});
$('modal-app-dialog')?.addEventListener('click', event => {
  if (event.target === $('modal-app-dialog')) settleAppDialog(false);
});
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && appDialogState) settleAppDialog(false);
});

function setSigninLoading(visible) {
  const loading = $('signin-loading');
  if (loading) loading.style.display = visible ? 'block' : 'none';
}

function showAuthError(message) {
  const alert = $('signin-error-alert');
  const text = $('signin-error-text');
  if (alert) alert.style.display = 'flex';
  if (text) text.textContent = message;
}

function hideAuthError() {
  const alert = $('signin-error-alert');
  if (alert) alert.style.display = 'none';
}

function statusLabel(status) {
  return status === 'approved' ? 'Đã duyệt' : status === 'rejected' ? 'Từ chối' : 'Chờ duyệt';
}

function statusBadge(status) {
  const safe = NOTE_STATUSES.includes(status) ? status : 'pending';
  return `<span class="status-badge ${safe}">${statusLabel(safe)}</span>`;
}

function syllabusLabel(status) {
  if (status === 'complete') return 'Đầy đủ';
  if (status === 'partial') return 'Một phần';
  if (status === 'manual') return 'Thủ công';
  return 'Chưa có';
}

function courseDocId(majorCode, courseCode) {
  return `${majorCode}__${courseCode}`;
}

function courseMajorOf(course) {
  if (course.major) return course.major;
  const id = course._docId || '';
  return id.includes('__') ? id.split('__')[0] : '';
}

function blankMajor() {
  return {
    code: '',
    name: '',
    nameEn: '',
    description: '',
    totalSemesters: 9,
    source: 'manual',
    archived: false,
  };
}

function blankCourse() {
  return {
    _docId: null,
    code: '',
    name: '',
    nameVi: '',
    semester: 1,
    credits: 3,
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
    electiveGroups: [],
    lecturer: '',
    link: '',
    resourceLinks: { drive: '', notion: '', github: '' },
    syllabusId: '',
    syllabusStatus: 'metadata',
    slots: [],
    labs: [],
    learningOutcomes: [],
    courseMaterials: [],
    constructiveQuestions: [],
    totalSlots: 0,
    completedSlots: 0,
    archived: false,
  };
}

async function runBatch(operations) {
  for (let i = 0; i < operations.length; i += 400) {
    const batch = writeBatch(db);
    for (const operation of operations.slice(i, i + 400)) {
      if (operation.type === 'delete') {
        batch.delete(operation.ref);
      } else if (operation.type === 'update') {
        batch.update(operation.ref, stripUndefined(operation.data));
      } else {
        batch.set(operation.ref, stripUndefined(operation.data), operation.options || {});
      }
    }
    await batch.commit();
  }
}

function switchView(viewName) {
  state.activeView = viewName;
  document.querySelectorAll('.nav-item').forEach(button => {
    button.classList.toggle('active', button.dataset.view === viewName);
  });
  document.querySelectorAll('.view-panel').forEach(panel => panel.classList.remove('active'));
  const target = $(`view-${viewName}`);
  if (target) target.classList.add('active');

  if (viewName === 'dashboard') {
    renderDashboardCharts();
    renderDashboardNotes();
  } else if (viewName === 'majors') {
    renderMajors();
  } else if (viewName === 'reviews') {
    renderReviewsTable();
  } else if (viewName === 'announcements') {
    renderAnnouncements();
  }
}

async function verifyAccess(user) {
  setSigninLoading(true);
  hideAuthError();
  try {
    const snapshot = await getDoc(doc(db, 'users', user.uid));
    const role = snapshot.exists() ? toStr(snapshot.data().role) || 'user' : 'user';
    if (role !== 'staff' && role !== 'admin') {
      await signOut(auth);
      showAuthError('Tài khoản sinh viên không có quyền truy cập cổng Quản trị. Vui lòng liên hệ Phòng Đào tạo hoặc đăng nhập bằng tài khoản Cán bộ (Staff/Admin).');
      showToast('Từ chối truy cập: tài khoản không có vai trò Staff/Admin', 'error');
      return;
    }
    state.currentUser = {
      uid: user.uid,
      email: user.email || '',
      displayName: user.displayName || user.email?.split('@')[0] || 'Quản trị viên',
      photoURL: user.photoURL || '',
      role,
    };
    if (analytics) setAnalyticsUserId(analytics, user.uid);
    track('login', { method: 'google', role });
    enterApp();
    showToast(`Chào mừng ${state.currentUser.displayName} (${role.toUpperCase()})`, 'success');
  } catch (error) {
    console.error('verifyAccess', error);
    showAuthError(`Lỗi kết nối Firebase: ${error.message}`);
    try {
      await signOut(auth);
    } catch (signOutError) {
      console.warn(signOutError);
    }
  } finally {
    setSigninLoading(false);
  }
}

function enterApp() {
  const signin = $('view-signin');
  if (signin) signin.classList.remove('active');
  const sidebar = $('app-sidebar');
  if (sidebar) sidebar.style.display = 'flex';
  const headerUser = $('header-user-area');
  if (headerUser) headerUser.style.display = 'flex';

  const avatar = $('header-avatar');
  const nameLabel = $('header-user-name');
  const roleBadge = $('header-role-badge');
  const authorDisplay = $('ann-author-display');

  if (state.currentUser) {
    if (avatar) avatar.textContent = (state.currentUser.displayName || 'A').charAt(0).toUpperCase();
    if (nameLabel) nameLabel.textContent = state.currentUser.displayName;
    if (roleBadge) {
      roleBadge.textContent = state.currentUser.role.toUpperCase();
      roleBadge.className = `role-pill ${state.currentUser.role}`;
    }
    if (authorDisplay) {
      authorDisplay.textContent = `${state.currentUser.displayName} (${state.currentUser.email || state.currentUser.uid})`;
    }
  }

  startSubscriptions();
  switchView('dashboard');
  applyRemoteConfig();
  refreshDashboardCounts();
}

function teardownSession() {
  state.unsubscribers.forEach(unsubscribe => {
    try {
      unsubscribe();
    } catch (error) {
      console.warn(error);
    }
  });
  state.unsubscribers = [];
  state.currentUser = null;
  state.majors = [];
  state.courses = [];
  state.notes = [];
  state.announcements = [];
  state.majorDraft = null;
  state.courseEditDraft = null;
  state.importFiles = [];
  state.importResult = null;

  if (state.chartNotes) {
    state.chartNotes.destroy();
    state.chartNotes = null;
  }
  if (state.chartCourses) {
    state.chartCourses.destroy();
    state.chartCourses = null;
  }

  const sidebar = $('app-sidebar');
  if (sidebar) sidebar.style.display = 'none';
  const headerUser = $('header-user-area');
  if (headerUser) headerUser.style.display = 'none';

  document.querySelectorAll('.view-panel').forEach(panel => panel.classList.remove('active'));
  const signin = $('view-signin');
  if (signin) signin.classList.add('active');

  ['stat-total-students', 'stat-pending-notes', 'stat-approved-notes', 'stat-majors'].forEach(id => {
    const el = $(id);
    if (el) el.textContent = '--';
  });

  const badge = $('nav-pending-badge');
  if (badge) {
    badge.textContent = '0';
    badge.style.display = 'none';
  }

  renderMajors();
  renderReviewsTable();
  renderAnnouncements();
  renderDashboardNotes();
  renderDashboardCharts();
}

function handleSnapshotError(label, error) {
  console.error(label, error);
  showToast(`${label}: ${error.code || error.message}`, 'error', 5200);
}

// Persistent per-screen error state with retry. A toast disappears, so the
// screen itself must state that data failed to load (Final §7).
function showScreenError(view, label, error) {
  const panel = $(`view-${view}`);
  if (!panel) return;
  let box = panel.querySelector('.screen-error');
  if (!box) {
    box = document.createElement('div');
    box.className = 'screen-error';
    panel.prepend(box);
  }
  box.innerHTML = `<div><strong>${esc(label)}</strong><p>${esc(error.code || error.message || String(error))}</p><button class="btn btn-outline btn-sm" type="button">Thử lại</button></div>`;
  box.querySelector('button').addEventListener('click', () => {
    box.remove();
    startSubscriptions();
  });
}

function clearScreenError(view) {
  $(`view-${view}`)?.querySelector('.screen-error')?.remove();
}

function startSubscriptions() {
  state.unsubscribers.forEach(unsubscribe => {
    try {
      unsubscribe();
    } catch (error) {
      console.warn(error);
    }
  });
  state.unsubscribers = [];

  const majorsUnsub = onSnapshot(collection(db, 'majors'), snapshot => {
    state.majors = snapshot.docs.map(item => ({ ...item.data(), _docId: item.id }));
    clearScreenError('majors');
    if (state.activeView === 'majors') renderMajors();
    updateDashboardNumbers();
    renderDashboardCharts();
  }, error => {
    handleSnapshotError('Không tải được chuyên ngành', error);
    showScreenError('majors', 'Không tải được danh sách chuyên ngành', error);
  });
  state.unsubscribers.push(majorsUnsub);

  const coursesUnsub = onSnapshot(collection(db, 'courses'), snapshot => {
    state.courses = snapshot.docs.map(item => {
      const data = item.data();
      return {
        ...data,
        _docId: item.id,
        major: toStr(data.major) || (item.id.includes('__') ? item.id.split('__')[0] : ''),
      };
    });
    if (state.activeView === 'majors') renderMajors();
    renderDashboardCharts();
  }, error => {
    handleSnapshotError('Không tải được môn học', error);
    showScreenError('majors', 'Không tải được danh sách môn học', error);
  });
  state.unsubscribers.push(coursesUnsub);

  const notesUnsub = onSnapshot(
    query(collection(db, 'experience_notes'), orderBy('createdAt', 'desc')),
    snapshot => {
      state.notes = snapshot.docs.map(item => ({ ...item.data(), _docId: item.id }));
      updatePendingBadge();
      updateDashboardNumbers();
      renderDashboardCharts();
      renderDashboardNotes();
      if (state.activeView === 'reviews') renderReviewsTable();
    },
    error => {
      handleSnapshotError('Không tải được bí kíp sinh viên', error);
      showScreenError('reviews', 'Không tải được hàng đợi duyệt', error);
    },
  );
  state.unsubscribers.push(notesUnsub);

  const announcementsUnsub = onSnapshot(
    query(collection(db, 'announcements'), orderBy('publishedAt', 'desc')),
    snapshot => {
      state.announcements = snapshot.docs.map(item => ({ ...item.data(), _docId: item.id }));
      clearScreenError('announcements');
      renderAnnouncements();
    },
    error => {
      handleSnapshotError('Không tải được thông báo', error);
      showScreenError('announcements', 'Không tải được thông báo', error);
    },
  );
  state.unsubscribers.push(announcementsUnsub);
}

async function refreshDashboardCounts() {
  try {
    const isAdmin = state.currentUser?.role === 'admin';
    const [usersSnap, pendingSnap, approvedSnap, majorsSnap] = await Promise.all([
      isAdmin ? getCountFromServer(collection(db, 'users')) : Promise.resolve(null),
      getCountFromServer(query(collection(db, 'experience_notes'), where('status', '==', 'pending'))),
      getCountFromServer(query(collection(db, 'experience_notes'), where('status', '==', 'approved'))),
      getCountFromServer(collection(db, 'majors')),
    ]);
    const setText = (id, value) => {
      const el = $(id);
      if (el) el.textContent = value;
    };
    setText('stat-total-students', isAdmin ? usersSnap.data().count : '—');
    setText('stat-pending-notes', pendingSnap.data().count);
    setText('stat-approved-notes', approvedSnap.data().count);
    setText('stat-majors', majorsSnap.data().count);
  } catch (error) {
    console.warn('refreshDashboardCounts', error);
    if (!state.countErrorShown) {
      state.countErrorShown = true;
      showToast(`Không lấy được số liệu tổng hợp: ${error.code || error.message}`, 'error', 5200);
    }
  }
}

function updateDashboardNumbers() {
  const setText = (id, value) => {
    const el = $(id);
    if (el) el.textContent = value;
  };
  setText('stat-pending-notes', state.notes.filter(note => note.status === 'pending').length);
  setText('stat-approved-notes', state.notes.filter(note => note.status === 'approved').length);
  setText('stat-majors', state.majors.length);
}

function updatePendingBadge() {
  const pending = state.notes.filter(note => note.status === 'pending').length;
  const badge = $('nav-pending-badge');
  if (badge) {
    badge.textContent = String(pending);
    badge.style.display = pending > 0 ? 'inline-block' : 'none';
  }
}

function renderDashboardCharts() {
  const notesCanvas = $('chart-notes-status');
  const coursesCanvas = $('chart-courses-semester');
  if (!notesCanvas || !coursesCanvas || typeof window.Chart === 'undefined') return;

  if (state.chartNotes) state.chartNotes.destroy();
  if (state.chartCourses) state.chartCourses.destroy();

  const counts = { pending: 0, approved: 0, rejected: 0 };
  state.notes.forEach(note => {
    const status = NOTE_STATUSES.includes(note.status) ? note.status : 'pending';
    counts[status] += 1;
  });

  state.chartNotes = new window.Chart(notesCanvas, {
    type: 'doughnut',
    data: {
      labels: ['Chờ duyệt', 'Đã duyệt', 'Từ chối'],
      datasets: [{
        data: [counts.pending, counts.approved, counts.rejected],
        backgroundColor: ['#D97706', '#16A34A', '#DC2626'],
        borderWidth: 0,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { position: 'bottom' } },
    },
  });

  const bySemester = {};
  state.courses.forEach(course => {
    const semester = toInt(course.semester, 0);
    bySemester[semester] = (bySemester[semester] || 0) + 1;
  });
  const semesters = Object.keys(bySemester).map(Number).sort((a, b) => a - b);
  const labels = semesters.length
    ? semesters.map(semester => semester === 0 ? 'Kỳ 0 / khác' : `Kỳ ${semester}`)
    : ['Chưa có dữ liệu'];

  state.chartCourses = new window.Chart(coursesCanvas, {
    type: 'bar',
    data: {
      labels,
      datasets: [{
        label: 'Số môn học',
        data: semesters.length ? semesters.map(semester => bySemester[semester]) : [0],
        backgroundColor: '#2563EB',
        borderRadius: 6,
        maxBarThickness: 42,
      }],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: { y: { beginAtZero: true, ticks: { precision: 0 } } },
    },
  });
}

function renderDashboardNotes() {
  const tbody = $('dashboard-recent-notes');
  if (!tbody) return;
  const recent = state.notes.slice(0, 8);
  if (!recent.length) {
    tbody.innerHTML = '<tr><td colspan="5" class="empty-cell">Chưa có bí kíp nào được sinh viên gửi.</td></tr>';
    return;
  }
  tbody.innerHTML = recent.map(note => `
    <tr>
      <td>${esc(note.authorName || note.uid || 'Sinh viên')}</td>
      <td><strong>${esc(note.courseCode || '')}</strong> ${esc(truncate(note.courseName, 40))}</td>
      <td title="${esc(note.content)}">${esc(truncate(note.content, 70))}</td>
      <td>${statusBadge(note.status)}</td>
      <td>${esc(formatDate(note.createdAt))}</td>
    </tr>
  `).join('');
}

function renderMajors() {
  const container = $('majors-cards-container');
  if (!container) return;

  const search = toStr($('major-search-input')?.value).trim().toLowerCase();
  const statusFilter = $('major-status-filter')?.value || 'active';

  const filtered = state.majors.filter(major => {
    const archived = toBool(major.archived);
    if (statusFilter === 'active' && archived) return false;
    if (statusFilter === 'archived' && !archived) return false;
    if (!search) return true;
    return `${major.code} ${major.name} ${major.nameEn || ''}`.toLowerCase().includes(search);
  });

  const countDisplay = $('major-count-display');
  if (countDisplay) {
    countDisplay.textContent = `${filtered.length}/${state.majors.length} chuyên ngành`;
  }

  if (!filtered.length) {
    container.innerHTML = `
      <div class="state-empty" style="grid-column: 1 / -1;">
        ${state.majors.length ? 'Không có chuyên ngành nào khớp bộ lọc.' : 'Chưa có chuyên ngành nào. Bấm “Thêm chuyên ngành” để bắt đầu.'}
      </div>
    `;
    return;
  }

  container.innerHTML = filtered
    .slice()
    .sort((a, b) => toStr(a.code).localeCompare(toStr(b.code)))
    .map(major => {
      const code = toStr(major.code || major._docId);
      const courses = state.courses.filter(course => courseMajorOf(course) === code);
      const credits = courses.reduce((sum, course) => sum + toInt(course.credits, 0), 0);
      const archived = toBool(major.archived);
      const source = major.source === 'flm_html' ? 'FLM HTML' : 'Thủ công';
      return `
        <div class="major-card ${archived ? 'archived' : ''}">
          <div class="major-card-header">
            <span class="major-code-badge">${esc(code)}</span>
            ${archived ? '<span class="status-badge archived">Lưu trữ</span>' : '<span class="status-badge active">Hoạt động</span>'}
          </div>
          <div class="major-card-title">${esc(major.name || '(Chưa có tên)')}</div>
          <div class="major-card-desc">${esc(truncate(major.description || 'Chưa có mô tả chương trình.', 180))}</div>
          <div class="major-card-meta">
            <span>${toInt(major.totalSemesters, 9)} học kỳ</span>
            <span>${courses.length} môn</span>
            <span>${credits} tín chỉ</span>
            <span class="status-inline">${esc(source)}</span>
          </div>
          <div class="major-card-actions">
            <button class="btn btn-outline btn-sm" data-action="edit-major" data-code="${esc(code)}">
              <span class="material-symbols-outlined">edit</span> Xem / sửa
            </button>
            <button class="btn btn-danger btn-sm" data-action="delete-major" data-code="${esc(code)}">
              <span class="material-symbols-outlined">delete</span> Xóa
            </button>
          </div>
        </div>
      `;
    })
    .join('');
}

function openMajorEditor(code) {
  const isEdit = Boolean(code);
  let major = blankMajor();
  let courses = [];

  if (isEdit) {
    const found = state.majors.find(item => (item.code || item._docId) === code);
    if (!found) {
      showToast('Không tìm thấy chuyên ngành.', 'error');
      return;
    }
    major = {
      code,
      name: toStr(found.name),
      nameEn: toStr(found.nameEn),
      description: toStr(found.description),
      totalSemesters: toInt(found.totalSemesters, 9),
      source: toStr(found.source) || 'manual',
      archived: toBool(found.archived),
    };
    courses = state.courses
      .filter(course => courseMajorOf(course) === code)
      .map(course => deepClone(course));
  }

  state.editingMajorCode = isEdit ? code : null;
  state.majorDraft = { major, courses };

  $('major-editor-title').textContent = isEdit ? `Chuyên ngành ${code}` : 'Thêm chuyên ngành mới';
  $('major-code').value = major.code;
  $('major-name').value = major.name;
  $('major-name-en').value = major.nameEn;
  $('major-semesters').value = major.totalSemesters;
  $('major-archived').checked = major.archived;
  $('major-desc').value = major.description;
  $('btn-delete-major').style.display = isEdit ? 'inline-flex' : 'none';

  renderMajorCoursesTable();
  openModal('modal-major-editor');
}

function renderMajorCoursesTable() {
  const tbody = $('major-course-tbody');
  if (!tbody || !state.majorDraft) return;
  const courses = state.majorDraft.courses;

  const summary = $('major-course-summary');
  if (summary) {
    const credits = courses.reduce((sum, course) => sum + toInt(course.credits, 0), 0);
    summary.textContent = `${courses.length} môn học • ${credits} tín chỉ`;
  }

  if (!courses.length) {
    tbody.innerHTML = '<tr><td colspan="7" class="empty-cell">Chưa có môn học. Bấm “Thêm môn” hoặc nhập từ file FLM.</td></tr>';
    return;
  }

  tbody.innerHTML = courses.map((course, index) => `
    <tr>
      <td><strong>${esc(course.code)}</strong></td>
      <td>${esc(truncate(course.name, 55))}${course.nameVi ? `<br><span class="muted-text">${esc(truncate(course.nameVi, 55))}</span>` : ''}${(course.electiveGroups || []).length ? `<br><span class="muted-text">Tự chọn: ${esc(course.electiveGroups.join(', '))}</span>` : ''}</td>
      <td>${toInt(course.semester, 0)}</td>
      <td>${toInt(course.credits, 0)}</td>
      <td>${(Array.isArray(course.slots) ? course.slots.length : toInt(course.totalSlots, 0))}</td>
      <td>${esc(syllabusLabel(course.syllabusStatus))}</td>
      <td style="text-align: right; white-space: nowrap;">
        <button class="icon-btn" style="color: var(--color-primary);" data-action="edit-course" data-index="${index}" title="Sửa môn">
          <span class="material-symbols-outlined">edit</span>
        </button>
        <button class="icon-btn" data-action="remove-course" data-index="${index}" title="Xóa môn">
          <span class="material-symbols-outlined">delete</span>
        </button>
      </td>
    </tr>
  `).join('');
}

function syncMajorForm() {
  if (!state.majorDraft) return;
  state.majorDraft.major = {
    code: $('major-code').value.trim(),
    name: $('major-name').value.trim(),
    nameEn: $('major-name-en').value.trim(),
    description: $('major-desc').value.trim(),
    totalSemesters: toInt($('major-semesters').value, 9),
    source: state.majorDraft.major.source || 'manual',
    archived: $('major-archived').checked,
  };
}

async function saveMajor() {
  if (!state.majorDraft) return;
  syncMajorForm();

  const major = state.majorDraft.major;
  const courses = state.majorDraft.courses;

  if (!MAJOR_CODE_RE.test(major.code)) {
    showToast('Mã chuyên ngành chỉ gồm chữ, số hoặc _ . - và dài 2–30 ký tự.', 'error');
    return;
  }
  if (!major.name) {
    showToast('Vui lòng nhập tên chuyên ngành.', 'error');
    return;
  }
  if (major.totalSemesters < 1 || major.totalSemesters > 12) {
    showToast('Tổng số học kỳ phải từ 1 đến 12.', 'error');
    return;
  }

  const seenCodes = new Set();
  for (const course of courses) {
    const code = toStr(course.code).trim();
    if (!COURSE_CODE_RE.test(code)) {
      showToast(`Mã môn “${code || '(trống)'}” không hợp lệ.`, 'error');
      return;
    }
    if (!toStr(course.name).trim()) {
      showToast(`Môn ${code} chưa có tên.`, 'error');
      return;
    }
    if (toInt(course.semester, 0) < 0 || toInt(course.semester, 0) > 12) {
      showToast(`Học kỳ của môn ${code} phải từ 0 đến 12.`, 'error');
      return;
    }
    if (toInt(course.credits, 0) < 0 || toInt(course.credits, 0) > 30) {
      showToast(`Số tín chỉ của môn ${code} phải từ 0 đến 30.`, 'error');
      return;
    }
    const key = code.toLowerCase();
    if (seenCodes.has(key)) {
      showToast(`Môn ${code} bị trùng trong chuyên ngành.`, 'error');
      return;
    }
    seenCodes.add(key);
  }

  const oldCode = state.editingMajorCode;
  const codeChanged = Boolean(oldCode && oldCode !== major.code);
  if (codeChanged) {
    const proceed = await showAppDialog({
      title: 'Đổi mã chuyên ngành',
      message: `Đổi mã chuyên ngành từ ${oldCode} sang ${major.code}? Toàn bộ môn học sẽ được chuyển theo mã mới.`,
      confirmLabel: 'Đổi mã',
    });
    if (!proceed) return;
  }

  const existingCourses = oldCode
    ? state.courses.filter(course => courseMajorOf(course) === oldCode)
    : [];
  const newDocIds = new Set(courses.map(course => courseDocId(major.code, toStr(course.code).trim())));
  const removed = codeChanged
    ? []
    : existingCourses.filter(course => !newDocIds.has(course._docId || courseDocId(major.code, toStr(course.code))));

  if (removed.length) {
    const proceed = await showAppDialog({
      title: 'Xóa môn không còn trong chuyên ngành',
      message: `Có ${removed.length} môn sẽ bị xóa: ${removed.map(course => course.code).join(', ')}. Tiếp tục lưu chuyên ngành?`,
      confirmLabel: 'Tiếp tục',
      danger: true,
    });
    if (!proceed) return;
  }

  const operations = [];
  const majorPayload = stripUndefined({
    code: major.code,
    name: major.name,
    nameEn: major.nameEn,
    description: major.description,
    totalSemesters: major.totalSemesters,
    source: major.source,
    archived: major.archived,
  });

  if (codeChanged) {
    operations.push({ type: 'delete', ref: doc(db, 'majors', oldCode) });
    existingCourses.forEach(course => {
      operations.push({ type: 'delete', ref: doc(db, 'courses', course._docId || courseDocId(oldCode, toStr(course.code))) });
    });
  }

  operations.push({ type: 'set', ref: doc(db, 'majors', major.code), data: majorPayload });
  courses.forEach(course => {
    const code = toStr(course.code).trim();
    const id = courseDocId(major.code, code);
    operations.push({
      type: 'set',
      ref: doc(db, 'courses', id),
      data: normalizeCourse(course, major.code),
    });
  });

  if (!codeChanged) {
    removed.forEach(course => {
      operations.push({ type: 'delete', ref: doc(db, 'courses', course._docId || courseDocId(major.code, toStr(course.code))) });
    });
  }

  setBusy(true, 'Đang lưu chuyên ngành...');
  try {
    await runBatch(operations);
    showToast(`Đã lưu chuyên ngành ${major.code} với ${courses.length} môn học.`, 'success');
    state.editingMajorCode = null;
    state.majorDraft = null;
    closeModal('modal-major-editor');
  } catch (error) {
    console.error('saveMajor', error);
    showToast(`Lưu thất bại: ${error.code || error.message}`, 'error', 5200);
  } finally {
    setBusy(false);
  }
}

async function deleteMajor(code) {
  const typed = await showAppDialog({
    title: 'Xóa chuyên ngành',
    message: `Nhập XOA để xóa chuyên ngành ${code} và toàn bộ môn học của nó. Thao tác không thể hoàn tác.`,
    confirmLabel: 'Xóa chuyên ngành',
    danger: true,
    expected: 'XOA',
  });
  if (typed !== 'XOA') return;

  const courses = state.courses.filter(course => courseMajorOf(course) === code);
  const operations = [
    { type: 'delete', ref: doc(db, 'majors', code) },
    ...courses.map(course => ({
      type: 'delete',
      ref: doc(db, 'courses', course._docId || courseDocId(code, toStr(course.code))),
    })),
  ];

  setBusy(true, 'Đang xóa chuyên ngành...');
  try {
    await runBatch(operations);
    showToast(`Đã xóa chuyên ngành ${code} và ${courses.length} môn học.`, 'success');
    closeModal('modal-major-editor');
    state.editingMajorCode = null;
    state.majorDraft = null;
  } catch (error) {
    console.error('deleteMajor', error);
    showToast(`Xóa thất bại: ${error.code || error.message}`, 'error', 5200);
  } finally {
    setBusy(false);
  }
}

function openCourseEditor(index) {
  if (!state.majorDraft) return;
  const isEdit = index !== null && index !== undefined;
  const course = isEdit ? deepClone(state.majorDraft.courses[index]) : blankCourse();
  state.editingCourseIndex = isEdit ? index : null;
  state.courseEditDraft = course;

  $('course-editor-title').textContent = isEdit ? `Môn học ${course.code}` : 'Thêm môn học';
  $('course-code').value = toStr(course.code);
  $('course-semester').value = toInt(course.semester, 1);
  $('course-credits').value = toInt(course.credits, 3);
  $('course-prereqs').value = (Array.isArray(course.prerequisites) ? course.prerequisites : []).join(', ');
  $('course-prereq-note').value = toStr(course.prerequisiteNote);
  $('course-name').value = toStr(course.name);
  $('course-name-vi').value = toStr(course.nameVi);
  $('course-lecturer').value = toStr(course.lecturer);
  $('course-link').value = toStr(course.link);
  $('course-overview').value = toStr(course.overview);
  $('course-student-tasks').value = toStr(course.studentTasks);
  $('course-tools').value = toStr(course.tools);
  $('course-degree-level').value = toStr(course.degreeLevel);
  $('course-time-allocation').value = toStr(course.timeAllocation);
  $('course-scoring-scale').value = toStr(course.scoringScale);
  $('course-min-pass').value = toStr(course.minAvgMarkToPass);
  $('course-decision-no').value = toStr(course.decisionNo);
  $('course-approved-date').value = toStr(course.approvedDate);
  $('course-learning-method').value = toStr(course.learningTeachingMethod);
  $('course-note').value = toStr(course.note);
  $('course-elective-groups').value = (Array.isArray(course.electiveGroups) ? course.electiveGroups : []).join(', ');
  $('course-drive').value = toStr(course.resourceLinks?.drive);
  $('course-notion').value = toStr(course.resourceLinks?.notion);
  $('course-github').value = toStr(course.resourceLinks?.github);

  renderSlotRows(course.slots || []);
  renderAssessmentRows(course.labs || []);
  renderLoRows(course.learningOutcomes || []);
  renderMaterialRows(course.courseMaterials || []);
  updateCourseSlotCount();
  activateCourseTab('tab-course-slots');
  openModal('modal-course-editor');
}

function renderSlotRows(slots) {
  const tbody = $('course-slots-tbody');
  if (!tbody) return;
  if (!slots.length) {
    tbody.innerHTML = '<tr><td colspan="6" class="empty-cell">Chưa có slot. Chỉ thêm dữ liệu thật từ FLM.</td></tr>';
    return;
  }
  tbody.innerHTML = slots.map((slot, index) => `
    <tr data-index="${index}">
      <td>
        <input type="number" min="1" max="200" data-field="number" value="${toInt(slot.number, index + 1)}">
        <input type="hidden" data-field="teachingType" value="${esc(slot.teachingType)}">
        <input type="hidden" data-field="lo" value="${esc(slot.lo)}">
        <input type="hidden" data-field="itu" value="${esc(slot.itu)}">
        <input type="hidden" data-field="download" value="${esc(slot.download)}">
        <input type="hidden" data-field="urls" value="${esc(slot.urls)}">
      </td>
      <td><input type="text" data-field="topic" value="${esc(slot.topic || slot.title)}"></td>
      <td><input type="text" data-field="materials" value="${esc(slot.materials)}"></td>
      <td><input type="text" data-field="tasks" value="${esc(slot.tasks)}"></td>
      <td><input type="text" data-field="cqs" value="${esc(slot.cqs)}"></td>
      <td>
        <button type="button" class="icon-btn" data-action="remove-slot" title="Xóa slot">
          <span class="material-symbols-outlined">delete</span>
        </button>
      </td>
    </tr>
  `).join('');
}

function renderAssessmentRows(assessments) {
  const tbody = $('course-assessments-tbody');
  if (!tbody) return;
  if (!assessments.length) {
    tbody.innerHTML = '<tr><td colspan="7" class="empty-cell">Chưa có đầu điểm.</td></tr>';
    return;
  }
  tbody.innerHTML = assessments.map((item, index) => `
    <tr data-index="${index}">
      <td>
        <input type="text" data-field="title" value="${esc(item.title || item.category)}">
        <input type="hidden" data-field="id" value="${esc(item.id)}">
        <input type="hidden" data-field="category" value="${esc(item.category)}">
        <input type="hidden" data-field="part" value="${esc(item.part)}">
        <input type="hidden" data-field="clo" value="${esc(item.clo)}">
        <input type="hidden" data-field="note" value="${esc(item.note)}">
        <input type="hidden" data-field="status" value="${esc(item.status || 'pending')}">
      </td>
      <td><input type="text" data-field="type" value="${esc(item.type)}"></td>
      <td><input type="text" data-field="weight" value="${toNumber(item.weight, 0)}"></td>
      <td><input type="text" data-field="completionCriteria" value="${esc(item.completionCriteria)}"></td>
      <td><input type="text" data-field="duration" value="${esc(item.duration)}"></td>
      <td><input type="text" data-field="gradingCriteria" value="${esc(item.gradingCriteria)}"></td>
      <td>
        <button type="button" class="icon-btn" data-action="remove-assessment" title="Xóa đầu điểm">
          <span class="material-symbols-outlined">delete</span>
        </button>
      </td>
    </tr>
  `).join('');
}

function renderLoRows(outcomes) {
  const container = $('course-los-container');
  if (!container) return;
  if (!outcomes.length) {
    container.innerHTML = '<div class="empty-cell">Chưa có chuẩn đầu ra.</div>';
    return;
  }
  container.innerHTML = outcomes.map((outcome, index) => `
    <div class="row-editor cols-lo frame-card" data-index="${index}">
      <input type="text" data-field="name" value="${esc(outcome.name)}" placeholder="CLO1">
      <input type="text" data-field="description" value="${esc(outcome.description)}" placeholder="Mô tả chuẩn đầu ra">
      <button type="button" class="icon-btn" data-action="remove-lo" title="Xóa LO">
        <span class="material-symbols-outlined">delete</span>
      </button>
    </div>
  `).join('');
}

function renderMaterialRows(materials) {
  const container = $('course-materials-container');
  if (!container) return;
  if (!materials.length) {
    container.innerHTML = '<div class="empty-cell">Chưa có giáo trình.</div>';
    return;
  }
  container.innerHTML = materials.map((material, index) => `
    <div class="row-editor cols-material frame-card" data-index="${index}">
      <input type="text" data-field="description" value="${esc(material.description)}" placeholder="Tên giáo trình">
      <input type="text" data-field="author" value="${esc(material.author)}" placeholder="Tác giả">
      <input type="text" data-field="publisher" value="${esc(material.publisher)}" placeholder="Nhà XB">
      <input type="text" data-field="publishedDate" value="${esc(material.publishedDate)}" placeholder="Năm XB">
      <label style="display:flex;align-items:center;gap:6px;font-size:12px;">
        <input type="checkbox" data-field="isMain" ${toBool(material.isMain) ? 'checked' : ''}> Chính
      </label>
      <button type="button" class="icon-btn" data-action="remove-material" title="Xóa giáo trình">
        <span class="material-symbols-outlined">delete</span>
      </button>
      <input type="hidden" data-field="edition" value="${esc(material.edition)}">
      <input type="hidden" data-field="isbn" value="${esc(material.isbn)}">
      <input type="hidden" data-field="note" value="${esc(material.note)}">
    </div>
  `).join('');
}

function fieldValue(row, field) {
  const input = row.querySelector(`[data-field="${field}"]`);
  if (!input) return '';
  if (input.type === 'checkbox') return input.checked;
  return input.value;
}

function syncCourseEditor() {
  const draft = state.courseEditDraft;
  if (!draft) return;

  draft.code = $('course-code').value.trim();
  draft.name = $('course-name').value.trim();
  draft.nameVi = $('course-name-vi').value.trim();
  draft.semester = toInt($('course-semester').value, 1);
  draft.credits = toInt($('course-credits').value, 0);
  draft.prerequisites = $('course-prereqs').value.split(/[,;\s]+/).map(item => item.trim()).filter(Boolean);
  draft.prerequisiteNote = $('course-prereq-note').value.trim();
  draft.lecturer = $('course-lecturer').value.trim();
  draft.link = $('course-link').value.trim();
  draft.overview = $('course-overview').value.trim();
  draft.studentTasks = $('course-student-tasks').value.trim();
  draft.tools = $('course-tools').value.trim();
  draft.degreeLevel = $('course-degree-level').value.trim();
  draft.timeAllocation = $('course-time-allocation').value.trim();
  draft.scoringScale = $('course-scoring-scale').value.trim();
  draft.minAvgMarkToPass = $('course-min-pass').value.trim();
  draft.decisionNo = $('course-decision-no').value.trim();
  draft.approvedDate = $('course-approved-date').value.trim();
  draft.learningTeachingMethod = $('course-learning-method').value.trim();
  draft.note = $('course-note').value.trim();
  draft.electiveGroups = $('course-elective-groups').value
    .split(/[,;]+/)
    .map(item => item.trim())
    .filter(Boolean);
  draft.resourceLinks = {
    drive: $('course-drive').value.trim(),
    notion: $('course-notion').value.trim(),
    github: $('course-github').value.trim(),
  };

  draft.slots = [...document.querySelectorAll('#course-slots-tbody tr[data-index]')].map((row, index) => {
    const number = toInt(fieldValue(row, 'number'), index + 1);
    const topic = toStr(fieldValue(row, 'topic')).trim();
    return {
      number,
      title: topic ? `Buổi ${number}: ${topic}` : `Bài học ${number}`,
      topic,
      teachingType: toStr(fieldValue(row, 'teachingType')),
      lo: toStr(fieldValue(row, 'lo')),
      itu: toStr(fieldValue(row, 'itu')),
      materials: toStr(fieldValue(row, 'materials')).trim(),
      download: toStr(fieldValue(row, 'download')),
      tasks: toStr(fieldValue(row, 'tasks')).trim(),
      urls: toStr(fieldValue(row, 'urls')),
      cqs: toStr(fieldValue(row, 'cqs')).trim(),
    };
  });

  draft.labs = [...document.querySelectorAll('#course-assessments-tbody tr[data-index]')].map((row, index) => {
    const title = toStr(fieldValue(row, 'title')).trim();
    const category = toStr(fieldValue(row, 'category')).trim();
    return {
      id: toStr(fieldValue(row, 'id')) || `assessment_${index + 1}`,
      title: title || category || `Đầu điểm ${index + 1}`,
      category: category || title,
      type: toStr(fieldValue(row, 'type')).trim(),
      part: toStr(fieldValue(row, 'part')),
      weight: toNumber(fieldValue(row, 'weight'), 0),
      completionCriteria: toStr(fieldValue(row, 'completionCriteria')).trim(),
      duration: toStr(fieldValue(row, 'duration')).trim(),
      clo: toStr(fieldValue(row, 'clo')),
      gradingCriteria: toStr(fieldValue(row, 'gradingCriteria')).trim(),
      note: toStr(fieldValue(row, 'note')),
      status: toStr(fieldValue(row, 'status')) || 'pending',
    };
  });

  draft.learningOutcomes = [...document.querySelectorAll('#course-los-container [data-index]')].map(row => ({
    name: toStr(fieldValue(row, 'name')).trim(),
    description: toStr(fieldValue(row, 'description')).trim(),
  }));

  draft.courseMaterials = [...document.querySelectorAll('#course-materials-container [data-index]')].map(row => ({
    description: toStr(fieldValue(row, 'description')).trim(),
    author: toStr(fieldValue(row, 'author')).trim(),
    publisher: toStr(fieldValue(row, 'publisher')).trim(),
    publishedDate: toStr(fieldValue(row, 'publishedDate')).trim(),
    edition: toStr(fieldValue(row, 'edition')),
    isbn: toStr(fieldValue(row, 'isbn')),
    isMain: Boolean(fieldValue(row, 'isMain')),
    note: toStr(fieldValue(row, 'note')),
  }));

  draft.totalSlots = draft.slots.length;
  const hasDetails = draft.slots.length || draft.labs.length || draft.learningOutcomes.length || draft.courseMaterials.length;
  if (draft.syllabusStatus === 'metadata' && hasDetails) draft.syllabusStatus = 'manual';
}

function updateCourseSlotCount() {
  const input = $('course-total-slots');
  if (!input) return;
  const count = document.querySelectorAll('#course-slots-tbody tr[data-index]').length;
  input.value = String(count);
}

function applyCourseEditor() {
  if (!state.majorDraft || !state.courseEditDraft) return;
  syncCourseEditor();
  const course = state.courseEditDraft;

  if (!COURSE_CODE_RE.test(course.code)) {
    showToast('Mã môn chỉ bắt đầu bằng chữ, dài 2–24 ký tự và không chứa ký tự đặc biệt ngoài _ . - *', 'error');
    return;
  }
  if (!course.name) {
    showToast('Vui lòng nhập tên môn học.', 'error');
    return;
  }
  if (course.semester < 0 || course.semester > 12) {
    showToast('Học kỳ phải từ 0 đến 12.', 'error');
    return;
  }
  if (course.credits < 0 || course.credits > 30) {
    showToast('Số tín chỉ phải từ 0 đến 30.', 'error');
    return;
  }

  const duplicate = state.majorDraft.courses.some((item, index) => (
    index !== state.editingCourseIndex && toStr(item.code).toLowerCase() === course.code.toLowerCase()
  ));
  if (duplicate) {
    showToast(`Môn ${course.code} đã tồn tại trong chuyên ngành.`, 'error');
    return;
  }

  if (state.editingCourseIndex === null) {
    state.majorDraft.courses.push(course);
  } else {
    state.majorDraft.courses[state.editingCourseIndex] = course;
  }

  state.courseEditDraft = null;
  state.editingCourseIndex = null;
  closeModal('modal-course-editor');
  renderMajorCoursesTable();
}

function activateCourseTab(tabId) {
  const modal = $('modal-course-editor');
  if (!modal) return;
  modal.querySelectorAll('.tab-btn').forEach(button => {
    button.classList.toggle('active', button.dataset.tab === tabId);
  });
  modal.querySelectorAll('.tab-content').forEach(content => {
    content.style.display = content.id === tabId ? 'block' : 'none';
  });
}

function openImportModal() {
  state.importFiles = [];
  state.importResult = null;
  $('import-file-input').value = '';
  $('import-major-code').value = '';
  $('import-major-name').value = '';
  $('import-total-semesters').value = '9';
  $('import-status-text').textContent = '';
  $('import-result-area').style.display = 'none';
  $('import-summary').innerHTML = '';
  $('import-warnings').innerHTML = '';
  $('import-course-tbody').innerHTML = '';
  renderImportFiles();
  openModal('modal-import-html');
}

async function addImportFiles(fileList) {
  const files = [...fileList];
  for (const file of files) {
    if (!/\.html?$/i.test(file.name) && file.type !== 'text/html') {
      showToast(`Bỏ qua ${file.name}: chỉ nhận tệp .html/.htm`, 'warning');
      continue;
    }
    if (state.importFiles.some(item => item.name === file.name && item.size === file.size)) continue;
    const html = await file.text();
    state.importFiles.push({
      name: file.name,
      size: file.size,
      html,
      type: detectFlmHtmlType(html),
    });
  }
  renderImportFiles();
}

function renderImportFiles() {
  const container = $('import-file-list');
  if (!container) return;
  if (!state.importFiles.length) {
    container.innerHTML = '<div class="table-note">Chưa chọn tệp nào.</div>';
    return;
  }
  container.innerHTML = state.importFiles.map((file, index) => `
    <div class="file-chip">
      <div style="display:flex;align-items:center;gap:10px;min-width:0;">
        <span class="file-kind ${file.type === 'unknown' ? 'unknown' : ''}">${esc(file.type === 'curriculum' ? 'Chương trình' : file.type === 'syllabus-list' ? 'Danh sách môn' : file.type === 'syllabus' ? 'Đề cương' : 'Không rõ')}</span>
        <span style="overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">${esc(file.name)}</span>
      </div>
      <button type="button" class="icon-btn" data-remove-import="${index}" title="Bỏ tệp">
        <span class="material-symbols-outlined">close</span>
      </button>
    </div>
  `).join('');
}

function parseImportFiles() {
  if (!state.importFiles.length) {
    showToast('Vui lòng chọn ít nhất một tệp HTML.', 'warning');
    return;
  }
  const result = mergeFlmFiles(state.importFiles.map(file => ({ name: file.name, html: file.html })));
  state.importResult = result;

  const codeInput = $('import-major-code');
  const nameInput = $('import-major-name');
  const semesterInput = $('import-total-semesters');
  if (!codeInput.value && result.major.code) codeInput.value = result.major.code;
  if (!nameInput.value && result.major.name) nameInput.value = result.major.name;
  if (result.major.totalSemesters) semesterInput.value = String(result.major.totalSemesters);

  const withSyllabus = result.courses.filter(course => course.syllabusStatus !== 'metadata').length;
  const withGroups = result.courses.filter(course => (course.electiveGroups || []).length > 0).length;
  const groupCount = new Set(result.courses.flatMap(course => course.electiveGroups || [])).size;
  $('import-status-text').textContent = `${result.courses.length} môn • ${withSyllabus} có đề cương`;
  $('import-summary').innerHTML = `
    <span><strong>${esc(result.major.code || 'Chưa rõ mã')}</strong> ${esc(result.major.name || '')}</span>
    <span>${result.courses.length} môn học</span>
    <span>${withSyllabus} môn có đề cương</span>
    <span>${result.courses.length - withSyllabus} môn chỉ có thông tin chung</span>
    <span>${withGroups} môn tự chọn • ${groupCount} nhóm</span>
  `;

  $('import-warnings').innerHTML = result.warnings.length
    ? result.warnings.map(warning => `<div class="warning-item">${esc(warning)}</div>`).join('')
    : '<div class="table-note">Không có cảnh báo.</div>';

  const tbody = $('import-course-tbody');
  tbody.innerHTML = result.courses.length
    ? result.courses.map((course, index) => `
      <tr>
        <td><input type="checkbox" class="import-course-check" data-index="${index}" checked></td>
        <td><strong>${esc(course.code)}</strong></td>
        <td>${esc(truncate(course.name, 60))}</td>
        <td>${toInt(course.semester, 0)}</td>
        <td>${toInt(course.credits, 0)}</td>
        <td>${esc((course.prerequisites || []).join(', '))}</td>
        <td>${esc((course.electiveGroups || []).join(', '))}</td>
        <td>${esc(syllabusLabel(course.syllabusStatus))}</td>
      </tr>
    `).join('')
    : '<tr><td colspan="8" class="empty-cell">Không đọc được môn học nào từ các tệp đã chọn.</td></tr>';

  $('import-select-all').checked = result.courses.length > 0;
  $('import-result-area').style.display = 'block';

  if (!result.major.code) {
    showToast('Không xác định được mã chuyên ngành, hãy nhập tay.', 'warning');
  }
}

async function commitImport() {
  if (!state.importResult) {
    showToast('Hãy phân tích tệp trước khi lưu.', 'warning');
    return;
  }

  const code = $('import-major-code').value.trim();
  const name = $('import-major-name').value.trim();
  const totalSemesters = toInt($('import-total-semesters').value, 9);

  if (!MAJOR_CODE_RE.test(code)) {
    showToast('Mã chuyên ngành chỉ gồm chữ, số hoặc _ . - và dài 2–30 ký tự.', 'error');
    return;
  }
  if (!name) {
    showToast('Vui lòng nhập tên chuyên ngành.', 'error');
    return;
  }
  if (totalSemesters < 1 || totalSemesters > 12) {
    showToast('Tổng số học kỳ phải từ 1 đến 12.', 'error');
    return;
  }

  const selectedIndexes = [...document.querySelectorAll('.import-course-check')]
    .filter(input => input.checked)
    .map(input => toInt(input.dataset.index, -1))
    .filter(index => index >= 0);
  const selectedCourses = selectedIndexes
    .map(index => state.importResult.courses[index])
    .filter(Boolean);

  if (!selectedCourses.length) {
    showToast('Chọn ít nhất một môn học để lưu.', 'warning');
    return;
  }

  const existingMajor = state.majors.find(major => (major.code || major._docId) === code);
  const existingByCode = new Map(
    state.courses
      .filter(course => courseMajorOf(course) === code)
      .map(course => [toStr(course.code).toLowerCase(), course]),
  );

  const seenCodes = new Set();
  for (const course of selectedCourses) {
    const courseCode = toStr(course.code).trim();
    if (!COURSE_CODE_RE.test(courseCode)) {
      showToast(`Mã môn “${courseCode}” không hợp lệ.`, 'error');
      return;
    }
    if (seenCodes.has(courseCode.toLowerCase())) {
      showToast(`Môn ${courseCode} bị trùng trong tệp nhập.`, 'error');
      return;
    }
    seenCodes.add(courseCode.toLowerCase());
  }

  const majorPayload = {
    code,
    name,
    nameEn: toStr(state.importResult.major.nameEn),
    description: toStr(state.importResult.major.description),
    totalSemesters,
    source: 'flm_html',
    archived: Boolean(existingMajor && toBool(existingMajor.archived)),
  };

  const operations = [{ type: 'set', ref: doc(db, 'majors', code), data: majorPayload }];
  selectedCourses.forEach(course => {
    const courseCode = toStr(course.code).trim();
    const existing = existingByCode.get(courseCode.toLowerCase());
    const targetId = existing?._docId || courseDocId(code, courseCode);
    const normalized = normalizeCourse({ ...course, code: courseCode }, code);
    if (!normalized.name) normalized.name = courseCode;
    operations.push({ type: 'set', ref: doc(db, 'courses', targetId), data: normalized });
  });

  setBusy(true, `Đang lưu ${selectedCourses.length} môn học...`);
  try {
    await runBatch(operations);
    showToast(`Đã nhập chuyên ngành ${code} với ${selectedCourses.length} môn học.`, 'success');
    closeModal('modal-import-html');
    state.importFiles = [];
    state.importResult = null;
    switchView('majors');
  } catch (error) {
    console.error('commitImport', error);
    showToast(`Nhập dữ liệu thất bại: ${error.code || error.message}`, 'error', 5200);
  } finally {
    setBusy(false);
  }
}

async function cleanupLegacyData() {
  const typed = await showAppDialog({
    title: 'Dọn dữ liệu cũ',
    message: 'Nhập XOA để xóa toàn bộ majors, courses và curriculums. Tài khoản, thông báo và bí kíp được giữ nguyên.',
    confirmLabel: 'Dọn dữ liệu',
    danger: true,
    expected: 'XOA',
  });
  if (typed !== 'XOA') return;

  setBusy(true, 'Đang dọn dữ liệu cũ...');
  try {
    const [majorsSnap, coursesSnap, curriculaSnap] = await Promise.all([
      getDocs(collection(db, 'majors')),
      getDocs(collection(db, 'courses')),
      getDocs(collection(db, 'curriculums')),
    ]);
    const operations = [];
    majorsSnap.docs.forEach(item => operations.push({ type: 'delete', ref: item.ref }));
    coursesSnap.docs.forEach(item => operations.push({ type: 'delete', ref: item.ref }));
    curriculaSnap.docs.forEach(item => operations.push({ type: 'delete', ref: item.ref }));

    if (!operations.length) {
      showToast('Không có dữ liệu ngành/môn/curriculum để xóa.', 'info');
      return;
    }

    await runBatch(operations);
    showToast(`Đã xóa ${operations.length} tài liệu (majors, courses, curriculums).`, 'success');
  } catch (error) {
    console.error('cleanupLegacyData', error);
    showToast(`Dọn dữ liệu thất bại: ${error.code || error.message}`, 'error', 5200);
  } finally {
    setBusy(false);
  }
}

function setNoteFilter(status) {
  state.noteStatusFilter = status;
  document.querySelectorAll('[data-filter-status]').forEach(button => {
    button.classList.toggle('active', button.dataset.filterStatus === status);
  });
  renderReviewsTable();
}

function filteredNotes() {
  if (state.noteStatusFilter === 'all') return state.notes;
  return state.notes.filter(note => (note.status || 'pending') === state.noteStatusFilter);
}

function renderReviewsTable() {
  const tbody = $('reviews-table-body');
  if (!tbody) return;
  const notes = filteredNotes();

  if (!notes.length) {
    const message = state.noteStatusFilter === 'pending'
      ? 'Không có bí kíp nào đang chờ duyệt.'
      : 'Không có bí kíp nào trong mục này.';
    tbody.innerHTML = `<tr><td colspan="7" class="empty-cell">${message}</td></tr>`;
    return;
  }

  tbody.innerHTML = notes.map(note => `
    <tr>
      <td>${esc(note.authorName || note.uid || 'Sinh viên')}</td>
      <td><strong>${esc(note.courseCode || '')}</strong><br><span class="muted-text">${esc(truncate(note.courseName, 50))}</span></td>
      <td title="${esc(note.content)}"><strong>${esc(note.title || '(Không tiêu đề)')}</strong><br><span class="muted-text">${esc(truncate(note.content, 100))}</span></td>
      <td>${esc(formatDate(note.createdAt))}</td>
      <td>${statusBadge(note.status)}</td>
      <td>${esc(truncate(note.reason, 60))}</td>
      <td style="text-align: right;">
        <button class="btn btn-outline btn-sm" data-action="open-note" data-id="${esc(note._docId)}">
          <span class="material-symbols-outlined">visibility</span>
          ${note.status === 'pending' ? 'Duyệt' : 'Xem'}
        </button>
      </td>
    </tr>
  `).join('');
}

function openNoteModal(noteId) {
  const note = state.notes.find(item => item._docId === noteId);
  if (!note) return;
  state.currentReviewNoteId = noteId;
  state.currentReviewNote = note;

  $('rev-note-course').textContent = `${note.courseCode || ''} — ${note.courseName || ''}`;
  $('rev-note-author').textContent = note.authorName || note.uid || 'Sinh viên';
  const statusEl = $('rev-note-status');
  const status = NOTE_STATUSES.includes(note.status) ? note.status : 'pending';
  statusEl.className = `status-badge ${status}`;
  statusEl.textContent = statusLabel(status);
  $('rev-note-title').textContent = note.title || '(Không có tiêu đề)';
  $('rev-note-content').textContent = note.content || '';

  const reason = $('rev-note-reason');
  reason.value = note.reason || '';
  $('rev-note-reason-count').textContent = String(reason.value.length);

  const isPending = status === 'pending';
  $('btn-approve-note').disabled = !isPending;
  $('btn-reject-note').disabled = !isPending;
  reason.disabled = !isPending;

  openModal('modal-review-note');
}

/// One inbox entry for the tip author. Firestore Rules lock the document
/// shape (type, route, id prefix, actor) so a staff client cannot forge
/// arbitrary messages into someone else's inbox.
async function publishReviewNotification(note, status, reason) {
  if (!note || !note.uid || !auth.currentUser) return;
  const approved = status === 'approved';
  const title = approved ? 'Bí kíp đã được duyệt' : 'Bí kíp bị từ chối';
  const label = approved ? 'đã được duyệt' : 'bị từ chối';
  const body = `${note.title || 'Bí kíp'} — ${label}. Lý do: ${reason}`.slice(0, 300);
  await setDoc(doc(db, 'users', note.uid, 'notifications', `review_${note._docId}`), {
    title,
    body,
    type: 'tip_review',
    read: false,
    receivedAt: serverTimestamp(),
    route: '/my-tips',
    recipientId: note.uid,
    actorId: auth.currentUser.uid,
  });
}

async function submitNoteDecision(status) {
  if (!['approved', 'rejected'].includes(status)) return;
  if (!state.currentReviewNoteId || !auth.currentUser) return;

  const reason = $('rev-note-reason').value.trim();
  const note = state.currentReviewNote;
  if (!reason) {
    showToast('Vui lòng nhập lý do duyệt/từ chối.', 'warning');
    return;
  }
  if (reason.length > 300) {
    showToast('Lý do tối đa 300 ký tự.', 'warning');
    return;
  }

  setBusy(true, 'Đang cập nhật bí kíp...');
  try {
    await updateDoc(doc(db, 'experience_notes', state.currentReviewNoteId), {
      status,
      reason,
      reviewedBy: auth.currentUser.uid,
      reviewedAt: serverTimestamp(),
    });
    let notified = true;
    try {
      await publishReviewNotification(note, status, reason);
    } catch (error) {
      notified = false;
      console.error('publishReviewNotification', error);
    }
    track('review_decision', { decision: status });
    showToast(
      notified
        ? (status === 'approved' ? 'Đã duyệt bí kíp và gửi thông báo tới hòm thư.' : 'Đã từ chối bí kíp và gửi thông báo tới hòm thư.')
        : (status === 'approved' ? 'Đã duyệt bí kíp nhưng chưa gửi được thông báo hòm thư.' : 'Đã từ chối bí kíp nhưng chưa gửi được thông báo hòm thư.'),
      notified ? 'success' : 'warning',
      5200,
    );
    closeModal('modal-review-note');
    state.currentReviewNoteId = null;
    state.currentReviewNote = null;
  } catch (error) {
    console.error('submitNoteDecision', error);
    showToast(`Không cập nhật được: ${error.code || error.message}`, 'error', 5200);
  } finally {
    setBusy(false);
  }
}

function renderAnnouncements() {
  const container = $('announcements-list');
  if (!container) return;
  if (!state.announcements.length) {
    container.innerHTML = '<div class="empty-cell">Chưa có thông báo nào.</div>';
    return;
  }
  const isAdmin = state.currentUser?.role === 'admin';
  container.innerHTML = state.announcements.map(item => `
    <div class="frame-card">
      <div class="card-heading-row">
        <strong>${esc(item.title)}</strong>
        ${isAdmin ? `
          <button class="icon-btn" data-action="delete-announcement" data-id="${esc(item._docId)}" title="Xóa thông báo">
            <span class="material-symbols-outlined">delete</span>
          </button>
        ` : ''}
      </div>
      <div class="muted-text" style="margin:6px 0;">${esc(item.authorUid || '')} • ${esc(formatDate(item.publishedAt))}</div>
      <div class="read-box read-box-sm">${esc(item.body)}</div>
    </div>
  `).join('');
}

async function submitAnnouncement(event) {
  event.preventDefault();
  if (!auth.currentUser) {
    showToast('Bạn cần đăng nhập lại.', 'error');
    return;
  }
  const title = $('ann-title').value.trim();
  const body = $('ann-body').value.trim();

  if (!title) {
    showToast('Vui lòng nhập tiêu đề thông báo.', 'warning');
    return;
  }
  if (title.length > 120) {
    showToast('Tiêu đề tối đa 120 ký tự.', 'warning');
    return;
  }
  if (!body) {
    showToast('Vui lòng nhập nội dung thông báo.', 'warning');
    return;
  }
  if (body.length > 1000) {
    showToast('Nội dung tối đa 1000 ký tự.', 'warning');
    return;
  }

  const submitButton = $('btn-submit-announcement');
  if (submitButton) submitButton.disabled = true;

  try {
    await addDoc(collection(db, 'announcements'), {
      title,
      body,
      authorUid: auth.currentUser.uid,
      publishedAt: serverTimestamp(),
    });
    $('ann-title').value = '';
    $('ann-body').value = '';
    $('ann-title-count').textContent = '0';
    $('ann-body-count').textContent = '0';
    track('announcement_published', { role: state.currentUser?.role || 'staff' });
    showToast('Đã đăng thông báo tới ứng dụng di động.', 'success');
  } catch (error) {
    console.error('submitAnnouncement', error);
    showToast(`Đăng thông báo thất bại: ${error.code || error.message}`, 'error', 5200);
  } finally {
    if (submitButton) submitButton.disabled = false;
  }
}

async function deleteAnnouncement(id) {
  if (state.currentUser?.role !== 'admin') {
    showToast('Chỉ Admin được xóa thông báo.', 'warning');
    return;
  }
  const confirmed = await showAppDialog({
    title: 'Xóa thông báo',
    message: 'Xóa thông báo này? Thao tác không thể hoàn tác.',
    confirmLabel: 'Xóa',
    danger: true,
  });
  if (!confirmed) return;
  try {
    await deleteDoc(doc(db, 'announcements', id));
    showToast('Đã xóa thông báo.', 'success');
  } catch (error) {
    console.error('deleteAnnouncement', error);
    showToast(`Xóa thông báo thất bại: ${error.code || error.message}`, 'error', 5200);
  }
}

document.querySelectorAll('.nav-item').forEach(button => {
  button.addEventListener('click', () => switchView(button.dataset.view));
});

$('btn-google-signin')?.addEventListener('click', async () => {
  hideAuthError();
  setSigninLoading(true);
  try {
    await signInWithPopup(auth, googleProvider);
  } catch (error) {
    console.error('signInWithPopup', error);
    showAuthError(`Lỗi đăng nhập Google: ${error.message}`);
  } finally {
    setSigninLoading(false);
  }
});

$('btn-signout')?.addEventListener('click', async () => {
  try {
    await signOut(auth);
  } catch (error) {
    console.warn(error);
  }
  showToast('Đã đăng xuất khỏi cổng quản trị.', 'info');
});

onAuthStateChanged(auth, async user => {
  if (user) {
    await verifyAccess(user);
  } else {
    teardownSession();
  }
});

document.querySelectorAll('[data-close-modal]').forEach(button => {
  button.addEventListener('click', () => closeModal(button.dataset.closeModal));
});

document.querySelectorAll('.modal-backdrop').forEach(backdrop => {
  backdrop.addEventListener('click', event => {
    if (event.target === backdrop) backdrop.classList.remove('open');
  });
});

document.addEventListener('keydown', event => {
  if (event.key !== 'Escape') return;
  const open = document.querySelector('.modal-backdrop.open');
  if (open) open.classList.remove('open');
});

$('btn-refresh-dashboard')?.addEventListener('click', () => {
  refreshDashboardCounts();
  renderDashboardCharts();
  renderDashboardNotes();
  showToast('Đã làm mới số liệu tổng quan.', 'info');
});

$('btn-goto-reviews')?.addEventListener('click', () => switchView('reviews'));
$('btn-add-major')?.addEventListener('click', () => openModal('modal-major-choice'));
$('btn-choice-manual')?.addEventListener('click', () => {
  closeModal('modal-major-choice');
  openMajorEditor(null);
});
$('btn-choice-import')?.addEventListener('click', () => {
  closeModal('modal-major-choice');
  openImportModal();
});
$('btn-cleanup-data')?.addEventListener('click', cleanupLegacyData);

$('major-search-input')?.addEventListener('input', renderMajors);
$('major-status-filter')?.addEventListener('change', renderMajors);

$('majors-cards-container')?.addEventListener('click', event => {
  const button = event.target.closest('[data-action]');
  if (!button) return;
  const code = button.dataset.code;
  if (button.dataset.action === 'edit-major') {
    openMajorEditor(code);
  } else if (button.dataset.action === 'delete-major') {
    deleteMajor(code);
  }
});

$('major-course-tbody')?.addEventListener('click', async event => {
  const button = event.target.closest('[data-action]');
  if (!button || !state.majorDraft) return;
  const index = toInt(button.dataset.index, -1);
  if (index < 0) return;
  if (button.dataset.action === 'edit-course') {
    openCourseEditor(index);
  } else if (button.dataset.action === 'remove-course') {
    const course = state.majorDraft.courses[index];
    if (!course) return;
    const confirmed = await showAppDialog({
      title: 'Xóa môn khỏi chuyên ngành',
      message: `Xóa môn ${course.code} khỏi chuyên ngành?`,
      confirmLabel: 'Xóa',
      danger: true,
    });
    if (!confirmed) return;
    state.majorDraft.courses.splice(index, 1);
    renderMajorCoursesTable();
  }
});

$('btn-add-course-to-major')?.addEventListener('click', () => openCourseEditor(null));
$('btn-save-major')?.addEventListener('click', saveMajor);
$('btn-delete-major')?.addEventListener('click', () => {
  if (state.editingMajorCode) deleteMajor(state.editingMajorCode);
});

$('course-code')?.addEventListener('input', event => {
  event.target.value = event.target.value.toUpperCase();
});

$('modal-course-editor')?.addEventListener('click', event => {
  const tab = event.target.closest('.tab-btn');
  if (tab) activateCourseTab(tab.dataset.tab);
});

$('btn-apply-course')?.addEventListener('click', applyCourseEditor);

$('btn-add-slot-row')?.addEventListener('click', () => {
  if (!state.courseEditDraft) return;
  syncCourseEditor();
  const next = state.courseEditDraft.slots.length + 1;
  state.courseEditDraft.slots.push({
    number: next,
    title: `Bài học ${next}`,
    topic: '',
    teachingType: '',
    lo: '',
    itu: '',
    materials: '',
    download: '',
    tasks: '',
    urls: '',
    cqs: '',
  });
  renderSlotRows(state.courseEditDraft.slots);
  updateCourseSlotCount();
});

$('course-slots-tbody')?.addEventListener('click', event => {
  const button = event.target.closest('[data-action="remove-slot"]');
  if (!button || !state.courseEditDraft) return;
  syncCourseEditor();
  const index = toInt(button.closest('tr')?.dataset.index, -1);
  if (index < 0) return;
  state.courseEditDraft.slots.splice(index, 1);
  renderSlotRows(state.courseEditDraft.slots);
  updateCourseSlotCount();
});

$('btn-add-assessment-row')?.addEventListener('click', () => {
  if (!state.courseEditDraft) return;
  syncCourseEditor();
  state.courseEditDraft.labs.push({
    id: `assessment_${state.courseEditDraft.labs.length + 1}`,
    title: '',
    category: '',
    type: '',
    part: '',
    weight: 0,
    completionCriteria: '',
    duration: '',
    clo: '',
    gradingCriteria: '',
    note: '',
    status: 'pending',
  });
  renderAssessmentRows(state.courseEditDraft.labs);
});

$('course-assessments-tbody')?.addEventListener('click', event => {
  const button = event.target.closest('[data-action="remove-assessment"]');
  if (!button || !state.courseEditDraft) return;
  syncCourseEditor();
  const index = toInt(button.closest('tr')?.dataset.index, -1);
  if (index < 0) return;
  state.courseEditDraft.labs.splice(index, 1);
  renderAssessmentRows(state.courseEditDraft.labs);
});

$('btn-add-lo-row')?.addEventListener('click', () => {
  if (!state.courseEditDraft) return;
  syncCourseEditor();
  state.courseEditDraft.learningOutcomes.push({ name: '', description: '' });
  renderLoRows(state.courseEditDraft.learningOutcomes);
});

$('course-los-container')?.addEventListener('click', event => {
  const button = event.target.closest('[data-action="remove-lo"]');
  if (!button || !state.courseEditDraft) return;
  syncCourseEditor();
  const index = toInt(button.closest('[data-index]')?.dataset.index, -1);
  if (index < 0) return;
  state.courseEditDraft.learningOutcomes.splice(index, 1);
  renderLoRows(state.courseEditDraft.learningOutcomes);
});

$('btn-add-material-row')?.addEventListener('click', () => {
  if (!state.courseEditDraft) return;
  syncCourseEditor();
  state.courseEditDraft.courseMaterials.push({
    description: '',
    author: '',
    publisher: '',
    publishedDate: '',
    edition: '',
    isbn: '',
    isMain: false,
    note: '',
  });
  renderMaterialRows(state.courseEditDraft.courseMaterials);
});

$('course-materials-container')?.addEventListener('click', event => {
  const button = event.target.closest('[data-action="remove-material"]');
  if (!button || !state.courseEditDraft) return;
  syncCourseEditor();
  const index = toInt(button.closest('[data-index]')?.dataset.index, -1);
  if (index < 0) return;
  state.courseEditDraft.courseMaterials.splice(index, 1);
  renderMaterialRows(state.courseEditDraft.courseMaterials);
});

$('import-dropzone')?.addEventListener('click', () => $('import-file-input')?.click());
$('import-file-input')?.addEventListener('change', event => {
  addImportFiles(event.target.files);
  event.target.value = '';
});

['dragenter', 'dragover'].forEach(name => {
  $('import-dropzone')?.addEventListener(name, event => {
    event.preventDefault();
    $('import-dropzone').classList.add('drag-active');
  });
});
['dragleave', 'drop'].forEach(name => {
  $('import-dropzone')?.addEventListener(name, event => {
    event.preventDefault();
    $('import-dropzone').classList.remove('drag-active');
  });
});
$('import-dropzone')?.addEventListener('drop', event => {
  if (event.dataTransfer?.files?.length) addImportFiles(event.dataTransfer.files);
});

$('import-file-list')?.addEventListener('click', event => {
  const button = event.target.closest('[data-remove-import]');
  if (!button) return;
  const index = toInt(button.dataset.removeImport, -1);
  if (index < 0) return;
  state.importFiles.splice(index, 1);
  state.importResult = null;
  $('import-result-area').style.display = 'none';
  renderImportFiles();
});

$('btn-parse-import')?.addEventListener('click', parseImportFiles);
$('btn-commit-import')?.addEventListener('click', commitImport);
$('import-select-all')?.addEventListener('change', event => {
  document.querySelectorAll('.import-course-check').forEach(input => {
    input.checked = event.target.checked;
  });
});

$('review-filter-group')?.addEventListener('click', event => {
  const button = event.target.closest('[data-filter-status]');
  if (button) setNoteFilter(button.dataset.filterStatus);
});

$('reviews-table-body')?.addEventListener('click', event => {
  const button = event.target.closest('[data-action="open-note"]');
  if (button) openNoteModal(button.dataset.id);
});

$('rev-note-reason')?.addEventListener('input', event => {
  $('rev-note-reason-count').textContent = String(event.target.value.length);
});

document.querySelectorAll('#modal-review-note .quick-chip').forEach(chip => {
  chip.addEventListener('click', () => {
    const reason = $('rev-note-reason');
    reason.value = chip.dataset.template || '';
    $('rev-note-reason-count').textContent = String(reason.value.length);
  });
});

$('btn-approve-note')?.addEventListener('click', () => submitNoteDecision('approved'));
$('btn-reject-note')?.addEventListener('click', () => submitNoteDecision('rejected'));

$('announcement-form')?.addEventListener('submit', submitAnnouncement);
$('ann-title')?.addEventListener('input', event => {
  $('ann-title-count').textContent = String(event.target.value.length);
});
$('ann-body')?.addEventListener('input', event => {
  $('ann-body-count').textContent = String(event.target.value.length);
});
$('announcements-list')?.addEventListener('click', event => {
  const button = event.target.closest('[data-action="delete-announcement"]');
  if (button) deleteAnnouncement(button.dataset.id);
});

renderMajors();
renderReviewsTable();
renderAnnouncements();
renderDashboardNotes();
renderDashboardCharts();
