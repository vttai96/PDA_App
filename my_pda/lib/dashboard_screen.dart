import 'package:flutter/material.dart';
import 'widgets/custom_bottom_nav.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, String?>? user;

  const DashboardScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NGƯỜI VẬN HÀNH',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?['name'] ?? 'Người dùng',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if ((user?['role'] ?? '').isNotEmpty)
                    Text(
                      user?['role'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Bảng Điều Khiển',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Shift card
            // Shift card with optional left accent and custom status pill
            Builder(
              builder: (context) {
                // Example data; replace with dynamic values as needed
                final bool isRunning = true;
                const String shiftTime = '06:00 - 14:00';

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1620),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // left accent (only green when running)
                      Container(
                        width: 6,
                        height: 84,
                        decoration: BoxDecoration(
                          color: isRunning
                              ? Colors.green
                              : const Color(0xFF1B2430),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 16.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'CA LÀM VIỆC HIỆN TẠI',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'CA SÁNG',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // custom status pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isRunning
                                          ? const Color(0xFF1A3935)
                                          : const Color(0xFF23303A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        // small green dot
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isRunning
                                                ? Colors.greenAccent
                                                : Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isRunning ? 'ĐANG CHẠY' : 'ĐANG DỪNG',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // shift time below
                                  Text(
                                    shiftTime,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Completed card
                Expanded(
                  child: Container(
                    height: 120,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1724),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ĐÃ HOÀN THÀNH',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B1620),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          '12',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 0.6,
                            minHeight: 6,
                            backgroundColor: const Color(0xFF071018),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.greenAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Waiting tasks card
                Expanded(
                  child: Container(
                    height: 120,
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1724),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'CÔNG VIỆC CHỜ',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B1620),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.more_horiz,
                                size: 16,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          '5',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 0.25,
                            minHeight: 6,
                            backgroundColor: const Color(0xFF071018),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Big scan card (styled with corner markers, circular icon and pill)
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B78FF),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Stack(
                    children: [
                      // corner markers
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.white24, width: 5),
                              left: BorderSide(color: Colors.white24, width: 5),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.white24, width: 5),
                              right: BorderSide(
                                color: Colors.white24,
                                width: 5,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white24,
                                width: 5,
                              ),
                              left: BorderSide(color: Colors.white24, width: 5),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white24,
                                width: 5,
                              ),
                              right: BorderSide(
                                color: Colors.white24,
                                width: 5,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),

                      // center content
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3EA0FF),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.qr_code_scanner,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'QUÉT MÃ TANK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 5.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D63C9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Nhấn để mở camera',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}
