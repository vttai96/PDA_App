import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/api_config.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isForceUpdate;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isForceUpdate,
  });
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  static UpdateService get instance => _instance;
  UpdateService._internal();

  final Dio _dio = Dio();

  /// Gọi API kiểm tra version
  Future<UpdateInfo> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.0"
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      // Giả sử API endpoint là GET /app/version
      final response = await _dio.get(
        ApiConfig.endpoint('/app/version').toString(),
        options: Options(headers: ApiConfig.defaultHeaders),
      );

      if (response.statusCode == 200 && response.data['Message'] == 'Success') {
        final data = response.data['Data'];
        final String latestVersion = data['latestVersion'] ?? currentVersion;
        final int latestVersionCode = data['versionCode'] ?? currentBuildNumber;
        final String downloadUrl = data['downloadUrl'] ?? '';
        final String releaseNotes = data['releaseNotes'] ?? '';
        final bool isForceUpdate = data['isForceUpdate'] ?? false;

        bool hasUpdate = false;
        if (latestVersionCode > currentBuildNumber) {
          hasUpdate = true;
        } else if (_isVersionGreaterThan(latestVersion, currentVersion)) {
          // Fallback so sánh string version nếu versionCode bằng
          hasUpdate = true;
        }

        return UpdateInfo(
          hasUpdate: hasUpdate,
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
          releaseNotes: releaseNotes,
          isForceUpdate: isForceUpdate,
        );
      }
    } catch (e) {
      debugPrint('Lỗi kiểm tra cập nhật: $e');
    }
    
    // Nếu lỗi hoặc không có bản cập nhật mới
    return UpdateInfo(
      hasUpdate: false,
      latestVersion: '',
      downloadUrl: '',
      releaseNotes: '',
      isForceUpdate: false,
    );
  }

  /// Tải file APK và cài đặt
  Future<void> downloadAndInstall(
    String downloadUrl,
    Function(double progress) onProgress,
  ) async {
    try {
      // Yêu cầu quyền lưu trữ
      if (Platform.isAndroid) {
        if (await Permission.storage.request().isDenied) {
          throw Exception("Bị từ chối quyền truy cập bộ nhớ");
        }
      }

      final dir = await getTemporaryDirectory();
      // Hoặc getExternalStorageDirectory()
      final savePath = '${dir.path}/app_update.apk';

      // Tạo url đúng tuyệt đối
      String url = downloadUrl;
      if (!url.startsWith('http')) {
        final normalizedBase = ApiConfig.baseUrl.endsWith('/')
            ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
            : ApiConfig.baseUrl;
        final normalizedPath = downloadUrl.startsWith('/') ? downloadUrl : '/$downloadUrl';
        url = '$normalizedBase$normalizedPath';
      }

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      // Kích hoạt Intent cài đặt APK
      if (Platform.isAndroid) {
         if (await Permission.requestInstallPackages.request().isDenied) {
            debugPrint("Cảnh báo: Quyền cài đặt ứng dụng bị từ chối");
         }
      }

      final result = await OpenFilex.open(savePath);
      debugPrint("Mở file cài đặt: ${result.message}");

    } catch (e) {
      debugPrint("Lỗi download & cài đặt: $e");
      rethrow;
    }
  }

  // Hàm so sánh version (ví dụ: "1.0.2" so với "1.0.0")
  bool _isVersionGreaterThan(String v1, String v2) {
    try {
      List<int> vals1 = v1.split('.').map((e) => int.parse(e)).toList();
      List<int> vals2 = v2.split('.').map((e) => int.parse(e)).toList();
      for (int i = 0; i < vals1.length; i++) {
        if (i >= vals2.length) return true;
        if (vals1[i] > vals2[i]) return true;
        if (vals1[i] < vals2[i]) return false;
      }
    } catch (e) {
      // Bỏ qua lỗi parse
    }
    return false;
  }
}
