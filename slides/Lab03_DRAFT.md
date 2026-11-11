# PRM393 Lab 3 — Slide Deck Draft

> Draft outline only. Final deliverable must be a 12–15 page PDF named `Lab03_<StudentID>_slides.pdf`. Add Student ID and genuine screenshots/traces before export. Do not present pending checks as completed.

## 1. Title

**FPTU Second Brain — PRM393 Lab 3**  
Student: `[NEEDS STUDENT ID]` · Team: `[NEEDS TEAM MEMBERS]`

## 2. Problem and users

- Students need one place for course prerequisites, study tasks, and notes.
- Personas and original flows: link to `ux/persona.md`, `ux/user-flow.md`, and `ux/academic-workflows.md`.
- Add a short problem statement and instructor feedback from the original submission.

## 3. Product scope

- Course roadmap and prerequisite checking.
- Tasks and notes stored under the authenticated Firebase UID.
- Google Sign-In, study advisor, notifications, and study report export.
- Separate implemented code from runtime-verified behavior.

## 4. Three core flows

Diagram the three user flows from the UX documents. Mark each happy path, error branch, and recovery step. Add current app screenshots after capture.

## 5. App screens

Show the 8+ core Lab 2 screens plus Sign-In and Settings/Demo Area. Use real emulator screenshots and identify the emulator/date. Do not use Figma mockups as proof of runtime behavior.

## 6. Architecture

Show Screen → ViewModel → Service → Firebase. Include `AsyncViewState<T>` and service injection. Add the architecture diagram from `docs/architecture.md` or redraw it clearly.

## 7. Firebase data model and access rules

Diagram `users/{uid}/tasks`, `users/{uid}/notes`, `users/{uid}/tokens`, and the root `courses` catalog. Add a screenshot of current deployed Rules only after read-only Console verification.

## 8. Authentication and user data

- Google Sign-In succeeded on emulator and reached HomeScreen.
- Source filters to `fpt.edu.vn` and checks the returned email.
- Add runtime evidence for the rejected-domain branch after testing it.

## 9. Roadmap and Firestore

Show catalog courses and prerequisite result driven by `passedCourses`. Add the verified emulator screen and Firebase Console catalog/profile evidence, with private identifiers obscured.

## 10. Tasks, notes, and sync

- Task create and completion state were observed in Firestore.
- Note read/write was observed; Firestore Timestamp parsing was fixed.
- Manual sync reloaded Roadmap, Tasks, and Notes.
- Add current screenshots/logs; test data used for verification has been removed.

## 11. Firebase feature set

Summarize FCM, Analytics, Crashlytics, Remote Config, and Storage as implemented in code. Use a status table with columns **Code**, **Runtime evidence**, **Pending**. Do not mark Console/device checks complete until evidence exists.

## 12. Testing

- 54 Flutter unit/widget tests passed in the last recorded run.
- `flutter analyze`: 0 issues; debug APK build passed.
- ARTEMIS E2E remains pending: checklist requires at least 10 tests, three runs each, traces, and exploratory notes.

## 13. Security, privacy, and limitations

Cover authenticated UID scoping, default-deny local Rules, consent before PDF upload, ignored Firebase config, unverified current Rules deployment, and Storage bucket status. No secrets in screenshots.

## 14. Demo and next work

Plan the 5–10 minute demo: sign-in → roadmap → task/note → sync → FCM/Remote Config/Crashlytics/PDF after those checks are verified. End with remaining evidence and submission actions. Do not link a video until one exists.

