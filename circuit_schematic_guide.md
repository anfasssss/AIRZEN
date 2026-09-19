# AIRZEN - Complete Hardware Wiring & Circuit Schematic Guide

This guide details the complete wiring diagram, pin assignments, power distribution architecture, and hardware assembly instructions for the **AIRZEN** ESP32 Smart Healthcare & Environmental IoT System.

---

## 1. Power Supply Architecture (CRITICAL)

> [!CAUTION]
> **DO NOT power the 2x Servos, 5V Water Pump, and Relays directly from the ESP32's 5V/VIN or 3.3V pins!**
> - The ESP32's onboard linear voltage regulator can only supply ~500mA–800mA.
> - An SG90 servo motor can draw up to **500mA–800mA stall current** each.
> - A 5V DC submersible water pump draws **1000mA–1500mA** under load.
> - Running these off the ESP32 will cause severe brownout resets (`Brownout detector was triggered`) and Wi-Fi disconnects.

### Dual-Rail Power Distribution Scheme
```
   +-------------------------------------------------------------+
   |             EXTERNAL 5V / 2A-3A DC POWER ADAPTER            |
   +------------------------------+------------------------------+
                                  |
               +------------------+------------------+
               | (+5V VCC Rail)                      | (GND Rail)
               |                                     |
               +---> Servo 1 (Window) VCC            +---> Servo 1 GND
               +---> Servo 2 (Door) VCC              +---> Servo 2 GND
               +---> 2-Channel Relay VCC             +---> 2-Channel Relay GND
               +---> Water Pump (via Relay COM-NO)   +---> Water Pump (-)
               +---> ESP32 VIN (or 5V pin)           +---> ESP32 GND  <==== COMMON GROUND!
```

> [!IMPORTANT]
> **COMMON GROUND**: Always connect the **GND** of the external 5V power supply to the **GND** of the ESP32. Without a common ground reference, PWM signals to servos and digital signals to relays and sensors will float and malfunction.

---

## 2. Complete ESP32 Pinout & Connection Table

| Component | Component Pin | ESP32 Pin | Connected Power Rail | Notes / Specifics |
| :--- | :--- | :--- | :--- | :--- |
| **MQ-135 Air Quality Sensor** | VCC | — | **5V Power Rail** | MQ-135 internal heater requires 5V |
| | GND | — | **Common GND** | Ground |
| | AOUT (Analog) | **GPIO 34** | — | ADC1 channel (Safe with active Wi-Fi) |
| **Sound Detection Sensor** | VCC | — | **3.3V or 5V** | 3.3V recommended for 3.3V ADC safety |
| | GND | — | **Common GND** | Ground |
| | AOUT (Analog) | **GPIO 35** | — | ADC1 channel (Analog noise amplitude) |
| **DHT11 / DHT22 Sensor** | VCC | — | **3.3V (ESP32)** | Operating voltage |
| | GND | — | **Common GND** | Ground |
| | DATA | **GPIO 4** | — | Add 4.7kΩ–10kΩ pull-up to 3.3V if bare sensor |
| **Flame Sensor Module** | VCC | — | **3.3V or 5V** | Module VCC |
| | GND | — | **Common GND** | Ground |
| | DOUT (Digital) | **GPIO 5** | — | Goes LOW when flame/fire is detected |
| **0.96" I2C OLED (SSD1306)** | VDD / VCC | — | **3.3V (ESP32)** | 3.3V logic display |
| | GND | — | **Common GND** | Ground |
| | SCK / SCL | **GPIO 22** | — | Hardware I2C Clock |
| | SDA | **GPIO 21** | — | Hardware I2C Data |
| **Window SG90 Servo (Servo 1)** | Red (VCC) | — | **Ext. 5V Rail** | Power from external 5V supply |
| | Brown (GND) | — | **Common GND** | Power ground |
| | Orange (Signal)| **GPIO 18** | — | ESP32 PWM Output (Noise control) |
| **Door SG90 Servo (Servo 2)** | Red (VCC) | — | **Ext. 5V Rail** | Power from external 5V supply |
| | Brown (GND) | — | **Common GND** | Power ground |
| | Orange (Signal)| **GPIO 19** | — | ESP32 PWM Output (Manual Door control) |
| **2-Channel 5V Relay Module** | VCC | — | **Ext. 5V Rail** | Relay coil power (5V) |
| | GND | — | **Common GND** | Ground |
| | IN1 (Vent Fan) | **GPIO 26** | — | Active-LOW control for Fan |
| | IN2 (Water Pump)| **GPIO 27** | — | Active-LOW control for Pump |
| **Room Light LED** | Anode (+) | **GPIO 25** | — | In series with a **220Ω - 330Ω resistor** |
| | Cathode (-) | — | **Common GND** | Ground |
| **Hardware Buzzer (Optional)** | Anode (+) | **GPIO 14** | — | Piezo / Active Buzzer |
| | Cathode (-) | — | **Common GND** | Ground |

---

## 3. High-Current Actuator Wiring (Relays)

### A. 5V Submersible Water Pump Wiring
- **Relay Channel 2**:
  - Relay **COM (Common)** pin: Connect to **+5V (External Power)**.
  - Relay **NO (Normally Open)** pin: Connect to **Red (+) wire of Water Pump**.
  - **Black (-) wire of Water Pump**: Connect to **Common GND**.
- *Behavior*: When fire is detected, GPIO 27 pulls LOW -> Relay energizes -> NO connects to COM -> Water pump turns ON and delivers water.

### B. 12V or 5V DC Ventilation Fan Wiring
- **Relay Channel 1**:
  - Relay **COM**: Connect to **+DC Supply** (External 5V or 12V depending on your fan rating).
  - Relay **NO**: Connect to **Red (+) wire of Ventilation Fan**.
  - **Black (-) wire of Ventilation Fan**: Connect to **Ground**.
- *Behavior*: When air quality is poor or temperature is high, GPIO 26 pulls LOW -> Fan runs.

---

## 4. Breadboard & Assembly Best Practices

1. **Decoupling Capacitors**: Place a **100µF – 470µF electrolytic capacitor** across the external 5V and GND rail near the servo motors to smooth out instantaneous current spikes caused by motor startup.
2. **MQ-135 Burn-in Time**: The MQ-135 sensor requires an initial **24–48 hour preheat/burn-in cycle** when first powered up for its internal tin dioxide ($SnO_2$) heating layer to stabilize before accurate PPM readings can be obtained.
3. **Flame Sensor Positioning**: Ensure the IR receiver LED of the flame sensor has an unobstructed line of sight into the test area/room model. Keep it away from direct sunlight to avoid false triggers.
4. **Relay Jumper**: Most 2-channel relay boards feature a `VCC-JDVCC` jumper. For maximum optocoupler isolation, you can remove the jumper and supply 5V directly to `JD-VCC` from external 5V, while `VCC` connects to ESP32 3.3V/5V.
