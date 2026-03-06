import 'package:flutter/material.dart';

class ScanCompleteItem {
  final String name;
  final String target;
  final DateTime? scannedAt;

  const ScanCompleteItem({
    required this.name,
    required this.target,
    this.scannedAt,
  });
}

class ScanCompleteScreen extends StatelessWidget {
  final List<ScanCompleteItem> items;

  const ScanCompleteScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Tổng kết hoàn thành',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildHeader(),
            const SizedBox(height: 24),
            const Text(
              'NHẬT KÝ XÁC THỰC',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildItemCard(item);
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF133B2E),
            ),
            child: Center(
              child: SizedBox(
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Color(0xFF22C55E),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Hoàn thành đổ liệu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Tất cả nguyên liệu đã được quét thành công',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFCBD5F5), fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(ScanCompleteItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF16302E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatTarget(item.target),
                  style: const TextStyle(
                    color: Color(0xFF4BDF80),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Lô: ---',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF1F2933), height: 1, thickness: 0.5),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time_filled,
                size: 14,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                _formatScanTime(item.scannedAt),
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatScanTime(DateTime? dateTime) {
    if (dateTime == null) return 'Thời gian quét chưa có';

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final day = twoDigits(dateTime.day);
    final month = twoDigits(dateTime.month);
    final year = dateTime.year.toString();
    final hour = twoDigits(dateTime.hour);
    final minute = twoDigits(dateTime.minute);
    final second = twoDigits(dateTime.second);

    return '$day/$month/$year $hour:$minute:$second';
  }

  String _formatTarget(String raw) {
    // Tách phần số và đơn vị, sau đó format số về dạng float 2 chữ số thập phân
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(raw);
    if (match == null) return raw;

    final numberPart = match.group(1)!;
    final unitPart = raw.replaceFirst(numberPart, '').trim();

    final value = double.tryParse(numberPart);
    if (value == null) return raw;

    final formatted = value.toStringAsFixed(1);
    return unitPart.isEmpty ? formatted : '$formatted $unitPart';
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            icon: const Icon(Icons.cloud_upload),
            label: const Text(
              'XÁC NHẬN VÀ KẾT THÚC',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF374151)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text(
              'QUÉT TANK TIẾP THEO',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
