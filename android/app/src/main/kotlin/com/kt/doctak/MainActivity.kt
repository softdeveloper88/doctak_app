//package com.kt.doctak
//
//import android.content.Intent
//import android.os.Build
//import android.os.Handler
//import android.os.Looper
//import android.util.Log
//import io.flutter.embedding.android.FlutterActivity
//import io.flutter.embedding.engine.FlutterEngine
//import io.flutter.plugin.common.MethodChannel
//import android.content.Context
//import android.os.Bundle
//import java.util.UUID
//
//class MainActivity: FlutterActivity() {
//    companion object {
//        private const val TAG = "MainActivity"
//        private const val CHANNEL_NAME = "com.kt.doctak/call"
//
//        // To maintain a reference to the latest engine to be used by other components
//        var flutterEngine: FlutterEngine? = null
//    }
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//
//        Log.d(TAG, "Configuring Flutter engine")
//
//        // Store the engine reference for potential use by other components
//        MainActivity.flutterEngine = flutterEngine
//
//        // Set up method channel for call functionality
//        setupCallMethodChannel(flutterEngine)
//
//        // Check if we were launched with call data - might be in onCreate or here
//        val intent = this.intent
//        handleCallLaunchData(intent)
//    }
//
//    override fun onCreate(intent: Bundle?) {
//        super.onCreate(intent)
//        Log.d(TAG, "MainActivity onCreate")
//
//        // Handle call launch data from intent
//        handleCallLaunchData(getIntent())
//    }
//
//    override fun onNewIntent(intent: Intent) {
//        super.onNewIntent(intent)
//        Log.d(TAG, "MainActivity onNewIntent")
//
//        // Update the intent
//        setIntent(intent)
//
//        // Process call data from the new intent
//        handleCallLaunchData(intent)
//    }
//
//    private fun handleCallLaunchData(intent: Intent?) {
//        if (intent == null) {
//            Log.d(TAG, "Intent is null in handleCallLaunchData")
//            return
//        }
//
//        if (intent.getBooleanExtra("call_screen", false)) {
//            Log.d(TAG, "🔔 MainActivity launched with call data")
//
//            // Extract call data
//            val callId = intent.getStringExtra("call_id") ?: ""
//            val callerId = intent.getStringExtra("caller_id") ?: ""
//            val callerName = intent.getStringExtra("caller_name") ?: ""
//            val callerAvatar = intent.getStringExtra("caller_avatar") ?: ""
//            val isVideoCall = intent.getBooleanExtra("is_video_call", false)
//
//            Log.d(TAG, "Call data: id=$callId, name=$callerName, video=$isVideoCall")
//
//            // Wait for Flutter to initialize and then navigate to call screen
//            // We need to delay this slightly to ensure Flutter is ready
//            Handler(Looper.getMainLooper()).postDelayed({
//                try {
//                    Log.d(TAG, "Attempting to navigate to Flutter call screen")
//
//                    // Make sure Flutter engine is available
//                    if (flutterEngine == null) {
//                        Log.e(TAG, "❌ Flutter engine is null, cannot navigate")
//                        return@postDelayed
//                    }
//
//                    // Send the data to Flutter via the method channel
//                    val callData = mapOf(
//                        "call_id" to callId,
//                        "caller_id" to callerId,
//                        "caller_name" to callerName,
//                        "caller_avatar" to callerAvatar,
//                        "is_video_call" to isVideoCall
//                    )
//
//                    Log.d(TAG, "Sending navigation request to Flutter with data: $callData")
//
//                    // Notify Flutter to open the call screen
//                    MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL_NAME)
//                        .invokeMethod("navigateToCallScreen", callData)
//
//                    Log.d(TAG, "✓ Navigation request sent to Flutter")
//                } catch (e: Exception) {
//                    Log.e(TAG, "❌ Error sending call data to Flutter: ${e.message}", e)
//                }
//            }, 1500) // 1.5 second delay to ensure Flutter is initialized
//        } else {
//            Log.d(TAG, "Standard MainActivity launch (no call data)")
//        }
//    }
//
//    private fun setupCallMethodChannel(flutterEngine: FlutterEngine) {
//        Log.d(TAG, "Setting up call method channel")
//
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
//            Log.d(TAG, "Received method call: ${call.method}")
//
//            when (call.method) {
//                "startCall" -> {
//                    try {
//                        // Extract call parameters
//                        val callId = call.argument<String>("callId") ?: UUID.randomUUID().toString()
//                        val receiverId = call.argument<String>("receiverId") ?: ""
//                        val receiverName = call.argument<String>("receiverName") ?: "Unknown"
//                        val receiverAvatar = call.argument<String>("receiverAvatar") ?: ""
//                        val isVideoCall = call.argument<Boolean>("isVideoCall") ?: false
//
//                        Log.d(TAG, "Starting call to $receiverName (ID: $receiverId)")
//
//                        // Start Call Service to handle the call
//                        val intent = Intent(context, CallService::class.java).apply {
//                            action = CallService.ACTION_START_CALL
//                            putExtra(CallService.EXTRA_CALL_ID, callId)
//                            putExtra(CallService.EXTRA_CALLER_ID, receiverId)
//                            putExtra(CallService.EXTRA_CALLER_NAME, receiverName)
//                            putExtra(CallService.EXTRA_CALLER_AVATAR, receiverAvatar)
//                            putExtra(CallService.EXTRA_IS_VIDEO_CALL, isVideoCall)
//                        }
//
//                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                            context.startForegroundService(intent)
//                        } else {
//                            context.startService(intent)
//                        }
//
//                        // Save call state for potential restores
//                        CallBroadcastReceiver().saveCallState(
//                            context,
//                            callId,
//                            receiverId,
//                            receiverName,
//                            receiverAvatar
//                        )
//
//                        result.success(mapOf(
//                            "success" to true,
//                            "callId" to callId
//                        ))
//                    } catch (e: Exception) {
//                        Log.e(TAG, "Error starting call: ${e.message}", e)
//                        result.error("START_CALL_ERROR", e.message, null)
//                    }
//                }
//
//                "endCall" -> {
//                    try {
//                        val callId = call.argument<String>("callId") ?: ""
//
//                        // End the call via service
//                        val intent = Intent(context, CallService::class.java).apply {
//                            action = CallService.ACTION_END_CALL
//                            putExtra(CallService.EXTRA_CALL_ID, callId)
//                        }
//                        context.startService(intent)
//
//                        // Clear saved call state
//                        CallBroadcastReceiver().clearCallState(context)
//
//                        result.success(mapOf("success" to true))
//                    } catch (e: Exception) {
//                        Log.e(TAG, "Error ending call: ${e.message}", e)
//                        result.error("END_CALL_ERROR", e.message, null)
//                    }
//                }
//
//                "acceptCall" -> {
//                    try {
//                        val callId = call.argument<String>("callId") ?: ""
//
//                        // Accept the call via service
//                        val intent = Intent(context, CallService::class.java).apply {
//                            action = CallService.ACTION_ACCEPT_CALL
//                            putExtra(CallService.EXTRA_CALL_ID, callId)
//                        }
//                        context.startService(intent)
//
//                        result.success(mapOf("success" to true))
//                    } catch (e: Exception) {
//                        Log.e(TAG, "Error accepting call: ${e.message}", e)
//                        result.error("ACCEPT_CALL_ERROR", e.message, null)
//                    }
//                }
//
//                "rejectCall" -> {
//                    try {
//                        val callId = call.argument<String>("callId") ?: ""
//
//                        // Reject the call via service
//                        val intent = Intent(context, CallService::class.java).apply {
//                            action = CallService.ACTION_REJECT_CALL
//                            putExtra(CallService.EXTRA_CALL_ID, callId)
//                        }
//                        context.startService(intent)
//
//                        // Clear saved call state
//                        CallBroadcastReceiver().clearCallState(context)
//
//                        result.success(mapOf("success" to true))
//                    } catch (e: Exception) {
//                        Log.e(TAG, "Error rejecting call: ${e.message}", e)
//                        result.error("REJECT_CALL_ERROR", e.message, null)
//                    }
//                }
//
//                "checkCallPermissions" -> {
//                    // This would implement permission checking logic
//                    // For now we just return true as placeholder
//                    result.success(mapOf(
//                        "hasPermissions" to true
//                    ))
//                }
//
//                "getCallSettings" -> {
//                    // Return any device-specific call settings
//                    // This is a placeholder implementation
//                    result.success(mapOf(
//                        "useBluetoothByDefault" to true,
//                        "useSpeakerForVideoByDefault" to true
//                    ))
//                }
//
//                else -> {
//                    result.notImplemented()
//                }
//            }
//        }
//    }
//
//    override fun onDestroy() {
//        try {
//            // Only clear the engine reference if it matches and isn't null
//            if (MainActivity.flutterEngine != null && flutterEngine == MainActivity.flutterEngine) {
//                Log.d(TAG, "Clearing Flutter engine reference in onDestroy")
//                MainActivity.flutterEngine = null
//            }
//        } catch (e: Exception) {
//            Log.e(TAG, "Error in onDestroy: ${e.message}", e)
//        }
//
//        super.onDestroy()
//    }
//}
//package com.kt.doctak
//
//import android.content.Intent
//import android.os.Build
//import android.os.Handler
//import android.os.Looper
//import android.util.Log
package com.kt.doctak
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity(){}

