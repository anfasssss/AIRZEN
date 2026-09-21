import SwiftUI
import AudioToolbox
import AVFoundation
import Combine

// =============================================================================
// TELEMETRY DATA MODEL
// =============================================================================
struct TelemetryData: Codable {
    var airQuality: Int?
    var airQualityPPM: Int?
    var sound: Int?
    var temperature: Double?
    var humidity: Double?
    var fireDetected: Bool?
    var fanState: Bool?
    var pumpState: Bool?
    var lightState: Bool?
    var windowClosed: Bool?
    var doorOpen: Bool?
    var activeAlert: String?
    var alertMessage: String?
}

// =============================================================================
// MAIN CONTENT VIEW
// =============================================================================
struct ContentView: View {
    @AppStorage("esp32_ip") private var savedIp: String = ""
    @State private var ipInput: String = ""
    @State private var connectionStatus: String = "🔴 Disconnected"
    @State private var isConnected: Bool = false
    
    // Telemetry State
    @State private var telemetry = TelemetryData()
    @State private var lightSwitch: Bool = false
    @State private var doorSwitch: Bool = false
    @State private var isUserToggling: Bool = false
    
    // Splash Animation State
    @State private var isShowingSplash: Bool = true
    
    // Polling Timer (1 second)
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background: Deep Cybernetic Space Gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 6/255, green: 11/255, blue: 28/255),
                    Color(red: 11/255, green: 20/255, blue: 44/255),
                    Color(red: 17/255, green: 30/255, blue: 59/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main Scrollable Dashboard
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // TOP APP HEADER
                    headerView
                    
                    // IP CONNECTION BAR
                    connectionBarView
                    
                    // ACTIVE CRITICAL ALERT BANNER (IF TRIGGERED)
                    if let alert = telemetry.activeAlert, alert != "NONE" {
                        emergencyBanner(alert: alert)
                    }
                    
                    // SECTION 1: 5 LARGE PROMINENT SENSOR BOXES
                    VStack(alignment: .leading, spacing: 14) {
                        Text("LIVE SENSOR TELEMETRY")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255))
                            .tracking(1.5)
                            .padding(.horizontal, 4)
                        
                        // 1. AIR QUALITY BOX (MQ-135)
                        airQualityCard
                        
                        // 2. FIRE & FLAME BOX (FLAME SENSOR - LARGE & PROMINENT)
                        fireEmergencyCard
                        
                        // 3. TEMPERATURE BOX (DHT)
                        temperatureCard
                        
                        // 4. HUMIDITY BOX (DHT)
                        humidityCard
                        
                        // 5. SOUND NOISE BOX (SOUND SENSOR)
                        soundNoiseCard
                    }
                    
                    // SECTION 2: 2 LARGE MANUAL CONTROL SWITCHES
                    VStack(alignment: .leading, spacing: 14) {
                        Text("MANUAL ROOM CONTROLS")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255))
                            .tracking(1.5)
                            .padding(.horizontal, 4)
                            .padding(.top, 8)
                        
                        // ROOM LIGHT SWITCH CARD
                        roomLightCard
                        
                        // ROOM DOOR SWITCH CARD
                        roomDoorCard
                    }
                    
                    // ACTUATOR STATUS OVERVIEW SUMMARY
                    actuatorSummaryCard
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
            .opacity(isShowingSplash ? 0 : 1)
            
            // STARTING SPLASH ANIMATION SCREEN
            if isShowingSplash {
                SplashAnimationView {
                    withAnimation(.easeInOut(duration: 0.7)) {
                        isShowingSplash = false
                    }
                }
                .transition(.asymmetric(insertion: .identity, removal: .opacity.combined(with: .scale(scale: 1.08))))
                .zIndex(10)
            }
        }
        .onAppear {
            ipInput = savedIp
            fetchData()
        }
        .onReceive(timer) { _ in
            if !isShowingSplash {
                fetchData()
            }
        }
    }
    
    // =========================================================================
    // SUBVIEWS: HEADER & CONNECTION
    // =========================================================================
    var headerView: some View {
        VStack(spacing: 8) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color(red: 72/255, green: 202/255, blue: 228/255).opacity(0.5), radius: 12)
            
            Text("AIRZEN")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255))
                .tracking(2.5)
            
            Text("SMART HEALTHCARE & ENVIRONMENT NETWORK")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.gray.opacity(0.9))
                .tracking(0.8)
        }
        .padding(.top, 6)
    }
    
    var connectionBarView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                TextField("ESP32 IP (e.g. 192.168.43.45)", text: $ipInput)
                    .padding(12)
                    .background(Color(red: 25/255, green: 35/255, blue: 62/255))
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .ipKeyboardModifiers()
                
                Button(action: {
                    savedIp = ipInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    connectionStatus = "🟡 Connecting..."
                    fetchData()
                }) {
                    Text("Connect")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 6/255, green: 11/255, blue: 28/255))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 72/255, green: 202/255, blue: 228/255), Color(red: 6/255, green: 214/255, blue: 160/255)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                }
            }
            
            Text(connectionStatus)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isConnected ? Color(red: 6/255, green: 214/255, blue: 160/255) : Color(red: 247/255, green: 127/255, blue: 0/255))
        }
        .padding(14)
        .background(Color(red: 18/255, green: 27/255, blue: 50/255))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    func emergencyBanner(alert: String) -> some View {
        let isFire = alert == "FIRE_EMERGENCY"
        return HStack(spacing: 12) {
            Text(isFire ? "🔥" : "⚠️")
                .font(.system(size: 28))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isFire ? "CRITICAL FIRE EMERGENCY!" : "SYSTEM ATTENTION REQUIRED")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                Text(telemetry.alertMessage ?? "Alert Active")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
            }
            Spacer()
        }
        .padding(14)
        .background(isFire ? Color(red: 230/255, green: 57/255, blue: 70/255) : Color(red: 247/255, green: 127/255, blue: 0/255))
        .cornerRadius(12)
        .shadow(color: isFire ? Color.red.opacity(0.5) : Color.orange.opacity(0.5), radius: 10)
    }
    
    // =========================================================================
    // 5 LARGE SENSOR CARDS
    // =========================================================================
    
    // 1. AIR QUALITY CARD (MQ-135)
    var airQualityCard: some View {
        let val = telemetry.airQuality ?? 0
        let isBad = val >= 1500
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("💨")
                        .font(.title2)
                    Text("AIR QUALITY MONITOR")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("MQ-135 SENSOR")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 72/255, green: 202/255, blue: 228/255).opacity(0.15))
                    .cornerRadius(6)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(val)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(isBad ? Color(red: 230/255, green: 57/255, blue: 70/255) : Color(red: 72/255, green: 202/255, blue: 228/255))
                Text("ADC UNITS (PPM ~\(telemetry.airQualityPPM ?? 0))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
            }
            
            // Visual Gauge Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    Capsule()
                        .fill(isBad ? Color.red : (val >= 900 ? Color.orange : Color.green))
                        .frame(width: min(CGFloat(val) / 3500.0 * geo.size.width, geo.size.width), height: 8)
                }
            }
            .frame(height: 8)
            
            // Status Tag & Action Indicator
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(airStatusColor(val))
                        .frame(width: 8, height: 8)
                    Text(airStatusText(val))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(airStatusColor(val))
                }
                Spacer()
                Text("Ventilation Fan: \((telemetry.fanState ?? false) ? "🌀 RUNNING" : "OFF")")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor((telemetry.fanState ?? false) ? Color.orange : Color.gray)
            }
        }
        .padding(18)
        .background(Color(red: 20/255, green: 30/255, blue: 54/255))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isBad ? Color.red.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1.5)
        )
    }
    
    // 2. FIRE EMERGENCY DETECTION CARD (FLAME SENSOR - LARGE & PROMINENT)
    var fireEmergencyCard: some View {
        let isFire = telemetry.fireDetected ?? false
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Text(isFire ? "🔥" : "🛡️")
                        .font(.title2)
                    Text("FIRE EMERGENCY SYSTEM")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("FLAME SENSOR")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isFire ? Color.red : Color.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isFire ? Color.red : Color.green).opacity(0.15))
                    .cornerRadius(6)
            }
            
            if isFire {
                // ACTIVE FIRE EMERGENCY STATE
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text("🔥")
                            .font(.system(size: 40))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FIRE DETECTED!")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(Color(red: 230/255, green: 57/255, blue: 70/255))
                            Text("EMERGENCY SUPPRESSION ACTIVE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Label("5V Water Pump: ACTIVE", systemImage: "drop.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.cyan)
                        Spacer()
                        Label("Ventilation: STOPPED", systemImage: "fan.slash.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.orange)
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
            } else {
                // NORMAL SAFE STATE
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Text("🛡️")
                            .font(.system(size: 36))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("STATUS: CLEAR")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(Color(red: 6/255, green: 214/255, blue: 160/255))
                            Text("NO FIRE OR FLAME DETECTED")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    HStack {
                        Text("💧 Water Pump: STANDBY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Sensor Monitoring: ACTIVE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.green)
                    }
                }
            }
        }
        .padding(18)
        .background(
            isFire ?
            Color(red: 45/255, green: 15/255, blue: 22/255) :
            Color(red: 20/255, green: 30/255, blue: 54/255)
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isFire ? Color.red : Color.white.opacity(0.08), lineWidth: isFire ? 2 : 1.5)
        )
        .shadow(color: isFire ? Color.red.opacity(0.4) : Color.clear, radius: 12)
    }
    
    // 3. TEMPERATURE CARD (DHT)
    var temperatureCard: some View {
        let temp = telemetry.temperature ?? 0.0
        let isHot = temp >= 35.0
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("🌡️")
                        .font(.title2)
                    Text("ROOM TEMPERATURE")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("DHT SENSOR")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(6)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", temp))
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(isHot ? Color.red : Color.white)
                Text("°C CELSIUS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
            }
            
            // Thermal Level Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    Capsule()
                        .fill(isHot ? Color.red : Color.orange)
                        .frame(width: min(max(CGFloat(temp) / 50.0 * geo.size.width, 0), geo.size.width), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text(isHot ? "⚠️ HIGH TEMPERATURE ALERT" : "OPTIMAL THERMAL COMFORT")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isHot ? Color.red : Color.green)
                Spacer()
                Text("Auto Fan: \(isHot ? "ON" : "OFF")")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isHot ? Color.orange : Color.gray)
            }
        }
        .padding(18)
        .background(Color(red: 20/255, green: 30/255, blue: 54/255))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isHot ? Color.red.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
        )
    }
    
    // 4. HUMIDITY CARD (DHT)
    var humidityCard: some View {
        let hum = telemetry.humidity ?? 0.0
        let isHigh = hum >= 75.0
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("💧")
                        .font(.title2)
                    Text("RELATIVE HUMIDITY")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("DHT SENSOR")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 72/255, green: 202/255, blue: 228/255).opacity(0.15))
                    .cornerRadius(6)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", hum))
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(isHigh ? Color.orange : Color(red: 72/255, green: 202/255, blue: 228/255))
                Text("% MOISTURE")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
            }
            
            // Moisture Level Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    Capsule()
                        .fill(Color(red: 72/255, green: 202/255, blue: 228/255))
                        .frame(width: min(max(CGFloat(hum) / 100.0 * geo.size.width, 0), geo.size.width), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text(isHigh ? "⚠️ ELEVATED MOISTURE LEVEL" : "NORMAL HUMIDITY LEVEL")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isHigh ? Color.orange : Color.green)
                Spacer()
                Text("Status: \(isHigh ? "HUMID" : "COMFORTABLE")")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gray)
            }
        }
        .padding(18)
        .background(Color(red: 20/255, green: 30/255, blue: 54/255))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
        )
    }
    
    // 5. SOUND & NOISE LEVEL CARD (SOUND SENSOR)
    var soundNoiseCard: some View {
        let sound = telemetry.sound ?? 0
        let isLoud = sound >= 2400
        let isQuiet = sound <= 300 && sound > 0
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("🔊")
                        .font(.title2)
                    Text("ACOUSTIC SOUND LEVEL")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("SOUND SENSOR")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.purple)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.15))
                    .cornerRadius(6)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(sound)")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(isLoud ? Color.red : (isQuiet ? Color.yellow : Color(red: 6/255, green: 214/255, blue: 160/255)))
                Text("AMP UNITS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
            }
            
            // Sound Amplitude Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    Capsule()
                        .fill(isLoud ? Color.red : (isQuiet ? Color.yellow : Color(red: 6/255, green: 214/255, blue: 160/255)))
                        .frame(width: min(max(CGFloat(sound) / 3500.0 * geo.size.width, 0), geo.size.width), height: 8)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text(isLoud ? "⚠️ HIGH NOISE DETECTED!" : (isQuiet ? "🤫 SILENT ROOM" : "OPTIMAL SOUND LEVEL"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isLoud ? Color.red : (isQuiet ? Color.yellow : Color.green))
                Spacer()
                Text("Auto Window: \((telemetry.windowClosed ?? false) ? "🪟 CLOSED" : "🪟 OPEN")")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor((telemetry.windowClosed ?? false) ? Color.orange : Color.green)
            }
        }
        .padding(18)
        .background(Color(red: 20/255, green: 30/255, blue: 54/255))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(isLoud ? Color.red.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
        )
    }
    
    // =========================================================================
    // 2 LARGE MANUAL CONTROL CARDS (LIGHT & DOOR)
    // =========================================================================
    
    // ROOM LIGHT CARD
    var roomLightCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(lightSwitch ? Color.yellow.opacity(0.25) : Color.white.opacity(0.08))
                    .frame(width: 58, height: 58)
                Text(lightSwitch ? "💡" : "🔦")
                    .font(.system(size: 30))
                    .shadow(color: lightSwitch ? Color.yellow.opacity(0.8) : Color.clear, radius: 8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("ROOM LIGHTING (LED)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(lightSwitch ? "STATUS: ILLUMINATED (ON)" : "STATUS: TURNED OFF")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(lightSwitch ? Color.yellow : Color.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $lightSwitch)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color.yellow))
                .scaleEffect(1.15)
                .onChange(of: lightSwitch) { _, val in
                    if isUserToggling { sendControl(device: "light", state: val ? "1" : "0") }
                }
        }
        .padding(18)
        .background(Color(red: 22/255, green: 32/255, blue: 58/255))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(lightSwitch ? Color.yellow.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
        )
    }
    
    // ROOM DOOR CARD
    var roomDoorCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(doorSwitch ? Color(red: 6/255, green: 214/255, blue: 160/255).opacity(0.25) : Color.white.opacity(0.08))
                    .frame(width: 58, height: 58)
                Text(doorSwitch ? "🚪" : "🔒")
                    .font(.system(size: 30))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("ROOM DOOR (SERVO)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(doorSwitch ? "STATUS: OPEN (UNLOCKED)" : "STATUS: CLOSED (LOCKED)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(doorSwitch ? Color.green : Color.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $doorSwitch)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color(red: 6/255, green: 214/255, blue: 160/255)))
                .scaleEffect(1.15)
                .onChange(of: doorSwitch) { _, val in
                    if isUserToggling { sendControl(device: "door", state: val ? "1" : "0") }
                }
        }
        .padding(18)
        .background(Color(red: 22/255, green: 32/255, blue: 58/255))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(doorSwitch ? Color.green.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
        )
    }
    
    // ACTUATOR STATUS OVERVIEW SUMMARY
    var actuatorSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AUTOMATION RELAYS & SERVOS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .tracking(1)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🌀 Ventilation Fan:")
                        .foregroundColor(.white)
                    Spacer()
                    Text((telemetry.fanState ?? false) ? "ACTIVE (RUNNING)" : "OFF (IDLE)")
                        .bold()
                        .foregroundColor((telemetry.fanState ?? false) ? Color.orange : Color.gray)
                }
                HStack {
                    Text("🪟 Window Noise Servo:")
                        .foregroundColor(.white)
                    Spacer()
                    Text((telemetry.windowClosed ?? false) ? "CLOSED (NOISE MITIGATION)" : "OPEN (NORMAL)")
                        .bold()
                        .foregroundColor((telemetry.windowClosed ?? false) ? Color.orange : Color.green)
                }
                HStack {
                    Text("💧 Submersible Water Pump:")
                        .foregroundColor(.white)
                    Spacer()
                    Text((telemetry.pumpState ?? false) ? "ACTIVE (SPRAYING)" : "OFF (STANDBY)")
                        .bold()
                        .foregroundColor((telemetry.pumpState ?? false) ? Color.cyan : Color.gray)
                }
            }
            .font(.system(size: 12))
        }
        .padding(16)
        .background(Color(red: 16/255, green: 24/255, blue: 44/255))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    // =========================================================================
    // NETWORKING HELPERS
    // =========================================================================
    func fetchData() {
        guard !savedIp.isEmpty else { return }
        let urlString = savedIp.hasPrefix("http://") ? "\(savedIp)/api/data" : "http://\(savedIp)/api/data"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.5
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let decoded = try? JSONDecoder().decode(TelemetryData.self, from: data) {
                    self.telemetry = decoded
                    self.isConnected = true
                    self.connectionStatus = "🟢 Connected to \(savedIp)"
                    
                    isUserToggling = false
                    self.lightSwitch = decoded.lightState ?? false
                    self.doorSwitch = decoded.doorOpen ?? false
                    isUserToggling = true
                    
                    // Audio siren feedback on alert
                    if let alert = decoded.activeAlert, alert != "NONE" {
                        AudioServicesPlaySystemSound(1005)
                    }
                } else {
                    self.isConnected = false
                    self.connectionStatus = "🔴 Disconnected from \(savedIp)"
                }
            }
        }.resume()
    }
    
    func sendControl(device: String, state: String) {
        guard !savedIp.isEmpty else { return }
        let base = savedIp.hasPrefix("http://") ? savedIp : "http://\(savedIp)"
        guard let url = URL(string: "\(base)/api/control?device=\(device)&state=\(state)") else { return }
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 1.5
        URLSession.shared.dataTask(with: req).resume()
    }
    
    func airStatusText(_ val: Int) -> String {
        if val >= 1500 { return "HAZARDOUS AIR (FAN ON)" }
        if val >= 900 { return "MODERATE AIR QUALITY" }
        return "CLEAN & PURE AIR"
    }
    
    func airStatusColor(_ val: Int) -> Color {
        if val >= 1500 { return .red }
        if val >= 900 { return .orange }
        return .green
    }
}

