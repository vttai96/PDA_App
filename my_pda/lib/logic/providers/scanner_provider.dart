import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_datawedge/flutter_datawedge.dart';
import '../../data/services/datawedge_service.dart';

class ScannerProvider extends ChangeNotifier {
  ScannerProvider() {
    _initScanner();
  }

  StreamSubscription<ScanResult>? _scanSubscription;
  String _lastScannedCode = '';
  String get lastScannedCode => _lastScannedCode;
  Stream<ScanResult> get scanStream => DataWedgeService.instance.scanStream;

  void _initScanner() {
    if (DataWedgeService.instance.isSupported) {
      _scanSubscription = DataWedgeService.instance.scanStream.listen((result) {
        final code = result.data.trim();
        if (code.isNotEmpty) {
          _lastScannedCode = code;
          notifyListeners();
        }
      });
    }
  }

  void clearLastScan() {
    _lastScannedCode = '';
    notifyListeners();
  }

  Future<void> softTrigger() async {
    await DataWedgeService.instance.softTrigger();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }
}

