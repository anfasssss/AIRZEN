package com.airzen.app;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.NotificationCompat;

import com.google.android.material.switchmaterial.SwitchMaterial;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends AppCompatActivity {

    private static final String CHANNEL_ID = "airzen_alerts";
    private static final String PREFS_NAME = "AirzenPrefs";
    private static final String KEY_ESP_IP = "esp_ip";

    // UI Elements
    private EditText etEspIp;
    private Button btnConnect;
    private TextView tvAlertBanner;
    private TextView tvAirQuality, tvAirStatus;
    private TextView tvSound, tvSoundStatus;
    private TextView tvTemperature, tvHumidity;
    private TextView tvVentFan, tvWindowStatus, tvWaterPump, tvFlameStatus;
    private SwitchMaterial switchLight, switchDoor;

    // State & Helpers
    private TextView tvConnectionStatus;
    private String espBaseUrl = "";
    private int consecutiveFailures = 0;
    private boolean isConnected = false;
    private final ExecutorService networkExecutor = Executors.newSingleThreadExecutor();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private AlarmSoundManager alarmSoundManager;
    private NotificationManager notificationManager;
    private boolean isPolling = false;
    private boolean userInteracting = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        alarmSoundManager = new AlarmSoundManager(this);
        notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        createNotificationChannel();

        initViews();
        loadSavedIp();
        setupListeners();
        startDataPolling();
    }

    private void initViews() {
        etEspIp = findViewById(R.id.etEspIp);
        btnConnect = findViewById(R.id.btnConnect);
        tvConnectionStatus = findViewById(R.id.tvConnectionStatus);
        tvAlertBanner = findViewById(R.id.tvAlertBanner);
        tvAirQuality = findViewById(R.id.tvAirQuality);
        tvAirStatus = findViewById(R.id.tvAirStatus);
        tvSound = findViewById(R.id.tvSound);
        tvSoundStatus = findViewById(R.id.tvSoundStatus);
        tvTemperature = findViewById(R.id.tvTemperature);
        tvHumidity = findViewById(R.id.tvHumidity);
        tvVentFan = findViewById(R.id.tvVentFan);
        tvWindowStatus = findViewById(R.id.tvWindowStatus);
        tvWaterPump = findViewById(R.id.tvWaterPump);
        tvFlameStatus = findViewById(R.id.tvFlameStatus);
        switchLight = findViewById(R.id.switchLight);
        switchDoor = findViewById(R.id.switchDoor);
    }

    private void loadSavedIp() {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        String savedIp = prefs.getString(KEY_ESP_IP, "");
        if (savedIp.isEmpty() || "airzen.local".equalsIgnoreCase(savedIp)) {
            etEspIp.setText("");
            espBaseUrl = "";
            tvConnectionStatus.setText("🔴 Enter ESP32 IP address above & tap Connect");
            tvConnectionStatus.setTextColor(Color.parseColor("#F77F00"));
        } else {
            etEspIp.setText(savedIp);
            updateBaseUrl(savedIp);
        }
    }

    private void updateBaseUrl(String input) {
        if (!input.startsWith("http://") && !input.startsWith("https://")) {
            espBaseUrl = "http://" + input.trim();
        } else {
            espBaseUrl = input.trim();
        }
        if (espBaseUrl.endsWith("/")) {
            espBaseUrl = espBaseUrl.substring(0, espBaseUrl.length() - 1);
        }
    }

    private void setupListeners() {
        btnConnect.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String ip = etEspIp.getText().toString().trim();
                if (ip.isEmpty()) {
                    Toast.makeText(MainActivity.this, "Please enter ESP32 IP address (e.g. 192.168.43.50)", Toast.LENGTH_LONG).show();
                    return;
                }
                if ("airzen.local".equalsIgnoreCase(ip) || ip.endsWith(".local")) {
                    Toast.makeText(MainActivity.this, "⚠️ Note: On Hotspot, 'airzen.local' won't work. Please use number IP (e.g. 192.168.43.xxx)!", Toast.LENGTH_LONG).show();
                }
                updateBaseUrl(ip);
                getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
                        .edit()
                        .putString(KEY_ESP_IP, ip)
                        .apply();
                tvConnectionStatus.setText("🟡 Connecting to " + espBaseUrl + "...");
                tvConnectionStatus.setTextColor(Color.parseColor("#F77F00"));
                consecutiveFailures = 0;
                fetchTelemetryData();
            }
        });

        // Light control switch
        switchLight.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (userInteracting) {
                    sendControlCommand("light", isChecked ? "1" : "0");
                }
            }
        });

        // Door control switch
        switchDoor.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (userInteracting) {
                    sendControlCommand("door", isChecked ? "1" : "0");
                }
            }
        });
    }

    private void startDataPolling() {
        isPolling = true;
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                if (!isPolling) return;
                fetchTelemetryData();
                mainHandler.postDelayed(this, 1000); // 1-second refresh
            }
        });
    }

    private void fetchTelemetryData() {
        if (espBaseUrl == null || espBaseUrl.isEmpty()) return;

        networkExecutor.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    URL url = new URL(espBaseUrl + "/api/data");
                    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                    conn.setRequestMethod("GET");
                    conn.setConnectTimeout(2000);
                    conn.setReadTimeout(2000);

                    int responseCode = conn.getResponseCode();
                    if (responseCode == 200) {
                        BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
                        StringBuilder sb = new StringBuilder();
                        String line;
                        while ((line = reader.readLine()) != null) {
                            sb.append(line);
                        }
                        reader.close();
                        final String jsonStr = sb.toString();

                        mainHandler.post(new Runnable() {
                            @Override
                            public void run() {
                                consecutiveFailures = 0;
                                isConnected = true;
                                tvConnectionStatus.setText("🟢 Connected to " + espBaseUrl);
                                tvConnectionStatus.setTextColor(Color.parseColor("#06D6A0"));
                                updateUIFromJson(jsonStr);
                            }
                        });
                    } else {
                        handleConnectionFailure("Server returned HTTP " + responseCode);
                    }
                    conn.disconnect();
                } catch (final Exception e) {
                    handleConnectionFailure(e.getMessage() != null ? e.getMessage() : "Timeout / Host unreachable");
                }
            }
        });
    }

    private void handleConnectionFailure(final String errorMsg) {
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                consecutiveFailures++;
                if (consecutiveFailures >= 2) {
                    isConnected = false;
                    tvConnectionStatus.setText("🔴 Cannot connect to " + espBaseUrl + "\nVerify ESP32 is on Hotspot and check IP address.");
                    tvConnectionStatus.setTextColor(Color.parseColor("#E63946"));
                }
            }
        });
    }

    private void updateUIFromJson(String jsonStr) {
        try {
            JSONObject obj = new JSONObject(jsonStr);

            int air = obj.optInt("airQuality", 0);
            int sound = obj.optInt("sound", 0);
            double temp = obj.optDouble("temperature", 0.0);
            double hum = obj.optDouble("humidity", 0.0);
            boolean fire = obj.optBoolean("fireDetected", false);
            boolean fan = obj.optBoolean("fanState", false);
            boolean pump = obj.optBoolean("pumpState", false);
            boolean light = obj.optBoolean("lightState", false);
            boolean window = obj.optBoolean("windowClosed", false);
            boolean door = obj.optBoolean("doorOpen", false);
            String activeAlert = obj.optString("activeAlert", "NONE");
            String alertMsg = obj.optString("alertMessage", "System Normal");

            // Air Quality
            tvAirQuality.setText(String.valueOf(air));
            if (air >= 1500) {
                tvAirStatus.setText("HAZARDOUS!");
                tvAirStatus.setTextColor(Color.parseColor("#E63946"));
            } else if (air >= 900) {
                tvAirStatus.setText("MODERATE");
                tvAirStatus.setTextColor(Color.parseColor("#F77F00"));
            } else {
                tvAirStatus.setText("CLEAN / PURE");
                tvAirStatus.setTextColor(Color.parseColor("#06D6A0"));
            }

            // Sound
            tvSound.setText(String.valueOf(sound));
            if (sound >= 2400) {
                tvSoundStatus.setText("HIGH NOISE!");
                tvSoundStatus.setTextColor(Color.parseColor("#E63946"));
            } else if (sound <= 300) {
                tvSoundStatus.setText("SILENT");
                tvSoundStatus.setTextColor(Color.parseColor("#F77F00"));
            } else {
                tvSoundStatus.setText("OPTIMAL");
                tvSoundStatus.setTextColor(Color.parseColor("#06D6A0"));
            }

            // Climate
            tvTemperature.setText(String.format("%.1f °C", temp));
            tvHumidity.setText(String.format("%.1f %%", hum));

            // Actuators
            tvVentFan.setText(fan ? "🌀 Ventilation Fan: ACTIVE (ON)" : "🌀 Ventilation Fan: OFF (IDLE)");
            tvWindowStatus.setText(window ? "🪟 Window: CLOSED (NOISE MITIGATION)" : "🪟 Window: OPEN");
            tvWaterPump.setText(pump ? "💧 Water Pump: ACTIVE (RUNNING)" : "💧 Water Pump: OFF");
            tvFlameStatus.setText(fire ? "🔥 Flame Status: FIRE DETECTED!!" : "🔥 Flame Status: CLEAR");
            tvFlameStatus.setTextColor(fire ? Color.parseColor("#E63946") : Color.parseColor("#06D6A0"));

            // Switches (Prevent triggering listener when syncing from ESP32 state)
            userInteracting = false;
            if (switchLight.isChecked() != light) switchLight.setChecked(light);
            if (switchDoor.isChecked() != door) switchDoor.setChecked(door);
            userInteracting = true;

            // Alarm & Notification Handling
            if (!"NONE".equalsIgnoreCase(activeAlert)) {
                tvAlertBanner.setVisibility(View.VISIBLE);
                tvAlertBanner.setText(alertMsg);
                boolean isFire = "FIRE_EMERGENCY".equalsIgnoreCase(activeAlert);
                tvAlertBanner.setBackgroundColor(isFire ? Color.parseColor("#E63946") : Color.parseColor("#F77F00"));

                // Play Audio Siren & Vibrate Phone
                alarmSoundManager.startAlarm(isFire);
                showPushNotification(alertMsg, isFire);
            } else {
                tvAlertBanner.setVisibility(View.GONE);
                alarmSoundManager.stopAlarm();
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void sendControlCommand(final String device, final String state) {
        networkExecutor.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    URL url = new URL(espBaseUrl + "/api/control?device=" + device + "&state=" + state);
                    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                    conn.setRequestMethod("POST");
                    conn.setConnectTimeout(1500);
                    conn.getResponseCode();
                    conn.disconnect();
                } catch (Exception ignored) {}
            }
        });
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "AIRZEN Emergency Alerts",
                    NotificationManager.IMPORTANCE_HIGH);
            channel.setDescription("Push notifications and loud audible alarms for AIRZEN system");
            channel.enableVibration(true);
            if (notificationManager != null) {
                notificationManager.createNotificationChannel(channel);
            }
        }
    }

    private void showPushNotification(String message, boolean isFire) {
        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle(isFire ? "🔥 AIRZEN FIRE EMERGENCY" : "⚠️ AIRZEN SYSTEM ALERT")
                .setContentText(message)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setAutoCancel(true);

        if (notificationManager != null) {
            notificationManager.notify(101, builder.build());
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        isPolling = false;
        if (alarmSoundManager != null) {
            alarmSoundManager.stopAlarm();
        }
        networkExecutor.shutdown();
    }
}
