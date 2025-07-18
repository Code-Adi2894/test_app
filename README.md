# Test App

A Flutter application with ObjectBox database and real-time synchronization capabilities.

## Features

- User authentication (login/register)
- Case management system
- Site management
- Task management
- Offline-first with ObjectBox local database
- Real-time synchronization
- Connectivity status monitoring

## Prerequisites

Before running this project, make sure you have the following installed:

- **Flutter SDK** (version 3.8.1 or higher)
- **Dart SDK** (included with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Android SDK** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **Git**

## Installation Steps

### 1. Clone the Repository

```bash
git clone <repository-url>
cd test_app
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Generate ObjectBox Code

This project uses ObjectBox for local database management. You need to generate the database code:

**Note:** If you encounter conflicts, you can force a clean build:

```bash
docker pub run build_runner build --delete-conflicting-outputs
```

**Important:** After running the build_runner command, the `objectbox-model.json` file will be generated. You need to copy this file to the root folder of your project before running the sync server.

### 4. Setup Sync Server (Optional)

The app includes real-time synchronization capabilities. To use sync features:

1. **Run ObjectBox Sync Server using Docker:**
   ```bash
   docker run --rm -d --name objectbox-sync --volume "${PWD}:/data" --publish 127.0.0.1:9999:9999 --publish 127.0.0.1:9980:9980 objectboxio/sync-server-trial --model /data/objectbox-model.json --unsecured-no-authentication --admin-bind 0.0.0.0:9980
   ```

   This command:
   - Runs the ObjectBox sync server in a Docker container
   - Maps the current directory to `/data` in the container
   - Exposes port 9999 for sync connections
   - Exposes port 9980 for admin interface
   - Uses the `objectbox-model.json` file from your project root (make sure it's copied there after step 3)
   - Runs without authentication for development

   **Prerequisite:** Ensure the `objectbox-model.json` file is in your project root folder (copied from step 3 above).

2. **Update the sync server IP in `lib/main.dart`:**
   - For Android emulator: `10.0.2.2` (default)
   - For physical devices: `127.0.0.1` or your server IP
   - For iOS simulator: `127.0.0.1`

**Note:** Make sure Docker is installed and running on your system before executing this command.

## Running the Application

### For Android

1. **Connect an Android device or start an emulator**

2. **Run the app:**
   ```bash
   flutter run
   ```

3. **For release build:**
   ```bash
   flutter build apk
   ```

### For iOS (macOS only)

1. **Install iOS dependencies:**
   ```bash
   cd ios
   pod install
   cd ..
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

3. **For release build:**
   ```bash
   flutter build ios
   ```

### For Web

```bash
flutter run -d chrome
```

## Running on Multiple Devices

To test the app on multiple devices simultaneously and verify synchronization:

### 1. Start the Sync Server

First, ensure the ObjectBox sync server is running:

```bash
docker run --rm -d --name objectbox-sync --volume "${PWD}:/data" --publish 127.0.0.1:9999:9999 --publish 127.0.0.1:9980:9980 objectboxio/sync-server-trial --model /data/objectbox-model.json --unsecured-no-authentication --admin-bind 0.0.0.0:9980
```

### 2. Configure Network Access

For devices to connect to the sync server, you need to:

**Option A: Use your computer's IP address**
1. Find your computer's IP address:
   - **Windows:** `ipconfig` in Command Prompt
   - **macOS/Linux:** `ifconfig` or `ip addr` in Terminal
2. Update the sync server IP in `lib/main.dart` to use your computer's IP instead of `127.0.0.1`

**Option B: Use port forwarding (for emulators)**
- Android emulators automatically forward `10.0.2.2` to your host machine
- iOS simulators can use `127.0.0.1` if running on the same machine

### 3. Run on Multiple Devices

**Android Devices:**
```bash
# List connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run on all connected devices
flutter run -d all
```

**iOS Devices:**
```bash
# Run on iOS simulator
flutter run -d ios

# Run on connected iPhone (requires Apple Developer account)
flutter run -d <device-id>
```

**Mixed Platform Testing:**
```bash
# Run on Android emulator and iOS simulator simultaneously
flutter run -d android
flutter run -d ios
```

### 4. Verify Synchronization

1. **Create data on one device** (e.g., add a new case or task)
2. **Check sync status** in the app's offline indicator
3. **Verify data appears on other devices** after sync completes
4. **Test offline functionality** by disconnecting devices from network

### 5. Sync Server Monitoring

Access the sync server admin interface at `http://localhost:9980` to:
- Monitor connected clients
- View sync statistics
- Check data synchronization status

### Troubleshooting Multi-Device Issues

**Devices can't connect to sync server:**
- Ensure all devices are on the same network
- Check firewall settings on your computer
- Verify the sync server IP is accessible from all devices
- Use `ping <your-computer-ip>` from devices to test connectivity

**Sync not working between devices:**
- Check the offline indicator in the app
- Verify sync server is running and accessible
- Restart the sync server if needed
- Check network connectivity on all devices

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── objectbox.dart           # ObjectBox database setup
├── entities.dart            # Data models
├── Screens/                 # UI screens
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── case_list_screen.dart
│   └── ...
├── services/                # Business logic
│   ├── user_service.dart
│   ├── site_service.dart
│   ├── sync_service.dart
│   └── conflict_resolution_service.dart
└── widgets/                 # Reusable UI components
    ├── offline_indicator.dart
    ├── site_filter_dropdown.dart
    └── user_info_widget.dart
```

## Key Dependencies

- **objectbox**: Local database management
- **objectbox_sync_flutter_libs**: Real-time synchronization
- **connectivity_plus**: Network connectivity monitoring
- **image_picker**: Image selection functionality
- **path_provider**: File system access

## Troubleshooting

### Common Issues

1. **ObjectBox generation fails:**
   ```bash
   flutter clean
   flutter pub get
   docker pub run build_runner build --delete-conflicting-outputs
   ```

2. **iOS build issues:**
   ```bash
   cd ios
   pod deintegrate
   pod install
   cd ..
   flutter clean
   flutter pub get
   ```

3. **Android build issues:**
   ```bash
   flutter clean
   flutter pub get
   cd android
   ./gradlew clean
   cd ..
   ```

### Sync Server Issues

- Ensure the sync server is running on the correct port (9999)
- Check firewall settings if using a remote server
- Verify network connectivity between device and server

## Development

### Code Generation

When you modify the data models in `lib/entities.dart`, regenerate the ObjectBox code:

```bash
flutter pub run build_runner build
```

### Testing

Run the test suite:

```bash
flutter test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## License

This project is licensed under the MIT License.
