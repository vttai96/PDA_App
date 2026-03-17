import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _prefsKey = 'API_BASE_URL';

  /// Giá trị mặc định khi chưa có URL nào được lưu.
  static const _defaultUrl = 'http://127.0.0.1:8088';

  /// URL hiện tại đang sử dụng – có thể thay đổi runtime.
  static String baseUrl = _defaultUrl;

  /// Đọc URL đã lưu từ SharedPreferences (gọi 1 lần trong main).
  static Future<void> loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.trim().isNotEmpty) {
      baseUrl = saved.trim();
    }
  }

  /// Lưu URL mới vào SharedPreferences và cập nhật biến runtime.
  static Future<void> updateBaseUrl(String url) async {
    final trimmed = url.trim();
    baseUrl = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, trimmed);
  }

  /// Headers chung cho mọi lời gọi API – giá trị x-header được đọc từ .env.
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'x-header': (dotenv.env['X_HEADER'] ?? '').trim(),
  };

  static Uri endpoint(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }
}
