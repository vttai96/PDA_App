import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:my_pda/barcode_fail_screen.dart';
import 'barcode_success_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final bool fromDashboard;

  const BarcodeScannerScreen({super.key, this.fromDashboard = false});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _scanDebounce;
  bool _isProcessingScan = false;

  @override
  void initState() {
    super.initState();
    // Tự động focus để PDA bắn mã như bàn phím
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        // Ẩn bàn phím ảo, chỉ dùng scanner của PDA
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      }
    });

    // Tự động xử lý khi TextField nhận được mã từ scanner (không cần nhấn nút)
    _controller.addListener(() {
      final text = _controller.text;
      if (text.isEmpty || _isProcessingScan) return;

      _scanDebounce?.cancel();
      _scanDebounce = Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        if (_controller.text.isEmpty || _isProcessingScan) return;
        _isProcessingScan = true;
        _handleScanned(_controller.text);
      });
    });
  }

  @override
  void dispose() {
    _scanDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleScanned(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    if (widget.fromDashboard) {
      Navigator.of(context).pop(trimmed);
      return;
    }

    // Ngữ cảnh khác: hiển thị màn hình thành công/thất bại
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BarcodeSuccessScreen(scannedCode: trimmed),
        // builder: (_) => const BarcodeFailScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      Navigator.of(context).pop(true);
    } else {
      // Nếu cần quét tiếp, làm sạch input và focus lại
      _controller.clear();
      _focusNode.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      _isProcessingScan = false;
    }
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
                  // TextField ẩn để nhận dữ liệu từ PDA (keyboard wedge)
                  Opacity(
                    opacity: 0,
                    child: SizedBox(
                      height: 1,
                      width: 1,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        showCursor: false,
                        onSubmitted: (value) {
                          _handleScanned(value);
                        },
                        keyboardType: TextInputType.none,
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
                  const SizedBox(height: 8),
                  const Text(
                    'Hệ thống sẽ tự động nhận diện khi quét thành công.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF374151)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      // Quét lại: ở lại màn hình, có thể reset trạng thái / show snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đang quét lại...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Text(
                      'Quét lại',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
