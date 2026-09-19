# AIRZEN - Blynk IoT 2.0 Cloud & Mobile App Setup Guide

This guide walks you through setting up the **Blynk IoT** platform to receive real-time sensor streams, push notifications, smartphone alarm sounds, and remote controls for the **AIRZEN** system.

---

## 1. Create a Blynk Account & Template

1. Sign up or log in at **[https://blynk.cloud/](https://blynk.cloud/)**.
2. Download the **Blynk IoT** mobile app from Google Play Store or Apple App Store.
3. In the Blynk Web Console:
   - Click on **Developer Zone (wrench icon)** -> **Templates**.
   - Click **+ New Template**.
   - Name: `AIRZEN System`
   - Hardware: `ESP32`
   - Connection Type: `WiFi`
   - Description: `AIRZEN Smart Healthcare & Environmental Monitoring System`
   - Click **Done**.
4. Copy the auto-generated code header at the top of the Template page:
   ```cpp
   #define BLYNK_TEMPLATE_ID "TMPLxxxxxx"
   #define BLYNK_TEMPLATE_NAME "AIRZEN System"
   #define BLYNK_AUTH_TOKEN "Your_Token"
   ```
   Paste these credentials into [`config.h`](file:///Users/macbook/Documents/project%20prbhapurma/AIRZEN/config.h).

---

## 2. Configure Datastreams (Virtual Pins)

Navigate to the **Datastreams** tab within your `AIRZEN System` template and create the following 10 datastreams:

| Pin | Name | Data Type | Min | Max | Default | Units |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **V0** | `Air Quality` | Integer | `0` | `4095` | `0` | PPM / ADC |
| **V1** | `Temperature` | Double | `-20` | `80` | `0.0` | °C |
| **V2** | `Humidity` | Double | `0` | `100` | `0.0` | % |
| **V3** | `Sound Level` | Integer | `0` | `4095` | `0` | Amp |
| **V4** | `Room Light` | Integer | `0` | `1` | `0` | — |
| **V5** | `Door Lock` | Integer | `0` | `1` | `0` | — |
| **V6** | `Fire Alarm` | Integer | `0` | `255` | `0` | — |
| **V7** | `Ventilation Fan`| Integer | `0` | `255` | `0` | — |
| **V8** | `Water Pump` | Integer | `0` | `255` | `0` | — |
| **V9** | `Window State` | String | — | — | `"OPEN"` | — |

---

## 3. Configure Events & Smartphone Alarms

Navigate to the **Events** tab in the Template editor. Click **+ Add New Event** for each of the following alerts:

### 1. `fire_alert` (Critical Emergency Alarm)
- **Event Name**: `Fire Detected`
- **Event Code**: `fire_alert`
- **Type**: `Critical`
- **Notifications Tab**:
  - Enable **Send event to Notifications**
  - Enable **Push Notification** to mobile app
  - Notification Sound: Select **Alarm / Siren** (Loud Alarm)
  - Message: `🔥 FIRE DETECTED! Submersible Water Pump Activated!`

### 2. `air_alert` (Air Quality Warning)
- **Event Name**: `Poor Air Quality`
- **Event Code**: `air_alert`
- **Type**: `Warning`
- **Notifications Tab**:
  - Enable **Push Notification**
  - Notification Sound: **Alert Tone**
  - Message: `⚠️ Poor Air Quality Detected! Ventilation Fan Activated.`

### 3. `sound_high_alert` (Noise Mitigation Alert)
- **Event Name**: `High Noise Detected`
- **Event Code**: `sound_high_alert`
- **Type**: `Warning`
- **Notifications Tab**:
  - Enable **Push Notification**
  - Message: `🔊 High Noise Detected! Window closed automatically.`

### 4. `sound_low_alert` (Silence Alert)
- **Event Name**: `Silence / Low Sound`
- **Event Code**: `sound_low_alert`
- **Type**: `Info`
- **Notifications Tab**:
  - Enable **Push Notification**
  - Message: `🤫 Silence Alert! Ambient sound is very low.`

### 5. `temp_alert` (High Temperature Alert)
- **Event Name**: `High Temperature`
- **Event Code**: `temp_alert`
- **Type**: `Warning`
- **Notifications Tab**:
  - Enable **Push Notification**
  - Message: `🌡️ High Temperature Alert! Ventilation Fan Activated.`

### 6. `humidity_alert` (High Humidity Alert)
- **Event Name**: `High Humidity`
- **Event Code**: `humidity_alert`
- **Type**: `Warning`
- **Notifications Tab**:
  - Enable **Push Notification**
  - Message: `💧 High Humidity Alert! Ambient moisture is elevated.`

---

## 4. Mobile App Dashboard Layout

Open the **Blynk IoT** app on your iOS or Android device:
1. Tap the wrench/developer mode icon and open your **AIRZEN System** template.
2. Drag and drop the following UI widgets onto the canvas:

- **Row 1: Emergency & Status Indicators**
  - **LED Widget**: Datastream `V6 (Fire Alarm)` - Red color.
  - **LED Widget**: Datastream `V7 (Ventilation Fan)` - Cyan/Blue color.
  - **LED Widget**: Datastream `V8 (Water Pump)` - Green color.
  - **Value Display**: Datastream `V9 (Window State)` - Label: `Window`.

- **Row 2: Air Quality & Sound Gauges**
  - **Radial Gauge Widget**: Datastream `V0 (Air Quality)` - Range `0 - 3000`, Title: `Air Quality`.
  - **Radial Gauge Widget**: Datastream `V3 (Sound Level)` - Range `0 - 4095`, Title: `Sound (Noise)`.

- **Row 3: Climate Monitoring**
  - **Value Display / Level Widget**: Datastream `V1 (Temperature)` - Title: `Temperature (°C)`.
  - **Value Display / Level Widget**: Datastream `V2 (Humidity)` - Title: `Humidity (%)`.

- **Row 4: Manual Room Automation Switches**
  - **Button / Styled Switch**: Datastream `V4 (Room Light)` - Mode: `Switch`, Title: `💡 Room Light`.
  - **Button / Styled Switch**: Datastream `V5 (Door Lock)` - Mode: `Switch`, Title: `🚪 Room Door`.

- **Row 5: Historical Data Chart (SuperChart)**
  - Add streams: `V0 (Air Quality)`, `V1 (Temperature)`, `V3 (Sound)` to visualize 24-hour trends.

---

## 5. Mobile Phone Sound & Alarm Settings

To ensure alarms ring loud and clear on your smartphone even in silent mode:
1. On **Android**:
   - Go to **Settings** -> **Apps** -> **Blynk IoT** -> **Notifications**.
   - Tap **Notification Categories** -> **Critical Events / Alerts**.
   - Set **Importance** to **High / Urgent**.
   - Enable **Override Do Not Disturb**.
2. On **iOS**:
   - Go to **Settings** -> **Blynk IoT** -> **Notifications**.
   - Ensure **Sounds** and **Critical Alerts** (if prompted) are turned ON.