// =============================================================================
// FUTURISTIC STARTING ANIMATION VIEW (SPLASH SCREEN)
// =============================================================================
struct SplashAnimationView: View {
    var onFinished: () -> Void
    
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0.0
    @State private var ringScale1: CGFloat = 0.5
    @State private var ringScale2: CGFloat = 0.5
    @State private var ringOpacity: Double = 0.8
    @State private var rotationDegree: Double = 0
    @State private var textTracking: CGFloat = 14
    @State private var textOpacity: Double = 0.0
    @State private var progressWidth: CGFloat = 0
    @State private var statusIndex: Int = 0
    
    let statusMessages = [
        "Initializing Sensor Core...",
        "Calibrating Environment AI...",
        "Connecting Health Stream...",
        "AIRZEN System Ready"
    ]
    
    var body: some View {
        ZStack {
            // High-Tech Cyber Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 4/255, green: 8/255, blue: 22/255),
                    Color(red: 8/255, green: 16/255, blue: 38/255),
                    Color(red: 16/255, green: 28/255, blue: 56/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // CENTER LOGO WITH PULSING CYBERNETIC RADAR RINGS
                ZStack {
                    // Outer Expanding Glow Ring
                    Circle()
                        .stroke(
                            Color(red: 72/255, green: 202/255, blue: 228/255).opacity(ringOpacity * 0.35),
                            lineWidth: 1.5
                        )
                        .frame(width: 230, height: 230)
                        .scaleEffect(ringScale2)
                    
                    // Middle Pulsing Ring
                    Circle()
                        .stroke(
                            Color(red: 6/255, green: 214/255, blue: 160/255).opacity(ringOpacity * 0.55),
                            lineWidth: 2
                        )
                        .frame(width: 175, height: 175)
                        .scaleEffect(ringScale1)
                    
                    // Rotating Cybernetic Dash Ring
                    Circle()
                        .stroke(
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 12])
                        )
                        .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255).opacity(0.75))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(rotationDegree))
                    
                    // Central Glowing App Logo
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 108, height: 108)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(color: Color(red: 72/255, green: 202/255, blue: 228/255).opacity(0.7), radius: 22)
                        .shadow(color: Color(red: 6/255, green: 214/255, blue: 160/255).opacity(0.4), radius: 32)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                
                // TITLE & SUBTITLE WITH CINEMATIC REVEAL
                VStack(spacing: 8) {
                    Text("AIRZEN")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255))
                        .tracking(textTracking)
                        .opacity(textOpacity)
                        .shadow(color: Color(red: 72/255, green: 202/255, blue: 228/255).opacity(0.6), radius: 12)
                    
                    Text("AIR INTELLIGENCE & POLLUTION REGULATION NETWORK")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(Color.gray.opacity(0.9))
                        .tracking(0.8)
                        .opacity(textOpacity)
                }
                .padding(.top, 10)
                
                Spacer()
                
                // DIAGNOSTIC STATUS LOADER
                VStack(spacing: 10) {
                    Text(statusMessages[statusIndex])
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255))
                        .opacity(textOpacity)
                        .animation(.easeInOut(duration: 0.25), value: statusIndex)
                    
                    // Loading Progress Bar
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 220, height: 4.5)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 6/255, green: 214/255, blue: 160/255),
                                        Color(red: 72/255, green: 202/255, blue: 228/255)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: progressWidth, height: 4.5)
                            .shadow(color: Color(red: 72/255, green: 202/255, blue: 228/255).opacity(0.8), radius: 6)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            runAnimationSequence()
        }
    }
    
    // MARK: - Animation Timeline
    private func runAnimationSequence() {
        // Continuous Radar Rotation
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            rotationDegree = 360
        }
        
        // Phase 1: Logo & Rings Pop
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Expanding Outer Rings
        withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: true)) {
            ringScale1 = 1.08
            ringScale2 = 1.15
            ringOpacity = 0.3
        }
        
        // Phase 2: Cinematic Text Tracking Animation
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            textTracking = 3
            textOpacity = 1.0
        }
        
        // Phase 3: Progressive Diagnostic Checks
        withAnimation(.easeInOut(duration: 2.2).delay(0.1)) {
            progressWidth = 220
        }
        
        // Status Step 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            statusIndex = 1
        }
        // Status Step 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            statusIndex = 2
        }
        // Status Step 3 (Ready)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            statusIndex = 3
            AudioServicesPlaySystemSound(1519) // Gentle iOS Haptic Pop
        }
        
        // Phase 4: Seamless Dismiss into Dashboard
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onFinished()
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Cross-Platform View Extensions
extension View {
    @ViewBuilder
    func ipKeyboardModifiers() -> some View {
        #if os(iOS)
        self
            .keyboardType(.numbersAndPunctuation)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
        #else
        self
        #endif
    }
}
