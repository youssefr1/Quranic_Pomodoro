# Quranic Pomodoro

A premium Flutter-based productivity application designed to help users balance their work or study with Quranic reading and meditation. It blends the scientifically proven **Pomodoro Technique** with a spiritual routine.

## 🌟 Core Concept
The app guides you through 25-minute focus sessions (standard Pomodoro duration). During these sessions, or in the breaks between them, it encourages the reading of the Quran by presenting specific, digestible portions known as **Quarters (Rub' el Hizb)**.

---

## 🚀 Key Features

*   **Integrated Pomodoro Timer:**
    *   Features customizable focus and break sessions.
    *   Uses a "Premium Completion Dialog" with celebratory Islamic aesthetics when you finish a session.
*   **Intelligent Quran Integration:**
    *   **Quarter Service:** Automatically selects a random "Quarter" (1 out of 240 in the Quran) to read or reflect upon.
    *   **Auto-Refresh:** The suggested quarter refreshes every 25 minutes, synchronized with your focus cycles.
*   **Floating Overlay Bubble:**
    *   A persistent, system-level timer bubble that stays on top of other apps. This allows you to track your remaining focus time even while reading the Quran within the app or using other tools.
*   **Offline First:**
    *   Contains the entire Quranic text locally (`quran_offline.json`), ensuring fast access and privacy without needing an internet connection.
*   **Premium Visual Experience:**
    *   A high-end "Islamic-Modern" design language using deep greens (`#1B5E20`) and accent gold (`#D4AF37`).
    *   Built with a focus on typography (Cairo and Amiri fonts) and fluid animations.
*   **Background Resilience:**
    *   Uses advanced background services and notifications to ensure your timer never dies, even if you switch away from the app.

---

## 🛠️ Technical Stack
*   **Framework:** Flutter (Android & iOS).
*   **State Management:** Provider.
*   **Responsiveness:** `flutter_screenutil` (ensuring the UI looks perfect on every screen size).
*   **System Integration:** `flutter_overlay_window` for the floating timer and `flutter_background_service` for reliable timing.
*   **Local Storage:** `shared_preferences` for saving your settings and progress.
