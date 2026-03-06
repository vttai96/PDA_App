import 'dart:async';

import 'package:flutter/material.dart';

class BarcodeSuccessScreen extends StatefulWidget {
  const BarcodeSuccessScreen({super.key});

  @override
  State<BarcodeSuccessScreen> createState() => _BarcodeSuccessScreenState();
}

class _BarcodeSuccessScreenState extends State<BarcodeSuccessScreen> {
  Timer? _autoBackTimer;
  int _secondsLeft = 3;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    const totalMillis = 3000;
    const tickMillis = 100;

    int elapsed = 0;
    _autoBackTimer = Timer.periodic(const Duration(milliseconds: tickMillis), (
      timer,
    ) {
      elapsed += tickMillis;
      final clampedElapsed = elapsed.clamp(0, totalMillis);
      final remainingMillis = (totalMillis - clampedElapsed).clamp(
        0,
        totalMillis,
      );
      final newProgress = clampedElapsed / totalMillis;
      final secondsLeft = (remainingMillis / 1000).ceil();

      if (!mounted) {
        timer.cancel();
        return;
      }

      if (newProgress >= 1.0) {
        setState(() {
          _progress = 1.0;
          _secondsLeft = 0;
        });
        timer.cancel();
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _progress = newProgress;
          _secondsLeft = secondsLeft;
        });
      }
    });
  }

  @override
  void dispose() {
    _autoBackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF041807),
      appBar: AppBar(
        backgroundColor: const Color(0xFF041807),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text(
          'XÁC NHẬN QUÉT',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            _buildSuccessIcon(),
            const SizedBox(height: 24),
            const Text(
              'VẬT LIỆU HỢP LỆ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF4ADE80),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Khối lượng đã được cập nhật thành công vào hệ thống sản xuất.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            _buildMaterialDetailCard(),
            const Spacer(),
            _buildBackToFormulaButton(context),
            const SizedBox(height: 28),
            _buildAutoBackSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            const Color(0xFF22C55E).withOpacity(0.8),
            const Color(0xFF22C55E).withOpacity(0.0),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF22C55E), width: 5),
          ),
          child: const Center(
            child: Icon(Icons.check, size: 64, color: Color(0xFF22C55E)),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialDetailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF052814),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF15803D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHI TIẾT VẬT LIỆU',
            style: TextStyle(
              color: Color(0xFF4ADE80),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Tên vật liệu',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                ),
              ),
              Expanded(
                child: Text(
                  'Nhôm Hợp Kim 6061',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF14532D)),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Khối lượng đã thêm',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                ),
              ),
              Expanded(
                child: Text(
                  '15.5 kg',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackToFormulaButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),
        onPressed: () {
          // Huỷ timer (nếu còn) và trả kết quả thành công cho màn trước
          _autoBackTimer?.cancel();
          Navigator.of(context).pop(true);
        },
        child: const Text(
          'Về Trang Công Thức',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildAutoBackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tự động quay lại màn hình...',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        const SizedBox(height: 4),
        const Text(
          'Không cần thao tác thêm',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFF064E3B),
                  color: const Color(0xFF22C55E),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_secondsLeft}s',
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
