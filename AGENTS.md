# AGENTS.md — QuizBaaz 3D

Workspace instruction file for the **QuizBaaz 3D** Flutter project. Loaded into agent
context when working in this repo. Keep it short, factual, and in sync with the code.

## 1. What this project is

Gamified quiz & learning app built with **Flutter 3.x / Dart 3.x**. Core surfaces:

- Daily 10-question competitive quiz with timer + speed bonus + anti-cheat.
- Chapter-wise JSON question bank (categories → chapters → questions).
- Live leaderboard, yesterday's champion podium, gift rewards tracking.
- 3D streak fire, glassmorphism + neon-glow dark UI.
- Guest trial onboarding (zero-friction, no forced sign-up).
- In-app **Admin panel** (screens under `lib/presentation/screens/admin/`) for
  bulk question upload, daily quiz scheduling, champion dispatch, gift tracker,
  user/shop/avatar management, and audit logs.

Author: Keshab Sarkar (@Keshab1997). Repo: `Keshab1997/quizbaaz-flutter`.

## 2. Tech stack (read before adding dependencies)

| Area | Choice |
|---|---|
| Framework | Flutter 3.x, Dart 3.x (`>=3.0.0 <4.0.0`) |
| State management | **Provider** (`provider ^6.1.2`) — see `lib/data/providers/` |
| Backend | Firebase: `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in` |
| Local persistence | **Hive** (`hive` + `hive_flutter`) + `shared_preferences` |
| Networking | `http` (admin uploads via `imgbb_service`, `sync_service`) |
| UI / fonts | `google_fonts` (**Poppins** for en/hi, **Hind Siliguri** for bn), `lottie`, `confetti`, `audioplayers`, `cached_network_image` |
| Localisation | hand-rolled catalogues in `lib/l10n/` + `flutter_localizations` (see §4a) |
| Static analysis | `flutter_lints` via `analysis_options.yaml` |

Do **not** introduce Riverpod, GetX, or Bloc unless the whole app migrates. New state
lives in `lib/data/providers/` as `ChangeNotifier` subclasses consumed with `Consumer`.

## 3. Directory layout (follow this exactly)

```text
lib/
├── core/
│   ├── constants/   # app_colors.dart, app_assets.dart, strings (no logic)
│   └── theme/       # app_theme.dart — glassmorphism + neon definitions
├── data/
│   ├── models/      # plain serializable model classes (fromJson/toJson)
│   ├── providers/   # Provider state classes (single source of UI state)
│   ├── repositories/ # repository layer between providers and services
│   └── services/    # firebase_options, firestore_service, hive_service,
│                    # imgbb_service, shop_service, sync_service
└── presentation/
    ├── screens/     # one folder per feature (admin, battle, daily_quiz,
    │                #   dashboard, leaderboard, profile, shop, etc.)
    └── widgets/     # reusable: glass_card, neon_button, streak_flame_widget,
                     #   champion_podium_widget, cached_avatar, app_background,
                     #   name_effect_text, purchase_celebration
```

- Put new constants in `core/constants`, new theme tokens in `core/theme`.
- One screen per file; one widget per file with a matching `_widget`/`_screen` suffix.
- Keep models free of Firebase imports where possible; isolate Firestore mapping in
  `services/firestore_service.dart` and `repositories/`.

## 4. Coding conventions

- Run `flutter analyze` before finishing any change. Zero errors, zero warnings.
- Follow `flutter_lints`. Prefer `const` constructors for widgets, use
  `Equatable`-free plain models with explicit `==`/`copyWith` only when needed.
- **Never hardcode a user-facing string.** Every label goes through `S.*`
  (see §4a). Code identifiers, comments, and doc comments stay in English.
- Asset paths must be declared in `pubspec.yaml` `flutter.assets` AND referenced via
  `core/constants/app_assets.dart` — never hardcode raw asset strings in widgets.
- Colors come from `core/constants/app_colors.dart`; do not inline hex values in UI.

## 4a. Localisation (en / bn / hi)

The app ships three hand-written UI languages and machine-translates quiz
*content* into ~36 languages on demand. These are two separate settings and a
user can mix them (English interface, Tamil questions).

```text
lib/l10n/
├── strings_en.dart    # base catalogue — SOURCE OF TRUTH for keys
├── strings_bn.dart    # Bangla
├── strings_hi.dart    # Hindi
└── app_strings.dart   # GENERATED accessor class `S` — do not edit by hand
```

**Adding or changing a string**

1. Add the key + English text to `strings_en.dart` (use `{name}` placeholders,
   never Dart interpolation, so translators can reorder them).
2. Add the same key to `strings_bn.dart` and `strings_hi.dart`.
3. Regenerate and check parity:

   ```bash
   python3 tool/gen_strings.py    # writes app_strings.dart, reports gaps
   python3 tool/verify_l10n.py    # unknown keys, const misuse, bracket damage
   ```

4. Use it: `Text(S.profileTitle)` or `Text(S.chapterCount(n: 12))`.

**Rules**

- `S.*` is a runtime getter, so it can **never** sit inside a `const`
  expression. `const Text(S.cancel)` does not compile — drop the `const`.
- A key missing from bn/hi silently falls back to English; a key missing
  everywhere renders as the key name. Neither ever throws.
