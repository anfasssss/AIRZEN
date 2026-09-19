# AIRZEN - Custom Android App (APK) Build & Installation Guide

This guide explains how to generate, install, and run the custom **AIRZEN Android App (APK)** on your smartphone.

---

## 📱 Method 1: Build the APK using Android Studio (Recommended)

The full native Android source code is available in the [`AIRZEN_Android_App/`](file:///Users/macbook/Documents/project%20prbhapurma/AIRZEN_Android_App) directory.

### Step 1: Open the Project
1. Download and open **Android Studio** on your computer.
2. Click **File** -> **Open...** and select the folder:
   ```
   AIRZEN_Android_App
   ```
3. Android Studio will automatically sync the Gradle files and build the project dependencies.

### Step 2: Build the APK File
1. In the top menu bar, click on:
   **Build** -> **Build Bundle(s) / APK(s)** -> **Build APK(s)**.
2. Wait a few seconds for the build process to finish.
3. In the bottom-right corner, you will see a notification:
   > *"APK(s) generated successfully for 1 module: app"*
4. Click the blue **locate** link. It will open the folder containing:
   ```
   app-debug.apk
   ```
   *(Located in: `AIRZEN_Android_App/app/build/outputs/apk/debug/app-debug.apk`)*.

### Step 3: Install on Your Phone
1. Transfer `app-debug.apk` to your phone using a USB cable, WhatsApp, Google Drive, or Bluetooth.
2. On your Android phone, tap on `app-debug.apk`.
3. If prompted with *"For security, your phone is not allowed to install unknown apps from this source"*, tap **Settings** and toggle **Allow from this source**.
4. Tap **Install** -> **Open**.

---

## ⚡ Method 2: Instant PWA / WebAPK Install (No PC Software Needed!)

The ESP32 firmware hosts the complete AIRZEN dashboard directly in its flash memory. You can install it on your phone as a standalone app APK in seconds without installing Android Studio:

1. Connect your ESP32 to power.
2. Ensure your smartphone is connected to the same Wi-Fi network.
3. Check the ESP32 IP address displayed on the **OLED screen** (e.g., `192.168.1.105`) or simply use:
   ```
   http://airzen.local
   ```
4. Open **Google Chrome** on your Android phone and navigate to:
   ```
   http://airzen.local
   ```
   *(or `http://<ESP32-IP-Address>`)*
5. Tap the three dots menu (⋮) in Chrome and tap:
   **"Add to Home screen"** or **"Install app"**.
6. The **AIRZEN** icon will appear on your Android home screen and app drawer as an independent, full-screen app with audio siren alarms and live controls!

---

## 🌐 Method 3: 1-Click Cloud APK Build via MIT App Inventor

If you prefer building in a web browser without Android Studio:
1. Go to **[http://ai2.appinventor.mit.edu/](http://ai2.appinventor.mit.edu/)** and sign in with your Google account.
2. Add a `Web` component, a `Clock` component (Timer interval: 1000ms), and UI labels/switches.
3. In Blocks, set `Clock.Timer` -> `Web1.Url` to `"http://airzen.local/api/data"` -> `Web1.Get`.
4. When `Web1.GotText`, decode JSON and update the text fields.
5. Click **Build** -> **Android App (.apk)**.
6. Scan the QR code on your phone with your camera to download and install the `.apk` directly.

---

## 🔊 Testing the Phone Alarm & Alarms

When running the app:
1. Enter your ESP32 IP or `airzen.local` into the top connection bar and tap **Connect**.
2. **Poor Air Quality**: Blow smoke or alcohol vapor near the MQ-135 -> Fan turns ON, phone vibrates, and the app sounds a loud acoustic alert.
3. **Loud Sound**: Clap loudly near the sound sensor -> Window servo closes to 90°, and the phone rings the noise alert.
4. **Fire Emergency**: Bring a lighter near the flame sensor -> Water pump turns ON, and the phone sounds a continuous emergency police siren.
5. **Light / Door Switch**: Toggle the switches on the app -> The LED instantly illuminates, and the door servo moves between 0° and 90°.
