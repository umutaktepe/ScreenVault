package com.example.screenvault

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Request maximum refresh rate (e.g. 120Hz) on high-refresh-rate displays
        // to prevent Xiaomi HyperOS from dropping to 60Hz during keyboard transitions
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val disp = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                display
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay
            }
            val modes = disp?.supportedModes
            val maxMode = modes?.maxByOrNull { it.refreshRate }
            if (maxMode != null) {
                val params = window.attributes
                params.preferredDisplayModeId = maxMode.modeId
                window.attributes = params
            }
        }

        // Enable edge-to-edge window insets handling for smooth system keyboard animations
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        }
    }
}
