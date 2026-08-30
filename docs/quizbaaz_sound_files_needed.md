# 🔊 QuizBaaz — Sound Files You Need to Download

তুমি sound file ডাউনলোড করে **ঠিক এই নামে** `quizbaaz-flutter/assets/sounds/` folder-এ রাখবে।
Format: **short `.wav`** (সব platform-এ সবচেয়ে কম latency-তে চলে)।

> কোডে নামগুলো `lib/data/services/sound_service.dart` → `soundFiles` map-এ locked আছে।
> ফাইল না থাকলে app crash করবে না — শুধু সেই sound-টা চুপ থাকবে (graceful skip)।

---

## UI / Navigation (5 ফাইল)

| File name | কোথায় বাজে |
|---|---|
| `ui_click.wav` | button, tab, quick action tap |
| `ui_back.wav` | back / pop / battle cancel |
| `ui_open.wav` | dialog / purchase celebration open |
| `ui_deny.wav` | locked chapter, insufficient funds, already owned |
| `ui_whoosh.wav` | screen transition, quiz শুরু, next question slide |

## Quiz (15 ফাইল)

| File name | কোথায় বাজে |
|---|---|
| `quiz_start.wav` | daily/chapter quiz শুরু |
| `quiz_correct.wav` | সঠিক উত্তর (ding) |
| `quiz_wrong.wav` | ভুল উত্তর (buzz) |
| `quiz_timeout.wav` | time up |
| `quiz_tick.wav` | শেষ ৫ সেকেন্ডের tick |
| `quiz_complete.wav` | quiz শেষ fanfare |
| `quiz_perfect.wav` | perfect score |
| `lifeline_5050.wav` | 50-50 lifeline |
| `lifeline_freeze.wav` | freeze timer |
| `lifeline_skip.wav` | skip question |
| `lifeline_hint.wav` | hint reveal |
| `lifeline_audience.wav` | audience poll |
| `revive.wav` | extra life revive |
| `boost.wav` | double points active |
| `coin.wav` | coins/gems credit |

## Battle Arena (7 ফাইল)

| File name | কোথায় বাজে |
|---|---|
| `battle_search.wav` | opponent খোঁজার radar (loop) |
| `battle_found.wav` | match found alert |
| `battle_vs.wav` | VS slam intro |
| `battle_count.wav` | 3-2-1 countdown |
| `battle_go.wav` | GO! |
| `battle_win.wav` | জয়ের fanfare |
| `battle_lose.wav` | হারের sting (streak reset-এও) |

## Rewards / Shop / Streak (4 ফাইল)

| File name | কোথায় বাজে |
|---|---|
| `purchase.wav` | shop purchase (cha-ching) |
| `unlock.wav` | *(reserved — chapter unlock, এখনো wired হয়নি)* |
| `fire.wav` | streak motivation |
| `champion.wav` | daily winner / podium celebration |

---

**মোট = ৩১টা ফাইল**, সব `assets/sounds/`-এ।

### Free source (license-friendly)
- **Kenney.nl** (audio packs, wav/ogg)
- **Mixkit.co** (free SFX, wav)
- **Pixabay Sound Effects** (free, wav/mp3)
- **Freesound.org** (CC0 filter)

### ফাইল বসানোর পর
1. সব ফাইল `assets/sounds/`-এ রাখো (নাম হুবহু উপরের মতো, `.wav`)
2. `flutter pub get` → build করো
3. Profile → Settings → **Sound Effects** on/off toggle দিয়ে টেস্ট করো

> 💡 Sound on/off = Profile → Settings → "Sound Effects" (default ON)
> 💡 Vibration on/off = Profile → Settings → "Vibration" (default OFF)
