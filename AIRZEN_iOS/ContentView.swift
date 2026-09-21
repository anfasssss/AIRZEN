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
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
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
                                    .onChange(of: lightSwitch) { val in
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
                                    .onChange(of: doorSwitch) { val in
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
        .onAppear {
            ipInput = savedIp
            fetchData()
        }
        .onReceive(timer) { _ in
            fetchData()
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
                        AudioServicesPlaySystemSound(1005) // iOS Alert beep
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
