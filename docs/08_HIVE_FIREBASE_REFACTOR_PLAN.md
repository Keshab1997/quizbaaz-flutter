# 🗄️ QuizBaaz — Hive-First Data Refactor

> **লক্ষ্য:** অ্যাপের কোথাও কোনো hardcoded/dummy ডেটা থাকবে না।
> সব ডেটা **Hive** থেকে আসবে, Hive-ই single source of truth।
> **Firebase (Firestore)** শুধু Hive-এর সাথে দুই-দিকে sync হবে।
>
> **নিয়ম:** UI → Provider → **Hive** → (background) → Firestore
> UI কখনও সরাসরি Firestore পড়ে না। অফলাইনেও পুরো অ্যাপ চলে।

---

## 📊 Progress Tracker

| # | Task | Status |
|---|------|--------|
| T01 | Hive foundation (boxes, TTL cache, offline queue) + `UserStats` | ✅ Done |
| T02 | `SyncService` — Hive ⇄ Firestore two-way sync + queue drain | ✅ Done |
| T03 | Stats tracking wiring (accuracy, streak, per-chapter, battles) | ✅ Done |
| T04 | **Dashboard/Home** — সব hardcoded ডেটা বাদ | ✅ Done |
| T05 | Leaderboard screen — Hive cache + Firestore + empty states | ✅ Done |
| T06 | Champion card + `champion_podium_widget` — real data | ✅ Done |
| T07 | Profile screen — real stats, earned-only badges, live settings | ✅ Done |
| T08 | Rewards — Hive-backed gifts, demo prizes বাদ | ✅ Done |
| T09 | Battle — config-driven, results saved to stats | ✅ Done |
| T10 | Admin role-guard + real metrics + nav index bug fix | ✅ Done |
| T11 | SharedPreferences সম্পূর্ণ বাদ → Hive-only (auto-migration) | ✅ Done |
| T12 | Dead code cleanup + tests | ✅ Done |

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│ Presentation — শুধু Provider পড়ে, কোনো literal ডেটা নেই │
└──────────────┬───────────────────────────────────────┘
┌──────────────▼───────────────────────────────────────┐
│ Providers: user · quiz · battle · rewards · auth      │
└──────────────┬───────────────────────────────────────┘
┌──────────────▼───────────────────────────────────────┐
│ HiveService ◄── SINGLE SOURCE OF TRUTH                │
│ qb_user · qb_stats · qb_cache · qb_meta · qb_pending  │
└──────────────┬───────────────────────────────────────┘
┌──────────────▼───────────────────────────────────────┐
│ SyncService → FirestoreService                        │
│ push: queue drain · pull: user/stats/rank/config      │
└───────────────────────────────────────────────────────┘
```

### Firestore layout

```
users/{uid}                    → profile (UserModel)
users/{uid}/meta/stats         → UserStats
users/{uid}/gifts/{giftId}     → GiftClaim
leaderboard/{yyyy-MM-dd}/scores/{uid}
champions/{yyyy-MM-dd}/winners/{uid}
config/app                     → AppConfig (game rules, admin list)
```

---

## 🧹 যেসব hardcoded ডেটা মুছে ফেলা হয়েছে

| আগে | এখন |
|---|---|
| `'Good morning, ...'` ফিক্সড | ঘড়ি অনুযায়ী morning/afternoon/evening/night |
| accuracy `'72%'` | `UserStats.accuracyPercent` (ডেটা না থাকলে `--`) |
| `'Top 18% today'` | `UserProvider.percentileLabel` (আসল rank থেকে) |
| champion `'Rahul Das'`, `'96 pts'`, `'500 coins + smartwatch'` | `ChampionModel` (Firestore→Hive); না থাকলে "No champion yet" |
| leaderboard `Liam G. / Sarah K. / Ben J. / Maya S.` | আসল `leaderboard` rows; খালি হলে "No scores today yet" |
| hero `'10 questions'`, `'03:20'`, `'500 coins'` | `AppConfig` থেকে হিসাব করা |
| streak `x/7`, ফিক্সড subtitle | `config.streakGoalDays` + বাকি দিনের হিসাব |
| Admin বোতাম সবার জন্য | শুধু `isAdmin` হলে দেখা যায় |
| Admin metrics `1,284` / `8,420` | Firestore aggregate count (real) |
| podium widget-এ fake `'Subham Roy'` | champion না থাকলে empty state |
| profile badges সবসময় ৩টা | শুধু **অর্জিত** badge (stats থেকে হিসাব) |
| profile settings switch ডেড | Hive-এ সংরক্ষিত, আসলেই কাজ করে |
| rewards demo gift (smartwatch, Amazon voucher) | Firestore→Hive; না থাকলে empty state |
| `UserModel` default 1450 coins / 45 gems / 6 streak | সব **0** থেকে শুরু |
| repository-র fallback ভুয়া প্রশ্ন | খালি হলে "No questions available" |
| bundled `live_leaderboard.json`, `yesterday_champions.json` | **ডিলিট** — ranking কখনো bundle থেকে আসে না |
| quiz timer hardcoded `15` | `config.secondsPerQuestion` |
| battle `'7-question'`, `'Bot ~45%'` | `config.battleQuestionCount` + neutral copy |

---

## 📁 ফাইল পরিবর্তনের তালিকা

**নতুন**
- `lib/data/models/user_stats.dart` — সব gameplay পরিসংখ্যান + merge logic
- `lib/data/models/app_config.dart` — remote-controlled game rules
- `lib/data/services/sync_service.dart` — push/pull/queue-drain
- `lib/data/repositories/leaderboard_repository.dart` — Hive-first ranking

**বড় পরিবর্তন**
- `hive_service.dart` — ৫ box, TTL cache, offline queue, v1→v2 migration
- `firestore_service.dart` — stats/champions/gifts/config/admin-metrics, সব call bool ফেরত দেয়
- `user_provider.dart` — Hive-only, stats, config, admin, settings, sync
- `quiz_provider.dart` — config-driven, `recordQuizResult()` কল করে
- `battle_provider.dart` — config-driven + `recordBattleResult()`
- `rewards_provider.dart` — Hive cache + Firestore, demo gift বাদ
- `quiz_repository.dart` — Hive cache, dummy fallback বাদ
- `dashboard_screen.dart`, `leaderboard_screen.dart`, `profile_screen.dart`,
  `admin_dashboard_screen.dart`, `champion_podium_widget.dart`,
  `daily_quiz_screen.dart`, `battle_screen.dart`, `quiz_result_screen.dart`,
  `chapter_list_screen.dart`, `main.dart`, `user_model.dart`

**ডিলিট**
- `assets/data/live_leaderboard.json`
- `assets/data/yesterday_champions.json`
- `lib/presentation/widgets/custom_bottom_nav.dart` (unused duplicate)
- `shared_preferences` dependency

---

## 🐛 আরও যেসব বাগ ঠিক হলো

1. **Bottom-nav index** — অন্য স্ক্রিন থেকে ফিরলে Home আবার highlight হয়
2. **Leaderboard infinite spinner** — এখন খালি হলে empty state + pull-to-refresh
3. **Streak** — `lastStreakDate` দেখে বাড়ে/রিসেট হয় (আগে ফিক্সড ছিল)
4. **Guest bonus** — hardcoded 500/20 → `config.signupBonusCoins/Gems`
5. **Google link** — এখন Firebase `uid` + photo ব্যবহার করে (আগে email ছিল userId)

---

## ✅ তোমার করণীয় (verify)

```bash
git pull
flutter pub get          # shared_preferences বাদ গেছে, তাই জরুরি
flutter analyze
flutter test
flutter run
```

**যা দেখতে হবে:**
- [ ] নতুন install-এ coins/gems/streak/accuracy সব **0 / `--`**
- [ ] Daily Quiz খেললে accuracy, streak, best score আপডেট হয়
- [ ] অ্যাপ kill করে আবার খুললে সব ডেটা টিকে থাকে (Hive)
- [ ] Firestore বন্ধ/নেট অফ থাকলেও crash হয় না, লেখা queue-তে জমে
- [ ] নেট ফিরলে queue নিজে থেকে drain হয় (Admin → Sync Now-এ কতগুলো replay হলো দেখাবে)
- [ ] Admin বোতাম সাধারণ ইউজারের কাছে **দেখাই যায় না**
- [ ] leaderboard/champion খালি থাকলে সুন্দর empty state (কোনো ভুয়া নাম নেই)

### Admin অ্যাক্সেস চালু করতে
Firestore-এ `config/app` ডকুমেন্ট বানাও:
```json
{ "admin_user_ids": ["<তোমার-firebase-uid>"] }
```
অথবা `users/{uid}` ডকে `is_admin: true` সেট করো।
একই ডকুমেন্ট থেকে `daily_question_count`, `seconds_per_question`,
`coins_per_correct_daily` ইত্যাদি সব নিয়ম বদলানো যায় — অ্যাপ আপডেট ছাড়াই।

---

## ⚠️ জানা সীমাবদ্ধতা

- **Firestore security rules** এখনো লেখা হয়নি — production-এ যাওয়ার আগে দরকার
  (`users/{uid}` শুধু নিজের, `leaderboard` read-all/write-own, `config` read-only)
- Champions স্বয়ংক্রিয়ভাবে publish হয় না — Admin panel থেকে বাটন চাপতে হয়
  (পরে Cloud Function দিয়ে cron করা যাবে)
- Shop catalogue (`ShopCatalog`) এখনো কোডে — এটা authored config, user data নয়
