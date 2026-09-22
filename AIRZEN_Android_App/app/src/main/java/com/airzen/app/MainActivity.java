package com.airzen.app;

import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
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
import android.view.animation.LinearInterpolator;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
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

    // Splash Animation Views
    private FrameLayout layoutSplash;
    private ImageView ivRadarOuter, ivRadarInner, ivSplashLogo;
    private TextView tvSplashStatus, tvSplashPercent;
    private ProgressBar pbSplash;

    // UI Elements - Connection & Alerts
    private EditText etEspIp;
    private Button btnConnect;
    private TextView tvConnectionStatus;
    private TextView tvAlertBanner;

    // UI Elements - Fire Emergency Card
    private CardView cardFireStatus;
    private LinearLayout layoutFireInner;
    private TextView tvFireIcon, tvFireBadge, tvFireDesc, tvWaterPump;

    // UI Elements - Sensor Cards
    private TextView tvAirQuality, tvAirStatus;
    private ProgressBar pbAirQuality;
    private TextView tvTemperature, tvTempStatus, tvVentFan;
    private TextView tvHumidity, tvHumidityStatus;
    private TextView tvSound, tvSoundStatus, tvWindowStatus;

    // UI Elements - Room Controls
    private SwitchMaterial switchLight, switchDoor;
    private TextView tvLightState, tvDoorState;

    // State & Network Helpers
    private String espBaseUrl = "";
    private int consecutiveFailures = 0;
    private boolean isConnected = false;
    private final ExecutorService networkExecutor = Executors.newSingleThreadExecutor();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private AlarmSoundManager alarmSoundManager;
    private NotificationManager notificationManager;
    private boolean isPolling = false;
    private boolean userInteracting = false;
    private boolean isManuallyMuted = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        alarmSoundManager = new AlarmSoundManager(this);
        notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        createNotificationChannel();

        initViews();
        startStartupAnimation();
        loadSavedIp();
        setupListeners();
        startDataPolling();
    }

    private void initViews() {
        // Splash Views
        layoutSplash = findViewById(R.id.layoutSplash);
        ivRadarOuter = findViewById(R.id.ivRadarOuter);
        ivRadarInner = findViewById(R.id.ivRadarInner);
        ivSplashLogo = findViewById(R.id.ivSplashLogo);
        tvSplashStatus = findViewById(R.id.tvSplashStatus);
        tvSplashPercent = findViewById(R.id.tvSplashPercent);
        pbSplash = findViewById(R.id.pbSplash);

        // Connection
        etEspIp = findViewById(R.id.etEspIp);
        btnConnect = findViewById(R.id.btnConnect);
        tvConnectionStatus = findViewById(R.id.tvConnectionStatus);
        tvAlertBanner = findViewById(R.id.tvAlertBanner);

        // Fire Card
        cardFireStatus = findViewById(R.id.cardFireStatus);
        layoutFireInner = findViewById(R.id.layoutFireInner);
        tvFireIcon = findViewById(R.id.tvFireIcon);
        tvFireBadge = findViewById(R.id.tvFireBadge);
        tvFireDesc = findViewById(R.id.tvFireDesc);
        tvWaterPump = findViewById(R.id.tvWaterPump);

        // Air Quality
        tvAirQuality = findViewById(R.id.tvAirQuality);
        tvAirStatus = findViewById(R.id.tvAirStatus);
        pbAirQuality = findViewById(R.id.pbAirQuality);

        // Temperature & Fan
        tvTemperature = findViewById(R.id.tvTemperature);
        tvTempStatus = findViewById(R.id.tvTempStatus);
        tvVentFan = findViewById(R.id.tvVentFan);

        // Humidity
        tvHumidity = findViewById(R.id.tvHumidity);
        tvHumidityStatus = findViewById(R.id.tvHumidityStatus);

        // Sound & Window
        tvSound = findViewById(R.id.tvSound);
        tvSoundStatus = findViewById(R.id.tvSoundStatus);
        tvWindowStatus = findViewById(R.id.tvWindowStatus);

        // Controls
        switchLight = findViewById(R.id.switchLight);
        tvLightState = findViewById(R.id.tvLightState);
        switchDoor = findViewById(R.id.switchDoor);
        tvDoorState = findViewById(R.id.tvDoorState);
    }

    private void startStartupAnimation() {
        if (layoutSplash == null) return;

        // Continuous rotation for radar rings
        ObjectAnimator outerAnim = ObjectAnimator.ofFloat(ivRadarOuter, "rotation", 0f, 360f);
        outerAnim.setDuration(8000);
        outerAnim.setRepeatCount(ValueAnimator.INFINITE);
        outerAnim.setInterpolator(new LinearInterpolator());
        outerAnim.start();

        ObjectAnimator innerAnim = ObjectAnimator.ofFloat(ivRadarInner, "rotation", 0f, -360f);
        innerAnim.setDuration(6000);
        innerAnim.setRepeatCount(ValueAnimator.INFINITE);
        innerAnim.setInterpolator(new LinearInterpolator());
        innerAnim.start();

        // Logo subtle pulse
        ivSplashLogo.setScaleX(0.85f);
        ivSplashLogo.setScaleY(0.85f);
        ivSplashLogo.animate().scaleX(1.05f).scaleY(1.05f).setDuration(1200).start();

        // Step 1: Scanning Sensors (400ms)
        mainHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (pbSplash != null) pbSplash.setProgress(35);
                if (tvSplashStatus != null) tvSplashStatus.setText("Scanning hardware sensors...");
                if (tvSplashPercent != null) tvSplashPercent.setText("35%");
            }
        }, 400);

        // Step 2: Calibrating (1100ms)
        mainHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (pbSplash != null) pbSplash.setProgress(70);
                if (tvSplashStatus != null) tvSplashStatus.setText("Calibrating MQ-135 & DHT11...");
                if (tvSplashPercent != null) tvSplashPercent.setText("70%");
            }
        }, 1100);

        // Step 3: Ready (1800ms)
        mainHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (pbSplash != null) pbSplash.setProgress(100);
                if (tvSplashStatus != null) tvSplashStatus.setText("AIRZEN Station Ready!");
                if (tvSplashPercent != null) tvSplashPercent.setText("100%");
            }
        }, 1800);

        // Step 4: Dismiss splash with smooth cinematic fade (2400ms)
        mainHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (layoutSplash != null) {
                    layoutSplash.animate()
                            .alpha(0f)
                            .setDuration(500)
                            .withEndAction(new Runnable() {
                                @Override
                                public void run() {
                                    layoutSplash.setVisibility(View.GONE);
                                }
                            })
                            .start();
                }
            }
        }, 2400);
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
                    Toast.makeText(MainActivity.this, "⚠️ Note: On Hotspot, please use number IP (e.g. 192.168.43.xxx)!", Toast.LENGTH_LONG).show();
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
                    tvLightState.setText(isChecked ? "LIGHT IS ON (ILLUMINATING)" : "LIGHT IS OFF");
                }
            }
        });

        // Door control switch
        switchDoor.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (userInteracting) {
                    sendControlCommand("door", isChecked ? "1" : "0");
                    tvDoorState.setText(isChecked ? "DOOR IS OPEN (UNLOCKED)" : "DOOR IS CLOSED (LOCKED)");
                }
            }
        });

        // Banner click to silence/mute continuous siren
        tvAlertBanner.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                isManuallyMuted = true;
                if (alarmSoundManager != null) {
                    alarmSoundManager.stopAlarm();
                }
                tvAlertBanner.setText(tvAlertBanner.getText().toString().replace("  [Tap to Silence 🔕]", "") + "  🔕 (Silenced)");
                Toast.makeText(MainActivity.this, "Alarm Silenced for this event", Toast.LENGTH_SHORT).show();
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

            // 1. MEGA FIRE EMERGENCY CARD
            if (fire) {
                layoutFireInner.setBackgroundResource(R.drawable.bg_card_fire_hazard);
                tvFireIcon.setText("🔥");
                tvFireBadge.setText("CRITICAL: FIRE DETECTED!");
                tvFireBadge.setTextColor(Color.parseColor("#FF4D6D"));
                tvFireDesc.setText("URGENT: Active flame detected! Automated fire-suppression protocol engaged.");
                tvWaterPump.setText("💧 5V Water Pump: ACTIVE (EXTINGUISHING)");
                tvWaterPump.setTextColor(Color.parseColor("#FF4D6D"));
            } else {
                layoutFireInner.setBackgroundResource(R.drawable.bg_card_fire_safe);
                tvFireIcon.setText("🛡️");
                tvFireBadge.setText("SAFE (NO FIRE DETECTED)");
                tvFireBadge.setTextColor(Color.parseColor("#06D6A0"));
                tvFireDesc.setText("Continuous flame sensor monitoring active. Environment secure.");
                tvWaterPump.setText(pump ? "💧 Water Pump: ACTIVE (RUNNING)" : "💧 Water Pump (Relay 2): OFF (STANDBY)");
                tvWaterPump.setTextColor(Color.parseColor("#48CAE4"));
            }

            // 2. Air Quality (MQ-135)
            tvAirQuality.setText(String.valueOf(air));
            if (pbAirQuality != null) {
                pbAirQuality.setProgress(Math.min(air, 4000));
            }
            if (air >= 1500) {
                tvAirStatus.setText("HAZARDOUS AIR!");
                tvAirStatus.setBackgroundResource(R.drawable.bg_badge_red);
                tvAirStatus.setTextColor(Color.parseColor("#E63946"));
            } else if (air >= 900) {
                tvAirStatus.setText("MODERATE");
                tvAirStatus.setBackgroundResource(R.drawable.bg_badge_orange);
                tvAirStatus.setTextColor(Color.parseColor("#F77F00"));
            } else {
                tvAirStatus.setText("CLEAN & FRESH");
                tvAirStatus.setBackgroundResource(R.drawable.bg_badge_green);
                tvAirStatus.setTextColor(Color.parseColor("#06D6A0"));
            }

            // 3. Temperature & Ventilation Fan
            tvTemperature.setText(String.format("%.1f °C", temp));
            if (temp >= 35.0) {
                tvTempStatus.setText("HIGH HEAT");
                tvTempStatus.setBackgroundResource(R.drawable.bg_badge_red);
                tvTempStatus.setTextColor(Color.parseColor("#E63946"));
            } else {
                tvTempStatus.setText("NORMAL");
                tvTempStatus.setBackgroundResource(R.drawable.bg_badge_green);
                tvTempStatus.setTextColor(Color.parseColor("#06D6A0"));
            }
            tvVentFan.setText(fan ? "🌀 Ventilation Fan: ACTIVE (AUTO COOLING)" : "🌀 Ventilation Fan (Relay 1): OFF (IDLE)");
            tvVentFan.setTextColor(fan ? Color.parseColor("#06D6A0") : Color.parseColor("#8D99AE"));

            // 4. Humidity
            tvHumidity.setText(String.format("%.1f %%", hum));
            if (hum > 75.0) {
                tvHumidityStatus.setText("HIGH MOISTURE");
                tvHumidityStatus.setBackgroundResource(R.drawable.bg_badge_orange);
                tvHumidityStatus.setTextColor(Color.parseColor("#F77F00"));
            } else {
                tvHumidityStatus.setText("COMFORTABLE");
                tvHumidityStatus.setBackgroundResource(R.drawable.bg_badge_cyan);
                tvHumidityStatus.setTextColor(Color.parseColor("#48CAE4"));
            }

            // 5. Sound & Window
            tvSound.setText(String.valueOf(sound));
            if (sound >= 2400) {
                tvSoundStatus.setText("HIGH NOISE!");
                tvSoundStatus.setBackgroundResource(R.drawable.bg_badge_red);
                tvSoundStatus.setTextColor(Color.parseColor("#E63946"));
            } else if (sound <= 300) {
                tvSoundStatus.setText("SILENT");
                tvSoundStatus.setBackgroundResource(R.drawable.bg_badge_orange);
                tvSoundStatus.setTextColor(Color.parseColor("#F77F00"));
            } else {
                tvSoundStatus.setText("OPTIMAL");
                tvSoundStatus.setBackgroundResource(R.drawable.bg_badge_green);
                tvSoundStatus.setTextColor(Color.parseColor("#06D6A0"));
            }
            tvWindowStatus.setText(window ? "🪟 Window Servo (GPIO 18): CLOSED (NOISE MITIGATION)" : "🪟 Window Servo (GPIO 18): OPEN");
            tvWindowStatus.setTextColor(window ? Color.parseColor("#F77F00") : Color.parseColor("#8D99AE"));

            // 6. Actuator Switches Sync
            userInteracting = false;
            if (switchLight.isChecked() != light) switchLight.setChecked(light);
            tvLightState.setText(light ? "LIGHT IS ON (ILLUMINATING)" : "LIGHT IS OFF");

            if (switchDoor.isChecked() != door) switchDoor.setChecked(door);
            tvDoorState.setText(door ? "DOOR IS OPEN (UNLOCKED)" : "DOOR IS CLOSED (LOCKED)");
            userInteracting = true;

            // 7. Alarm & Notification Handling
            if (!"NONE".equalsIgnoreCase(activeAlert)) {
                tvAlertBanner.setVisibility(View.VISIBLE);
                boolean isFire = "FIRE_EMERGENCY".equalsIgnoreCase(activeAlert);
                tvAlertBanner.setBackgroundResource(isFire ? R.drawable.bg_badge_red : R.drawable.bg_badge_orange);
                if (isManuallyMuted) {
                    tvAlertBanner.setText(alertMsg + "  🔕 (Silenced)");
                } else {
                    tvAlertBanner.setText(alertMsg + "  [Tap to Silence 🔕]");
                    // Continuous Audio Siren & Vibrate Phone
                    alarmSoundManager.startAlarm(isFire);
                }
                showPushNotification(alertMsg, isFire);
            } else {
                isManuallyMuted = false;
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
                .setSmallIcon(R.drawable.ic_launcher)
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
