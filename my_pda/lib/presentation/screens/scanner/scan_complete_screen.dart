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

class ScanCompleteScreen extends StatefulWidget {
  final List<ScanCompleteItem> items;
  final String tankNumber;
  final String productionOrder;
  final String batchNumber;
  final String recipeName;
  final String recipeVersion;
  final String productCode;
  final String productName;
  final String shift;
  final String plannedStart;
  final Future<bool> Function() onConfirmComplete;

  const ScanCompleteScreen({
    super.key,
    required this.items,
    required this.onConfirmComplete,
    this.tankNumber = '',
    this.productionOrder = '',
    this.batchNumber = '',
    this.recipeName = '',
    this.recipeVersion = '',
    this.productCode = '',
    this.productName = '',
    this.shift = '',
    this.plannedStart = '',
  });

  @override
  State<ScanCompleteScreen> createState() => _ScanCompleteScreenState();
}

class _ScanCompleteScreenState extends State<ScanCompleteScreen> {
  bool _isSubmitting = false;
  bool _apiConfirmed = false;
  String? _errorMessage;

  Future<void> _handleConfirm() async {
    if (_isSubmitting || _apiConfirmed) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final ok = await widget.onConfirmComplete();
    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _apiConfirmed = ok;
      _errorMessage = ok ? null : 'Xác nhận thất bại. Vui lòng thử lại.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF101922),
        appBar: AppBar(
          backgroundColor: const Color(0xFF111827),
          elevation: 0,
          automaticallyImplyLeading: false,
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
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                        ],
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildItemCard(widget.items[index]),
                        );
                      }, childCount: widget.items.length),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
              ),
            ),
            _buildFixedBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String showValue(String value) => value.isEmpty ? '---' : value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF133B2E),
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Color(0xFF22C55E),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Hoàn thành đổ liệu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tất cả nguyên liệu đã được quét thành công',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFCBD5F5), fontSize: 16),
        ),
        const SizedBox(height: 12),
        Text(
          'Tank: ${showValue(widget.tankNumber)} | PO: ${showValue(widget.productionOrder)} | Batch: ${showValue(widget.batchNumber)}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFCBD5F5), fontSize: 12),
        ),
        Text(
          'Product: ${showValue(widget.productCode)} - ${showValue(widget.productName)}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFCBD5F5), fontSize: 12),
        ),
        Text(
          'Recipe: ${showValue(widget.recipeName)} v${showValue(widget.recipeVersion)} | Shift: ${showValue(widget.shift)} | Planned: ${showValue(widget.plannedStart)}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFCBD5F5), fontSize: 12),
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

  Widget _buildFixedBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF101922),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
            ),
            const SizedBox(height: 10),
          ],
          if (!_apiConfirmed)
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
                onPressed: _handleConfirm,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _isSubmitting ? 'ĐANG GỬI XÁC NHẬN...' : 'XÁC NHẬN VÀ KẾT THÚC',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (_apiConfirmed)
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
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(
                  'QUÉT TANK TIẾP THEO',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatScanTime(DateTime? dateTime) {
    if (dateTime == null) return 'Thời gian quét chưa có';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(dateTime.day)}/${twoDigits(dateTime.month)}/${dateTime.year} '
        '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}:${twoDigits(dateTime.second)}';
  }

  String _formatTarget(String raw) {
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(raw);
    if (match == null) return raw;
    final value = double.tryParse(match.group(1)!);
    if (value == null) return raw;
    return '${value.toStringAsFixed(1)} ${raw.replaceAll(match.group(1)!, '').trim()}';
  }
}
