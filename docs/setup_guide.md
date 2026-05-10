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

### To Prepare a Flash Drive / Device Distribution:

1. Push your code to your GitHub repo.
2. Go to the **Actions** tab on your GitHub repo website.
3. Select the latest build and scroll down to the **Artifacts** section at the bottom.

#### 💻 For macOS & Windows Desktop:
1. Download **`Mac_App_USB`** or **`Windows_App_USB`**.
2. Unzip the downloaded folder.
3. Copy the folder directly onto your client's USB flash drive.
4. On Mac, your client can drag it to applications (and run `xattr -cr` if needed to bypass Gatekeeper). On Windows, double-click `OrderFlow.exe` in the folder to open it instantly.

#### 📱 For Android Mobile Devices:
1. Download **`Android_App_USB`** from your artifacts (this is the standalone compiled `app-release.apk` installer).
2. Transfer the `.apk` file directly onto your client's device (you can copy it to their USB flash drive, or send it directly to their phone via WhatsApp, Email, or a shared Google Drive link).
3. On the client's Android device, open their built-in **Files / File Manager** app and tap the **`app-release.apk`** file.
4. If Android displays a security prompt saying "installing unknown apps from this source is blocked", tap **Settings** and toggle on **"Allow from this source"** (this is standard for offline standalone apps that are distributed directly instead of through the Google Play Store).
5. Tap **Install**, and they can launch and use `OrderFlow` completely offline!

---

## Offline Database Backup & Maintenance

* Since the database is offline, its SQLite database file resides inside your local macOS Application Support directory:
  `~/Library/Application Support/com.orderflow.offline/offline_order_manager.db`
* To safeguard your store data, simply copy this file to an external thumb-drive or cloud folder as a backup.

---

## Application Reset & Testing Stage

To facilitate rapid, secure testing of newly compiled releases starting from a clean database state:
* **Three-Stage Onboarding**: The Setup Wizard enforces a strict sequential 3-stage process:
  1. **Step 1 (Store Identity & Branding)**: Customize the merchant storefront name, tagline, and select a premium icon emblem.
  2. **Step 2 (Admin Setup)**: Register the master administrative username and security key (supporting Password or PIN modes).
  3. **Step 3 (Populate Catalog)**: Stage and save initial product inventory items into SQLite.
* **Reset Feature**: The application features a built-in **Reset Application** function.
* **Accessing the Reset Action**:
  * **Desktop viewports**: Click the red-outlined **Reset Application** button at the bottom of the left sidebar.
  * **Mobile viewports**: Click the trash-can **Reset Application** icon in the top-right corner of the mobile App Bar.
* **🔒 Security Verification**: To prevent accidental data loss or unauthorized database wipes, clicking reset displays a stateful authorization prompt. The merchant **must enter their active administrative PIN or Password** to authorize the reset.
* **Database Behavior**: On successful authorization, the application executes an atomic transaction that safely purges all orders, inventory tables, and admin credentials from SQLite.
* **Instant Redirection**: Once wiped, the application instantly redirects back to **Step 1 (Store Identity & Branding)**, allowing you to run onboarding and catalog staging test routines starting from a pristine local environment!
