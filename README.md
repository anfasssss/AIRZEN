# AIRZEN (Air Intelligence & Regular for Pollution Environment Network)
### ESP32 Based Smart Healthcare & Environmental Monitoring System with Custom Android App (APK)

AIRZEN എന്നത് ESP32 മൈക്രോകൺട്രോളറും **കസ്റ്റം ആൻഡ്രോയിഡ് ആപ്പും (APK)** ഉപയോഗിച്ച് വികസിപ്പിച്ചെടുത്ത അത്യാധുനികമായ ഒരു സ്മാർട്ട് ഹെൽത്ത്‌കെയർ & എൻവയോൺമെന്റ് ഓട്ടോമേഷൻ സിസ്റ്റമാണ്.

---

## 🌟 പ്രധാന സവിശേഷതകൾ (Key Features)

1. **എയർ ക്വാളിറ്റി മോണിറ്ററിംഗ് (Air Quality Monitoring)**:
   - **MQ-135** സെൻസർ ഉപയോഗിച്ച് വായുവിന്റെ ഗുണനിലവാരം തത്സമയം പരിശോധിക്കുന്നു.
   - എയർ ക്വാളിറ്റി മോശമാകുമ്പോൾ ഓട്ടോമാറ്റിക്കായി **വെന്റിലേഷൻ ഫാൻ (Relay 1)** ഓണാകുന്നു.
   - കസ്റ്റം ആൻഡ്രോയിഡ് ആപ്പിലേക്ക് തത്സമയം **ഹൈ-പ്രയോറിറ്റി നോട്ടിഫിക്കേഷനും ലൗഡ് അലാറവും** എത്തുന്നു.
   - ലൈവ് വാല്യൂസ് ആപ്പിലും OLED ഡിസ്‌പ്ലേയിലും കാണിക്കുന്നു.

2. **ശബ്ദ നിയന്ത്രണ സംവിധാനം (Sound Monitoring & Noise Control)**:
   - സൗണ്ട് സെൻസർ വഴി പരിസരത്തെ ശബ്ദതീവ്രത അളക്കുന്നു.
   - ശബ്ദം പരിധിയിൽ കൂടുമ്പോൾ **മൈക്രോ സെർവോ മോട്ടോർ 1** ഉപയോഗിച്ച് **ജനൽ ഓട്ടോമാറ്റിക്കായി അടയുന്നു**.
   - ആപ്പിലേക്ക് അലേർട്ടും അലാറം ടോണും വരുന്നു.
   - റൂമിൽ അമിത നിശബ്ദത ഉണ്ടായാലും ആപ്പിലേക്ക് അലേർട്ട് ലഭിക്കുന്നു.

3. **താപനില & ഈർപ്പം നിരീക്ഷണം (Temperature & Humidity - DHT)**:
   - റൂമിലെ ചൂട് കൂടുമ്പോൾ വെന്റിലേഷൻ ഫാൻ ഓണാകുകയും ആപ്പിൽ അലാറം അടിക്കുകയും ചെയ്യുന്നു.
   - ഈർപ്പം കൂടുമ്പോഴും ആപ്പിൽ അലേർട്ട് ലഭിക്കുന്നു (ഇതിൽ ഫാൻ ഓണാകില്ല).

4. **തീപിടുത്ത മുന്നറിയിപ്പ് (Fire Detection & Suppression)**:
   - **ഫ്ലെയിം സെൻസർ (Flame Sensor)** തീപിടുത്തം തിരിച്ചറിഞ്ഞാൽ നിമിഷങ്ങൾക്കകം **5V വാട്ടർ പമ്പ് (Relay 2)** പ്രവർത്തിപ്പിച്ച് റൂമിൽ വെള്ളം സ്പ്രേ ചെയ്യുന്നു.
   - ഒപ്പം ഫോണിൽ **ലൗഡ് എമർജൻസി സൈറൺ അലാറം (Siren Alarm)** മുഴങ്ങുന്നു.
   - തീ ആളിപ്പടരാതിരിക്കാൻ വെന്റിലേഷൻ ഫാൻ നിർബന്ധമായും ഓഫ് ചെയ്തു നിർത്തുന്നു.

5. **മാനുവൽ കൺട്രോൾ സ്വിച്ചുകൾ (Custom App Remote Switches)**:
   - ആൻഡ്രോയിഡ് ആപ്പിലെ സ്വിച്ച് ഉപയോഗിച്ച് റൂമിലെ **ലൈറ്റ് (LED)** ഓൺ/ഓഫ് ചെയ്യാം.
   - ആപ്പിലെ രണ്ടാമത്തെ സ്വിച്ച് വഴി **മൈക്രോ സെർവോ മോട്ടോർ 2** പ്രവർത്തിപ്പിച്ച് **ഡോർ (Door)** തുറക്കാനും അടയ്ക്കാനും സാധിക്കും.

6. **ഹൈ-ടെക് OLED ഇന്റർഫേസ് (SSD1306 128x64)**:
   - സിസ്റ്റം ബൂട്ട് ചെയ്യുമ്പോൾ കിടിലൻ ആനിമേഷനോടൊപ്പം **"AIRZEN"** ലോഗോയും സെൽഫ് ചെക്കിംഗ് പ്രോഗ്രസ് ബാറും കാണിക്കുന്നു.
   - തുടർന്ന് ഓരോ സെൻസറിന്റെയും റീഡിംഗുകളും ആക്ച്വേറ്ററുകളുടെ സ്റ്റാറ്റസും മാറിമാറി കാണിക്കുന്നു.
   - തീപിടുത്തമുണ്ടായാൽ സ്‌ക്രീൻ മിന്നിത്തിളങ്ങുന്ന എമർജൻസി വാണിംഗ് നൽകുന്നു.

