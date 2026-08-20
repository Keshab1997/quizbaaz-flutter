# 🗄️ QuizBaaz — Hive-First Data Refactor Plan

> **লক্ষ্য:** অ্যাপের কোথাও কোনো hardcoded/dummy ডেটা থাকবে না।
> সব ডেটা **Hive** থেকে আসবে, Hive-ই single source of truth।
> **Firebase (Firestore)** শুধু Hive-এর সাথে দুই-দিকে sync হবে।
>
> **নিয়ম:** UI → Provider → **Hive** → (background) → Firestore
> UI কখনও সরাসরি Firestore পড়বে না। অফলাইনেও পুরো অ্যাপ চলবে।

---

## 📊 Progress Tracker

| # | Task | Status | Commit |
|---|------|--------|--------|
| T01 | Hive foundation (boxes, cache, sync-queue) + `UserStats` model | ✅ Done | `feat(hive): T01` |
| T02 | `SyncService` — Hive ⇄ Firestore two-way sync + offline queue | ⬜ Todo | – |
| T03 | Stats tracking wiring (accuracy, quizzes, per-chapter) | ⬜ Todo | – |
| T04 | **Dashboard/Home** — সব hardcoded ডেটা বাদ | ⬜ Todo | – |
| T05 | Leaderboard screen — Hive cache + Firestore live | ⬜ Todo | – |
| T06 | Champion card + `champion_podium_widget` — real data | ⬜ Todo | – |
| T07 | Profile screen — real stats from Hive | ⬜ Todo | – |
| T08 | Rewards + Shop — Hive-backed inventory/claims | ⬜ Todo | – |
| T09 | Battle screen — dummy opponent বাদ | ⬜ Todo | – |
| T10 | Admin role-guard + bottom-nav index bug + duplicate nav widget | ⬜ Todo | – |
| T11 | SharedPreferences সম্পূর্ণ বাদ → Hive-only (auto-migration সহ) | ⬜ Todo | – |
| T12 | Final `flutter analyze` cleanup + README/docs update | ⬜ Todo | – |

**Legend:** ⬜ Todo · 🟡 In progress · ✅ Done · 🔴 Blocked (তোমার report লাগবে)

---

## 🏗️ Target Architecture

```
┌────────────────────────────────────────────────────────┐
│  Presentation (screens/widgets)                        │
│  → শুধু Provider থেকে পড়ে, কোনো literal ডেটা নেই        │
└───────────────┬────────────────────────────────────────┘
                │ context.watch<XProvider>()
┌───────────────▼────────────────────────────────────────┐
│  Providers (user, quiz, battle, rewards, auth)         │
│  → read/write শুধু HiveService দিয়ে (instant, sync)     │
└───────────────┬────────────────────────────────────────┘
                │
┌───────────────▼────────────────────────────────────────┐
│  HiveService  ◄── SINGLE SOURCE OF TRUTH               │
│  boxes: qb_user · qb_stats · qb_cache · qb_meta        │
│         qb_pending (offline write queue)               │
└───────────────┬────────────────────────────────────────┘
                │ background, non-blocking
┌───────────────▼────────────────────────────────────────┐
│  SyncService → FirestoreService                        │
│  push: pending queue drain                             │
│  pull: users/{uid}, leaderboard/{date}, champions/{d}  │
└────────────────────────────────────────────────────────┘
```

### Hive Boxes

| Box | কী রাখে |
|-----|---------|
| `qb_user` | current user JSON |
| `qb_stats` | `UserStats` (answered, correct, accuracy, per-chapter) |
| `qb_cache` | TTL সহ remote ডেটার cache (leaderboard, champions, chapters) |
| `qb_meta` | lastSyncAt, schemaVersion, lastRewardDate, flags |
| `qb_pending` | অফলাইনে জমে থাকা Firestore write গুলো |

---

## 🔎 Hardcoded ডেটার অডিট (যা যা সরাতে হবে)

### `dashboard_screen.dart`
| লাইন | কী | কোথা থেকে আসবে |
|---|---|---|
| 193 | `'Good morning, ...'` ফিক্সড | সময় অনুযায়ী dynamic |
| 486 | `'72%'` accuracy | `UserStats.accuracy` (Hive) |
| 488 | `'Top 18% today'` | leaderboard percentile |
| 893 | `'Rahul Das'` champion | `UserProvider.yesterdayTopChampion` |
| 902 | `'96 pts • Rank #1'` | ঐ champion model |
| 917 | `'500 coins + smartwatch'` | `ChampionModel.giftName/bonusCoins` |
| 941-946 | পুরো `_Rank` লিস্ট | `UserProvider.leaderboard` |
| 434 | `'03:20'` timer | quiz config |
| 437 | `'500 coins'` reward | quiz config |
| 1003 | Admin বোতাম সবার জন্য | role guard |

### অন্যান্য (পরে যাচাই হবে)
- `profile_screen.dart` (864 লাইন) — stat কার্ডগুলো
- `leaderboard_screen.dart` (453) — asset JSON fallback
- `battle_screen.dart` (617) — dummy opponent
- `rewards_screen.dart` (609) / `shop_screen.dart` (243)
- `champion_podium_widget.dart`

---

## ✅ T01 — Hive Foundation (সম্পন্ন)

**নতুন ফাইল**
- `lib/data/models/user_stats.dart` — সব gameplay পরিসংখ্যান, JSON serializable
- `lib/data/services/hive_service.dart` — সম্পূর্ণ নতুন করে লেখা

**যা যোগ হলো**
1. **৫টি আলাদা box** (উপরের টেবিল অনুযায়ী)
2. **Legacy migration** — পুরনো `quizbaaz_box` থেকে ডেটা স্বয়ংক্রিয়ভাবে নতুন box-এ চলে যাবে, ইউজার কিছু হারাবে না
3. **TTL cache API** — `cachePut / cacheGet / cacheAge / isCacheFresh`
4. **Offline write queue** — `enqueuePending / pendingOps / removePending`
5. **`UserStats` persistence** — `saveStats / loadStats`
6. **Meta store** — `setMeta / getMeta`, `lastSyncAt`, `schemaVersion = 2`
7. পুরনো সব API (`saveUser`, `loadGameProgress` ইত্যাদি) অক্ষত — তাই এই ধাপে কোনো screen ভাঙবে না

**Backward compatible?** হ্যাঁ। `UserProvider` কোনো পরিবর্তন ছাড়াই আগের মতো চলবে।

**তোমার করণীয়:**
```bash
git pull
flutter pub get
flutter analyze
```
error/warning থাকলে আমাকে পাঠাও → ঠিক করে T02-এ যাব।

---

## 📌 কাজের নিয়ম (আমাদের workflow)

1. আমি **একটি করে** task করব → commit → push
2. তুমি local-এ `flutter analyze` / `flutter run` চালিয়ে report দেবে
3. error থাকলে আগে সেটা fix, তারপর পরের task
4. প্রতিটি ধাপে এই ফাইলের **Progress Tracker** আপডেট হবে
