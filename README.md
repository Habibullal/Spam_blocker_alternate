
📵 Spam Blocker
===============

A cross-platform mobile application built using **Flutter**, with native **Kotlin** integration, designed to block spam calls using a real-time synced and locally cached list of blocked numbers. The app also allows users to report suspicious numbers, which can be reviewed by an admin. Admins can manage authorized devices and update the spam list via Firebase.

🚀 Features
-----------
- 📱 Built with Flutter for cross-platform support (Android).
- 📞 Native Android call-blocking using Kotlin.
- 🔐 Device-level authentication using unique device ID.
- ☁️ Firebase integration for real-time database, authentication, and storage.
- 🚨 User reporting of suspicious numbers.
- 🛠️ Admin panel to authorize devices and manage blocked numbers.

🛠️ Installation & Setup
------------------------

✅ Prerequisites
- Flutter SDK
- Android Studio (for Android emulators and native Kotlin integration)
- Firebase project setup (with Firestore & Firebase Authentication)
- Git

🔧 Flutter Installation

> Follow the instructions below based on your operating system.

Windows:
1. Download Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Extract the zip and add the `flutter/bin` folder to your `PATH`.
3. Run: `flutter doctor`
4. Install required dependencies and Android Studio when prompted.

Linux / macOS:
```bash
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"
flutter doctor
```

📂 Clone the Repository
-----------------------
```bash
git clone https://github.com/<your-username>/spam-blocker.git
cd spam-blocker
```

📦 Install Flutter Dependencies
-------------------------------
```bash
flutter pub get
```

🔌 Set Up Firebase
------------------
1. Go to Firebase Console: https://console.firebase.google.com
2. Create a new project and add an Android app.
3. Download `google-services.json` and place it in `android/app/`.
4. Enable:
   - Firebase Authentication
   - Cloud Firestore
5. Update `android/build.gradle` and `android/app/build.gradle`.
6. Add internet permissions in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_PHONE_STATE"/>
<uses-permission android:name="android.permission.READ_CALL_LOG"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>
```

▶️ Run the App
--------------
```bash
flutter run
```

📁 Project Structure (Simplified)
---------------------------------
```
lib/
├── main.dart
├── screens/
│   ├── home_screen.dart
│   ├── report_screen.dart
├── services/
│   ├── firebase_service.dart
│   ├── call_blocking_service.dart
android/
├── app/
│   ├── src/
│       ├── main/
│           ├── kotlin/
│               ├── com.example.spamblocker.MainActivity.kt
```

🔐 Authentication
-----------------
- Auth is handled using the device’s **unique ID**.
- Only authorized devices (approved by admin) can access core features.

⚙️ Call Blocking (Kotlin)
-------------------------
The app uses Kotlin to intercept and block calls from numbers present in the local cache of blocked numbers (synced with Firebase).

> ⚠️ Requires runtime permissions and may not work on all Android versions due to system restrictions.

🧑‍💻 Contributing
-----------------
1. Fork the repository.
2. Create your feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -am 'Add new feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request.

🧪 Testing
----------
Use `flutter test` for unit testing. Manual testing is required for call blocking behavior on physical devices.

📄 License
---------
This project is licensed under the MIT License. See the LICENSE file for details.

📬 Contact
----------
Feel free to raise an issue or reach out via email if you have any questions or feedback.

🙌 Acknowledgements
-------------------
- Flutter Team
- Firebase by Google
- Stack Overflow and GitHub community
