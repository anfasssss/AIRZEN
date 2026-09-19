package com.airzen.app;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;

/**
 * Generates an audible siren alarm and smartphone vibration without requiring external media assets.
 */
public class AlarmSoundManager {

    private final Context context;
    private final Vibrator vibrator;
    private AudioTrack audioTrack;
    private Thread soundThread;
    private volatile boolean isRunning = false;

    public AlarmSoundManager(Context context) {
        this.context = context;
        this.vibrator = (Vibrator) context.getSystemService(Context.VIBRATOR_SERVICE);
    }

    public synchronized void startAlarm(final boolean isCriticalEmergency) {
        if (isRunning) return;
        isRunning = true;

        // Vibrate phone
        if (vibrator != null && vibrator.hasVibrator()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                long[] pattern = isCriticalEmergency ? new long[]{0, 400, 200, 400} : new long[]{0, 250, 250};
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, 0));
            } else {
                vibrator.vibrate(new long[]{0, 300, 200}, 0);
            }
        }

        // Generate synthetic audio siren in a background thread
        soundThread = new Thread(new Runnable() {
            @Override
            public void run() {
                int sampleRate = 22050;
                int bufferSize = AudioTrack.getMinBufferSize(
                        sampleRate,
                        AudioFormat.CHANNEL_OUT_MONO,
                        AudioFormat.ENCODING_PCM_16BIT);

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    audioTrack = new AudioTrack.Builder()
                            .setAudioAttributes(new AudioAttributes.Builder()
                                    .setUsage(AudioAttributes.USAGE_ALARM)
                                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                    .build())
                            .setAudioFormat(new AudioFormat.Builder()
                                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                                    .setSampleRate(sampleRate)
                                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                                    .build())
                            .setBufferSizeInBytes(bufferSize)
                            .setTransferMode(AudioTrack.MODE_STREAM)
                            .build();
                } else {
                    audioTrack = new AudioTrack(
                            AudioManager.STREAM_ALARM,
                            sampleRate,
                            AudioFormat.CHANNEL_OUT_MONO,
                            AudioFormat.ENCODING_PCM_16BIT,
                            bufferSize,
                            AudioTrack.MODE_STREAM);
                }

                audioTrack.play();

                short[] buffer = new short[bufferSize];
                double phase = 0;
                double freq = 700.0;
                boolean ascending = true;

                while (isRunning) {
                    // Two-tone rising/falling police siren sweep
                    if (isCriticalEmergency) {
                        freq += ascending ? 25.0 : -25.0;
                        if (freq >= 1600.0) ascending = false;
                        if (freq <= 700.0) ascending = true;
                    } else {
                        freq += ascending ? 15.0 : -15.0;
                        if (freq >= 1200.0) ascending = false;
                        if (freq <= 800.0) ascending = true;
                    }

                    for (int i = 0; i < buffer.length; i++) {
                        buffer[i] = (short) (Math.sin(phase) * 32767);
                        phase += 2 * Math.PI * freq / sampleRate;
                        if (phase > 2 * Math.PI) phase -= 2 * Math.PI;
                    }

                    audioTrack.write(buffer, 0, buffer.length);
                }

                try {
                    audioTrack.stop();
                    audioTrack.release();
                } catch (Exception ignored) {}
            }
        });
        soundThread.setPriority(Thread.MAX_PRIORITY);
        soundThread.start();
    }

    public synchronized void stopAlarm() {
        if (!isRunning) return;
        isRunning = false;

        if (vibrator != null) {
            vibrator.cancel();
        }

        if (soundThread != null) {
            try {
                soundThread.interrupt();
            } catch (Exception ignored) {}
            soundThread = null;
        }
    }
}
