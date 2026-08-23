# Admin TODO Progress

## ✅ Done

- [x] Shop item image preview in Admin Shop Manager list
- [x] Premium cloud avatar ownership and direct unlock flow
- [x] Admin loading/empty/error UI polish for Firebase/offline/permission issues
- [x] Admin audit logs for user/shop/avatar changes
- [x] Admin validation for required image, duplicate names, categories, and non-negative prices
- [x] Trilingual content model (`LocalizedText`) for questions, chapters and subjects
- [x] `tool/validate_questions.py` — schema, duplicate ids, translation coverage

Notes:
- Audit logs are written to `admin_audit_logs` with actor uid/email when Firebase Auth is available.
- Premium cloud avatars use inventory ids like `cloud_avatar_<avatar_doc_id>`.

---

## 🚧 In progress — AI Question Generator

Full plan with schema, prompts and rationale:
**[`docs/11_ADMIN_AI_QUESTION_GENERATOR_PLAN.md`](docs/11_ADMIN_AI_QUESTION_GENERATOR_PLAN.md)**

Goal: one click adds **10 exam-accurate questions** in **en / bn / hi** to a
chapter — question, 4 options, correct answer, explanation — and **never**
removes what is already there.

### Phase A — unblock the key manager
- [ ] T0.1 Widen `cloud_firestore` to `>=5.0.0 <7.0.0` and `firebase_core` to `>=3.0.0 <5.0.0` in [admin_api_key_manager](https://github.com/Keshab1997/admin_api_key_manager)
- [ ] T0.2 Smoke-test the package against Firestore 6.x
- [ ] T0.3 Add the git dependency to QuizBaaz, confirm `flutter pub get`

### Phase B — storage + the append guarantee
- [ ] T1.1 `QuestionBankService` — Firestore CRUD, batched writes, counters
- [ ] T1.2 `QuizRepository` merges asset + Firestore banks, dedupes by id
- [ ] T1.3 Hive cache of the merged bank, invalidated on admin write
- [ ] T1.4 Firestore rules — public read, admin-only write
- [ ] T2.1 `fingerprint()` + text normaliser (+ tests)
- [ ] T2.2 Next-sequence resolver (reads existing ids first)
- [ ] T2.3 Near-duplicate similarity check
- [ ] T2.4 Batch id + "Undo last batch" (24h)
- [ ] T2.5 Test: 40 questions + generate 10 = 50, never 10

### Phase C — manual admin CRUD (useful on its own)
- [ ] T5.8 `TrilingualField` widget — EN/BN/HI tabs, filled-dot indicators
- [ ] T5.9 Per-field "Translate" action (authoring-time only)
- [ ] T5.1 Chapter Manager — subject → chapter tree with counts and coverage
- [ ] T5.2 Add/edit chapter sheet (trilingual)
- [ ] T5.3 Add/edit subject sheet (trilingual)
- [ ] T5.4 Reorder chapters
- [ ] T5.5 Question Manager — list, search, filters
- [ ] T5.6 Manual add/edit question form with live validation
- [ ] T5.7 Delete single question, with confirm + audit log

### Phase D — generation
- [ ] T3.1 `QuestionPromptBuilder` — chapter context + existing stems + strict schema
- [ ] T3.2 `QuestionValidator` in Dart, mirroring `tool/validate_questions.py`
- [ ] T3.3 Retry-on-reject loop (max 3 rounds), top-up to the requested count
- [ ] T3.4 Optional verification pass with a second key
- [ ] T3.5 Golden tests — malformed JSON, 3 options, bad index, dup options, untranslated
- [ ] T4.1 `AiQuestionGenerator` with a progress stream
- [ ] T4.2 Provider adapters — Gemini native + OpenAI-compatible
- [ ] T4.3 Chunking (2 × 5), retry, top-up
- [ ] T4.4 `reportSuccess` / `reportFailure` into the key pool
- [ ] T4.5 Friendly errors — no key, all cooling, quota, offline

### Phase E — review + entry points
- [ ] T5.10 Generation review screen — per-question status, edit, drop
- [ ] T5.11 Approve-selected → batched append + audit log
- [ ] T5.12 "47 → 55 questions" banner + Undo
- [ ] T5.13 Dashboard tiles: Chapter Manager, Question Bank, API Keys
- [ ] T5.14 Mount `AdminApiKeysScreen` behind the admin gate

### Phase F — polish
- [ ] T6.1 Admin generator strings into `strings_en/bn/hi.dart`
- [ ] T6.2 `gen_strings.py` + `verify_l10n.py` clean
- [ ] T7.1 Export chapter to JSON from the app
- [ ] T7.2 `tool/pull_firestore_questions.py`
- [ ] T7.3 Round-trip export → `validate_questions.py` passes
- [ ] T8.1–T8.7 Test pass + `flutter analyze` clean

---

## ❓ Open decisions

| # | Question | Default |
|---|---|---|
| D1 | Widen package constraints, or vendor the services? | Widen |
| D2 | Verification pass on by default? | Opt-in; on for Math & Physical Science |
| D3 | 10 in one call, or 2 × 5? | 2 × 5 |
| D4 | Admin questions live immediately? | Yes; export is for offline parity |
| D5 | Admin UI English-only? | Yes |
