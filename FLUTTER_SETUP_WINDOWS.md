# Flutter Setup Guide for Windows

## Quick Fix: Install Flutter and Add to PATH

### Step 1: Download Flutter SDK

1. Go to https://docs.flutter.dev/get-started/install/windows
2. Download the Flutter SDK (ZIP file)
3. Extract the ZIP file to a location like:
   - `C:\src\flutter` (recommended)
   - Or `C:\Users\YourName\flutter`

**Important:** Do NOT install Flutter in a path with spaces or special characters.

### Step 2: Add Flutter to PATH

#### Option A: Using System Environment Variables (Recommended)

1. Press `Windows + R` to open Run dialog
2. Type `sysdm.cpl` and press Enter
3. Click the **Advanced** tab
4. Click **Environment Variables**
5. Under **User variables** (or **System variables**), find **Path** and click **Edit**
6. Click **New** and add the path to Flutter's `bin` folder:
   - Example: `C:\src\flutter\bin`
7. Click **OK** on all dialogs
8. **Close and reopen** your terminal/PowerShell/Command Prompt

#### Option B: Using PowerShell (Temporary - Current Session Only)

Run this command in PowerShell (replaces `C:\src\flutter` with your actual Flutter path):

```powershell
$env:Path += ";C:\src\flutter\bin"
```

### Step 3: Verify Installation

1. Open a **new** PowerShell or Command Prompt window
2. Run:
   ```bash
   flutter doctor
   ```
3. This will check your Flutter installation and show what else you need

### Step 4: Install Required Dependencies

Based on `flutter doctor` output, you may need:

1. **Android Studio** (for Android development)
   - Download: https://developer.android.com/studio
   - Install Android SDK and Android SDK Platform-Tools

2. **Chrome** (for web development - you're trying to run on Chrome)
   - Download: https://www.google.com/chrome/
   - Flutter uses Chrome for web development

3. **Git** (usually already installed)
   - Download: https://git-scm.com/download/win

### Step 5: Accept Android Licenses (if using Android)

```bash
flutter doctor --android-licenses
```

Press `y` to accept all licenses.

### Step 6: Run Your App

Once Flutter is installed and in PATH:

```bash
# For vendor app on Chrome
flutter run -d chrome -t lib/vendor/main_vendor.dart

# For customer app on Chrome
flutter run -d chrome -t lib/customer/main_customer.dart
```

## Alternative: Use Android Studio

If you have Android Studio installed:

1. Open Android Studio
2. Open this project folder
3. Android Studio will detect it's a Flutter project
4. Configure Flutter SDK path in: **File → Settings → Languages & Frameworks → Flutter**
5. Use the Run button in Android Studio

## Quick Check Commands

After installation, verify with:

```bash
# Check Flutter version
flutter --version

# Check available devices
flutter devices

# Check Flutter setup
flutter doctor
```

## Troubleshooting

### "Flutter command not found" after adding to PATH
- **Solution**: Close ALL terminal windows and open a new one
- Or restart your computer

### "Unable to locate Android SDK"
- **Solution**: Install Android Studio and configure SDK location
- Or set `ANDROID_HOME` environment variable

### "Chrome not found"
- **Solution**: Install Google Chrome browser
- Or use a different device: `flutter devices` to see available options

## Need Help?

- Flutter Docs: https://docs.flutter.dev
- Flutter Installation: https://docs.flutter.dev/get-started/install/windows
- Flutter Community: https://flutter.dev/community

