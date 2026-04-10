import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_datawedge/flutter_datawedge.dart';

class DataWedgeService {
  DataWedgeService._();

  static final DataWedgeService instance = DataWedgeService._();

  static const String _profileName = 'TANTIEN_APP_PROFILE';

  final FlutterDataWedge _dataWedge = FlutterDataWedge();
  StreamSubscription<ScanResult>? _scanSubscription;
  StreamSubscription<ActionResult>? _eventSubscription;
  final StreamController<ScanResult> _scanController =
      StreamController<ScanResult>.broadcast();

  bool _initialized = false;
  Future<void>? _initializingFuture;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // Luồng broadcast dùng chung cho toàn bộ màn hình trong app.
  Stream<ScanResult> get scanStream => _scanController.stream;

  Future<void> initialize() {
    if (!isSupported || _initialized) {
      return Future.value();
    }
    if (_initializingFuture != null) {
      return _initializingFuture!;
    }

    _initializingFuture = _initializeInternal();
    return _initializingFuture!;
  }

  Future<void> _initializeInternal() async {
    try {
      await _dataWedge.initialize();
      await _dataWedge.createDefaultProfile(profileName: _profileName);
      debugPrint('DW(Service): initialized + profile=$_profileName');

      // Theo dõi phản hồi command từ DataWedge để debug.
      _eventSubscription = _dataWedge.onScannerEvent.listen((result) {
        debugPrint(
          'DW(Service) event: command=${result.command} result=${result.result}',
        );
      });

      // Đẩy kết quả quét ra stream dùng chung.
      _scanSubscription = _dataWedge.onScanResult.listen(
        (result) {
          _scanController.add(result);
        },
        onError: (Object error) {
          debugPrint('DW(Service) scan stream error: $error');
        },
      );

      _initialized = true;
    } catch (e) {
      debugPrint('DW(Service) init error: $e');
    }
  }

  Future<void> softTrigger() async {
    await initialize();
    if (!isSupported) return;

    // Gửi lệnh kích hoạt quét mềm (tương đương bấm trigger scanner).
    final actionResult = await _dataWedge.scannerControl(true);
    actionResult.when(
      success: (_) => debugPrint('DW(Service): soft trigger command sent'),
      failure: (error) =>
          debugPrint('DW(Service): soft trigger failed: $error'),
    );
  }

  Future<void> dispose() async {
    await _scanSubscription?.cancel();
    await _eventSubscription?.cancel();
    await _scanController.close();
    _scanSubscription = null;
    _eventSubscription = null;
    _initialized = false;
    _initializingFuture = null;
  }
}
