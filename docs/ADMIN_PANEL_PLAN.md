# 🛡️ Admin Panel - Complete Plan

## Overview
Admin panel যেখানে admin shop manage করতে পারবে, users দেখতে পারবে, এবং content add করতে পারবে।

---

## 📋 Admin Panel Features

### 1️⃣ **Dashboard (Home)**
- Total Users count
- Total Guests count
- Total Quizzes played today
- Total Revenue (Coins/Gems spent)
- Quick stats cards

### 2️⃣ **User Management**
- **All Users List**
  - User ID
  - Username
  - Full Name
  - Email
  - Join Date
  - Total Quizzes
  - Best Score
  - Daily Streak
  - Status (Active/Inactive)
  
- **Guest Users List**
  - Guest ID
  - Device Info
  - First Seen
  - Last Active
  - Quizzes Played
  - Option to convert to full user

- **User Details View**
  - Profile info
  - Quiz history
  - Purchase history
  - Inventory items
  - Ban/Unban option

### 3️⃣ **Shop Management**
- **View All Items**
  - List all shop items
  - Category filter
  - Search items

- **Add New Item**
  - Item Name
  - Description
  - Category (dropdown)
  - Price (Coins/Gems)
  - Quantity
  - Is Cosmetic (toggle)
  - Upload Icon (ImageBB)
  - Preview before save

- **Edit Item**
  - Update any field
  - Enable/Disable item
  - Change price

- **Delete Item**
  - Confirm dialog
  - Soft delete (hide) or Hard delete

### 4️⃣ **Avatar Management**
- **View All Avatars**
  - Default avatars
  - Premium avatars
  - Preview images

- **Add New Avatar**
  - Avatar Name
  - Category (Male/Female/Premium)
  - Upload Image (ImageBB)
  - Set as Premium (toggle)
  - Set Price (if premium)
  - Preview before save

- **Edit Avatar**
  - Change name
  - Change category
  - Change image
  - Change price

- **Delete Avatar**
  - Confirm dialog

### 5️⃣ **Content Management**
- **Question Banks**
  - View all chapters
  - Add new chapter
  - Add questions to chapter
  - Edit/Delete questions

- **Daily Quiz**
  - Set daily questions
  - Schedule quiz
  - View daily results

### 6️⃣ **Rewards & Gifts**
- **Champion Management**
  - View yesterday's champion
  - Set rewards/gifts
  - Publish champions

- **Gift Items**
  - Add gift items
  - Set gift conditions
  - Track gift claims

### 7️⃣ **Settings**
- **App Config**
  - Coins per correct answer
  - Gems per perfect score
  - Timer settings
  - Streak settings

- **Admin Settings**
  - Add admin users
  - Remove admin access
  - Admin activity log

---

## 🎨 UI Design

### Color Scheme
- Background: Dark Navy (#070A18)
- Cards: Glassmorphism
- Accent: Neon Cyan, Gold, Purple
- Same as app theme

### Layout
```
┌─────────────────────────────────────┐
│  🛡️ Admin Panel          [Logout]  │
├─────────────────────────────────────┤
│  [Dashboard] [Users] [Shop] [Content]│
├─────────────────────────────────────┤
│                                     │
│         Main Content Area           │
│                                     │
└─────────────────────────────────────┘
```

---

## 🔧 Technical Implementation

### Image Upload Flow (ImageBB)
```
1. Admin selects image
2. Upload to ImageBB API
3. Get public URL
4. Save URL to Firestore
5. App loads from URL
```

### ImageBB API
```dart
// Upload to ImageBB
POST https://api.imgbb.com/1/upload
  ?key=YOUR_API_KEY
  &image=BASE64_IMAGE
  
Response:
{
  "data": {
    "url": "https://i.ibb.co/xxx/image.png",
    "display_url": "https://i.ibb.co/xxx/image.png"
  }
}
```

### Firestore Structure
```
admin/
├── config/
│   └── app_settings
├── activity_log/
│   └── {log_id}
└── ...

users/{userId}
  - profile
  - stats
  - quiz_history
  - purchase_history
  - inventory

shop_items/
├── {item_id}
│   - name
│   - description
│   - category
│   - price
│   - currency
│   - quantity
│   - is_cosmetic
│   - icon_url
│   - is_active
│   - created_at

avatars/
├── {avatar_id}
│   - name
│   - category (male/female/premium)
│   - image_url
│   - is_premium
│   - price
│   - is_active
│   - created_at
```

---

## 📱 Screens to Build

| # | Screen | Priority |
|---|--------|----------|
| 1 | Admin Dashboard | High |
| 2 | User List | High |
| 3 | Guest List | Medium |
| 4 | Shop Item Manager | High |
| 5 | Add/Edit Shop Item | High |
| 6 | Avatar Manager | High |
| 7 | Add/Edit Avatar | High |
| 8 | Question Manager | Medium |
| 9 | Settings | Medium |

---

## 🚀 Implementation Order

### Phase 1 (Core)
1. ✅ Clean admin dashboard
2. ✅ User list from Firestore
3. ✅ Guest list
4. ✅ Shop item list
5. ✅ Add shop item with ImageBB

### Phase 2 (Enhancement)
6. Avatar management
7. Edit/Delete items
8. Question management
9. Settings

---

## 📝 Notes
- Use ImageBB for all image uploads
- Images stored as URLs in Firestore
- App loads images from URLs (not local assets)
- Admin actions logged in Firestore
- Real-time updates using Firestore streams
