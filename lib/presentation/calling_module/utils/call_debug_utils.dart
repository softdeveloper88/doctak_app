// lib/presentation/calling_module/utils/call_debug_utils.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/call_state.dart';

/// Debug utility class for the calling module
class CallDebugUtils {
  static final CallDebugUtils _instance = CallDebugUtils._internal();
  factory CallDebugUtils() => _instance;
  CallDebugUtils._internal();

  // Debug flags
  static const bool _isDebugMode = kDebugMode;
  static const bool _verboseLogging = true;

  // Log levels
  static const String _levelInfo = '📋';
  static const String _levelWarning = '⚠️';
  static const String _levelError = '❌';
  static const String _levelSuccess = '✅';
  static const String _levelDebug = '🔍';

  /// Log with timestamp and level
  static void _log(String level, String category, String message) {
    if (!_isDebugMode) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    print('[$timestamp] $level [$category] $message');
  }

  /// Log info message
  static void logInfo(String category, String message) {
    _log(_levelInfo, category, message);
  }

  /// Log warning message
  static void logWarning(String category, String message) {
    _log(_levelWarning, category, message);
  }

  /// Log error message
  static void logError(String category, String message) {
    _log(_levelError, category, message);
  }

  /// Log success message
  static void logSuccess(String category, String message) {
    _log(_levelSuccess, category, message);
  }

  /// Log debug message (only if verbose logging is enabled)
  static void logDebug(String category, String message) {
    if (_verboseLogging) {
      _log(_levelDebug, category, message);
    }
  }

  /// Log call state changes
  static void logCallStateChange(CallState oldState, CallState newState) {
    if (!_isDebugMode) return;

    logInfo('CALL_STATE', 'State change detected:');

    if (oldState.connectionState != newState.connectionState) {
      logInfo(
        'CALL_STATE',
        '  Connection: ${oldState.connectionState} → ${newState.connectionState}',
      );
    }

    if (oldState.isLocalUserJoined != newState.isLocalUserJoined) {
      logInfo(
        'CALL_STATE',
        '  Local user joined: ${oldState.isLocalUserJoined} → ${newState.isLocalUserJoined}',
      );
    }

    if (oldState.isRemoteUserJoined != newState.isRemoteUserJoined) {
      logInfo(
        'CALL_STATE',
        '  Remote user joined: ${oldState.isRemoteUserJoined} → ${newState.isRemoteUserJoined}',
      );
    }

    if (oldState.remoteUid != newState.remoteUid) {
      logInfo(
        'CALL_STATE',
        '  Remote UID: ${oldState.remoteUid} → ${newState.remoteUid}',
      );
    }

    if (oldState.isLocalVideoEnabled != newState.isLocalVideoEnabled) {
      logInfo(
        'CALL_STATE',
        '  Local video: ${oldState.isLocalVideoEnabled} → ${newState.isLocalVideoEnabled}',
      );
    }

    if (oldState.isMuted != newState.isMuted) {
      logInfo(
        'CALL_STATE',
        '  Muted: ${oldState.isMuted} → ${newState.isMuted}',
      );
    }

    if (oldState.networkQuality != newState.networkQuality) {
      logInfo(
        'CALL_STATE',
        '  Network quality: ${oldState.networkQuality} → ${newState.networkQuality}',
      );
    }
  }

  /// Log system information
  static void logSystemInfo() {
    if (!_isDebugMode) return;

    logInfo('SYSTEM', 'Platform: ${Platform.operatingSystem}');
    logInfo('SYSTEM', 'Platform version: ${Platform.operatingSystemVersion}');
    logInfo('SYSTEM', 'Dart version: ${Platform.version}');
    logInfo('SYSTEM', 'Debug mode: $_isDebugMode');
    logInfo('SYSTEM', 'Verbose logging: $_verboseLogging');
  }

  /// Log call initialization details
  static void logCallInitialization({
    required String callId,
    required String localUserId,
    required String remoteUserId,
    required bool isVideoCall,
    required bool isIncoming,
  }) {
    logInfo('CALL_INIT', 'Initializing call:');
    logInfo('CALL_INIT', '  Call ID: $callId');
    logInfo('CALL_INIT', '  Local user: $localUserId');
    logInfo('CALL_INIT', '  Remote user: $remoteUserId');
    logInfo('CALL_INIT', '  Type: ${isVideoCall ? 'VIDEO' : 'AUDIO'}');
    logInfo(
      'CALL_INIT',
      '  Direction: ${isIncoming ? 'INCOMING' : 'OUTGOING'}',
    );
    logSystemInfo();
  }

  /// Log Agora engine events
  static void logAgoraEvent(String eventName, Map<String, dynamic> data) {
    if (!_isDebugMode) return;

    logDebug('AGORA_EVENT', '$eventName:');
    data.forEach((key, value) {
      logDebug('AGORA_EVENT', '  $key: $value');
    });
  }

  /// Log network statistics
  static void logNetworkStats({
    required int txBitrate,
    required int rxBitrate,
    required int txPacketLossRate,
    required int rxPacketLossRate,
    required int rtt,
  }) {
    if (!_verboseLogging) return;

    logDebug('NETWORK', 'Network statistics:');
    logDebug('NETWORK', '  TX Bitrate: ${txBitrate}kbps');
    logDebug('NETWORK', '  RX Bitrate: ${rxBitrate}kbps');
    logDebug('NETWORK', '  TX Packet Loss: $txPacketLossRate%');
    logDebug('NETWORK', '  RX Packet Loss: $rxPacketLossRate%');
    logDebug('NETWORK', '  RTT: ${rtt}ms');
  }

