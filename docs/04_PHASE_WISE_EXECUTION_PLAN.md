# 🚀 ধাপে ধাপে কাজের পরিকল্পনা (Phase-by-Phase Execution Plan)

কাজটি যাতে কখনো মাঝপথে আটকে না যায়, সেজন্য মোবাইল অ্যাপ, গেস্ট ফানেল, ব্যাকএন্ড ও অ্যাডমিন প্যানেল মিলিয়ে পুরো ডেভেলপমেন্টকে **৭টি সুনির্দিষ্ট ফেজে (Phases)** বিন্যস্ত করা হলো:

---

## 📌 Phase 1: প্রজেক্ট সেটআপ ও গ্লাস থিম/অ্যাসেট ফাউন্ডেশন
- [ ] **Step 1.1:** নতুন Flutter প্রজেক্ট তৈরি ও `pubspec.yaml` ডিপেন্ডেন্সি যোগ করা (`provider`, `google_fonts`, `lottie`, `audioplayers`, `confetti`, `shared_preferences`, `cached_network_image`)।
- [ ] **Step 1.2:** কালার প্যালেট, নিয়ন গ্লো ও ডার্ক গ্লাস মরফিজম থিম কনফিগার করা (`app_colors.dart`, `app_theme.dart`)।
- [ ] **Step 1.3:** ৩D আইকন ও অ্যাসেট ফোল্ডার সেটআপ (`assets/images/`, `assets/icons/`, `assets/data/`, `assets/audio/`)।
- [ ] **Step 1.4:** রিইউজেবল গ্লাস কার্ড (`GlassCard`) এবং নিয়ন বাটন (`NeonButton`) তৈরি।

---

## 📌 Phase 2: হোম ড্যাশবোর্ড স্ক্রিন ডেভেলপমেন্ট (Guest & User Home Screen)
- [ ] **Step 2.1:** **Top App Bar / Header:** প্রোফাইল অবতার, গ্রিটিংস, কয়েন ও জেম কাউন্টার, নোটিফিকেশন বেল।
- [ ] **Step 2.2:** **Hero Section:** "TODAY'S QUIZ - 10 QUESTIONS" টাইমার ও চেস্ট রিওয়ার্ড কার্ড + "START QUIZ >" নিয়ন বাটন + "LIVE PLAYERS (1,284 Online)" কার্ড।
- [ ] **Step 2.3:** **Interactive Widgets:** 
  - **Yesterday's Champion Widget:** ১ নম্বর বিজয়ী, ৩D ক্যারেক্টার ও গিফটের বিবরণ (Smart Watch/Voucher)।
  - **Daily Streak Widget:** ৩D আগুনের শিখা (Fire Flame) ও ৭ দিনের ট্র্যাকার।
  - **Leaderboard Snippet:** শীর্ষ ৩ জনের সংক্ষিপ্ত র‍্যাংক কার্ড।
- [ ] **Step 2.4:** **Quick Action Grid (5 Buttons):** Chapter Quiz, Practice, 1 vs 1 Battle, Rewards, Shop।
- [ ] **Step 2.5:** **Bottom Navigation Bar:** মাঝখানে গোল্ডেন শিল্ড বাটন সহ ফ্লোটিং গ্লাস ন্যাভ বার।

---

## 📌 Phase 3: ডেটা মডেল ও লোকাল JSON Question Bank ইন্টিগ্রেশন
- [ ] **Step 3.1:** JSON ডেটা মডেল তৈরি (`QuestionModel`, `ChapterModel`, `ChampionModel`, `UserProfileModel`)।
- [ ] **Step 3.2:** `assets/data/` ফোল্ডারে ডামি JSON ফাইল যুক্ত করা (`chapters_list.json`, `sci_ch_01.json`, `daily_quiz.json`, `yesterday_champions.json`)।
- [ ] **Step 3.3:** `QuizRepository` তৈরি করে অফলাইন ও লোকাল JSON লোড করা।

---

