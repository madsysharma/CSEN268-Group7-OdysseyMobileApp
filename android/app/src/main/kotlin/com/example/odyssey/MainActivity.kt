package com.example.odyssey

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import com.google.android.gms.security.ProviderInstaller
import android.util.Log

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
    }
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Install security provider if needed
        try {
            ProviderInstaller.installIfNeeded(applicationContext)
            Log.d(TAG, "Provider installed successfully.")
        } catch (e: Exception) {
            Log.e(TAG, "Error installing provider: ${e.message}")
        }
    }
}