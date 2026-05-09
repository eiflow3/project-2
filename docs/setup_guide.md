# Setup and Installation Guide

This document provides complete instructions to configure, run, and build the **Offline Flutter Order Management Desktop Application** on macOS systems.

---

## Prerequisites

Before starting up the application, verify that the following dependencies are installed:

1. **Flutter SDK**: Required to compile and run the application.
2. **Xcode**: (macOS Desktop compilation requires Xcode CLI Tools).
   * Install Xcode from the Mac App Store or via command line:
     ```bash
     xcode-select --install
     ```
3. **Cocoapods**: Required for compiling native plugin linkages (such as `path_provider_macos` or `sqflite` macOS plugins).
   * Install via Homebrew:
     ```bash
     brew install cocoapods
     ```

---

## Step-by-Step Environment Setup

### 1. Flutter SDK Installation
If not already installed, Flutter can be installed easily using Homebrew:
```bash
brew install --cask flutter
```
Alternatively, configure the system path to point to your manually extracted Flutter binary:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```

Verify your installation by running:
```bash
flutter doctor
```
Ensure that the "macOS toolchain" section shows a green checkmark or is active.

### 2. Enabling macOS Desktop Support
If macOS desktop is not enabled, enable it in Flutter's global config:
```bash
flutter config --enable-macos-desktop
```

---

## Project Initialization & Launching

### 1. Fetching Package Dependencies
Navigate to the project root directory and download all required packages:
```bash
flutter pub get
```

### 2. Running the App in Development Mode
Launch the application directly targeting your native macOS desktop environment:
```bash
flutter run -d macos
```

### 3. Compiling the Production Release Build
To bundle the application into a standalone native macOS executable (`.app` package):
```bash
flutter build macos --release
```
The compiled artifact will be generated under:
`build/macos/Build/Products/Release/order_management_system.app`

---

## Running the Test Suite

Our codebase includes a comprehensive suite of widget and logic tests (such as checking first-time onboarding rendering and asynchronous provider resolutions).

To execute the test suite, run:
```bash
flutter test
```

## Desktop FFI Database Layer

Since desktop platforms (macOS, Windows, and Linux) run in a standalone host process, the application employs `sqflite_common_ffi` to link Dart directly with the host's native SQLite engine via FFI (Foreign Function Interface) bindings. This matches professional standards and avoids requiring any running servers, keeping the app 100% serverless and offline.

---

## Cloud Builds & Flash Drive Distribution

If you do not have a full local development setup (such as Xcode for macOS or MSVC for Windows) on your laptop, the repository is preconfigured with a **GitHub Actions cloud build system** located at `.github/workflows/build_apps.yml`.

Whenever you commit and push your code to the `main` branch of your repository on GitHub, GitHub's free servers will automatically compile the release binaries:
1. **Mac Application**: Packaged as `OrderFlow_Mac.zip`.
2. **Windows Application**: Packaged as `OrderFlow_Windows.zip`.
3. **Android Application**: Packaged as standard `.apk` mobile installer.

### To Prepare a Flash Drive:
1. Push your code to your GitHub repo.
2. Go to the **Actions** tab on your GitHub repo website.
3. Select the latest build and scroll down to **Artifacts** to download the Mac, Windows, and Android ZIP files.
4. Unzip them and transfer them straight to your client's USB drive!

---

## Offline Database Backup & Maintenance

* Since the database is offline, its SQLite database file resides inside your local macOS Application Support directory:
  `~/Library/Application Support/com.example.offline_orders/offline_orders.db`
* To safeguard your store data, simply copy this file to an external thumb-drive or cloud folder as a backup.

---

## Application Reset & Testing Stage

To facilitate rapid testing of newly compiled releases starting from the first-time Setup Wizard:
* **Reset Feature**: The application features a built-in **Reset Application** function.
* **Accessing the Reset Action**:
  * **Desktop viewports**: Click the **Reset Application** red-outlined button in the bottom section of the left sidebar menu.
  * **Mobile viewports**: Click the trash/delete **Reset Application** icon button in the top-right corner of the mobile App Bar.
* **Database Behavior**: This triggers an atomic SQLite transaction that deletes all registered transaction orders, empties the product inventory database, clears the registered master account credentials, and injects the default temporary administrative key (PIN: `1234`).
* **Instant Redirection**: On success, the UI instantly redirects back to **Step 1 (Administrative Master Registration Setup)**, allowing you to run testing routines from a pristine database environment.
