import SwiftUI
import AudioToolbox
import AVFoundation
import Combine

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
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Main Dashboard View
            mainDashboard
                .opacity(isShowingSplash ? 0 : 1)
            
            // Starting Splash Animation Screen
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
    
    // MARK: - Main Dashboard
    var mainDashboard: some View {
        ZStack {
            Color(red: 11/255, green: 19/255, blue: 43/255).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    
                    // HEADER
                    VStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 76, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: Color(red: 72/255, green: 202/255, blue: 228/255).opacity(0.4), radius: 10)
                        
                        Text("AIRZEN")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255))
                            .tracking(2)
                        
                        Text("SMART HEALTHCARE & ENVIRONMENT SYSTEM")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.gray)
                    }
                    .padding(.top, 8)
                    
                    // IP CONNECTION BAR
                    VStack(spacing: 8) {
                        HStack {
                            TextField("ESP32 IP (e.g. 192.168.43.45)", text: $ipInput)
                                .padding(10)
                                .background(Color(red: 28/255, green: 37/255, blue: 65/255))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .keyboardType(.numbersAndPunctuation)
                                .autocapitalization(.none)
                            
                            Button(action: {
                                savedIp = ipInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                connectionStatus = "🟡 Connecting..."
                                fetchData()
                            }) {
                                Text("Connect")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 11/255, green: 19/255, blue: 43/255))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(red: 72/255, green: 202/255, blue: 228/255))
                                    .cornerRadius(8)
                            }
                        }
                        
                        Text(connectionStatus)
                            .font(.caption)
                            .foregroundColor(isConnected ? Color.green : Color.orange)
                    }
                    .padding(12)
                    .background(Color(red: 20/255, green: 28/255, blue: 50/255))
                    .cornerRadius(12)
                    
                    // EMERGENCY BANNER
                    if let alert = telemetry.activeAlert, alert != "NONE" {
                        VStack(spacing: 4) {
                            Text(alert == "FIRE_EMERGENCY" ? "🔥 CRITICAL EMERGENCY ALERT" : "⚠️ SYSTEM WARNING")
                                .font(.headline)
                                .bold()
                            Text(telemetry.alertMessage ?? "Alert Active!")
                                .font(.subheadline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(alert == "FIRE_EMERGENCY" ? Color.red : Color.orange)
                        .cornerRadius(12)
                    }
                    
                    // SENSOR CARDS ROW 1: AIR QUALITY & SOUND
                    HStack(spacing: 12) {
                        // Air Quality Card
                        VStack(alignment: .leading, spacing: 6) {
                            Text("AIR QUALITY")
                                .font(.caption2)
                                .bold()
                                .foregroundColor(.gray)
                            
                            Text("\(telemetry.airQuality ?? 0)")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255))
                            
                            Text(airStatusText(telemetry.airQuality ?? 0))
                                .font(.caption2)
                                .bold()
                                .foregroundColor(airStatusColor(telemetry.airQuality ?? 0))
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 28/255, green: 37/255, blue: 65/255))
                        .cornerRadius(12)
                        
                        // Sound Noise Card
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SOUND LEVEL")
                                .font(.caption2)
                                .bold()
                                .foregroundColor(.gray)
                            
                            Text("\(telemetry.sound ?? 0)")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255))
                            
                            Text((telemetry.sound ?? 0) > 2400 ? "LOUD NOISE!" : "OPTIMAL")
                                .font(.caption2)
                                .bold()
                                .foregroundColor((telemetry.sound ?? 0) > 2400 ? .red : .green)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 28/255, green: 37/255, blue: 65/255))
                        .cornerRadius(12)
                    }
                    
                    // SENSOR CARDS ROW 2: CLIMATE
                    HStack(spacing: 12) {
                        // Temperature
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TEMPERATURE")
                                .font(.caption2)
                                .bold()
                                .foregroundColor(.gray)
                            
                            Text(String(format: "%.1f °C", telemetry.temperature ?? 0.0))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 28/255, green: 37/255, blue: 65/255))
                        .cornerRadius(12)
                        
                        // Humidity
                        VStack(alignment: .leading, spacing: 6) {
                            Text("HUMIDITY")
                                .font(.caption2)
                                .bold()
                                .foregroundColor(.gray)
                            
                            Text(String(format: "%.1f %%", telemetry.humidity ?? 0.0))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 28/255, green: 37/255, blue: 65/255))
                        .cornerRadius(12)
                    }
                    
                    // MANUAL CONTROLS
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MANUAL ROOM CONTROLS")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 12) {
                            // Light Toggle Card
                            VStack(spacing: 8) {
                                Text("💡 Room Light")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                Toggle("", isOn: $lightSwitch)
                                    .labelsHidden()
                                    .onChange(of: lightSwitch) { _, val in
                                        if isUserToggling { sendControl(device: "light", state: val ? "1" : "0") }
                                    }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 28/255, green: 37/255, blue: 65/255))
                            .cornerRadius(12)
                            
                            // Door Toggle Card
                            VStack(spacing: 8) {
                                Text("🚪 Room Door")
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                Toggle("", isOn: $doorSwitch)
                                    .labelsHidden()
                                    .onChange(of: doorSwitch) { _, val in
                                        if isUserToggling { sendControl(device: "door", state: val ? "1" : "0") }
                                    }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 28/255, green: 37/255, blue: 65/255))
                            .cornerRadius(12)
                        }
                    }
                    
                    // ACTUATOR STATUS OVERVIEW
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AUTOMATION ACTUATORS")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("🌀 **Ventilation Fan:** \((telemetry.fanState ?? false) ? "ACTIVE (ON)" : "OFF")")
                            Text("🪟 **Window (Noise Auto):** \((telemetry.windowClosed ?? false) ? "CLOSED (NOISE)" : "OPEN")")
                            Text("💧 **Water Pump:** \((telemetry.pumpState ?? false) ? "ACTIVE" : "OFF")")
                            Text("🔥 **Flame Sensor:** \((telemetry.fireDetected ?? false) ? "FIRE DETECTED!" : "CLEAR")")
                                .foregroundColor((telemetry.fireDetected ?? false) ? .red : .green)
                        }
                        .font(.footnote)
                        .foregroundColor(.white)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 28/255, green: 37/255, blue: 65/255))
                    .cornerRadius(12)
                    
                }
                .padding()
            }
        }
    }
    
    // MARK: - Networking
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
                    self.connectionStatus = "🟢 Connected (\(savedIp))"
                    
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
        if val >= 1500 { return "HAZARDOUS!" }
        if val >= 900 { return "MODERATE" }
        return "CLEAN / PURE"
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
    @State private var textTracking: CGFloat = 12
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
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 7/255, green: 13/255, blue: 31/255),
                    Color(red: 11/255, green: 19/255, blue: 43/255),
                    Color(red: 28/255, green: 37/255, blue: 65/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // CENTER LOGO WITH ROTATING RADAR RINGS
                ZStack {
                    // Outer Expanding Glow Ring
                    Circle()
                        .stroke(
                            Color(red: 72/255, green: 202/255, blue: 228/255).opacity(ringOpacity * 0.3),
                            lineWidth: 1.5
                        )
                        .frame(width: 220, height: 220)
                        .scaleEffect(ringScale2)
                    
                    // Middle Pulsing Ring
                    Circle()
                        .stroke(
                            Color(red: 6/255, green: 214/255, blue: 160/255).opacity(ringOpacity * 0.5),
                            lineWidth: 2
                        )
                        .frame(width: 170, height: 170)
                        .scaleEffect(ringScale1)
                    
                    // Rotating Cybernetic Dash Ring
                    Circle()
                        .stroke(
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 12])
                        )
                        .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255).opacity(0.7))
                        .frame(width: 136, height: 136)
                        .rotationEffect(.degrees(rotationDegree))
                    
                    // Central Glowing App Logo
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 104, height: 104)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color(red: 72/255, green: 202/255, blue: 228/255).opacity(0.7), radius: 20)
                        .shadow(color: Color(red: 6/255, green: 214/255, blue: 160/255).opacity(0.4), radius: 30)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                
                // TITLE & SUBTITLE WITH CINEMATIC REVEAL
                VStack(spacing: 6) {
                    Text("AIRZEN")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255))
                        .tracking(textTracking)
                        .opacity(textOpacity)
                        .shadow(color: Color(red: 72/255, green: 202/255, blue: 228/255).opacity(0.5), radius: 10)
                    
                    Text("SMART HEALTHCARE & ENVIRONMENT NETWORK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.gray.opacity(0.9))
                        .opacity(textOpacity)
                }
                .padding(.top, 10)
                
                Spacer()
                
                // DIAGNOSTIC STATUS LOADER
                VStack(spacing: 8) {
                    Text(statusMessages[statusIndex])
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(red: 72/255, green: 202/255, blue: 228/255))
                        .opacity(textOpacity)
                        .animation(.easeInOut(duration: 0.25), value: statusIndex)
                    
                    // Loading Progress Bar
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 200, height: 4)
                        
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
                            .frame(width: progressWidth, height: 4)
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
            progressWidth = 200
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
            AudioServicesPlaySystemSound(1519) // Subtle iOS Haptic Pop
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
