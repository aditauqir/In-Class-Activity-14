# CSC 4360 - In-Class Activity 14: Firebase Cloud Messaging

**Name:** Adi Tauqir (Undergraduate)  
**Course:** CSC 4360 - Mobile Application Development  
**Repository:** https://github.com/aditauqir/In-Class-Activity-14.git  

---

## Overview & Setup

How to get started:

1. **Clone the repo and get packages:**
   ```bash
   git clone https://github.com/aditauqir/In-Class-Activity-14.git
   cd In-Class-Activity-14
   flutter pub get
   ```

2. **Required Firebase Configuration:**
   - The app connects to Firebase project **mad-inclass11** (Project ID: `mad-inclass11`, Number: `705627349691`) for Cloud Messaging, Cloud Firestore (`products` collection), and Firebase Storage (`banners/` and product images).
   - Pinned dependencies in `pubspec.yaml`:
     - `firebase_core: ^4.0.0`
     - `firebase_messaging: ^16.0.0`
     - `firebase_storage: ^13.6.1`
     - `cloud_firestore: ^6.0.0`
     - `firebase_auth: ^6.0.0`
   - Android configuration is located in `android/app/google-services.json` and `lib/firebase_options.dart`.

3. **Run the App:**
   Launch an Android emulator (API 33+ for runtime notification permissions) or connect a physical device:
   ```bash
   flutter run
   ```

4. **Run Tests & Static Analysis:**
   ```bash
   flutter analyze
   flutter test
   ```

---

## Implemented Features

**FCM Centralized Service (`lib/fcm_service.dart`)**: A dedicated service handling foreground message receipt (`FirebaseMessaging.onMessage`), background notification taps (`FirebaseMessaging.onMessageOpenedApp`), cold-start launches (`messaging.getInitialMessage()`), permission requests, and token stream listeners. Cleans up all stream subscriptions on `dispose()`.

**Full-Width Fall Banner & Courier UI (`lib/widgets/fcm_banner.dart`)**: A payload-reactive courier banner with centered headline, full phone-width Fall Colors banner image, and real-time handler diagnostics (last handler, message count, message ID, payload validation status). Supports both local asset fallbacks and remote Firebase Storage download URLs.

**Payload Shield & Rejection Guard**: Validates incoming cloud data against the contract `action: update_ui` and registered asset/storage keys. Safely catches invalid or malformed payloads (such as `asset: unknown`), displaying an inline diagnostic rejection message without crashing or corrupting previous UI state.

**Autumn Product Manager (`lib/screens/products_screen.dart`)**: The real-time Firestore product catalog from In-Class 11, updated with In-Class 13's clean monochrome design language. Features real-time `products` streaming, client-side search by name, min/max price range filtering, reset filters, and complete CRUD with modal bottom sheet editor and deletion dialogs.

**Phosphor Icons Design System (`lib/widgets/phosphor_icons.dart`)**: Lightweight vector icon system implementing official SVG paths from Phosphor Icons (`arrowLeft`, `identificationBadge`, `pencilSimple`, `trash`, `plus`, `magnifyingGlass`, `lock`, `eye`, `eyeSlash`, `signOut`, `shieldCheck`).

---

## Four-Test Reliability Results (T1–T4)

| Test | Lifecycle State | Action & Expected Path | Observed Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **T1** | **Foreground** | App visible; payload sent; expect `FirebaseMessaging.onMessage` | Handler displayed `onMessage`, banner updated, count incremented | **Pass** |
| **T2** | **Background** | App minimized; notification tapped; expect `onMessageOpenedApp` | Resumed into foreground, handler showed `onMessageOpenedApp`, count updated | **Pass** |
| **T3** | **Terminated** | App killed; launched via notification tap; expect `getInitialMessage()` | Cold-start retrieval succeeded on first frame, count reset to 1 | **Pass** |
| **T4** | **Payload Shield** | Sent invalid payload `asset: unknown`; expect rejection guard | Rejection diagnostic displayed, previous UI preserved, zero crash | **Pass** |
