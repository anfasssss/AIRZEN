/**
 * =====================================================================================
 * PROJECT: AIRZEN (Air Intelligence & Regular for Pollution Environment Network)
 * PLATFORM: ESP32 DevKit V1
 * ARCHITECTURE: Embedded REST API WebServer + Custom Android App (APK) Support
 * 
 * FEATURES:
 * 1. Real-time Air Quality (MQ-135) with automated ventilation fan & phone alerts.
 * 2. Sound level monitoring with automated noise-containment window servo & phone alerts.
 * 3. Temperature & Humidity (DHT) monitoring with automated fan & phone alerts.
 * 4. Fire Emergency Detection (Flame sensor) with automated 5V water pump & phone siren.
 * 5. Remote controls for Room Light (LED) and Room Door (Micro Servo) from Android App.
 * 6. High-Tech 0.96" I2C OLED with startup branding animation & live telemetry screens.
 * 7. Built-in REST API (/api/data, /api/control) & mDNS ("http://airzen.local").
 * =====================================================================================
 */

#include <WiFi.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include <DHT.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ESP32Servo.h>

#include "config.h"

// =============================================================================
// OBJECT INSTANTIATIONS
// =============================================================================
DHT dht(PIN_DHT, DHTTYPE);
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
Servo servoWindow;
Servo servoDoor;
WebServer server(HTTP_PORT);

// =============================================================================
// SYSTEM STATE VARIABLES
// =============================================================================
// Telemetry Data
int   rawAirQuality     = 0;
int   airQualityPPM     = 0;
int   soundPeakToPeak   = 0;
float currentTemp       = 0.0;
float currentHumidity   = 0.0;
bool  isFireDetected    = false;

// Actuator States
bool  fanState          = false;
bool  pumpState         = false;
bool  lightState        = false;
bool  windowClosed      = false;
bool  doorOpen          = false;

// Active Alert State for Custom App
String activeAlert      = "NONE";
String alertMessage     = "System Normal";

// Timers
unsigned long lastSensorReadTime    = 0;
unsigned long lastOledPageSwitch    = 0;
unsigned long fireDetectedTimestamp = 0;
uint8_t       currentOledPage       = 0;

// =============================================================================
// FORWARD DECLARATIONS
// =============================================================================
void playBootAnimation();
void readAllSensors();
void processSafetyAndAutomationLogic();
void updateOledDisplay();
int  measureSoundPeakToPeak(uint16_t sampleWindowMs);
void setRelay(uint8_t pin, bool state);
void setWindowPosition(bool closeWindow);
void setDoorPosition(bool openDoor);
void setupWebServerRoutes();
void handleCors();

