# 🔐 Firebase + Google Sign-In Setup Guide

QuizBaaz-এ Google Sign-In চালু করতে Firebase দরকার। কোড (`lib/`) already ready —
নিচের ধাপগুলো একবার করে দিলেই Google Sign-In কাজ করবে।

---

## ✅ যা যা লাগবে

| জিনিস | বিবরণ |
|---|---|
| Google account | Firebase Console-এ login করার জন্য |
| Package name | `com.keshabstudios.quizbaaz` |
| `google-services.json` | Firebase থেকে download করে local-এ বসাতে হবে |

---

## 📌 Step 1 — Firebase Project তৈরি

1. খোলো: **https://console.firebase.google.com**
2. **Add project** (বা Create a project) → নাম দাও: `QuizBaaz`
3. Google Analytics (ঐচ্ছিক) — চাইলে enable করো, না করলেও চলবে
4. **Create project** → অপেক্ষা করো

## 📌 Step 2 — Android App Register করা

1. Project dashboard-এ Android icon (🤖) এ click করো — **"Add app"**
2. **Android package name**-এ দাও:
   ```
   com.keshabstudios.quizbaaz
   ```
3. (Optional) App nickname: `QuizBaaz`
4. **Register app**
5. **Download google-services.json** → ফাইলটা এই জায়গায় রাখো:
   ```
   android/app/google-services.json
   ```
   (তোমার local project folder-এ, `android/app/`-এর ভেতরে)

## 📌 Step 3 — Gradle-তে Google Services plugin যোগ

তোমার local project-এ এই ২টা file edit করো:

**`android/build.gradle.kts`** (root) — `plugins` block-এ এই line যোগ করো:
```kotlin
id("com.google.gms.google-services") version "4.4.2" apply false
```

**`android/app/build.gradle.kts`** — একদম উপরে (সবার আগে) এই line যোগ করো:
```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

> 💡 **Note:** `android/build.gradle.kts`-তে `settings.gradle.kts`-এর pluginManagement
> repositories-তে `google()` আছে কিনা দেখো। Flutter-এর নতুন template-এ থাকে; না থাকলে যোগ করো:
> ```kotlin
> repositories {
>     google()
>     mavenCentral()
> }
> ```

## 📌 Step 4 — Google Sign-In provider Enable করা

1. Firebase console → left menu → **Build → Authentication**
2. **Get started**
3. **Sign-in method** tab → **Google** → click
4. **Enable** toggle ON করো
5. Project support email select করো → **Save**

## 📌 Step 5 — SHA-1 Fingerprint যোগ করা (❗ খুব জরুরি)

SHA-1 ছাড়া Android-এ Google Sign-In **কাজ করবে না**। করতে হবে:

**5a. SHA-1 বের করো:**
```bash
cd ~/Vs\ Code\ Apps/quizbaaz-flutter/android
./gradlew signingReport
```
Output-এ `SHA1: XX:XX:...` খুঁজে বের করো (debug variant-টারটাই যথেষ্ট)।

**5b. Firebase-এ add করো:**
1. Firebase console → ⚙️ (gear icon) → **Project settings**
2. **Your apps** → তোমার Android app-টা select করো
3. **Add fingerprint** → SHA-1 paste → Save

> ⚠️ Release keystore বানালে release SHA-1-ও এখানে add করতে হবে।

## 📌 Step 6 — Run

```bash
cd ~/Vs\ Code\ Apps/quizbaaz-flutter
flutter clean
flutter pub get
flutter run
```

Profile screen বা quiz result-এ গিয়ে **Sign In** চাপলেই Google account picker আসবে। ✅

---

## 🔍 সমস্যা হলে (Troubleshooting)

| Error | কারণ | সমাধান |
|---|---|---|
| `ApiException 10` / `DEVELOPER_ERROR` | SHA-1 add হয়নি | Step 5 আবার করো |
| `operation-not-allowed` | Google provider enable হয়নি | Step 4 আবার করো |
| `google-services.json not found` | File ভুল জায়গায় | `android/app/`-এ রাখো |
| Build error (plugin) | Gradle plugin ঠিকমতো যোগ হয়নি | Step 3 check করো |
| `sign_in_failed` (generic) | Internet / emulator-এ Play Services নেই | Real device বা Play Services-সহ emulator |

---

## 📝 Code-তে কী কী হয়েছে (already done in repo)

| File | কাজ |
|---|---|
| `pubspec.yaml` | `firebase_core`, `firebase_auth`, `google_sign_in` dependency |
| `data/providers/auth_provider.dart` | 🆕 Google Sign-In / Sign-Out / error handling |
| `main.dart` | Firebase initialize (fail-safe) + AuthProvider register |
| `data/providers/user_provider.dart` | `linkGoogleAccount()` — guest → registered, bonus + data sync |
| `quiz_result_screen.dart` | Real 1-tap Google Sign-In (score save) |
| `profile_screen.dart` | Google account card + Sign In / Sign Out |

---

## 🔮 ভবিষ্যৎ (Phase 7 backend)

এখন sign-in local (SharedPreferences)। পরে backend/Firestore এলে:
- User data cloud-এ sync
- Leaderboard real-time
- Guest → account link (`linkWithCredential`) দিয়ে score merge
