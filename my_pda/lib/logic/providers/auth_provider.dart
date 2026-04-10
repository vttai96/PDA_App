import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, String?>? _user;

  Map<String, String?>? get user => _user;
  bool get isAuthenticated => _user != null;
  String get userRoleLevel => _user?['roleLevel'] ?? '0';

  void login(Map<String, String?> userData) {
    _user = userData;
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