// =============================================================================
// EMBEDDED DASHBOARD HTML/JS (Stored in flash memory)
// =============================================================================
const char INDEX_HTML[] PROGMEM = R"rawliteral(
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AIRZEN Mobile Console</title>
  <style>
    :root {
      --bg: #0b132b; --card: #1c2541; --accent: #48cae4; 
      --text: #f0f3f8; --danger: #e63946; --warn: #f77f00; --success: #06d6a0;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
    body { background: var(--bg); color: var(--text); padding: 16px; min-height: 100vh; }
    header { text-align: center; margin-bottom: 20px; }
    h1 { font-size: 26px; letter-spacing: 2px; color: var(--accent); }
    .subtitle { font-size: 12px; color: #8d99ae; }
    .alert-banner { display: none; padding: 12px; border-radius: 8px; font-weight: bold; text-align: center; margin-bottom: 16px; animation: pulse 1s infinite alternate; }
    .alert-fire { background: var(--danger); color: white; display: block; }
    .alert-warn { background: var(--warn); color: white; display: block; }
    @keyframes pulse { from { opacity: 0.85; } to { opacity: 1; transform: scale(1.01); } }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 14px; margin-bottom: 18px; }
    .card { background: var(--card); border-radius: 12px; padding: 14px; box-shadow: 0 4px 12px rgba(0,0,0,0.3); border: 1px solid #2d3748; }
    .card h3 { font-size: 13px; color: #8d99ae; margin-bottom: 6px; }
    .val { font-size: 28px; font-weight: 700; color: var(--accent); }
    .unit { font-size: 14px; color: #a0aec0; }
    .status-tag { display: inline-block; padding: 3px 8px; border-radius: 12px; font-size: 11px; margin-top: 6px; font-weight: bold; }
    .tag-good { background: rgba(6,214,160,0.2); color: var(--success); }
    .tag-bad { background: rgba(230,57,70,0.2); color: var(--danger); }
    .tag-warn { background: rgba(247,127,0,0.2); color: var(--warn); }
    .controls { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 20px; }
    .btn { background: #3a506b; border: none; color: white; padding: 14px; border-radius: 10px; font-size: 15px; font-weight: 600; cursor: pointer; transition: 0.2s; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px; }
    .btn.active { background: var(--accent); color: #0b132b; }
    .badge { font-size: 11px; opacity: 0.8; }
  </style>
</head>
<body>
  <header>
    <h1>AIRZEN</h1>
    <div class="subtitle">SMART HEALTHCARE & ENVIRONMENT NETWORK</div>
  </header>

  <div id="banner" class="alert-banner"></div>

  <div class="grid">
    <div class="card">
      <h3>AIR QUALITY (MQ-135)</h3>
      <div><span id="airVal" class="val">--</span> <span class="unit">ADC</span></div>
      <div id="airTag" class="status-tag tag-good">CLEAN</div>
    </div>
    <div class="card">
      <h3>TEMPERATURE</h3>
      <div><span id="tempVal" class="val">--</span> <span class="unit">°C</span></div>
      <div id="fanTag" class="status-tag tag-good">FAN: OFF</div>
    </div>
    <div class="card">
      <h3>HUMIDITY</h3>
      <div><span id="humVal" class="val">--</span> <span class="unit">%</span></div>
      <div class="status-tag tag-good">NORMAL</div>
    </div>
    <div class="card">
      <h3>SOUND NOISE</h3>
      <div><span id="soundVal" class="val">--</span> <span class="unit">AMP</span></div>
      <div id="soundTag" class="status-tag tag-good">OPTIMAL</div>
    </div>
  </div>

  <h3 style="margin-bottom: 10px; font-size: 14px; color: #8d99ae;">ROOM ACTUATORS</h3>
  <div class="controls">
    <button id="lightBtn" class="btn" onclick="toggleDevice('light')">
      <span>💡 Room Light</span>
      <span id="lightSt" class="badge">OFF</span>
    </button>
    <button id="doorBtn" class="btn" onclick="toggleDevice('door')">
      <span>🚪 Room Door</span>
      <span id="doorSt" class="badge">CLOSED</span>
    </button>
  </div>

  <div class="card" style="margin-top: 10px;">
    <h3>SYSTEM STATUS</h3>
    <div style="font-size: 13px; line-height: 1.8; margin-top: 6px;">
      <div>🪟 <b>Window (Noise Control):</b> <span id="windowSt">OPEN</span></div>
      <div>💧 <b>Water Pump:</b> <span id="pumpSt">OFF</span></div>
      <div>🔥 <b>Flame Sensor:</b> <span id="fireSt">CLEAR</span></div>
    </div>
  </div>

  <script>
    let audioCtx = null;
    let alarmPlaying = false;

    function playSiren() {
      if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      if (audioCtx.state === 'suspended') audioCtx.resume();
      if (alarmPlaying) return;
      alarmPlaying = true;
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(800, audioCtx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(1600, audioCtx.currentTime + 0.3);
      osc.frequency.exponentialRampToValueAtTime(800, audioCtx.currentTime + 0.6);
      gain.gain.setValueAtTime(0.3, audioCtx.currentTime);
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      osc.start();
      osc.stop(audioCtx.currentTime + 0.6);
      setTimeout(() => { alarmPlaying = false; }, 700);
    }

    async function fetchData() {
      try {
        const res = await fetch('/api/data');
        const d = await res.json();

        document.getElementById('airVal').innerText = d.airQuality;
        document.getElementById('tempVal').innerText = d.temperature.toFixed(1);
        document.getElementById('humVal').innerText = d.humidity.toFixed(1);
        document.getElementById('soundVal').innerText = d.sound;

        // Tags
        const airTag = document.getElementById('airTag');
        if (d.airQuality >= 1500) {
          airTag.className = 'status-tag tag-bad'; airTag.innerText = 'POLLUTED!';
        } else {
          airTag.className = 'status-tag tag-good'; airTag.innerText = 'CLEAN';
        }

        document.getElementById('fanTag').innerText = d.fanState ? 'FAN: ACTIVE' : 'FAN: OFF';
        document.getElementById('fanTag').className = d.fanState ? 'status-tag tag-warn' : 'status-tag tag-good';

        const soundTag = document.getElementById('soundTag');
        if (d.sound >= 2400) {
          soundTag.className = 'status-tag tag-bad'; soundTag.innerText = 'LOUD NOISE!';
        } else if (d.sound <= 300) {
          soundTag.className = 'status-tag tag-warn'; soundTag.innerText = 'SILENT';
        } else {
          soundTag.className = 'status-tag tag-good'; soundTag.innerText = 'OPTIMAL';
        }

        // Switches
        const lightBtn = document.getElementById('lightBtn');
        lightBtn.className = d.lightState ? 'btn active' : 'btn';
        document.getElementById('lightSt').innerText = d.lightState ? 'ON' : 'OFF';

        const doorBtn = document.getElementById('doorBtn');
        doorBtn.className = d.doorOpen ? 'btn active' : 'btn';
        document.getElementById('doorSt').innerText = d.doorOpen ? 'OPEN' : 'CLOSED';

        document.getElementById('windowSt').innerText = d.windowClosed ? 'CLOSED (NOISE)' : 'OPEN';
        document.getElementById('pumpSt').innerText = d.pumpState ? 'RUNNING' : 'OFF';
        document.getElementById('fireSt').innerText = d.fireDetected ? 'FIRE DETECTED!!' : 'CLEAR';

        // Alert Banner & Audio Siren
        const banner = document.getElementById('banner');
        if (d.activeAlert !== 'NONE') {
          banner.style.display = 'block';
          banner.className = d.fireDetected ? 'alert-banner alert-fire' : 'alert-banner alert-warn';
          banner.innerText = d.alertMessage;
          playSiren();
        } else {
          banner.style.display = 'none';
        }
      } catch(e) {
        console.error("Fetch error", e);
      }
    }

    async function toggleDevice(device) {
      await fetch(`/api/control?device=${device}&action=toggle`, { method: 'POST' });
      fetchData();
    }

    setInterval(fetchData, 1000);
    fetchData();
  </script>
</body>
</html>
)rawliteral";

// =============================================================================
// SETUP ROUTINE
// =============================================================================
void setup() {
  Serial.begin(115200);
  delay(200);
  Serial.println("\n========================================================");
  Serial.println("   AIRZEN - ESP32 Smart Healthcare & Environment System ");
  Serial.println("========================================================");

  // 1. Initialize GPIO Pin Modes
  pinMode(PIN_MQ135, INPUT);
  pinMode(PIN_SOUND, INPUT);
  pinMode(PIN_FLAME, INPUT_PULLUP);
  
  pinMode(PIN_LED_LIGHT, OUTPUT);
  pinMode(PIN_BUZZER, OUTPUT);
  pinMode(PIN_RELAY_FAN, OUTPUT);
  pinMode(PIN_RELAY_PUMP, OUTPUT);

  // Safe initial actuator states
  digitalWrite(PIN_LED_LIGHT, LOW);
  digitalWrite(PIN_BUZZER, LOW);
  setRelay(PIN_RELAY_FAN, false);
  setRelay(PIN_RELAY_PUMP, false);

  // 2. Initialize Servos (ESP32Servo)
  ESP32PWM::allocateTimer(0);
  ESP32PWM::allocateTimer(1);
  ESP32PWM::allocateTimer(2);
  ESP32PWM::allocateTimer(3);

  servoWindow.setPeriodHertz(50);
  servoDoor.setPeriodHertz(50);
  servoWindow.attach(PIN_SERVO_WINDOW, 500, 2400);
  servoDoor.attach(PIN_SERVO_DOOR, 500, 2400);

  // Initial servo positions: Window Open (Normal), Door Closed (Locked)
  setWindowPosition(false);
  setDoorPosition(false);

  // 3. Initialize DHT Sensor
  dht.begin();

  // 4. Initialize OLED Display (I2C)
  Wire.begin(OLED_SDA, OLED_SCL);
  if (!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_I2C_ADDR)) {
    Serial.println("[ERROR] SSD1306 OLED initialization failed!");
  } else {
    display.clearDisplay();
    display.setTextColor(SSD1306_WHITE);
    playBootAnimation();
  }

  // 5. Connect to Wi-Fi
  Serial.print("[WiFi] Connecting to: ");
  Serial.println(WIFI_SSID);

  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(10, 15);
  display.println("Connecting to WiFi");
  display.setCursor(10, 30);
  display.println(WIFI_SSID);
  display.drawRect(10, 48, 108, 8, SSD1306_WHITE);
  display.fillRect(12, 50, 40, 4, SSD1306_WHITE);
  display.display();

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] Connected successfully!");
    Serial.print("[WiFi] IP Address: ");
    Serial.println(WiFi.localIP());

    // Setup mDNS responder
    if (MDNS.begin(MDNS_HOSTNAME)) {
      Serial.printf("[mDNS] Responder started! Access via http://%s.local\n", MDNS_HOSTNAME);
    }

    display.fillRect(12, 50, 104, 4, SSD1306_WHITE);
    display.setCursor(10, 30);
    display.print("IP: ");
    display.println(WiFi.localIP());
    display.display();
    delay(1000);
  } else {
    Serial.println("\n[WiFi] Connection timeout! Running in offline mode.");
  }

  // 6. Setup Web Server REST Endpoints
  setupWebServerRoutes();
  server.begin();
  Serial.println("[HTTP] REST API Server started on port 80!");
}

// =============================================================================
// MAIN LOOP
// =============================================================================
void loop() {
  // 1. Handle incoming HTTP client requests
  server.handleClient();

  unsigned long currentMillis = millis();

  // 2. Periodic Sensor Sampling & Automation Logic
  if (currentMillis - lastSensorReadTime >= SENSOR_READ_INTERVAL) {
    lastSensorReadTime = currentMillis;
    readAllSensors();
    processSafetyAndAutomationLogic();
  }

  // 3. Update OLED Display Interface
  if (isFireDetected) {
    updateOledDisplay(); // Continuous blinking during fire
  } else if (currentMillis - lastOledPageSwitch >= OLED_PAGE_INTERVAL) {
    lastOledPageSwitch = currentMillis;
    currentOledPage = (currentOledPage + 1) % 3;
    updateOledDisplay();
  }
}

// =============================================================================
// REST API & WEB SERVER ROUTES
// =============================================================================
void setupWebServerRoutes() {
  // CORS support
  server.onNotFound([]() {
    if (server.method() == HTTP_OPTIONS) {
      server.sendHeader("Access-Control-Allow-Origin", "*");
      server.sendHeader("Access-Control-Allow-Methods", "POST,GET,OPTIONS");
      server.sendHeader("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
      server.send(200, "text/plain", "");
    } else {
      server.send(404, "text/plain", "Not Found");
    }
  });

  // Serve Embedded Mobile Web App
  server.on("/", HTTP_GET, []() {
    server.send_P(200, "text/html", INDEX_HTML);
  });

  // GET /api/data: Return full JSON state for Custom Android App
  server.on("/api/data", HTTP_GET, []() {
    handleCors();
    String json = "{";
    json += "\"airQuality\":" + String(rawAirQuality) + ",";
    json += "\"airQualityPPM\":" + String(airQualityPPM) + ",";
    json += "\"sound\":" + String(soundPeakToPeak) + ",";
    json += "\"temperature\":" + String(currentTemp, 1) + ",";
    json += "\"humidity\":" + String(currentHumidity, 1) + ",";
    json += "\"fireDetected\":" + String(isFireDetected ? "true" : "false") + ",";
    json += "\"fanState\":" + String(fanState ? "true" : "false") + ",";
    json += "\"pumpState\":" + String(pumpState ? "true" : "false") + ",";
    json += "\"lightState\":" + String(lightState ? "true" : "false") + ",";
    json += "\"windowClosed\":" + String(windowClosed ? "true" : "false") + ",";
    json += "\"doorOpen\":" + String(doorOpen ? "true" : "false") + ",";
    json += "\"activeAlert\":\"" + activeAlert + "\",";
    json += "\"alertMessage\":\"" + alertMessage + "\"";
    json += "}";

    server.send(200, "application/json", json);
  });

  // Control API for Light and Door
  auto handleControl = []() {
    handleCors();
    String device = server.arg("device");
    String action = server.arg("action");
    String state  = server.arg("state");

    if (device == "light") {
      if (action == "toggle") {
        lightState = !lightState;
      } else if (state.length() > 0) {
        lightState = (state == "1" || state == "true");
      }
      digitalWrite(PIN_LED_LIGHT, lightState ? HIGH : LOW);
      Serial.printf("[APP] Room Light set to %s\n", lightState ? "ON" : "OFF");
    } 
    else if (device == "door") {
      if (action == "toggle") {
        doorOpen = !doorOpen;
      } else if (state.length() > 0) {
        doorOpen = (state == "1" || state == "true");
      }
      setDoorPosition(doorOpen);
      Serial.printf("[APP] Room Door set to %s\n", doorOpen ? "OPEN" : "CLOSED");
    }
    else if (device == "window") {
      if (action == "toggle") {
        windowClosed = !windowClosed;
      } else if (state.length() > 0) {
        windowClosed = (state == "1" || state == "true");
      }
      setWindowPosition(windowClosed);
    }

    String resp = "{\"status\":\"ok\",\"device\":\"" + device + "\",";
    resp += "\"lightState\":" + String(lightState ? "true" : "false") + ",";
    resp += "\"doorOpen\":" + String(doorOpen ? "true" : "false") + "}";
    server.send(200, "application/json", resp);
  };

  server.on("/api/control", HTTP_GET, handleControl);
  server.on("/api/control", HTTP_POST, handleControl);
}

void handleCors() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "*");
}

// =============================================================================
// SENSOR READING IMPLEMENTATION
// =============================================================================
void readAllSensors() {
  // A. Air Quality (MQ-135)
  rawAirQuality = analogRead(PIN_MQ135);
  airQualityPPM = map(rawAirQuality, 300, 3800, 100, 2000);
  if (airQualityPPM < 50) airQualityPPM = 50;

  // B. Sound Sensor Peak-to-Peak Window
  soundPeakToPeak = measureSoundPeakToPeak(50);

  // C. Temperature & Humidity (DHT)
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  if (!isnan(t)) currentTemp = t;
  if (!isnan(h)) currentHumidity = h;

  // D. Flame Sensor
  isFireDetected = (digitalRead(PIN_FLAME) == FLAME_DETECTED_STATE);

  Serial.printf("[DATA] Air: %d | Sound: %d | Temp: %.1fC | Hum: %.1f%% | Fire: %s\n",
                rawAirQuality, soundPeakToPeak, currentTemp, currentHumidity, 
                isFireDetected ? "🔥 YES" : "NO");
}

int measureSoundPeakToPeak(uint16_t sampleWindowMs) {
  unsigned long startMillis = millis();
  int signalMax = 0;
  int signalMin = 4095;

  while (millis() - startMillis < sampleWindowMs) {
    int sample = analogRead(PIN_SOUND);
    if (sample < 4095) {
      if (sample > signalMax) signalMax = sample;
      if (sample < signalMin) signalMin = sample;
    }
  }
  return (signalMax - signalMin);
}

// =============================================================================
// SAFETY, AUTOMATION & ALERT LOGIC
// =============================================================================
void processSafetyAndAutomationLogic() {
  unsigned long now = millis();

  // 1. FIRE EMERGENCY RESPONSE (Highest Priority!)
  if (isFireDetected) {
    fireDetectedTimestamp = now;
    pumpState = true;
    setRelay(PIN_RELAY_PUMP, true);  // Water Pump ON immediately

    // SAFETY OVERRIDE: Keep Ventilation Fan OFF to avoid oxygen feeding flames
    fanState = false;
    setRelay(PIN_RELAY_FAN, false);

    // Audio alarm
    tone(PIN_BUZZER, 2000, 400);

    activeAlert  = "FIRE_EMERGENCY";
    alertMessage = "🔥 FIRE DETECTED! Water Pump Activated!";
    return;
  } else {
    // Cooldown check for water pump
    if (pumpState && (now - fireDetectedTimestamp >= FIRE_PUMP_COOLDOWN_MS)) {
      pumpState = false;
      setRelay(PIN_RELAY_PUMP, false);
      noTone(PIN_BUZZER);
    }
  }

  // 2. AIR QUALITY LOGIC (MQ-135)
  bool airQualityBad = (rawAirQuality >= AIR_QUALITY_BAD_THRESHOLD);
  if (airQualityBad) {
    if (!fanState) {
      fanState = true;
      setRelay(PIN_RELAY_FAN, true);
    }
    tone(PIN_BUZZER, 1200, 250);
    activeAlert  = "AIR_QUALITY_BAD";
    alertMessage = "⚠️ Poor Air Quality Detected! Ventilation Fan ON.";
    return;
  }

  // 3. TEMPERATURE & HUMIDITY LOGIC (DHT)
  bool tempHigh = (currentTemp >= TEMP_HIGH_THRESHOLD);
  if (tempHigh) {
    if (!fanState) {
      fanState = true;
      setRelay(PIN_RELAY_FAN, true);
    }
    tone(PIN_BUZZER, 1000, 200);
    activeAlert  = "TEMP_HIGH";
    alertMessage = "🌡️ High Temperature Alert! Ventilation Fan ON.";
    return;
  }

  // Turn off ventilation fan when air and temperature normalize
  if (!airQualityBad && !tempHigh && fanState) {
    if (rawAirQuality < (AIR_QUALITY_BAD_THRESHOLD - AIR_QUALITY_HYSTERESIS) &&
        currentTemp < (TEMP_HIGH_THRESHOLD - TEMP_HYSTERESIS)) {
      fanState = false;
      setRelay(PIN_RELAY_FAN, false);
    }
  }

  // High Humidity Alert (Ventilation fan is NOT used for humidity as specified)
  if (currentHumidity >= HUMIDITY_HIGH_THRESHOLD) {
    tone(PIN_BUZZER, 800, 200);
    activeAlert  = "HUMIDITY_HIGH";
    alertMessage = "💧 High Humidity Alert! Moisture is elevated.";
    return;
  }

  // 4. SOUND MONITORING & NOISE CONTAINMENT (Window Servo)
  if (soundPeakToPeak >= SOUND_HIGH_THRESHOLD) {
    if (!windowClosed) {
      windowClosed = true;
      setWindowPosition(true); // Close window to block loud external noise
    }
    tone(PIN_BUZZER, 1500, 300);
    activeAlert  = "SOUND_HIGH";
    alertMessage = "🔊 High Noise Alert! Window closed automatically.";
    return;
  } 
  else if (soundPeakToPeak <= SOUND_LOW_THRESHOLD && soundPeakToPeak > 0) {
    activeAlert  = "SOUND_LOW";
    alertMessage = "🤫 Silence Alert! Ambient sound is very low.";
    return;
  }

  // If no conditions are triggered, reset active alert
  activeAlert  = "NONE";
  alertMessage = "System Normal";
}

// =============================================================================
// ACTUATOR DRIVER HELPERS
// =============================================================================
void setRelay(uint8_t pin, bool state) {
  digitalWrite(pin, state ? RELAY_ACTIVE_LEVEL : RELAY_INACTIVE_LEVEL);
}

void setWindowPosition(bool closeWindow) {
  windowClosed = closeWindow;
  servoWindow.write(closeWindow ? WINDOW_CLOSED_ANGLE : WINDOW_OPEN_ANGLE);
}

void setDoorPosition(bool open) {
  doorOpen = open;
  servoDoor.write(open ? DOOR_OPEN_ANGLE : DOOR_CLOSED_ANGLE);
}

// =============================================================================
// HIGH-TECH OLED INTERFACE & ANIMATION
// =============================================================================
void playBootAnimation() {
  // Phase 1: Expanding tech-circles
  for (int r = 4; r <= 28; r += 3) {
    display.clearDisplay();
    display.drawCircle(64, 32, r, SSD1306_WHITE);
    display.drawCircle(64, 32, r - 2, SSD1306_WHITE);
    display.display();
    delay(30);
  }

  // Phase 2: Dynamic stylized "AIRZEN" branding reveal
  for (int y = -15; y <= 16; y += 4) {
    display.clearDisplay();
    // Tech corners
    display.drawLine(2, 2, 16, 2, SSD1306_WHITE);
    display.drawLine(2, 2, 2, 16, SSD1306_WHITE);
    display.drawLine(125, 2, 111, 2, SSD1306_WHITE);
    display.drawLine(125, 2, 125, 16, SSD1306_WHITE);
    display.drawLine(2, 61, 16, 61, SSD1306_WHITE);
    display.drawLine(2, 61, 2, 47, SSD1306_WHITE);
    display.drawLine(125, 61, 111, 61, SSD1306_WHITE);
    display.drawLine(125, 61, 125, 47, SSD1306_WHITE);

    display.setTextSize(2);
    display.setCursor(26, y);
    display.print("AIRZEN");
    display.display();
    delay(25);
  }

  // Phase 3: Subtitle & Loading bar
  display.setTextSize(1);
  display.setCursor(18, 38);
  display.print("SMART HEALTHCARE");
  display.drawFastHLine(14, 48, 100, SSD1306_WHITE);

  const char* steps[] = {
    "Init Sensors...",
    "Calibrating MQ135...",
    "Testing Relays...",
    "Servos Ready..."
  };

  for (int i = 0; i < 4; i++) {
    display.fillRect(14, 52, 100, 10, SSD1306_BLACK);
    display.setCursor(18, 53);
    display.print(steps[i]);
    display.drawRect(14, 49, 100, 2, SSD1306_WHITE);
    display.fillRect(14, 49, (i + 1) * 25, 2, SSD1306_WHITE);
    display.display();
    tone(PIN_BUZZER, 1800 + (i * 200), 40);
    delay(280);
  }
  delay(500);
}

void updateOledDisplay() {
  display.clearDisplay();

  // EMERGENCY FLASH SCREEN
  if (isFireDetected) {
    static bool blink = false;
    blink = !blink;
    if (blink) {
      display.fillRect(0, 0, 128, 64, SSD1306_WHITE);
      display.setTextColor(SSD1306_BLACK, SSD1306_WHITE);
    } else {
      display.setTextColor(SSD1306_WHITE, SSD1306_BLACK);
    }
    display.setTextSize(2);
    display.setCursor(16, 8);
    display.print("EMERGENCY");
    display.setCursor(14, 28);
    display.print("FIRE ALERT!");
    display.setTextSize(1);
    display.setCursor(12, 50);
    display.print("WATER PUMP ACTIVE");
    display.display();
    display.setTextColor(SSD1306_WHITE, SSD1306_BLACK);
    return;
  }

  // --- Top Common Header Bar ---
  display.setTextSize(1);
  display.setCursor(2, 2);
  display.print("AIRZEN");
  display.setCursor(76, 2);
  display.print(WiFi.status() == WL_CONNECTED ? "[WiFi OK]" : "[OFFLINE]");
  display.drawFastHLine(0, 11, 128, SSD1306_WHITE);

  // PAGE 0: AIR QUALITY & FIRE
  if (currentOledPage == 0) {
    display.setCursor(2, 15);
    display.print("Air Q: ");
    display.setTextSize(2);
    display.setCursor(44, 15);
    display.print(rawAirQuality);

    display.setTextSize(1);
    display.setCursor(2, 33);
    if (rawAirQuality >= AIR_QUALITY_BAD_THRESHOLD) {
      display.print("Status: HAZARDOUS!");
    } else if (rawAirQuality >= 900) {
      display.print("Status: MODERATE");
    } else {
      display.print("Status: PURE / GOOD");
    }

    display.setCursor(2, 45);
    display.printf("Vent Fan : %s", fanState ? "ON (ACTIVE)" : "OFF (IDLE)");
    display.setCursor(2, 55);
    display.printf("Fire St. : %s", isFireDetected ? "FIRE!!" : "NORMAL (OK)");
  }
  // PAGE 1: CLIMATE & NOISE METRICS
  else if (currentOledPage == 1) {
    display.setCursor(2, 15);
    display.printf("Temp: %.1f C", currentTemp);

    display.setCursor(2, 27);
    display.printf("Hum : %.1f %%", currentHumidity);

    display.setCursor(2, 39);
    display.printf("Noise Level: %d", soundPeakToPeak);

    display.setCursor(2, 52);
    display.print("Noise St: ");
    if (soundPeakToPeak >= SOUND_HIGH_THRESHOLD) {
      display.print("TOO LOUD!");
    } else if (soundPeakToPeak <= SOUND_LOW_THRESHOLD) {
      display.print("SILENT");
    } else {
      display.print("OPTIMAL");
    }
  }
  // PAGE 2: ROOM AUTOMATION
  else if (currentOledPage == 2) {
    display.setCursor(2, 15);
    display.print("ROOM AUTOMATION");

    display.setCursor(2, 27);
    display.printf("Window : %s", windowClosed ? "CLOSED (NOISE)" : "OPEN");

    display.setCursor(2, 39);
    display.printf("Door   : %s", doorOpen ? "OPEN (UNLOCKED)" : "CLOSED (LOCKED)");

    display.setCursor(2, 51);
    display.printf("Light  : %s", lightState ? "ON" : "OFF");
  }

  // Pagination dots
  for (int p = 0; p < 3; p++) {
    if (p == currentOledPage) {
      display.fillCircle(112 + (p * 5), 61, 1, SSD1306_WHITE);
    } else {
      display.drawPixel(112 + (p * 5), 61, SSD1306_WHITE);
    }
  }

  display.display();
}