//import io.flutter.plugin.common.MethodChannel
//import android.content.Context
//import android.os.Bundle
//import java.util.UUID
//import java.util.concurrent.atomic.AtomicBoolean
//
//class MainActivity: FlutterActivity() {
//
//}
//    companion object {
//        private const val TAG = "MainActivity"
//        private const val CHANNEL_NAME = "com.kt.doctak/call"
//
//        // To maintain a reference to the latest engine to be used by other components
//        var flutterEngine: FlutterEngine? = null
//    }
//
//    // Navigation queue for handling navigation requests when Flutter isn't ready
//    private val navigationQueue = mutableListOf<Map<String, Any>>()
//    private val isFlutterReady = AtomicBoolean(false)
//
//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)

//
//        Log.d(TAG, "Configuring Flutter engine")
//
//        // Store the engine reference for potential use by other components
//        MainActivity.flutterEngine = flutterEngine
//
//        // Set up method channel for call functionality
//        setupCallMethodChannel(flutterEngine)
//
//        // Check if we were launched with call data
//        val intent = this.intent
//        handleCallLaunchData(intent)
//    }
//
//    override fun onCreate(intent: Bundle?) {
//        super.onCreate(intent)
//        Log.d(TAG, "MainActivity onCreate")
//
//        // Handle call launch data from intent
//        handleCallLaunchData(getIntent())
//    }
//
//    override fun onFlutterUiDisplayed() {
//        super.onFlutterUiDisplayed()
//        Log.d(TAG, "Flutter UI is now displayed, marking as ready")
//        isFlutterReady.set(true)
//
//        // Process any pending navigation requests
//        processNavigationQueue()
//    }
//
//    override fun onResume() {
//        super.onResume()
//        Log.d(TAG, "MainActivity onResume")
//
//        // Ensure the engine reference is up to date
//        if (flutterEngine != null && flutterEngine != MainActivity.flutterEngine) {
//            MainActivity.flutterEngine = flutterEngine
//        }
//    }
//
//    override fun onPostResume() {
//        super.onPostResume()
//        Log.d(TAG, "MainActivity onPostResume")
//
//        // Give Flutter engine a chance to reattach if needed
//        flutterEngine?.lifecycleChannel?.appIsResumed()
//    }
//
//    override fun onNewIntent(intent: Intent) {
//        super.onNewIntent(intent)
//        Log.d(TAG, "MainActivity onNewIntent")
//
//        // Update the intent
//        setIntent(intent)
//
//        // Force redraw of Flutter view when returning to it
//        flutterEngine?.renderer?.let { renderer ->
//            try {
//                Log.d(TAG, "Attempting to refresh Flutter surface")
//                (renderer as? FlutterRenderer)?.let {
//                    // This triggers a surface refresh
//                    Handler(Looper.getMainLooper()).post {
//                        it.surfaceChanged(width = 0, height = 0)
//                        it.surfaceChanged(width = width, height = height)
//                    }
//                }
//            } catch (e: Exception) {
//                Log.e(TAG, "Error refreshing Flutter surface: ${e.message}", e)
//            }
//        }
//
//        // Process call data from the new intent
//        handleCallLaunchData(intent)
//    }
//
//    private fun handleCallLaunchData(intent: Intent?) {
//        if (intent == null) {
//            Log.d(TAG, "Intent is null in handleCallLaunchData")
//            return
//        }
//
//        if (intent.getBooleanExtra("call_screen", false)) {
//            Log.d(TAG, "🔔 MainActivity launched with call data")
//
//            // Extract call data
//            val callId = intent.getStringExtra("call_id") ?: ""
//            val callerId = intent.getStringExtra("caller_id") ?: ""
//            val callerName = intent.getStringExtra("caller_name") ?: ""
//            val callerAvatar = intent.getStringExtra("caller_avatar") ?: ""
//            val isVideoCall = intent.getBooleanExtra("is_video_call", false)
//
//            Log.d(TAG, "Call data: id=$callId, name=$callerName, video=$isVideoCall")
//
//            // Prepare call data map
//            val callData = mapOf(
//                "call_id" to callId,
//                "caller_id" to callerId,
//                "caller_name" to callerName,
//                "caller_avatar" to callerAvatar,
//                "is_video_call" to isVideoCall
//            )
//
//            // Queue the navigation for processing
//            queueNavigationRequest(callData)
//        } else {
//            Log.d(TAG, "Standard MainActivity launch (no call data)")
//        }
//    }
//
//    private fun queueNavigationRequest(callData: Map<String, Any>) {
//        Log.d(TAG, "Queueing navigation request with data: $callData")
//
//        if (isFlutterReady.get() && flutterEngine != null) {
//            // Flutter is ready, send navigation request immediately
//            Log.d(TAG, "Flutter is ready, sending navigation request now")
//            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL_NAME)
//                .invokeMethod("navigateToCallScreen", callData)
//        } else {
//            // Flutter is not ready, add to queue for later processing
//            Log.d(TAG, "Flutter is not ready, adding navigation request to queue")
//            synchronized(navigationQueue) {
//                navigationQueue.add(callData)
//            }
//
//            // Set a fallback timeout to ensure navigation happens even if onFlutterUiDisplayed isn't called
//            Handler(Looper.getMainLooper()).postDelayed({
//                if (!isFlutterReady.get()) {
//                    Log.d(TAG, "Fallback timer: Flutter still not ready, forcing navigation")
//                    isFlutterReady.set(true)
//                    processNavigationQueue()
//                }
//            }, 2000) // 2-second fallback
//        }
//    }
//
//    private fun processNavigationQueue() {
//        if (!isFlutterReady.get() || flutterEngine == null) {
//            Log.d(TAG, "Cannot process navigation queue: Flutter not ready or engine is null")
//            return
//        }
//
//        synchronized(navigationQueue) {
//            if (navigationQueue.isNotEmpty()) {
//                Log.d(TAG, "Processing ${navigationQueue.size} pending navigation requests")
//
//                navigationQueue.forEach { callData ->
//                    try {
//                        Log.d(TAG, "Sending navigation request to Flutter with data: $callData")
//                        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL_NAME)
//                            .invokeMethod("navigateToCallScreen", callData)
//                    } catch (e: Exception) {
//                        Log.e(TAG, "Error sending call data to Flutter: ${e.message}", e)
//                    }
//                }
//                navigationQueue.clear()
//            } else {
//                Log.d(TAG, "Navigation queue is empty, nothing to process")
//            }
//        }
//    }
//
//    private fun setupCallMethodChannel(flutterEngine: FlutterEngine) {
//        Log.d(TAG, "Setting up call method channel")
//
//        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
//            Log.d(TAG, "Received method call: ${call.method}")
//
//            when (call.method) {
//                "startCall" -> {
//                    try {
//                        // Extract call parameters
//                        val callId = call.argument<String>("callId") ?: UUID.randomUUID().toString()
//                        val receiverId = call.argument<String>("receiverId") ?: ""
//                        val receiverName = call.argument<String>("receiverName") ?: "Unknown"
//                        val receiverAvatar = call.argument<String>("receiverAvatar") ?: ""
//                        val isVideoCall = call.argument<Boolean>("isVideoCall") ?: false
//
//                        Log.d(TAG, "Starting call to $receiverName (ID: $receiverId)")
//
//                        // Start Call Service to handle the call
//                        val intent = Intent(context, CallService::class.java).apply {
//                            action = CallService.ACTION_START_CALL
//                            putExtra(CallService.EXTRA_CALL_ID, callId)
//                            putExtra(CallService.EXTRA_CALLER_ID, receiverId)
//                            putExtra(CallService.EXTRA_CALLER_NAME, receiverName)
//                            putExtra(CallService.EXTRA_CALLER_AVATAR, receiverAvatar)
//                            putExtra(CallService.EXTRA_IS_VIDEO_CALL, isVideoCall)
//                        }
//
//                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                            context.startForegroundService(intent)
//                        } else {
//                            context.startService(intent)
//                        }
//
//                        // Save call state for potential restores
//                        CallBroadcastReceiver().saveCallState(
//                            context,
//                            callId,
//                            receiverId,
//                            receiverName,
//                            receiverAvatar
//                        )
//
//                        result.success(mapOf(
//                            "success" to true,
//                            "callId" to callId
//                        ))
//                    } catch (e: Exception) {
//                        Log.e(TAG, "Error starting call: ${e.message}", e)
//                        result.error("START_CALL_ERROR", e.message, null)
//                    }
//                }
//
//                "endCall" -> {
//                    try {
//                        val callId = call.argument<String>("callId") ?: ""
//
//                        // End the call via service
//                        val intent = Intent(context, CallService::class.java).apply {
//                            action = CallService.ACTION_END_CALL
//                            putExtra(CallService.EXTRA_CALL_ID, callId)
//                        }
//                        context.startService(intent)
//
//                        // Clear saved call state
//                        CallBroadcastReceiver().clearCallState(context)
//
//                        result.success(mapOf("success" to true))
//                    } catch (e: Exception) {
//                        Log.e(TAG, "Error ending call: ${e.message}", e)
//                        result.error("END_CALL_ERROR", e.message, null)
//                    }
//                }
//
//                "acceptCall" -> {
//                    try {
//                        val callId = call.argument<String>("callId") ?: ""
//
//                        // Accept the call via service
//                        val intent = Intent(context, CallService::class.java).apply {
//                            action = CallService.ACTION_ACCEPT_CALL
//                            putExtra(CallService.EXTRA_CALL_ID, callId)
//                        }
//                        context.startService(intent)
//
//                        result.success(mapOf("success" to true))
//                    } catch (e: Exception) {
//                        Log.e(TAG, "Error accepting call: ${e.message}", e)
//                        result.error("ACCEPT_CALL_ERROR", e.message, null)
//                    }
//                }
//
//                "rejectCall" -> {
//                    try {
//                        val callId = call.argument<String>("callId") ?: ""
//
//                        // Reject the call via service
//                        val intent = Intent(context, CallService::class.java).apply {
//                            action = CallService.ACTION_REJECT_CALL
//                            putExtra(CallService.EXTRA_CALL_ID, callId)
//                        }
//                        context.startService(intent)
//
//                        // Clear saved call state
//                        CallBroadcastReceiver().clearCallState(context)
//
//                        result.success(mapOf("success" to true))
//                    } catch (e: Exception) {
//                        Log.e(TAG, "Error rejecting call: ${e.message}", e)
//                        result.error("REJECT_CALL_ERROR", e.message, null)
//                    }
//                }
//
//                "checkCallPermissions" -> {
//                    // This would implement permission checking logic
//                    // For now we just return true as placeholder
//                    result.success(mapOf(
//                        "hasPermissions" to true
//                    ))
//                }
//
//                "getCallSettings" -> {
//                    // Return any device-specific call settings
//                    // This is a placeholder implementation
//                    result.success(mapOf(
//                        "useBluetoothByDefault" to true,
//                        "useSpeakerForVideoByDefault" to true
//                    ))
//                }
//
//                else -> {
//                    result.notImplemented()
//                }
//            }
//        }
//    }
//
//    override fun onDestroy() {
//        try {
//            Log.d(TAG, "MainActivity onDestroy")
//
//            // Reset Flutter ready state
//            isFlutterReady.set(false)
//
//            // Clear navigation queue
//            synchronized(navigationQueue) {
//                navigationQueue.clear()
//            }
//
//            // Only clear the engine reference if it matches and isn't null
//            if (MainActivity.flutterEngine != null && flutterEngine == MainActivity.flutterEngine) {
//                Log.d(TAG, "Clearing Flutter engine reference in onDestroy")
//                MainActivity.flutterEngine = null
//            }
//        } catch (e: Exception) {
//            Log.e(TAG, "Error in onDestroy: ${e.message}", e)
//        }
//
//        super.onDestroy()
//    }
//}