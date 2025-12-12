# How to Run Flutter Project in Android Studio on Emulator

## Prerequisites
1. **Android Studio** installed (download from https://developer.android.com/studio)
2. **Flutter SDK** installed (download from https://flutter.dev/docs/get-started/install)
3. **Android SDK** installed (comes with Android Studio)

## Step 1: Open Project in Android Studio

1. Open **Android Studio**
2. Click **File** → **Open**
3. Navigate to your project folder: `cinemaApp-main`
4. Select the folder and click **OK**
5. Wait for Android Studio to index the project (this may take a few minutes)

## Step 2: Set Up Android Emulator

### Option A: Create a New Emulator (Recommended)

1. In Android Studio, click **Tools** → **Device Manager** (or click the device icon in the toolbar)
2. Click **Create Device** button
3. Select a device (e.g., **Pixel 5** or **Pixel 6**)
4. Click **Next**
5. Select a system image (e.g., **API 33** or **API 34** - latest stable version)
   - If you see "Download" next to it, click it to download first
6. Click **Next**
7. Review the configuration and click **Finish**
8. The emulator will appear in the Device Manager

### Option B: Use Existing Emulator

1. In Android Studio, click **Tools** → **Device Manager**
2. If you see an emulator listed, click the **Play** button (▶) next to it to start it

## Step 3: Verify Flutter Setup

1. In Android Studio, open **Terminal** (bottom panel)
2. Run this command to check Flutter:
   ```bash
   flutter doctor
   ```
3. Make sure all checks pass (especially Android toolchain)

## Step 4: Get Dependencies

1. In Android Studio terminal, run:
   ```bash
   flutter pub get
   ```
   This will download all required packages.

## Step 5: Run the Project

### For Customer App:

1. At the top of Android Studio, you'll see a device selector dropdown
2. Select your emulator from the dropdown (e.g., "Pixel 5 API 33")
3. Make sure the main file is set to: `lib/customer/main_customer.dart`
   - If not, right-click on `lib/customer/main_customer.dart` → **Run 'main_customer.dart'**
4. Click the **Run** button (green play icon ▶) or press **Shift + F10**
5. Wait for the app to build and launch on the emulator

### For Vendor App:

1. Select your emulator from the device dropdown
2. Right-click on `lib/vendor/main_vendor.dart`
3. Click **Run 'main_vendor.dart'**
4. Or click **Run** → **Run 'main_vendor.dart'**

## Alternative: Using Command Line

You can also run from the terminal:

### Customer App:
```bash
flutter run -d <emulator_id> -t lib/customer/main_customer.dart
```

### Vendor App:
```bash
flutter run -d <emulator_id> -t lib/vendor/main_vendor.dart
```

To see available devices:
```bash
flutter devices
```

## Troubleshooting

### Issue: "No devices found"
- **Solution**: Start the emulator first from Device Manager

### Issue: "Gradle build failed"
- **Solution**: 
  1. Click **File** → **Invalidate Caches** → **Invalidate and Restart**
  2. Wait for Android Studio to restart and re-index

### Issue: "SDK not found"
- **Solution**: 
  1. Click **File** → **Project Structure** → **SDK Location**
  2. Set Android SDK location (usually `C:\Users\YourName\AppData\Local\Android\Sdk`)

### Issue: "Flutter not found"
- **Solution**: 
  1. Click **File** → **Settings** (or **Preferences** on Mac)
  2. Go to **Languages & Frameworks** → **Flutter**
  3. Set Flutter SDK path (e.g., `C:\src\flutter`)

### Issue: "Build failed - dependencies"
- **Solution**: 
  1. Run `flutter clean` in terminal
  2. Run `flutter pub get`
  3. Try running again

## Quick Start Checklist

- [ ] Android Studio installed
- [ ] Flutter SDK installed
- [ ] Project opened in Android Studio
- [ ] Android emulator created and started
- [ ] `flutter pub get` executed successfully
- [ ] Emulator selected in device dropdown
- [ ] App running on emulator

## Tips

1. **First build takes longer** - Be patient, it may take 5-10 minutes
2. **Hot Reload** - After the app is running, you can press `r` in the terminal to hot reload changes
3. **Hot Restart** - Press `R` (capital R) to hot restart
4. **Stop App** - Press `q` in the terminal or click the stop button in Android Studio

## Running Both Apps

Since you have two apps (customer and vendor), you can:
1. Run one app, then stop it
2. Run the other app
3. Or use two different emulators/devices simultaneously

Good luck! 🚀

