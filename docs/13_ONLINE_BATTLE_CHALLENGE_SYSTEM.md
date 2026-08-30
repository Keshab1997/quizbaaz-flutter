# 🆕 Online Battle Challenge System — Integration Guide

## Overview

এই update আপনার existing 1v1 Battle Arena এর সাথে **Online User List + Challenge System** যোগ করছে।

---

## 🆕 নতুন Features

### 1. 🟢 Online Presence System
- App খুললে user Firestore `online_users` collection এ যোগ হয়
- প্রতি 20 seconds এ heartbeat পাঠায়
- App বন্ধ করলে বা minimize করলে offline হয়ে যায়
- Real-time stream দিয়ে কে কে online সেটা দেখা যায়

### 2. ⚔️ Challenge System
- Online user list থেকে যেকোনো user কে challenge পাঠানো যায়
- Receiver এর কাছে notification dialog আসে (30 seconds এর countdown সহ)
- Accept করলে 1v1 battle শুরু হয়
- Reject/Expired হলে sender কে জানানো হয়
- Guest users challenge পাঠাতে পারে না (sign in required)

### 3. 🎮 Existing Battle System এর সাথে Integration
- Challenge accept হলে existing `BattleProvider` এর `startBattleWithOpponent()` call হয়
- Existing scoring, rooms, forfeit — সব একই রকম থাকে
- Bot fallback ও আছে যদি opponent disconnect করে

### 4. 📱 Play Store Ready
- **No permission issues** — শুধু Firebase (already using)
- **No background services** — presence app lifecycle দিয়ে manage হয়
- **Offline support** — Firebase না পেলে gracefully degrade হয়
- **Privacy compliant** — শুধু name, avatar, level, availability share হয়

---

## 📁 নতুন Files

| File | Purpose |
|------|---------|
| `lib/data/services/online_presence_service.dart` | Online presence + heartbeat + real-time list |
| `lib/data/services/challenge_service.dart` | Challenge send/accept/reject/expire + streams |
| `lib/presentation/screens/battle/online_battle_screen.dart` | Online users list + challenge UI |
| `firestore.rules` | Updated security rules (existing + new collections) |

---

## 🔧 Integration Steps

### Step 1: Copy New Files

```
quizbaaz-flutter/
├── lib/data/services/
│   ├── online_presence_service.dart    ← NEW
│   ├── challenge_service.dart          ← NEW
│   └── ... existing files ...
├── lib/presentation/screens/battle/
│   ├── online_battle_screen.dart       ← NEW
│   └── battle_screen.dart             ← existing
```

### Step 2: Update `battle_room.dart` — Add Challenge Model Import

`lib/data/models/battle_room.dart` file এর top এ কোনো পরিবর্তন দরকার নেই।

### Step 3: Update `BattleProvider` — Add `startBattleWithOpponent()` method

`lib/data/providers/battle_provider.dart` এ এই method যোগ করুন:

```dart
/// Starts a battle with a specific opponent (from challenge accept).
void startBattleWithOpponent({
  required String opponentUid,
  required String opponentName,
  required String opponentAvatar,
  String? opponentAvatarUrl,
  required String difficulty,
}) {
  _opponent = BattleOpponent(
    name: opponentName,
    avatar: opponentAvatarUrl ?? opponentAvatar,
    isBot: false,
    uid: opponentUid,
  );
  _isBotMatch = false;
  _liveCapable = true;
  _difficulty = BattleDifficulty.values.firstWhere(
    (d) => d.name == difficulty,
    orElse: () => BattleDifficulty.normal,
  );
  _userId = _userProvider.user.userId;
  _phase = BattlePhase.searching;
  notifyListeners();
  
  // Derive deterministic room ID
  final roomId = BattleRoomService.roomIdFor(_userId, opponentUid);
  _roomId = roomId;
  _side = _userId.compareTo(opponentUid) <= 0 ? 'a' : 'b';
  
  // Watch the room (creator writes it, joiner waits)
  _roomSub = _roomService.watchRoom(roomId).listen((room) {
    if (room != null) {
      _room = room;
      _onRoomUpdate(room);
    }
  });
  
  // If we're the creator (lexicographically smaller uid), write the room
  if (_side == 'a') {
    _createRoomAndStart();
  }
}
```

### Step 4: Add Route for Online Battle Screen

`lib/main.dart` এ route যোগ করুন:

```dart
// In MaterialApp routes:
'/online_battle': (context) => const OnlineBattleScreen(),
```

### Step 5: Add Entry Point from Dashboard

Dashboard থেকে Online Battle screen এ যাবার button যোগ করুন:

```dart
// In dashboard_screen.dart, add a battle entry:
GestureDetector(
  onTap: () => Navigator.pushNamed(context, '/online_battle'),
  child: /* existing battle button style */
)
```

