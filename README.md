# FlutterSocial

![Flutter](https://img.shields.io/badge/flutter-3.13.0-blue)
![Firebase](https://img.shields.io/badge/Firebase-Active-orange)



FlutterSocial is a simple template of social networking app using **Flutter** and **Firebase**.  
It includes registration, onboarding, profile management, posts, threads, chats, and real-time messaging.  

---

## 1. Setting up the project

Clone the repository and install dependencies:

```bash
git clone https://github.com/yourusername/socially.git
cd socially
flutter pub get
```

## 2. Firebase Configuration

1. Create a new Firebase project.
2. Enable the following services:
   - **Authentication** (Email/Password+Google)
   - **Cloud Firestore**
   - **Cloud Storage**


Then add your Firebase configuration to your Flutter project:

```bash
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Store your Firebase config file here:

```bash
/lib/firebase_options.dart
```

Example of .env file (if using environment variables):

```bash
API_KEY=your_firebase_api_key
AUTH_DOMAIN=your_project_id.firebaseapp.com
PROJECT_ID=your_project_id
STORAGE_BUCKET=your_project_id.appspot.com
MESSAGING_SENDER_ID=your_sender_id
APP_ID=your_app_id

```

## 3. Packages list

**Client:**
- flutter
- firebase_core
- firebase_auth
- cloud_firestore
- firebase_storage
- provider / riverpod
- intl
- http

---

This template was developed using with assistance from the Nozomio NIA + LLM
