import 'package:flutter/material.dart';

class ManualConfirmScreen extends StatefulWidget {
  const ManualConfirmScreen({super.key});

  @override
  State<ManualConfirmScreen> createState() => _ManualConfirmScreenState();
}

class _ManualConfirmScreenState extends State<ManualConfirmScreen> {
  final TextEditingController _weightController = TextEditingController(
    text: '0.00',
  );
  String _inputValue = '0.00';
  String? _selectedReason;

  final List<String> _reasons = const [
    'Thiết bị lỗi',
    'Mã vạch mờ',
    'Không nhận diện được',
    'Khác',
  ];

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'back') {
        if (_inputValue.isNotEmpty) {
          _inputValue = _inputValue.substring(0, _inputValue.length - 1);
        }
      } else {
        if (_inputValue == '0' || _inputValue == '0.00') {
          _inputValue = '';
        }
        if (key == '.') {
          if (_inputValue.contains('.')) return;
          if (_inputValue.isEmpty) {
            _inputValue = '0';
          }
        }
        _inputValue += key;
      }

      if (_inputValue.isEmpty) {
        _inputValue = '0';
      }

      // Nếu người dùng nhập hơn 4 chữ số sau dấu thập phân,
      // tự động làm tròn về 4 chữ số.
      if (_inputValue.contains('.')) {
        final dotIndex = _inputValue.indexOf('.');
        final decimals = _inputValue.length - dotIndex - 1;
        if (decimals > 4) {
          final rounded = double.tryParse(_inputValue);
          if (rounded != null) {
            _inputValue = rounded.toStringAsFixed(4);
          }
        }
      }

      final value = double.tryParse(_inputValue);
      if (value != null) {
        _weightController.text = value.toStringAsFixed(4);
      } else {
        _weightController.text = _inputValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'XÁC NHẬN THỦ CÔNG',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [SizedBox(width: 30)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWarningBanner(),
              const SizedBox(height: 8),
              _buildMaterialCard(),
              const SizedBox(height: 10),
              _buildReasonDropdown(),
              const SizedBox(height: 12),
              _buildKeypad(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF05070A),
          border: Border(top: BorderSide(color: Color(0xFF1F2937))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  // TODO: handle confirm manual input
                },
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text(
                  'XÁC NHẬN NGAY',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4A2C19),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDC7C2B), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFBBF24)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Không đọc được nhãn. Vui lòng nhập khối lượng thủ công.',
              style: TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VẬT TƯ ĐÃ QUÉT',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'AL-2024-Sheet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    'Lô:',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '#88392',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0xFF1F2937),
          ),
          const SizedBox(height: 6),
          const Text(
            'NHẬP KHỐI LƯỢNG (KG)',
            style: TextStyle(
              color: Color(0xFFF97316),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0B101A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    readOnly: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'KG',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 18,
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

  Widget _buildReasonDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LÝ DO XÁC NHẬN TAY',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1F2937)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedReason,
              dropdownColor: const Color(0xFF111827),
              isExpanded: true,
              icon: const Icon(Icons.expand_more, color: Color(0xFF6B7280)),
              hint: const Text(
                'Chọn lý do...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              items: _reasons
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad() {
    final List<String> keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '.',
      '0',
      'back',
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.42,
        ),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];
          if (key == 'back') {
            return _buildKeypadButton(
              onTap: () => _onKeyPressed('back'),
              color: const Color(0xFF3F1A1D),
              child: const Icon(
                Icons.backspace_outlined,
                color: Color(0xFFFB7185),
              ),
            );
          }

          return _buildKeypadButton(
            onTap: () => _onKeyPressed(key),
            child: Text(
              key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKeypadButton({
    required VoidCallback onTap,
    required Widget child,
    Color color = const Color(0xFF111827),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