---

## 📂 പ്രോജക്റ്റ് ഫയലുകൾ (Project Files)

- [`AIRZEN_Complete_Project_Guide.pdf`](file:///Users/macbook/Documents/project%20prbhapurma/AIRZEN_Complete_Project_Guide.pdf) - **പൂർണ്ണമായ പ്രോജക്റ്റ് വിവരങ്ങൾ അടങ്ങിയ പ്രൊഫഷണൽ PDF ഡോക്യുമെന്റ്**.
- [`AIRZEN.apk`](file:///Users/macbook/Documents/project%20prbhapurma/AIRZEN.apk) - **നേരിട്ട് ഫോണിൽ ഇൻസ്റ്റാൾ ചെയ്യാവുന്ന റെഡി-ടു-യൂസ് ആൻഡ്രോയിഡ് ആപ്പ് (APK - 5.4MB)**.
- [`AIRZEN/AIRZEN.ino`](file:///Users/macbook/Documents/project%20prbhapurma/AIRZEN/AIRZEN.ino) - പൂർണ്ണമായ ESP32 ഫേംവെയർ (REST API & WebServer).
- [`AIRZEN/config.h`](file:///Users/macbook/Documents/project%20prbhapurma/AIRZEN/config.h) - പിൻ നമ്പറുകൾ, വൈഫൈ, സെൻസർ പരിധികൾ എന്നിവ ക്രമീകരിക്കാനുള്ള ഫയൽ.
- [`AIRZEN_Android_App/`](file:///Users/macbook/Documents/project%20prbhapurma/AIRZEN_Android_App) - സമ്പൂർണ്ണ നേറ്റീവ് ആൻഡ്രോയിഡ് ആപ്പ് പ്രോജക്റ്റ് (Java/Material UI).
- [`android_app_guide.md`](file:///Users/macbook/Documents/project%20prbhapurma/android_app_guide.md) - ആപ്പ് APK നിർമ്മിക്കാനും ഫോണിൽ ഇൻസ്റ്റാൾ ചെയ്യാനുമുള്ള സമ്പൂർണ്ണ ഗൈഡ്.
- [`circuit_schematic_guide.md`](file:///Users/macbook/Documents/project%20prbhapurma/circuit_schematic_guide.md) - സർക്യൂട്ട് കണക്ഷൻ, വയറിംഗ്, പവർ സപ്ലൈ ഗൈഡ്.

---

## 🛠️ ആവശ്യമായ Arduino ലൈബ്രറികൾ (Required Arduino Libraries)

Arduino IDE -> **Tools** -> **Manage Libraries...** തുറന്ന് താഴെ പറയുന്നവ ഇൻസ്റ്റാൾ ചെയ്യുക:

1. **DHT sensor library** (by Adafruit)
2. **Adafruit Unified Sensor** (by Adafruit)
3. **Adafruit SSD1306** (by Adafruit)
4. **Adafruit GFX Library** (by Adafruit)
5. **ESP32Servo** (by Kevin Harrington)

*(ശ്രദ്ധിക്കുക: WebServer, ESPmDNS, WiFi എന്നിവ ESP32 ബോർഡ് പാക്കേജിൽ തന്നെയുള്ളതാണ്. Blynk ലൈബ്രറി ആവശ്യമില്ല!)*

---

## 🚀 എങ്ങനെ റൺ ചെയ്യാം (Quick Start Instructions)

1. **ESP32 പ്രോഗ്രാം ചെയ്യുക**:
   - Arduino IDE-യിൽ [`AIRZEN/AIRZEN.ino`](file:///Users/macbook/Documents/project%20prbhapurma/AIRZEN/AIRZEN.ino) ഫയൽ തുറക്കുക.
   - [`AIRZEN/config.h`](file:///Users/macbook/Documents/project%20prbhapurma/AIRZEN/config.h) ഫയലിൽ നിങ്ങളുടെ വൈഫൈ പേരും പാസ്‌വേഡും നൽകുക (`WIFI_SSID`, `WIFI_PASSWORD`).
   - ESP32 ബോർഡ് സെലക്ട് ചെയ്ത് കോഡ് **Upload** ചെയ്യുക.
2. **ആൻഡ്രോയിഡ് ആപ്പ് ഇൻസ്റ്റാൾ ചെയ്യുക**:
   - [`android_app_guide.md`](file:///Users/macbook/Documents/project%20prbhapurma/android_app_guide.md) നോക്കി Android Studio വഴി `app-debug.apk` ജനറേറ്റ് ചെയ്ത് ഫോണിൽ ഇൻസ്റ്റാൾ ചെയ്യുക.
   - അല്ലെങ്കിൽ ഫോണിലെ ക്രോം ബ്രൗസറിൽ `http://airzen.local` തുറന്ന് **"Add to Home Screen"** വഴി നിമിഷങ്ങൾക്കകം ആപ്പ് ആയി ഉപയോഗിക്കുക!
