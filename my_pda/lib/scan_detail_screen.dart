import 'package:flutter/material.dart';
import 'manual_confirm_screen.dart';
import 'barcode_scanner_screen.dart';
import 'scan_complete_screen.dart';

enum _IngredientType { completed, waiting, neutral, warning }

class _IngredientConfig {
  final _IngredientType type;
  final String name;
  final String target;
  final String? status;
  final String? subtitle;
  final String? warning;
  final DateTime? scannedAt;

  const _IngredientConfig({
    required this.type,
    required this.name,
    required this.target,
    this.status,
    this.subtitle,
    this.warning,
    this.scannedAt,
  });
}

class ScanDetailScreen extends StatefulWidget {
  const ScanDetailScreen({super.key});

  @override
  State<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  late List<_IngredientConfig> _ingredients;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _resetIngredients();
  }

  void _resetIngredients() {
    _ingredients = <_IngredientConfig>[
      const _IngredientConfig(
        type: _IngredientType.completed,
        name: 'Acetone',
        target: '100kg',
        status: 'Đã khớp',
      ),
      const _IngredientConfig(
        type: _IngredientType.waiting,
        name: 'Ethyl Acetate',
        target: '250kg',
        subtitle: 'Đang chờ quét...',
      ),
      const _IngredientConfig(
        type: _IngredientType.neutral,
        name: 'Isopropanol',
        target: '50kg',
        subtitle: 'Chờ xử lý',
      ),
      const _IngredientConfig(
        type: _IngredientType.warning,
        name: 'Colorant Blue #5',
        target: '2kg',
        warning: 'Độ chính xác cao',
      ),
      const _IngredientConfig(
        type: _IngredientType.neutral,
        name: 'Nước cất',
        target: '100kg',
        subtitle: 'Chờ xử lý',
      ),
    ];

    // Mặc định chọn nguyên liệu đang ở trạng thái waiting (nếu có)
    final firstWaitingIndex = _ingredients.indexWhere(
      (ing) => ing.type == _IngredientType.waiting,
    );
    _selectedIndex = firstWaitingIndex != -1 ? firstWaitingIndex : null;
  }

  Future<void> _handleScanTap() async {
    if (_selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn một nguyên liệu trước khi quét.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (result == true && _selectedIndex != null) {
      setState(() {
        // Tạo list mới để đảm bảo luôn mutable khi cập nhật phần tử
        final newList = List<_IngredientConfig>.from(_ingredients);
        final currentIndex = _selectedIndex!;

        // Cập nhật nguyên liệu hiện tại sang completed
        final ing = newList[currentIndex];
        newList[currentIndex] = _IngredientConfig(
          type: _IngredientType.completed,
          name: ing.name,
          target: ing.target,
          status: 'Đã khớp',
          scannedAt: DateTime.now(),
        );

        // Nếu còn nguyên liệu kế tiếp, chuyển sang trạng thái waiting
        final nextIndex = currentIndex + 1;
        if (nextIndex < newList.length) {
          final nextIng = newList[nextIndex];
          if (nextIng.type != _IngredientType.completed) {
            newList[nextIndex] = _IngredientConfig(
              type: _IngredientType.waiting,
              name: nextIng.name,
              target: nextIng.target,
              subtitle: 'Đang chờ quét...',
              scannedAt: nextIng.scannedAt,
            );
            _selectedIndex = nextIndex;
          } else {
            _selectedIndex = null;
          }
        } else {
          _selectedIndex = null;
        }

        _ingredients = newList;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCompleted =
        _ingredients.isNotEmpty &&
        _ingredients.every((ing) => ing.type == _IngredientType.completed);
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
          'Chi Tiết Công Thức',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SizedBox(
              width: 32,
              height: 32,
              child: const Icon(Icons.restore, color: Colors.blue, size: 28),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTankHeaderCard(),
            const SizedBox(height: 16),
            _buildMetricsRow(),
            const SizedBox(height: 16),
            _buildScanStatusCard(context),
            const SizedBox(height: 24),
            const Text(
              'Nguyên Liệu Yêu Cầu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _ingredients.length; i++) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = i;
                  });
                },
                child: _buildIngredientItem(
                  ingredient: _ingredients[i],
                  selected: _selectedIndex == i,
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0B0E11),
          border: Border(top: BorderSide(color: Color(0xFF1F2937))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: allCompleted
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final summaryItems = _ingredients
                            .map(
                              (ing) => ScanCompleteItem(
                                name: ing.name,
                                target: ing.target,
                                scannedAt: ing.scannedAt,
                              ),
                            )
                            .toList();

                        Navigator.of(context)
                            .push<bool>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ScanCompleteScreen(items: summaryItems),
                              ),
                            )
                            .then((nextTank) {
                              if (nextTank == true) {
                                setState(_resetIngredients);
                              }
                            });
                      },
                      child: const Text(
                        'XÁC NHẬN VÀ KẾT THÚC',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF374151)),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Bỏ qua',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF334155),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ManualConfirmScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.keyboard, size: 24),
                          label: const Text(
                            'Nhập thủ công',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTankHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.factory, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Bồn #402',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Lô: B-99-2023',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hỗn Hợp Dung Môi Công Nghiệp A',
                            style: TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF342725),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF482E1D),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        'ĐANG THỰC HIỆN',
                        style: TextStyle(
                          color: Color(0xFFC9A943),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      children: const [
        Expanded(
          child: _MetricCard(
            label: 'MỤC TIÊU',
            value: '500',
            unit: 'kg',
            highlight: true,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MetricCard(label: 'HIỆN TẠI', value: '120', unit: 'kg'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MetricCard(label: 'CÒN LẠI', value: '4', unit: 'mục'),
        ),
      ],
    );
  }

  Widget _buildScanStatusCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _handleScanTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF137FEC),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'MÁY QUÉT ĐANG BẬT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sẵn sàng quét',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hướng PDA vào mã vạch nguyên liệu',
                    style: TextStyle(color: Color(0xFFC5DFFA), fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4299F0),
                border: Border.all(color: const Color(0xFF6AADF3), width: 2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientItem({
    required _IngredientConfig ingredient,
    required bool selected,
  }) {
    final borderColor = selected ? const Color(0xFF22C55E) : null;

    if (ingredient.type == _IngredientType.completed) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? const Color(0xFF1F2937)),
        ),
        child: _buildIngredientCompleted(
          name: ingredient.name,
          target: ingredient.target,
          status: ingredient.status ?? 'Đã khớp',
        ),
      );
    } else if (ingredient.type == _IngredientType.waiting) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor ?? const Color(0x00000000)),
        ),
        child: _buildIngredientWaiting(
          name: ingredient.name,
          target: ingredient.target,
          subtitle: ingredient.subtitle ?? '',
        ),
      );
    } else if (ingredient.type == _IngredientType.neutral) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? const Color(0x00000000)),
        ),
        child: _buildIngredientNeutral(
          name: ingredient.name,
          target: ingredient.target,
          subtitle: ingredient.subtitle ?? '',
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? const Color(0x00000000)),
        ),
        child: _buildIngredientWarning(
          name: ingredient.name,
          target: ingredient.target,
          warning: ingredient.warning ?? '',
        ),
      );
    }
  }

  Widget _buildIngredientCompleted({
    required String name,
    required String target,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131C28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFF1A8046),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF9AA2A3), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF546070),
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Mục tiêu: $target',
                      style: const TextStyle(
                        color: Color(0xFF354050),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '•',
                      style: TextStyle(color: Color(0xFF354050), fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Color(0xFF32905A),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.inventory, color: Color(0xFF313D4C)),
        ],
      ),
    );
  }

  Widget _buildIngredientWaiting({
    required String name,
    required String target,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2B3F),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: const Color(0xFF334155), width: 5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFF2563EB), width: 2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Mục tiêu: $target',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.barcode_reader,
              color: Color(0xFF6B7280),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientNeutral({
    required String name,
    required String target,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF455266), width: 2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFFB5BFCC),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Mục tiêu: $target',
                      style: const TextStyle(
                        color: Color(0xFF445265),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '•',
                      style: TextStyle(color: Color(0xFF445265), fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF445265),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientWarning({
    required String name,
    required String target,
    required String warning,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.redAccent, width: 2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFFB5BFCC),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Mục tiêu: $target',
                      style: const TextStyle(
                        color: Color(0xFF445265),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '•',
                      style: TextStyle(color: Color(0xFF445265), fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      warning,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool highlight;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = label == "MỤC TIÊU"
        ? const Color(0xFF1377DC)
        : Colors.white;
    final unitColor = label == "MỤC TIÊU"
        ? const Color(0xFF1377DC)
        : Colors.white70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(color: unitColor, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
