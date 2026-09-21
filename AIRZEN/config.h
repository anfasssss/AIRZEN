/**
 * @file config.h
 * @project AIRZEN - Air Intelligence & Regular for Pollution Environment Network
 * @brief System configuration, pin assignments, thresholds, and network settings for Custom App.
 */

#ifndef CONFIG_H
#define CONFIG_H

// =============================================================================
// 1. WI-FI CREDENTIALS & SERVER CONFIGURATION
// =============================================================================
#ifndef WIFI_SSID
#define WIFI_SSID           "Your_WiFi_SSID"
#endif
#ifndef WIFI_PASSWORD
#define WIFI_PASSWORD       "Your_WiFi_Password"
#endif

// Local mDNS Hostname: Allows access via http://airzen.local in your custom app or browser
#define MDNS_HOSTNAME       "airzen"
#define HTTP_PORT           80

// =============================================================================
// 2. HARDWARE GPIO PIN DEFINITIONS (ESP32 DEVKIT V1)
// =============================================================================
// Analog Sensors (Using ADC1 pins - safe and stable while Wi-Fi is active)
#define PIN_MQ135           34    // MQ-135 Air Quality Analog Out (ADC1_CH6)
#define PIN_SOUND           35    // Sound Sensor Analog Out (ADC1_CH7)

// Digital Sensors
#define PIN_DHT             4     // DHT11 / DHT22 Data Pin
#define PIN_FLAME           5     // Flame Sensor Digital Output (D0)

// Actuators & Relays
#define PIN_RELAY_FAN       26    // Relay 1: Ventilation Fan
#define PIN_RELAY_PUMP      27    // Relay 2: 5V Water Pump
#define PIN_LED_LIGHT       25    // Room Lighting LED (or Transistor/Relay)
#define PIN_BUZZER          14    // Onboard Hardware Buzzer (Optional alert)

// Servo Motors (PWM Pins)
#define PIN_SERVO_WINDOW    18    // Micro Servo 1: Automatic Noise-Control Window
#define PIN_SERVO_DOOR      19    // Micro Servo 2: Remote Door Control

// I2C OLED Display (SSD1306 128x64)
#define OLED_SDA            21    // I2C Data Pin
#define OLED_SCL            22    // I2C Clock Pin
#define SCREEN_WIDTH        128   // OLED display width, in pixels
#define SCREEN_HEIGHT       64    // OLED display height, in pixels
#define OLED_RESET          -1    // Reset pin # (or -1 if sharing Arduino reset pin)
#define SCREEN_I2C_ADDR     0x3C  // Common I2C address for SSD1306 (0x3C or 0x3D)

// =============================================================================
// 3. SENSOR CONFIGURATION & THRESHOLDS
// =============================================================================
#define DHTTYPE             DHT11 // Set to DHT11 or DHT22

// Air Quality Thresholds (0 - 4095 ADC Reading / Estimated PPM)
#define AIR_QUALITY_BAD_THRESHOLD   1500  // ADC reading above which air is considered polluted
#define AIR_QUALITY_HYSTERESIS      150   // Prevent rapid fan toggling

// Climate Thresholds
#define TEMP_HIGH_THRESHOLD         35.0  // °C - Fan turns ON when exceeded
#define TEMP_HYSTERESIS             1.5   // °C
#define HUMIDITY_HIGH_THRESHOLD     75.0  // % - Alert when exceeded

// Sound Level Thresholds (ADC peak-to-peak amplitude)
#define SOUND_HIGH_THRESHOLD        2400  // Loud noise triggers window close & alert
#define SOUND_LOW_THRESHOLD         300   // Deep silence threshold

// Flame Sensor Polarity (Most flame modules pull LOW on flame detection)
#define FLAME_DETECTED_STATE        LOW

// Relay Logic (Most Arduino/ESP32 relay modules are Active-LOW)
#define RELAY_ACTIVE_LEVEL          LOW
#define RELAY_INACTIVE_LEVEL        HIGH

// =============================================================================
// 4. SERVO ANGLES
// =============================================================================
#define WINDOW_OPEN_ANGLE           0     // Window Open position in degrees
#define WINDOW_CLOSED_ANGLE         90    // Window Closed position in degrees
#define DOOR_OPEN_ANGLE             90    // Door Open position in degrees
#define DOOR_CLOSED_ANGLE           0     // Door Closed position in degrees

// =============================================================================
// 5. TIMING CONSTANTS (Milliseconds)
// =============================================================================
#define SENSOR_READ_INTERVAL       1000UL // Read sensors every 1 second
#define OLED_PAGE_INTERVAL         3500UL // Rotate OLED info page every 3.5 seconds
#define FIRE_PUMP_COOLDOWN_MS      4000UL // Run water pump at least 4 seconds upon detection

#endif // CONFIG_H
