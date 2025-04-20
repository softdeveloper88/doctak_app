import 'package:flutter/services.dart';

class PlatformChannelService {
  // Updated channel name to match Kotlin files
  static const MethodChannel _channel = MethodChannel('com.kt.doctak/call');

  // Show incoming call UI on the platform side
  Future<void> showIncomingCallScreen({
    required String callId,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    bool isVideoCall = false,
  }) async {
    try {
      await _channel.invokeMethod('showIncomingCall', {
        'callId': callId,
        'callerId': callerId,
        'callerName': callerName,
        'callerAvatar': callerAvatar,
        'isVideoCall': isVideoCall,
      });
    } on PlatformException catch (e) {
      print('Error showing incoming call screen: ${e.message}');
      throw e;
    }
  }

  // Start outgoing call on platform side
  Future<void> startOutgoingCall({
    required String callId,
    required String receiverId,
    required String receiverName,
    required String receiverAvatar,
    bool isVideoCall = false,
  }) async {
    try {
      await _channel.invokeMethod('startCall', {  // Changed to match MainActivity method
        'callId': callId,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'receiverAvatar': receiverAvatar,
        'isVideoCall': isVideoCall,
      });
    } on PlatformException catch (e) {
      print('Error starting outgoing call: ${e.message}');
      throw e;
    }
  }

  // Accept call on platform side
  Future<void> acceptCall(String callId) async {
    try {
      await _channel.invokeMethod('acceptCall', {
        'callId': callId,
      });
    } on PlatformException catch (e) {
      print('Error accepting call: ${e.message}');
      throw e;
    }
  }

  // Reject call on platform side
  Future<void> rejectCall(String callId) async {
    try {
      await _channel.invokeMethod('rejectCall', {
        'callId': callId,
      });
    } on PlatformException catch (e) {
      print('Error rejecting call: ${e.message}');
      throw e;
    }
  }

  // End call on platform side
  Future<void> endCall(String callId) async {
    try {
      await _channel.invokeMethod('endCall', {
        'callId': callId,
      });
    } on PlatformException catch (e) {
      print('Error ending call: ${e.message}');
      throw e;
    }
  }
}