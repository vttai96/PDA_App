import 'package:flutter/material.dart';

class HistoryDetailScreen extends StatelessWidget {
  final Map<String, String> record;

  const HistoryDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    // sample ingredients data matching the provided UI
    final ingredients = [
      {
        'name': 'Nguyên Liệu A (Poly...)',
        'current': '50.2',
        'target': '50.0',
        'unit': 'kg',
        'color': const Color(0xFF22C55E),
        'mode': 'SCAN',
        'warning': false,
      },
      {
        'name': 'Dung Môi B',
        'current': '12.0',
        'target': '12.0',
        'unit': 'L',
        'color': const Color(0xFF22C55E),
        'mode': 'SCAN',
        'warning': false,
      },
      {
        'name': 'Chất Phụ Gia X',
        'current': '2.1',
        'target': '2.0',
        'unit': 'kg',
        'color': const Color(0xFFF97316),
        'mode': 'MANUAL',
        'warning': true,
      },
    ];

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
          'Chi Tiết Lịch Sử',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF1F2937)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.info, color: Color(0xFF137EEB)),
                SizedBox(width: 8),
                Text(
                  'THÔNG TIN MẺ LIỆU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBatchInfoCard(context),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.inventory, color: Color(0xFF137EEB)),
                const SizedBox(width: 8),
                const Text(
                  'DANH SÁCH NGUYÊN LIỆU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102D4A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${ingredients.length} Items',
                    style: const TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final ing in ingredients) ...[
              _buildIngredientCard(ing),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          border: Border(top: BorderSide(color: Color(0xFF1F2937))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: _buildBackButton(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBatchInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoCell(
                  showRightBorder: true,
                  showBottomBorder: true,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildInfoTile(
                      title: 'BỒN CHỨA (TANK)',
                      value: 'Tank-01 (Mixing)',
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildInfoCell(
                  showBottomBorder: true,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildInfoTile(
                      title: 'MÃ MẺ (BATCH ID)',
                      value: 'BATCH-${record['id'] ?? 'XX-01'}',
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildInfoCell(
                  showRightBorder: true,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF1D4ED8),
                          child: Text(
                            _initials(record['operator'] ?? ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInfoTile(
                            title: 'NGƯỜI THỰC HIỆN',
                            value: record['operator'] ?? '---',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildInfoCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _buildInfoTile(
                      title: 'THỜI GIAN',
                      value: record['time'] ?? '---',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCell({
    required Widget child,
    bool showRightBorder = false,
    bool showBottomBorder = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: showRightBorder
              ? const BorderSide(color: Color(0xFF1F2937))
              : BorderSide.none,
          bottom: showBottomBorder
              ? const BorderSide(color: Color(0xFF1F2937))
              : BorderSide.none,
        ),
      ),
      child: child,
    );
  }

  Widget _buildInfoTile({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientCard(Map<String, dynamic> ing) {
    final bool warning = ing['warning'] == true;
    final Color accent = ing['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: warning ? const Color(0xFFF97316) : const Color(0xFF1F2937),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(Icons.science, color: Colors.white70),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ing['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      ing['current'] as String,
                      style: TextStyle(
                        color: accent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' ${ing['unit']}  / ${(ing['target'] as String)} ${ing['unit']}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: _progressValue(ing),
                    backgroundColor: const Color(0xFF1F2937),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                if (warning) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Vượt định mức 5%',
                    style: TextStyle(color: Color(0xFFF97316), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (ing['mode'] == 'SCAN')
                  ? const Color(0xFF193638)
                  : const Color(0xFF2F2E30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: (ing['mode'] == 'SCAN')
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFF97316),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 3,
              children: [
                Icon(
                  ing['mode'] == 'SCAN'
                      ? Icons.qr_code_scanner
                      : Icons.edit_note,
                  color: (ing['mode'] == 'SCAN')
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFF97316),
                  size: 14,
                ),
                Text(
                  ing['mode'] as String,
                  style: TextStyle(
                    color: (ing['mode'] == 'SCAN')
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF97316),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _progressValue(Map<String, dynamic> ing) {
    final current = double.tryParse(ing['current'] as String) ?? 0;
    final target = double.tryParse(ing['target'] as String) ?? 1;
    return (current / target).clamp(0.0, 1.2);
  }

  Widget _buildBackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111827),
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF1F2937)),
          ),
        ),
        label: const Text(
          'QUAY LẠI',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0].isNotEmpty ? parts[0][0] : '') +
          (parts.last.isNotEmpty ? parts.last[0] : '');
    }
    return name.isNotEmpty ? name[0] : '?';
  }
}