### Step 6: Update Presence on App Lifecycle

`lib/main.dart` বা `lib/data/providers/user_provider.dart` এ:

```dart
// In the main widget's initState or AppLifecycleState handler:
// When app resumes → goOnline()
// When app pauses → goOffline()
```

### Step 7: Deploy Updated Firestore Rules

```bash
firebase deploy --only firestore:rules
```

### Step 8: Initialize Presence in App Start

`lib/main.dart` এর `main()` function এ Firebase init এর পর:

```dart
// After Firebase init and UserProvider.initialize():
final presence = OnlinePresenceService();
await presence.goOnline(
  uid: userProvider.user.userId,
  name: userProvider.user.username,
  avatar: userProvider.user.avatarPath,
  avatarUrl: userProvider.user.avatarUrl,
  level: userProvider.user.level,
);
```

---

## 🗄️ New Firestore Collections

### `online_users/{uid}`
```json
{
  "name": "Keshab",
  "avatar": "assets/images/avatars/quizbaaz_avatar_boy.png",
  "avatar_url": "https://...",
  "level": 12,
  "is_available": true,
  "current_activity": "idle",
  "last_seen": 1756543200000,
  "updated_at": Timestamp
}
```

### `battle_challenges/{challengeId}`
```json
{
  "from_uid": "uid_abc",
  "from_name": "Keshab",
  "from_avatar": "assets/...",
  "from_avatar_url": "",
  "from_level": 12,
  "to_uid": "uid_xyz",
  "to_name": "Ravi",
  "to_avatar": "assets/...",
  "to_avatar_url": "",
  "difficulty": "normal",
  "status": "pending",
  "created_at": 1756543200000,
  "expires_at": 1756543230000,
  "accepted_at": null
}
```

---

## 🔄 Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    ONLINE BATTLE FLOW                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  User A opens Battle Screen                              │
│       │                                                  │
│       ▼                                                  │
│  goOnline() → writes to online_users/{A}                 │
│       │                                                  │
│       ▼                                                  │
│  Sees User B online (real-time stream)                   │
│       │                                                  │
│       ▼                                                  │
│  Taps "CHALLENGE" button                                 │
│       │                                                  │
│       ▼                                                  │
│  sendChallenge() → writes to battle_challenges           │
│       │                                                  │
│       ▼                                                  │
│  ┌─── User B sees incoming challenge dialog ───┐        │
│  │   ⚔️ BATTLE CHALLENGE!                       │        │
│  │   [Avatar] Keshab Lv.12                      │        │
│  │   Difficulty: NORMAL                         │        │
│  │   ⏱ 30 seconds to respond                    │        │
│  │   [✕ DECLINE]     [⚔️ ACCEPT]                │        │
│  └──────────────────────────────────────────────┘        │
│       │                                                  │
│       ├─→ ACCEPT:                                        │
│       │    acceptChallenge() → status = 'accepted'       │
│       │    Both → create deterministic battle room       │
│       │    → Existing BattleProvider handles match       │
│       │                                                  │
│       ├─→ DECLINE:                                       │
│       │    rejectChallenge() → status = 'rejected'       │
│       │    A sees "Keshab declined your challenge"       │
│       │                                                  │
│       └─→ TIMEOUT (30s):                                 │
│            Auto-expire → status = 'expired'              │
│            A sees "Challenge expired"                    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ Play Store Safety Checklist

- [x] No background location tracking
- [x] No persistent foreground services
- [x] No phone state / contacts access
- [x] Firebase already in use — no new sensitive permissions
- [x] User data (name, avatar, level) — not PII beyond what's already in the app
- [x] Challenge system is opt-in (users choose to go to battle screen)
- [x] No real-money gambling — purely in-game coins/gems rewards
- [x] Graceful offline degradation — app works without internet
- [x] Age-appropriate content — quiz battles, no violence

---

## 🎨 UI Preview Description

### Online Battle Screen
- Dark glassmorphism background (Navy + Purple gradient)
- Green dot indicator for online users
- Each user tile shows: Avatar, Name, Level, Activity status
- Red gradient "CHALLENGE" button with neon glow
- "SENT" indicator with cyan loading spinner
- AppBar has difficulty selector (Easy/Normal/Hard)
- "Quick Match" button for existing random matchmaking
- Empty state with refresh button when no users online

### Incoming Challenge Dialog
- Centered modal with cyan glowing border
- Pulsing avatar animation
- Challenger name + level + difficulty
- 30-second countdown (turns red at 10s)
- DECLINE (red) and ACCEPT (cyan gradient) buttons

### Challenge Sent Dialog
- Orange glowing border
- Animated dots while waiting
- Elapsed time counter
- Cancel button
