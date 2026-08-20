# 📱 QuizBaaz (Gamified 3D Quiz App) - Master Project Blueprint

> **প্রজেক্টের মূল উদ্দেশ্য:** একটি আধুনিক, প্রিমিয়াম 3D গেমিফায়েড কুইজ অ্যাপ তৈরি করা যা Flutter দিয়ে নির্মিত হবে। এতে চ্যাপ্টারভিত্তিক JSON কোশ্চেন ব্যাংক, ডেইলি ১০ প্রশ্নের লাইভ কুইজ, ডেইলি লিডারবোর্ড, গতকালের চ্যাম্পিয়ন ও গিফট হিস্ট্রি, স্ট্রিক সিস্টেম, ভিজিটর/গেস্ট ট্রায়াল মোড এবং সম্পূর্ণ নিয়ন্ত্রণযোগ্য সেন্ট্রাল অ্যাডমিন প্যানেল থাকবে।

---

## 📑 ইনডেক্স ও ডকুমেন্টস গাইড (All System Documents)

| ক্রমিক | ডকুমেন্ট ফাইল | বিবরণ |
|---|---|---|
| **০১** | [`01_PROJECT_ROADMAP.md`](./01_PROJECT_ROADMAP.md) | সম্পূর্ণ প্রজেক্টের ওভারভিউ, আর্কিটেকচার ও টেকনোলজি স্ট্যাক |
| **০২** | [`02_ALL_PAGES_AND_SCREENS.md`](./02_ALL_PAGES_AND_SCREENS.md) | অ্যাপের সব পেজ (Screens), সাব-স্ক্রিন ও পপ-আপ মডালের বিস্তারিত তালিকা |
| **০৩** | [`03_JSON_DATA_SCHEMAS.md`](./03_JSON_DATA_SCHEMAS.md) | চ্যাপ্টার প্রশ্ন, ডেইলি কুইজ, লিডারবোর্ড, উইনার ও গিফট ডেটা স্কিমা |
| **০৪** | [`04_PHASE_WISE_EXECUTION_PLAN.md`](./04_PHASE_WISE_EXECUTION_PLAN.md) | ধাপে ধাপে কাজ করার সম্পূর্ণ চেকলিস্ট (Phase 1 to Phase 7) |
| **০৫** | [`05_ADMIN_PANEL_AND_BACKEND_SPEC.md`](./05_ADMIN_PANEL_AND_BACKEND_SPEC.md) | অ্যাডমিন ওয়েব কন্ট্রোল প্যানেল, কোশ্চেন আপলোডার ও গিফট ট্র্যাকার স্পেক |
| **০৬** | [`06_USER_AUTHENTICATION_AND_GUEST_TRIAL_FLOW.md`](./06_USER_AUTHENTICATION_AND_GUEST_TRIAL_FLOW.md) | নো-লগইন গেস্ট ট্রায়াল ভিজিট ও ১-ট্যাপে ফুল অ্যাকাউন্ট আপগ্রেড ফানেল |

---

## 🛠️ টেকনোলজি স্ট্যাক (Technology Stack)

* **মোবাইল অ্যাপ ফ্রন্টএন্ড:** Flutter (Dart 3+)
* **অ্যাডমিন প্যানেল ফ্রন্টএন্ড:** Flutter Web অথবা React / Next.js (Responsive Admin Dashboard)
* **স্টেট ম্যানেজমেন্ট:** Provider / Riverpod
* **থিম ও UI স্টাইল:** Dark Navy + Purple Gradient, Glassmorphism (`BackdropFilter`), Neon Glow
* **অ্যানিমেশন:** Lottie (Fire Streak, Confetti, Chest Box), AnimatedContainer, Rive
* **সাউন্ড ও ভাইব্রেশন:** `audioplayers`, `haptic_feedback`
* **অথেন্টিকেশন:** Firebase Anonymous Auth (গেস্ট মোডের জন্য) + Google Sign-In & Phone OTP
* **ডেটাবেস ও ক্লাউড ব্যাকএন্ড:** Firebase Cloud Firestore + Cloud Functions / REST API

