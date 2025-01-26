# HarvestGuard

A Flutter application for agricultural product trading and logistics management.

## Features

- **Product Management**: List and manage agricultural products
- **Auction System**: Participate in agricultural product auctions
- **Chat System**: Real-time communication between buyers and sellers
- **Shipment Tracking**: Track product shipments and deliveries
- **Authentication**: Secure user authentication using Firebase

## Getting Started

### Prerequisites

- Flutter SDK (>=3.4.3)
- Firebase account
- Android SDK (min SDK 31)

### Installation

1. Clone the repository
2. Install dependencies:
```sh
flutter pub get
```
3. Configure Firebase:
   - Add your `google-services.json` to the Android app
   - Add your `GoogleService-Info.plist` to the iOS app

### Running the App

```sh
flutter run
```

## Technology Stack

- **Frontend**: Flutter
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
  - Realtime Database
  - Cloud Storage
- **Local Storage**: SQLite
- **Maps Integration**: Google Maps Flutter
- **State Management**: Provider

## Dependencies

- `dismissible_page`: ^1.0.2
- `dynamic_color`: ^1.7.0
- `firebase_core`: ^3.0.0
- `cloud_firestore`: ^5.0.0
- `flutter_local_notifications`: ^17.1.2
- `google_maps_flutter`: ^2.10.0
- View 

pubspec.yaml

 for complete list

## Build

```sh
flutter build apk --release  # Android
flutter build ios            # iOS
```

## Development

The app follows Material Design guidelines and supports dynamic theming.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
