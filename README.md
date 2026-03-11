# Cublink – Smart Student Safety Ecosystem

Cublink is a full-stack IoT safety ecosystem designed to monitor and protect students through real-time location tracking and automated boundary monitoring.

The system integrates custom hardware (ESP32 with GPS telemetry) with a responsive cross-platform Flutter application using Firebase as the cloud synchronization layer.

Developed as a final-year Computer Science project, Cublink demonstrates how embedded hardware, cloud infrastructure, and mobile applications can work together to create a scalable safety monitoring system.

---

# Key Features

### Real-Time Location Tracking
Live GPS telemetry is streamed from the ESP32 hardware module and visualized on an interactive map using OpenStreetMap and CartoDB tiles.

### Dynamic Geofencing
Parents can define circular safe zones such as home or school. The system calculates the distance between the student and the geofence center using the **Haversine Formula**, triggering alerts when boundaries are crossed.

### Hardware Heartbeat Monitoring
The application monitors the ESP32's last communication timestamp. If the device stops transmitting data due to power loss or network issues, an alert is immediately generated.

### Custom Theme Engine
A fully custom light/dark theme engine adapts to system brightness and saves user preferences locally.

### Secure Session Management
Custom session validation prevents simultaneous logins from multiple devices.

### Background Monitoring
Geofence monitoring continues running using background services even when the application is closed.

---

# Hardware Prototype

The hardware prototype consists of an **ESP32 microcontroller** connected to a **NEO-6M GPS module**.  
The ESP32 reads GPS telemetry via UART communication and sends location updates to Firebase over Wi-Fi.

![Hardware Prototype](assets/hardware_prototype.png)

### Components

**ESP32 DevKit V1**
- Main microcontroller
- Handles Wi-Fi communication
- Processes GPS telemetry

**NEO-6M GPS Module**
- Provides real-time latitude and longitude
- Communicates with ESP32 using UART

**External GPS Antenna**
- Improves satellite signal reception
- Enables accurate outdoor positioning

---

# Hardware Communication

| GPS Module | ESP32 |
|-------------|------|
| VCC | 3.3V |
| GND | GND |
| TX | RX |
| RX | TX |

The ESP32 parses NMEA GPS sentences and sends structured JSON location data to Firebase.

---

# Tech Stack

## Mobile Application
- Flutter (Dart)
- Provider state management
- flutter_map
- latlong2
- geocoding
- shared_preferences

## Cloud Infrastructure
- Firebase Realtime Database
- Firebase Authentication
- Firebase Cloud Storage
- flutter_local_notifications

## Hardware
- ESP32 DevKit V1
- NEO-6M GPS Module
- Wi-Fi communication

---

# System Architecture

```
GPS Module
     ↓
ESP32 Microcontroller
     ↓
Wi-Fi Transmission
     ↓
Firebase Realtime Database
     ↓
Flutter Mobile Application
```

---

# Running the Project

To run the project locally, you must connect your own Firebase project.

## Prerequisites

- Flutter SDK (3.0+)
- Firebase account

---

## Installation

Clone the repository

```bash
git clone https://github.com/afsal63s/cublink.git
cd cublink
```

Install dependencies

```bash
flutter pub get
```

Configure Firebase

1. Create a Firebase project
2. Enable Realtime Database, Authentication, and Storage
3. Run

```bash
flutterfire configure
```

Run the application

```bash
flutter run
```

---

# Download

Download the Android APK from the releases page:

https://github.com/afsal63s/cublink/releases

---

# Author

Afsal Salim  

