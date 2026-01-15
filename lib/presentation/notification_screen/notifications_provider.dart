import 'package:flutter/cupertino.dart';

class NotificationsProvider with ChangeNotifier {
  int _totalNotifications = 0;

  int get totalNotifications => _totalNotifications;

  void setTotalNotifications(int total) {
    _totalNotifications = total;

    notifyListeners();
  }
}
