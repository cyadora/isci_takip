# İşçi Takip

A Flutter project for worker tracking and management with Firebase integration.

## Project Structure

This project follows the MVVM (Model-View-ViewModel) architecture:

- **models/**: Data models
- **views/**: UI components
- **view_models/**: Business logic and state management
- **services/**: API and Firebase services

## Firebase Setup

Before running the application, you need to set up Firebase:

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and/or iOS apps to your Firebase project
3. Download the configuration files:
   - For Android: `google-services.json` (place in `android/app/`)
   - For iOS: `GoogleService-Info.plist` (place in `ios/Runner/`)
4. Update the `firebase_options.dart` file with your Firebase configuration

## Dependencies

- **firebase_core**: Firebase initialization
- **firebase_auth**: Authentication services
- **cloud_firestore**: Database services
- **firebase_storage**: File storage services
- **provider**: State management
