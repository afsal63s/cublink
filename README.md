# 🐻 Cublink - Smart Student Safety Ecosystem

Cublink is a comprehensive, full-stack IoT safety ecosystem designed to monitor and protect students in real-time. Developed as an academic project, it bridges custom hardware (ESP32 & GPS) with a highly responsive, cross-platform Flutter application via the Firebase Realtime Database.

---

## ✨ Key Features

* **📍 Live Telemetry Tracking:** Real-time GPS plotting using custom CartoDB map tiles and OpenStreetMap data.
* **🛡️ Dynamic Geofencing:** Draw custom safe zones (e.g., School, Home). The app calculates live distances and triggers instant push notifications if a boundary is breached.
* **🩺 Hardware Heartbeat Monitor:** Built-in "Doctor" logic checks the ESP32 connection every few seconds. If the ID card loses power or signal, the parent is immediately alerted.
* **🌙 Premium Theme Engine:** Fully custom Light/Dark mode built from scratch, persistently saved to local device memory.
* **🔒 The "Bouncer" Security:** Custom session management ensuring single-device login integrity.
* **🏃 Background Services:** Continuous offline tracking and geofence monitoring even when the app is completely closed.

---

## 🛠️ Tech Stack

### Frontend (Mobile App)
* **Framework:** Flutter (Dart)
* **Architecture:** Provider (MVVM-inspired)
* **Maps & Navigation:** `flutter_map`, `latlong2`, `geocoding`
* **Local Storage:** `shared_preferences`

### Backend (Cloud Services)
* **Database:** Firebase Realtime Database (NoSQL)
* **Authentication:** Firebase Auth (Email/Password)
* **Storage:** Firebase Cloud Storage (Profile Images)
* **Push Notifications:** `flutter_local_notifications`, `flutter_background_service`

### Hardware (Smart ID Card)
* **Microcontroller:** ESP32 MCU
* **GPS Module:** NEO-8M GPS with UART interface

---

## 🏗️ System Architecture

The architecture follows a classic IoT triad, cleanly separating hardware payloads, cloud synchronization, and mobile UI rendering:

### 1. Hardware Layer
The ESP32 extracts raw NMEA data from the NEO-8M module, parses the latitude/longitude, and securely pushes the payload to Firebase over Wi-Fi.

### 2. Cloud Layer
A Firebase Realtime Database acts as the central synchronization hub, storing user-centric JSON nodes for locations, geofences, and alerts.

### 3. 🧠 State Management (Provider)
To ensure high performance and clean code, the app strictly separates business logic from the UI using the **Provider** package:
* **`GeofenceProvider`:** Handles complex distance math, syncs active zones with the database, and prevents memory leaks by managing active stream subscriptions.
* **`StudentProvider`:** Manages user profiles, image uploads to Firebase Storage, and secure data caching.
* **`ThemeProvider`:** Intelligently checks the host device's native brightness settings and saves user-overrides to the phone's local storage.

---

## 🚀 Getting Started (For Developers)

To run this project locally, you will need to connect your own Firebase instance, as API keys are secured and hidden from this repository.

### Prerequisites
* Flutter SDK (v3.0.0+)
* A Firebase Account

### Installation
1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/yourusername/cublink.git](https://github.com/yourusername/cublink.git)
    cd cublink
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Setup Firebase:**
    * Create a new project in the Firebase Console.
    * Enable Realtime Database, Authentication, and Storage.
    * Run `flutterfire configure` to generate your `firebase_options.dart` file.
4.  **Run the app:**
    ```bash
    flutter run
    ```

---

## 📱 Download the App

Want to test the UI and features? Download the compiled Android APK from the [Releases Page](link_to_your_releases_page_here).

---

## 👨‍💻 Author

**Afsal** *Final-Year B.Sc. Computer Science Project*