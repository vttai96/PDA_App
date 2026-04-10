import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:my_pda/presentation/screens/scanner/barcode_success_screen.dart';
import 'package:my_pda/data/services/datawedge_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final bool fromDashboard;
  final String? ingredientName;

  const BarcodeScannerScreen({
    super.key,
    this.fromDashboard = false,
    this.ingredientName,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _scanDebounce;
  StreamSubscription? _scanSubscription;
  bool _isProcessingScan = false;

  bool get _useDataWedge => DataWedgeService.instance.isSupported;

  String get _displayIngredientName {
    final name = widget.ingredientName?.trim() ?? '';
    return name.isEmpty ? 'Nguyên liệu đang quét' : name;
  }

  @override
  void initState() {
    super.initState();
    _startListeningScanner();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      Future.delayed(const Duration(milliseconds: 100), () {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      });
    });

    _controller.addListener(() {
      final text = _controller.text;
      if (text.isEmpty || _isProcessingScan) return;

      _scanDebounce?.cancel();
      _scanDebounce = Timer(const Duration(milliseconds: 180), () {
        if (!mounted || _controller.text.isEmpty || _isProcessingScan) return;
        _isProcessingScan = true;
        _handleScanned(_controller.text);
      });
    });
  }

  @override
  void dispose() {
    _scanDebounce?.cancel();
    _scanSubscription?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startListeningScanner() {
    if (!_useDataWedge) return;

    _scanSubscription = DataWedgeService.instance.scanStream.listen((result) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) return;
      if (_isProcessingScan) return;
      final code = result.data.trim();
      if (code.isEmpty) return;
      _isProcessingScan = true;
      _handleScanned(code);
    });
  }

  Future<void> _handleScanned(String raw) async {
    final scanned = raw.trim();
    if (scanned.isEmpty) {
      _isProcessingScan = false;
      return;
    }

    if (widget.fromDashboard) {
      Navigator.of(context).pop(scanned);
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            BarcodeSuccessScreen(ingredientName: _displayIngredientName),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      Navigator.of(context).pop(true);
    } else {
      _controller.clear();
      _focusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      _isProcessingScan = false;
    }
  }

  Future<void> _triggerScan() async {
    if (_useDataWedge) {
      await DataWedgeService.instance.softTrigger();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang quét lại...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Quét Mã Vạch',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_useDataWedge)
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        width: 1,
                        height: 1,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          showCursor: false,
                          onSubmitted: _handleScanned,
                          keyboardType: TextInputType.visiblePassword,
                          enableInteractiveSelection: false,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF1F2937),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: 120,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Đưa mã vạch vào khung quét',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF374151)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _triggerScan,
                child: const Text(
                  'Quét lại',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
