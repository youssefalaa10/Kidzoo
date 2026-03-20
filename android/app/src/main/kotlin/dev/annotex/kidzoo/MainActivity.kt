package dev.annotex.kidzoo

import android.content.Intent
import android.provider.Settings
import android.speech.tts.TextToSpeech
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "dev.annotex.kidzoo/tts_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openTtsSettings") {
                openTtsSettings()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openTtsSettings() {
        try {
            // Attempt to launch the data installation intent directly
            val installIntent = Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA)
            installIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(installIntent)
        } catch (e: Exception) {
            // Fallback to general TTS settings if the direct installer is not found
            try {
                val intent = Intent("com.android.settings.TTS_SETTINGS")
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(intent)
            } catch (ex: Exception) {
                // Ignore
            }
        }
    }
}