## 📌 Phase 4: ডেইলি কুইজ ও চ্যাপ্টার কুইজ ইঞ্জিন (Quiz Gameplay Engine)
- [ ] **Step 4.1:** **Daily Quiz Screen UI:** কোশ্চেন নাম্বার, টাইমার বার, প্রশ্ন কার্ড, ৪টি অপশন বাটন ও লাইফলাইন (50-50, +10s Time Freeze, Skip)।
- [ ] **Step 4.2:** **Quiz Gameplay Logic:** সঠিক/ভুল অ্যানিমেশন, সাউন্ড এফেক্ট ও অটো-নেক্সট ট্রানজিশন।
- [ ] **Step 4.3:** **Anti-Cheat Logic:** অ্যাপ ব্যাকগ্রাউন্ডে গেলে সতর্কবার্তা ও কুইজ অটো-সাবমিশন।
- [ ] **Step 4.4:** **Quiz Result Screen:** কনফেটি অ্যানিমেশন, স্কোরবোর্ড, এক্সপি/কয়েন আর্ন অ্যানিমেশন এবং "Review Answers" স্ক্রিন।

---

## 📌 Phase 5: গেস্ট অনবোর্ডিং, ১-ক্লিক সাইন ইন ও ডেটা মাইগ্রেশন
- [ ] **Step 5.1:** `AuthProvider` তৈরি — গেস্ট সেশন তৈরি ও ট্র্যাক করা।
- [ ] **Step 5.2:** গেস্ট ট্রায়াল কুইজ লজিক (গেস্ট ইউজাররা কুইজ খেলে রেজাল্ট পেজে স্কোর দেখতে পাবে)।
- [ ] **Step 5.3:** রেজাল্ট পেজ ও লিডারবোর্ডে "স্মার্ট কনভার্সন পপ-আপ" (Google 1-Tap Sign-In / Phone Login)।
- [ ] **Step 5.4:** গেস্ট থেকে ফুল অ্যাকাউন্টে ট্রানজিশনের সময় অর্জিত কয়েন ও স্ট্রিক স্বয়ংক্রিয়ভাবে অ্যাকাউন্ট লিঙ্ক করা (`linkWithCredential`)।

---

## 📌 Phase 6: লিডারবোর্ড ও গতকালের চ্যাম্পিয়ন/গিফট হিস্ট্রি
- [ ] **Step 6.1:** **Leaderboard Screen:** ১st, ২nd, ৩rd প্লেয়ারদের গোল্ডেন/সিলভার/ব্রোঞ্জ ৩D পডিয়াম ভিউ + নিচে ইউজারের নিজস্ব পজিশন কার্ড।
- [ ] **Step 6.2:** **Yesterday's Winners Archive:** গতকালের বিজয়ী তালিকা ও তাঁরা কী উপহার পেয়েছেন তার হিস্ট্রি।
- [ ] **Step 6.3:** **Rewards & Gift Claim Screen:** ফিজিক্যাল গিফটের জন্য কুরিয়ার অ্যাড্রেস ফর্ম ও ডেলিভারি ট্র্যাকিং স্ট্যাটাস।

---

## 📌 Phase 7: অ্যাডমিন ওয়েব প্যানেল ও সেন্ট্রাল ব্যাকএন্ড কন্ট্রোল
- [ ] **Step 7.1:** অ্যাডমিন অথেন্টিকেশন ও সুরক্ষিত অ্যাডমিন ড্যাশবোর্ড তৈরি।
- [ ] **Step 7.2:** **Question Manager:** একক বা Bulk JSON/Excel প্রশ্ন আপলোড সিস্টেম।
- [ ] **Step 7.3:** **Daily Quiz Scheduler:** আগামী দিনের ১০টি কুইজ প্রশ্ন শিডিউল করা।
- [ ] **Step 7.4:** **Winner & Gift Dispatcher:** প্রতিদিনের চ্যাম্পিয়ন ঘোষণা ও গিফট ডিসপ্যাচ ট্র্যাকার।
- [ ] **Step 7.5:** **User & Anti-Cheat Monitor:** চিটার ব্যান ও লাইভ অ্যাপ অ্যানালিটিক্স।
