import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  bool _hasInternet = true;

  bool get hasInternet => _hasInternet;

  ConnectivityService() {
    _initializeConnectivity();
  }

  void _initializeConnectivity() async {

    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
// This condition is for demo purposes only to explain every connection type.
// Use conditions which work for your requirements.
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      _updateStatus(ConnectivityResult.mobile);
      // Mobile network available.
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      _updateStatus(ConnectivityResult.wifi);

      // Wi-fi is available.
      // Note for Android:
      // When both mobile and Wi-Fi are turned on system will return Wi-Fi only as active network type
    } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      _updateStatus(ConnectivityResult.ethernet);

      // Ethernet connection available.
    } else if (connectivityResult.contains(ConnectivityResult.vpn)) {
      _updateStatus(ConnectivityResult.vpn);

      // Vpn connection active.
      // Note for iOS and macOS:
      // There is no separate network interface type for [vpn].
      // It returns [other] on any device (also simulator)
    } else if (connectivityResult.contains(ConnectivityResult.bluetooth)) {
      _updateStatus(ConnectivityResult.bluetooth);

      // Bluetooth connection available.
    } else if (connectivityResult.contains(ConnectivityResult.other)) {
      _updateStatus(ConnectivityResult.other);

      // Connected to a network which is not in the above mentioned networks.
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      _updateStatus(ConnectivityResult.none);

      // No available network types
    }

  }

  void _updateStatus(ConnectivityResult result) {
    _hasInternet = result != ConnectivityResult.none;
    notifyListeners();
  }
}