---

## 📂 সম্পূর্ণ প্রোজেক্টের ফোল্ডার স্ট্রাকচার

```text
lib/
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # নিয়ন গ্লো, গ্রেডিয়েন্ট ও ডার্ক প্যালেট
│   │   ├── app_assets.dart         # 3D ইমেজের পাথ, আইকন ও সাউন্ড
│   │   └── app_strings.dart        # সকল টেক্সট কনস্ট্যান্ট
│   ├── theme/
│   │   └── app_theme.dart          # ডার্ক গ্লাস থিম কনফিগারেশন
│   └── utils/
│       ├── audio_helper.dart       # সাউন্ড প্লেয়ার সার্ভিস
│       └── haptic_helper.dart      # ভাইব্রেশন ফিডব্যাক
│
├── data/
│   ├── models/
│   │   ├── question_model.dart     # কুইজ প্রশ্ন ও অপশন মডেল
│   │   ├── chapter_model.dart      # চ্যাপ্টার ও ক্যাটাগরি মডেল
│   │   ├── user_model.dart         # ইউজার প্রোফাইল, কয়েন, জেম ও স্ট্রিক
│   │   ├── leaderboard_model.dart  # র‍্যাংকিং ও স্কোর মডেল
│   │   └── reward_model.dart       # গিফট হিস্ট্রি ও শপ আইটেম মডেল
│   ├── providers/
│   │   ├── auth_provider.dart      # গেস্ট মোড বনাম অথেন্টিকেটেড ইউজার স্টেট
│   │   ├── quiz_provider.dart      # কুইজ স্টেট, টাইমার ও স্কোরিং
│   │   ├── user_provider.dart      # ইউজার ব্যালেন্স ও স্ট্রিক কন্ট্রোল
│   │   └── leaderboard_provider.dart # লাইভ লিডারবোর্ড ও চ্যাম্পিয়ন ডেটা
│   └── repositories/
│       ├── quiz_repository.dart    # JSON/API থেকে প্রশ্ন লোড করার লজিক
│       ├── auth_repository.dart    # অ্যানোনিমাস থেকে গুগল অ্যাকাউন্টে মাইগ্রেশন
│       └── admin_repository.dart   # অ্যাডমিন এপিআই কল
│
├── presentation/
│   ├── screens/
│   │   ├── splash/                 # স্প্ল্যাশ স্ক্রিন
│   │   ├── auth/                   # সাইনইন / ১-ক্লিক আপগ্রেড মডাল
│   │   ├── dashboard/              # মূল ড্যাশবোর্ড (গেস্ট ও লগইন ইউজার)
│   │   ├── daily_quiz/             # ডেইলি ১০ প্রশ্নের কুইজ স্ক্রিন
│   │   ├── chapter_quiz/           # চ্যাপ্টারভিত্তিক প্রশ্ন ব্যাংক স্ক্রিন
│   │   ├── quiz_result/            # রেজাল্ট, অ্যানিমেশন ও কনভার্সন পপ-আপ
│   │   ├── leaderboard/            # লিডারবোর্ড ও গতকালের বিজয়ী তালিকা
│   │   ├── rewards/                # রিওয়ার্ড ক্লেইম ও গিফট ট্র্যাকার
│   │   ├── shop/                   # কয়েন/জেম দিয়ে পাওয়ার-আপ শপ
│   │   ├── battle/                 # 1 vs 1 ব্যাটল ম্যাচমেকিং স্ক্রিন
│   │   └── profile/                # ইউজার স্ট্যাটস, ব্যাজ ও হিস্ট্রি
│   │
│   └── widgets/                    # রিইউজেবল গ্লাস কার্ড, বাটন ও অ্যানিমেশন
│       ├── glass_card.dart
│       ├── neon_button.dart
│       ├── timer_bar.dart
│       ├── streak_flame.dart
│       ├── trophy_podium.dart
│       └── guest_banner_strip.dart # গেস্টদের জন্য হালকা ব্যানার
│
└── main.dart
```
