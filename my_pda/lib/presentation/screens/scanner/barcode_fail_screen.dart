import 'package:flutter/material.dart';

class BarcodeFailScreen extends StatelessWidget {
  final String ingredientName;
  final String title;
  final String message;

  const BarcodeFailScreen({
    super.key,
    this.ingredientName = 'Nguyên liệu đang quét',
    this.title = 'Cảnh báo',
    this.message = 'Có lỗi xảy ra trong quá trình quét.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF221010),
      appBar: AppBar(
        backgroundColor: const Color(0xFF221010),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Thông báo lỗi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Icon(
                Icons.warning_amber_rounded,
                size: 92,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF230C0C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B0C0C)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Nguyên liệu: ',
                    style: TextStyle(color: Colors.white54),
                  ),
                  Expanded(
                    child: Text(
                      ingredientName,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
