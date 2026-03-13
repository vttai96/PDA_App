import 'package:flutter/material.dart';

class BarcodeFailScreen extends StatelessWidget {
  final String ingredientName;

  const BarcodeFailScreen({
    super.key,
    this.ingredientName = 'Nguyên liệu đang quét',
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
          'XÁC NHẬN VẬT TƯ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  _buildWarningIcon(),
                  const SizedBox(height: 24),
                  const Text(
                    'CẢNH BÁO: VƯỢT KHỐI LƯỢNG',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFF3B30),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tổng khối lượng quét đã vượt quá ngưỡng cho phép của công thức sản xuất.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFE5E7EB), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nguyên liệu: $ingredientName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildRetryButton(context),
                  const SizedBox(height: 24),
                  _buildLogicDetailCard(),
                  const SizedBox(height: 24),
                  _buildWeightsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningIcon() {
    return Center(
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF370F0F),
          border: Border.all(color: const Color(0xFFFF3B30), width: 4),
        ),
        child: Center(
          child: Icon(
            Icons.warning_outlined,
            size: 100,
            color: const Color(0xFFFF3B30).withValues(alpha: 0.95),
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF3B30),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 4,
          shadowColor: const Color(0xFFFF3B30).withValues(alpha: 0.5),
        ),
        onPressed: () {
          // Đóng màn lỗi và cho phép người dùng quét lại
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.refresh_rounded),
        label: const Text(
          'THỬ LẠI',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildLogicDetailCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF230C0C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3B0C0C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info, color: Color(0xFFF20D0D)),
              SizedBox(width: 8),
              Text(
                'CHI TIẾT LOGIC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF400E0E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Lỗi: Vượt ngưỡng quy định',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Nguyên liệu đang quét',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                ),
              ),
              Expanded(
                child: Text(
                  ingredientName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Khối lượng quét + Khối lượng hiện tại > Khối lượng yêu cầu',
            style: TextStyle(
              color: Color(0xFF8792A4),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeightRow(
          label: 'Khối lượng yêu cầu',
          value: '10.00 kg',
          highlightColor: const Color(0xFFE5E7EB),
          icon: const Icon(Icons.track_changes),
        ),
        const Divider(color: Color(0xFF3F3F46), height: 24),
        _buildWeightRow(
          label: 'Khối lượng hiện tại',
          value: '8.50 kg',
          highlightColor: const Color(0xFFE5E7EB),
          icon: const Icon(Icons.inventory),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF7F1D1D),
            borderRadius: BorderRadius.circular(14),
          ),
          child: _buildWeightRow(
            label: 'Khối lượng mới quét',
            value: '+ 2.00 kg',
            highlightColor: const Color(0xFFF20D0D),
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightRow({
    required String label,
    required String value,
    required Color highlightColor,
    required Icon icon,
  }) {
    final displayValue = label == "Khối lượng mới quét"
        ? Color(0xFFF20D0D)
        : Color(0xFF9CA3AF);
    final displayIcon = label == "Khối lượng mới quét"
        ? Color(0xFFF20D0D)
        : Color(0xFF9CA3AF);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon.icon, size: 16, color: displayIcon),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: displayValue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: highlightColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
