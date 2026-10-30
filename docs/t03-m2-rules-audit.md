# T03-M2 — Firebase Security Rules Audit & Deployment Readiness

**Status:** BLOCKED (approval + auth prerequisites) — rules themselves are **READY FOR APPROVAL**
on content; deployment cannot be executed this pass.
**Date:** 2026-10-29
**Scope:** Read-only audit. No rules changed, no deployment run, no `firebase init`, no Console
state modified.

---

## 1. Git status preservation

Working tree unchanged this pass: **17 modified + 7 untracked** files, exactly as left by prior
passes (folding in `docs/t03-firebase-readiness.md`, `docs/t03-m1-manual-setup.md` since T01). The
two rules files are **tracked and unmodified** — last touched in commit `0cad041` ("feat: add
Firebase security rules and seed data"); no local edits exist on top of them
(`git diff --stat -- firebase/` is empty).

## 2. Firebase CLI / config / auth status

| Check | Result |
|---|---|
| `firebase` on PATH | **Not installed** |
| `npx firebase-tools --version` | 15.34.2 (downloads on demand) |
| Authenticated accounts | **None** — `firebase login:list` → "No authorized accounts, run `firebase login`" |
| `firebase.json` in repo | **Missing** |
| `.firebaserc` in repo | **Missing** |

**Consequence:** no deployment is possible this pass regardless of rules quality — two
independent blockers. Per brief, `firebase init` was **not** run (forbidden: could overwrite
config and only scaffolds interactively anyway).

## 3. Rule-by-rule audit (`firebase/firestore.rules`)

| # | Rule | Finding | Verdict |
|---|---|---|---|
| F1 | `isAuthenticated()` / `isOwner(userId)` helpers | `isOwner` correctly requires **both** non-null auth and uid match — no short-circuit leak | ✅ SAFE |
| F2 | `users/{userId}` — profile read/write | Owner-only | ✅ SAFE |
| F3 | `users/{userId}/tasks/{taskId}` | Owner-only, matches T02 client contract (`users/{uid}/tasks`) | ✅ SAFE |
| F4 | `users/{userId}/notes/{noteId}` | Owner-only, matches T02 client contract | ✅ SAFE |
| F5 | `users/{userId}/sync/{syncId}` | Owner-only | ✅ SAFE |
| F6 | `courses/{courseId}` | Authenticated read, **write: false** (admin-only via Admin SDK) | ✅ SAFE |
| F7 | `curriculums/{curriculumId}` | Authenticated read, write: false | ✅ SAFE |
| F8 | `audit_logs/{logId}` | Append-only pattern: create requires `request.resource.data.userId == request.auth.uid`; read/update/delete all denied | ✅ SAFE |
| F9 | Catch-all `match /{document=**}` | `allow read, write: if false` — default deny present | ✅ SAFE |
| F0 | Broad public access | **None.** Every `allow` sits behind `isAuthenticated()` or `isOwner()`. No unauthenticated path exists. | ✅ SAFE |

Known non-blocker gaps (documented in `t03-firebase-readiness.md` §2.7, unchanged; FCM
`notifications` collection and `reports` Firestore path are absent because no client code writes
them yet — they become relevant only when T03+/T04+ adds that code):

- No rule for `notifications/{...}` (FCM task, out of scope)
- `reports/{uid}` exists in storage rules but has no Firestore counterpart (PDF export task, out of scope)

## 4. Rule-by-rule audit (`firebase/storage.rules`)

| # | Rule | Finding | Verdict |
|---|---|---|---|
| S1 | `isAuthenticated()` / `isOwner(userId)` helpers | Same pattern as F1 | ✅ SAFE |
| S2 | `isValidSize()` | 10 MB cap | ✅ SAFE |
| S3 | `isValidImageOrPdf()` | `image/*`, `application/pdf`, `text/plain` — as wide as the app needs | ✅ SAFE |
| S4 | `notes/{userId}/{fileName}` | Owner-only + size + MIME | ✅ SAFE |
| S5 | `reports/{userId}/{allPaths=**}` | Owner-only + size, delete allowed | ✅ SAFE |
| S6 | Catch-all default deny | Present | ✅ SAFE |
| S7 | Broad public access | None | ✅ SAFE |

Nit (non-blocking, noted for completeness): S4's `{fileName}` is single-segment, so a nested
`notes/{uid}/sub/file.pdf` write would be denied by the catch-all. The client currently writes
single-level paths (`firebase_storage_service.dart`), so no real call path is affected.

## 5. Deployment decision

**Rules content: READY FOR APPROVAL.** Full findings tables in §§3-4; no unsafe allow, no public
path, default-deny everywhere, ownership enforced all the way down.

**Deployment: BLOCKED this pass** — two prerequisites, both user-side:

1. No authenticated Firebase CLI session (`firebase login` never run on this machine)
2. No `firebase.json` — without it, the CLI has no rule-file mapping or project binding. The
   repo intentionally does not auto-scaffold it; the minimum safe shape is below and can be
   added on approval, or rules can be pasted directly in Console instead (zero repo change).

### Minimum safe `firebase.json` (on approval, ~10 lines, no `firebase init`)

```json
{
  "firestore": { "rules": "firebase/firestore.rules" },
  "storage": { "rules": "firebase/storage.rules" }
}
```

### Exact command that would be run (target project explicit)

```bash
npx firebase-tools deploy --only firestore:rules,storage --project prm323-lab2-gr6
```

Why `--only`: limits blast radius to rule files; no functions, hosting, indexes, or other
surfaces touched. Why `--project`: explicit instead of relying on `.firebaserc`; nothing
ambiguous resolves by default.

**Console-only alternative** (no CLI auth, no `firebase.json`, zero repo change, evidence
identical):

1. Firebase Console → `prm323-lab2-gr6` → Build → Firestore Database → Rules → paste contents of
   `firebase/firestore.rules` → **Publish**
2. Build → Storage → Rules → paste `firebase/storage.rules` → **Publish**

### Approval gate

Per brief: nothing deploys without your explicit approval in a separate step. Concrete choices:

- **Option A (recommended):** run `firebase login` in your own terminal (`npx firebase-tools
  login`), approve the `firebase.json` snippet above, then I run the exact `--only` deploy
  command and paste output as evidence.
- **Option B:** you paste both rules in Console and screenshot the deployed timestamps; I record
  them here as verification evidence with zero machine-side changes.

## 6. What was NOT done

- No rules file modified
- No `firebase init` / no new project
- No deploy executed → no deployment is claimed
- No Console state changed
- No secrets or tokens printed (CLI auth status checked via `login:list` which only reports account emails)
- Nothing committed

## 7. Next action requiring user approval

Pick Option A or B above; each yields the same endpoint. If A, the exact command line that will
run after `firebase login`:

```bash
npx firebase-tools deploy --only firestore:rules,storage --project prm323-lab2-gr6
```

Output will be pasted verbatim into `docs/t03-m2-rules-audit.md` as the deployment evidence
(§7 currently records intent, not success; the doc stays honest until then).

---

## 8. Deployment Execution Attempt (2026-10-29)

### 8.1 Precondition Verification
- Target Project ID: `prm323-lab2-gr6` (Project Number: `510519082861`)
- `firebase.json` mappings verified:
  - `firestore.rules` -> `firebase/firestore.rules`
  - `storage.rules` -> `firebase/storage.rules`
- Rules files integrity verified:
  - `firebase/firestore.rules` and `firebase/storage.rules` match HEAD exactly (0 diff against `0cad041`).
  - Owner scoping, authenticated access, and default-deny catch-alls are intact.
- Git status: existing modified and untracked files preserved; no automatic commit.

### 8.2 Execution & Status
- **Target Command:** `npx firebase-tools deploy --only firestore:rules,storage --project prm323-lab2-gr6`
- **Result:** BLOCKED — Environment Tool Safety Classifier Unavailable.
  - The local Claude Code agent runner (`auto` permission mode) encountered a safety classifier outage (`claude-general is temporarily unavailable`), rejecting execution of shell commands (`Bash` / `npx firebase-tools`).
  - Per safety constraint §5 ("If the project cannot be accessed or any precondition fails, STOP before deployment") and failure handling ("document the actual error and leave the verdict BLOCKED. Do not repeatedly retry without identifying the cause"), execution was halted without claiming deployment.

### 8.3 Deployment Verdict
**DEPLOYMENT STATUS: BLOCKED**
- Deployment has **NOT** occurred via the automated runner.
- The audited rules files remain completely unchanged and ready for deployment.
- **Manual Deployment Fallback:** User can execute in their interactive shell:
  ```bash
  npx firebase-tools deploy --only firestore:rules,storage --project prm323-lab2-gr6
  ```
  or publish directly via Firebase Console.
