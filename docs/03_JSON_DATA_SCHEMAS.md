# 🗄️ JSON ডেটা স্কিমা ও ডেটাবেস স্ট্রাকচার (Data Schemas)

অ্যাপের চ্যাপ্টার কোশ্চেন ব্যাংক, ডেইলি কুইজ, লিডারবোর্ড এবং রিওয়ার্ডগুলো যেভাবে JSON ফরম্যাটে থাকবে তার সম্পূর্ণ স্পেসিফিকেশন নিচে দেওয়া হলো:

---

## ১. চ্যাপ্টার ও বিষয় তালিকা (`chapters_list.json`)

```json
{
  "categories": [
    {
      "category_id": "cat_science",
      "category_name": "General Science",
      "category_icon": "assets/icons/3d_science.png",
      "total_chapters": 5,
      "chapters": [
        {
          "chapter_id": "sci_ch_01",
          "chapter_number": 1,
          "title": "Solar System & Space",
          "description": "Planets, stars, and cosmic mysteries",
          "total_questions": 20,
          "json_file": "assets/data/questions/sci_ch_01.json",
          "unlocked": true,
          "best_score": 18,
          "stars": 3
        },
        {
          "chapter_id": "sci_ch_02",
          "chapter_number": 2,
          "title": "Human Biology & Anatomy",
          "description": "Organs, blood circulatory system, and brain",
          "total_questions": 25,
          "json_file": "assets/data/questions/sci_ch_02.json",
          "unlocked": true,
          "best_score": 0,
          "stars": 0
        }
      ]
    }
  ]
}
```

---

## ২. চ্যাপ্টার প্রশ্ন ব্যাংক (`sci_ch_01.json`)

```json
{
  "chapter_id": "sci_ch_01",
  "chapter_title": "Solar System & Space",
  "questions": [
    {
      "id": "sci_q01",
      "question": "Which planet is known as the Red Planet?",
      "question_bn": "কোন গ্রহটি লাল গ্রহ নামে পরিচিত?",
      "options": [
        "Venus (শুক্র)",
        "Mars (মঙ্গল)",
        "Jupiter (বৃহস্পতি)",
        "Saturn (শনি)"
      ],
      "correct_index": 1,
      "explanation": "Mars appears reddish because of widespread iron oxide (rust) on its surface.",
      "points": 10,
      "time_limit_sec": 15
    },
    {
      "id": "sci_q02",
      "question": "Which is the largest planet in our Solar System?",
      "question_bn": "সৌরজগতের বৃহত্তম গ্রহ কোনটি?",
      "options": [
        "Earth (পৃথিবী)",
        "Jupiter (বৃহস্পতি)",
        "Neptune (নেপচুন)",
        "Uranus (ইউরেনাস)"
      ],
      "correct_index": 1,
      "explanation": "Jupiter is more than twice as massive as all the other planets combined.",
      "points": 10,
      "time_limit_sec": 15
    }
  ]
}
```

---

## ৩. ডেইলি কুইজ প্রশ্ন স্কিমা (`daily_quiz_2026_08_20.json`)

প্রতিদিন ঠিক ১০টি প্রশ্ন থাকবে:

```json
{
  "quiz_date": "2026-08-20",
  "quiz_id": "daily_20260820",
  "total_questions": 10,
  "time_per_question_sec": 15,
  "reward_coins": 500,
  "reward_xp": 100,
  "questions": [
    {
      "id": "dq_01",
      "question": "What is the powerhouse of the cell?",
      "question_bn": "কোষের শক্তিঘর (Powerhouse) কাকে বলা হয়?",
      "options": ["Nucleus", "Mitochondria", "Ribosome", "Golgi Body"],
      "correct_index": 1,
      "explanation": "Mitochondria generate most of the chemical energy needed by the cell.",
      "points": 10
    }
  ]
}
```

---

## ৪. গতকালের বিজয়ী ও উপহার তালিকা (`yesterday_champions.json`)

হোম পেজে "Yesterday's Champion" উইজেটে প্রদর্শনের জন্য:

```json
{
  "date": "2026-08-19",
  "champions": [
    {
      "rank": 1,
      "user_id": "user_789",
      "name": "Subham Roy",
      "username": "@subham_pro",
      "avatar_url": "assets/images/avatars/boy_champion_3d.png",
      "score": 100,
      "completion_time_sec": 42.5,
      "gift_title": "Noise Smartwatch 3D Edition",
      "gift_image": "assets/icons/3d_gift_watch.png",
      "reward_coins": 1000,
      "badge": "Grand Champion 🏆"
    },
    {
      "rank": 2,
      "user_id": "user_456",
      "name": "Priya Sharma",
      "username": "@priya_quiz",
      "avatar_url": "assets/images/avatars/girl_3d.png",
      "score": 95,
      "completion_time_sec": 48.0,
      "gift_title": "₹500 Amazon Gift Voucher",
      "gift_image": "assets/icons/3d_gift_voucher.png",
      "reward_coins": 500,
      "badge": "Silver Star 🥈"
    },
    {
      "rank": 3,
      "user_id": "user_123",
      "name": "Keshab Sarkar",
      "username": "@Keshab1997",
      "avatar_url": "assets/images/avatars/quizbaaz_avatar_boy.png",
      "score": 90,
      "completion_time_sec": 51.2,
      "gift_title": "Pro Badge + 300 Coins",
      "gift_image": "assets/icons/3d_gift_coins.png",
      "reward_coins": 300,
      "badge": "Bronze Hero 🥉"
    }
  ]
}
```

---

## ৫. আজকের লাইভ লিডারবোর্ড (`live_leaderboard.json`)

```json
{
  "total_participants": 1284,
  "last_updated": "2026-08-20T14:30:00Z",
  "top_players": [
    {
      "rank": 1,
      "name": "Ananya Roy",
      "avatar": "assets/images/avatars/girl_3d.png",
      "score": 100,
      "time_taken": "01:12s",
      "streak": 14
    },
    {
      "rank": 2,
      "name": "Keshab Sarkar",
      "avatar": "assets/images/avatars/quizbaaz_avatar_boy.png",
      "score": 98,
      "time_taken": "01:18s",
      "streak": 6
    }
  ]
}
```

---

## ৬. ইউজার প্রোফাইল ও স্ট্রিক স্টেট (`user_profile.json`)

```json
{
  "user_id": "usr_keshab_01",
  "username": "Keshab1997",
  "full_name": "Keshab Sarkar",
  "avatar": "assets/images/avatars/quizbaaz_avatar_boy.png",
  "coins": 2450,
  "gems": 85,
  "daily_streak": 6,
  "streak_history": [
    {"day": "Mon", "completed": true},
    {"day": "Tue", "completed": true},
    {"day": "Wed", "completed": true},
    {"day": "Thu", "completed": true},
    {"day": "Fri", "completed": true},
    {"day": "Sat", "completed": true},
    {"day": "Sun", "completed": false}
  ],
  "power_ups": {
    "fifty_fifty": 3,
    "time_freeze": 2,
    "skip_card": 1
  },
  "today_daily_quiz_played": false
}
```
