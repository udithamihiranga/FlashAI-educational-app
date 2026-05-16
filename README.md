# FlashAI

An AI-powered study assistant application built with Flutter, designed to help students learn more efficiently through automated note generation, flashcard creation, and progress tracking.

## Features

- **AI-Powered Note Generation** — Upload documents or enter text manually, and FlashAI automatically generates concise, pedagogically-sound summary notes using NVIDIA AI.
- **Automatic Flashcard Creation** — Notes are automatically converted into structured flashcards optimized for spaced repetition learning.
- **Learning Progress Tracking** — Track study sessions, flashcard review performance, and visualize your learning trajectory with detailed statistics.
- **Daily Streak System** — Stay motivated with daily study streaks and achievement tracking.
- **Push Notifications** — Receive intelligent study reminders and review suggestions via Firebase Cloud Messaging.
- **Notification Center** — View and manage all notifications with unread indicators and mark-as-read functionality.
- **Dark/Light Theme** — Switch between dark and light modes with persistent theme preferences.
- **User Authentication** — Secure authentication with email signup and Google Sign-In via Firebase Auth.
- **Cross-Platform** — Available on iOS, Android, and Web from a single Flutter codebase.

## Tech Stack

- **Framework:** Flutter 3.x (Dart)
- **State Management:** Provider
- **Backend:** Firebase
  - Firestore (database)
  - Firebase Auth (authentication)
  - Cloud Functions (serverless logic)
  - Cloud Storage (file storage)
  - FCM (push notifications)
- **AI:** NVIDIA NIM API
- **Local Storage:** SQLite (sqflite)
- **Notifications:** flutter_local_notifications

## Getting Started

### Prerequisites

- Flutter SDK 3.11.4+
- Dart 3.11.4+
- Firebase project with:
  - Authentication (Email + Google Sign-In)
  - Firestore Database
  - Cloud Functions
  - Cloud Storage
  - Firebase Cloud Messaging
- An NVIDIA API key from [build.nvidia.com](https://build.nvidia.com)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/flashai.git
   cd flashai
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables:**
   - Copy `.env.example` to `.env` and fill in your API keys:
     ```
     NVIDIA_API_KEY=your_nvidia_api_key
     NVIDIA_BUILD_API_KEY=your_nvidia_api_key
     ```

4. **Set up Firebase:**
   - Follow the [Firebase Flutter setup guide](https://firebase.google.com/docs/flutter/setup) to add your Firebase configuration files:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`

5. **Run the app:**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── features/
│   ├── auth/                 # Authentication screens & providers
│   │   ├── presentation/
│   │   │   ├── screens/      # Login, Signup screens
│   │   │   └── widgets/      # Auth UI components
│   │   └── data/             # Auth service & repository
│   ├── dashboard/            # Dashboard with learning stats
│   │   └── presentation/
│   │       ├── screens/
│   │       └── widgets/
│   ├── notes/                # Notes creation, viewing & management
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── services/
│   ├── study/                # Study sessions & flashcard review
│   │   └── presentation/
│   ├── notifications/        # Notification center
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── data/
│   ├── flashcards/           # Flashcard models & progress tracking
│   ├── mastery/              # Mastery log & analytics
│   └── settings/             # App settings & profile
├── core/
│   ├── navigation/           # Route management
│   ├── theme/                # App theming
│   └── presentation/         # Shared screens & widgets
├── features/
│   └── shared/
│       └── widgets/          # Reusable UI components
├── services/
│   ├── api/                  # API services (NVIDIA)
│   ├── firebase/             # Firebase initialization
│   ├── notification/         # Notification state management
│   └── push/                 # Push notification handling
└── main.dart                 # App entry point
```

## Building for Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ipa --release
```

### Web
```bash
flutter build web --release
```

## License

This project is submitted as part of a Bachelor of Science in ICT at the General Sir John Kotelawala Defence University. See the [LICENSE](LICENSE) file for details.