- `S` is deliberately context-free (a static class). `LocaleProvider` swaps the
  catalogue and `MaterialApp` is keyed on the language code, so the whole tree
  rebuilds and every `S.*` is re-read.
- `tool/apply_l10n.py` is the migration pass that converted the original
  hardcoded literals; re-run it after adding screens that were written with raw
  English strings.

**Quiz content translation**

`TranslationService` (`lib/data/services/translation_service.dart`) calls
Google's keyless `translate_a/single` endpoint, caches every result in the Hive
cache box for 90 days, de-duplicates in-flight requests, and falls back to the
original text on any failure. Render question text with `TranslatableText`
instead of `Text`, and put a `TranslateChip` on the question card.

**Fonts**: `AppTheme.darkThemeFor(languageCode)` picks Hind Siliguri for Bangla
and Poppins otherwise — Poppins has no Bengali glyphs.

## 5. Data & assets

- Question banks: JSON files under `assets/data/` (see `docs/03_JSON_DATA_SCHEMAS.md`
  for the exact schema — Category → Chapter → Question).
- New chapters can be generated with `tool/generate_chapters.py` (Python).
- `docs/` holds the architecture blueprints (`01_PROJECT_ROADMAP.md` … `06_USER_AUTH_...`).
  Read the matching doc before touching that subsystem.

## 6. Build, run, test

```bash
flutter pub get
flutter analyze
flutter test            # currently only test/widget_test.dart
flutter run             # device/emulator
flutter build web       # web build (used for admin + web GUI testing)
```

Firebase config lives in `lib/data/services/firebase_options.dart` (generated) and
`firebase.json` / `.firebaserc` at repo root. Do not edit `firebase_options.dart` by
hand — regenerate via `flutterfire configure`.

## 7. Skills to use for fast, accurate work

Invoke the matching skill **before** improvising. The installed **`superpowers`**
plugin (Jesse Vincent's workflow pack) is the backbone of disciplined, fast, correct
work here — its skills sit ABOVE any default behavior, but BELOW this file's explicit
instructions. Rule of thumb: if there is even a 1% chance a skill applies, invoke it.

### Always-on (superpowers)

- **`using-superpowers`** — triggers at the start of *every* conversation. It mandates
  the skill-first discipline: check for a relevant skill before any response or action,
  including clarifying questions. Follow it.

### Process skills (run FIRST, before implementation)

| Trigger | Skill | Purpose |
|---|---|---|
| Starting any creative/feature work (new feature, component, behavior change) | `brainstorming` | Explore intent, requirements, design before coding |
| Have a spec/requirements for a multi-step task | `writing-plans` | Produce a written implementation plan before touching code |
| Have a written plan to execute (separate session, review checkpoints) | `executing-plans` | Run the plan with checkpoints |
| Executing a plan with independent tasks **in this session** | `subagent-driven-development` | Drive implementation via subagents |
| 2+ independent tasks, no shared state | `dispatching-parallel-agents` | Parallelize independent work |
| Starting isolated feature work / before a plan | `using-git-worktrees` | Get an isolated workspace (native or git worktree) |
| Any bug, test failure, or unexpected behavior | `systematic-debugging` | Diagnose before proposing fixes |
| Implementing any feature or bugfix | `test-driven-development` | Write the failing test before the code |
| About to claim "done / fixed / passing" or before commit/PR | `verification-before-completion` | Run verification, show evidence, then assert |
| Completing a task / major feature / before merge | `requesting-code-review` | Verify work meets requirements |
| Receiving code-review feedback | `receiving-code-review` | Verify technically; don't blindly agree |
| Implementation done, tests pass, deciding integration | `finishing-a-development-branch` | Structured merge / PR / cleanup options |
| Creating/editing/verifying a skill | `writing-skills` | Use the skill-authoring workflow |

### Project-specific & platform skills

| Task | Skill to use | Notes |
|---|---|---|
| Test the web build in a real browser (click/type/screenshot) | `browser-use` (control-browser) or `web-gui-tester` | After `flutter build web`; black-box GUI verification |
| Generate/edit `.docx`/`.pdf`/`.xlsx`/`.pptx` (reports, schemas, decks) | `document-skills:docx|:pdf|:xlsx|:pptx` (or `officecli`) | Bulk question templates, admin docs |
| Mirror this repo to another GitHub account (personal ↔ pro/portfolio) | `cross-account-github-sync` | Sets up GitHub Actions auto-sync |
| Config broken (skill/MCP/hook/command/plugin missing/failing) | `zcode-guide:diagnosing-*` | Symptom→cause→fix workflow |
| Architecture / file-relationship question across the repo | `graphify` | Treat `graphify-out/` queries as graphify first |
| Turn a repeated workflow into a reusable skill | `skill-creator` | Improves future speed/consistency |
| Telegram channel pairing/policy/broadcast | `telegram:configure`, `telegram:access` | Only if the app integrates Telegram |

General guidance: prefer the repo's existing patterns over new libraries; read the
relevant `docs/*.md` before large changes; keep `flutter analyze` clean.

## 8. Commits & scope

- Branch from `main` for changes; the user commits/pushes on request.
- Keep commits focused per feature; reference the feature area in the message
  (e.g. `admin:`, `quiz:`, `ui:`).
- Never commit secrets, `firebase_options.dart` real keys, or `.env` files. Use
  environment variables / local settings for credentials.
