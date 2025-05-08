// lib/presentation/call_module/providers/media_provider.dart
import 'package:flutter/foundation.dart';

/// Provider to manage media settings
class MediaProvider extends ChangeNotifier {
  bool _isVideoCallActive = false;
  bool _isLocalVideoEnabled = true;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  bool _isLocalVideoFullScreen = false;
  bool _isUsingLowerVideoQuality = false;

  // Getters
  bool get isVideoCallActive => _isVideoCallActive;
  bool get isLocalVideoEnabled => _isLocalVideoEnabled;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isFrontCamera => _isFrontCamera;
  bool get isLocalVideoFullScreen => _isLocalVideoFullScreen;
  bool get isUsingLowerVideoQuality => _isUsingLowerVideoQuality;

  // Initialize with defaults
  MediaProvider({
    bool isVideoCall = false,
  }) {
    _isVideoCallActive = isVideoCall;
    _isSpeakerOn = isVideoCall; // Turn on speaker by default for video calls
  }

  // Setters
  void setVideoCallActive(bool value) {
    if (_isVideoCallActive != value) {
      _isVideoCallActive = value;
      notifyListeners();
    }
  }

  void setLocalVideoEnabled(bool value) {
    if (_isLocalVideoEnabled != value) {
      _isLocalVideoEnabled = value;
      notifyListeners();
    }
  }

  void setMuted(bool value) {
    if (_isMuted != value) {
      _isMuted = value;
      notifyListeners();
    }
  }

  void setSpeakerOn(bool value) {
    if (_isSpeakerOn != value) {
      _isSpeakerOn = value;
      notifyListeners();
    }
  }

  void setFrontCamera(bool value) {
    if (_isFrontCamera != value) {
      _isFrontCamera = value;
      notifyListeners();
    }
  }

  void setLocalVideoFullScreen(bool value) {
    if (_isLocalVideoFullScreen != value) {
      _isLocalVideoFullScreen = value;
      notifyListeners();
    }
  }

  void setUsingLowerVideoQuality(bool value) {
    if (_isUsingLowerVideoQuality != value) {
      _isUsingLowerVideoQuality = value;
      notifyListeners();
    }
  }

  // Toggle functions
  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  void toggleLocalVideo() {
    _isLocalVideoEnabled = !_isLocalVideoEnabled;
    notifyListeners();
  }

  void toggleCamera() {
    _isFrontCamera = !_isFrontCamera;
    notifyListeners();
  }

  void toggleLocalVideoFullScreen() {
    _isLocalVideoFullScreen = !_isLocalVideoFullScreen;
    notifyListeners();
  }
}