  /// Log call timeline events
  static void logCallTimeline(String event, {Map<String, dynamic>? data}) {
    logInfo('TIMELINE', '$event${data != null ? ' - $data' : ''}');
  }

  /// Generate call diagnostic report
  static String generateCallDiagnosticReport(CallState callState) {
    final buffer = StringBuffer();
    final timestamp = DateTime.now().toIso8601String();

    buffer.writeln('=== CALL DIAGNOSTIC REPORT ===');
    buffer.writeln('Generated: $timestamp');
    buffer.writeln(
      'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    );
    buffer.writeln('');

    buffer.writeln('CALL STATE:');
    buffer.writeln('  Call ID: ${callState.callId}');
    buffer.writeln('  Call Type: ${callState.callType}');
    buffer.writeln('  Connection State: ${callState.connectionState}');
    buffer.writeln('  Local User Joined: ${callState.isLocalUserJoined}');
    buffer.writeln('  Remote User Joined: ${callState.isRemoteUserJoined}');
    buffer.writeln('  Remote UID: ${callState.remoteUid}');
    buffer.writeln('  Call Duration: ${callState.formattedCallDuration}');
    buffer.writeln('');

    buffer.writeln('MEDIA STATE:');
    buffer.writeln('  Local Video Enabled: ${callState.isLocalVideoEnabled}');
    buffer.writeln('  Is Muted: ${callState.isMuted}');
    buffer.writeln('  Speaker On: ${callState.isSpeakerOn}');
    buffer.writeln('  Front Camera: ${callState.isFrontCamera}');
    buffer.writeln(
      '  Local Video Full Screen: ${callState.isLocalVideoFullScreen}',
    );
    buffer.writeln('  Controls Visible: ${callState.isControlsVisible}');
    buffer.writeln('');

    buffer.writeln('NETWORK STATE:');
    buffer.writeln('  Network Quality: ${callState.networkQuality}');
    buffer.writeln('  Local User Speaking: ${callState.isLocalUserSpeaking}');
    buffer.writeln('  Remote User Speaking: ${callState.isRemoteUserSpeaking}');
    buffer.writeln(
      '  Using Lower Video Quality: ${callState.isUsingLowerVideoQuality}',
    );
    buffer.writeln('');

    buffer.writeln('=== END DIAGNOSTIC REPORT ===');

    return buffer.toString();
  }

  /// Log diagnostic report
  static void logDiagnosticReport(CallState callState) {
    if (!_isDebugMode) return;

    final report = generateCallDiagnosticReport(callState);
    print(report);
  }

  /// Start call performance monitoring
  static Timer startPerformanceMonitoring(CallState Function() getCallState) {
    return Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isDebugMode) {
        timer.cancel();
        return;
      }

      final callState = getCallState();

      // Auto-cancel timer if call has ended or failed
      if (callState.connectionState == CallConnectionState.disconnected ||
          callState.connectionState == CallConnectionState.failed) {
        logDebug(
          'PERFORMANCE',
          'Call disconnected, stopping performance monitoring',
        );
        timer.cancel();
        return;
      }

      logDebug('PERFORMANCE', 'Call status check:');
      logDebug('PERFORMANCE', '  Connection: ${callState.connectionState}');
      logDebug('PERFORMANCE', '  Duration: ${callState.formattedCallDuration}');
      logDebug('PERFORMANCE', '  Network: ${callState.networkQuality}');

      // Log potential issues
      if (callState.connectionState == CallConnectionState.reconnecting) {
        logWarning(
          'PERFORMANCE',
          'Call is reconnecting - possible network issues',
        );
      }

      if (callState.networkQuality != null && callState.networkQuality! > 3) {
        logWarning(
          'PERFORMANCE',
          'Poor network quality detected: ${callState.networkQuality}',
        );
      }

      if (!callState.isRemoteUserJoined && callState.callDuration > 30) {
        logWarning('PERFORMANCE', 'Remote user not joined after 30 seconds');
      }
    });
  }

  /// Check for common issues and provide suggestions
  static List<String> analyzeCallIssues(CallState callState) {
    final issues = <String>[];

    // Connection issues
    if (callState.connectionState == CallConnectionState.failed) {
      issues.add('Call connection failed - check network connectivity');
    } else if (callState.connectionState == CallConnectionState.reconnecting) {
      issues.add('Call is reconnecting - network instability detected');
    }

    // Remote user issues
    if (!callState.isRemoteUserJoined && callState.callDuration > 30) {
      issues.add(
        'Remote user has not joined after 30 seconds - possible network or configuration issue',
      );
    }

    // Network quality issues
    if (callState.networkQuality != null && callState.networkQuality! > 4) {
      issues.add(
        'Very poor network quality - consider switching to audio-only call',
      );
    }

    // Media issues
    if (callState.callType == CallType.video &&
        !callState.isLocalVideoEnabled) {
      issues.add(
        'Video call but local video is disabled - check camera permissions',
      );
    }

    return issues;
  }

  /// Log call issues analysis
  static void logCallIssuesAnalysis(CallState callState) {
    final issues = analyzeCallIssues(callState);

    if (issues.isEmpty) {
      logSuccess('ANALYSIS', 'No issues detected');
    } else {
      logWarning('ANALYSIS', 'Issues detected:');
      for (int i = 0; i < issues.length; i++) {
        logWarning('ANALYSIS', '  ${i + 1}. ${issues[i]}');
      }
    }
  }
}
