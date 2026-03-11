import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'forgot_pin_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? selectedUser;
  String pin = "";
  final List<Map<String, String?>> users = [
    {
      'name': 'Nguyễn Văn An',
      'role': 'Giám Sát Ca • ID: 8942',
      'avatar': 'assets/avatar1.png',
    },
    {
      'name': 'Trần Thị Bình',
      'role': 'Kiểm Soát Chất Lượng • ID: 4421',
      'avatar': 'assets/avatar2.png',
    },
    {
      'name': 'Lê Minh Cường',
      'role': 'Vận Hành Dây Chuyền • ID: 1190',
      'avatar': 'assets/avatar3.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Select the first user by default
    if (users.isNotEmpty) {
      selectedUser = users[0]['name'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildUserSelection(),
              const SizedBox(height: 20),
              if (selectedUser != null) ...[
                _buildPinEntry(),
                const SizedBox(height: 24),
                _buildNumpad(),
              ],
              const Spacer(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.factory, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dây Chuyền 4 Trạm B',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Sản Xuất', style: TextStyle(color: Colors.grey)),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: Colors.green, size: 10),
              SizedBox(width: 6),
              Text(
                'TRỰC TUYẾN',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserSelection() {
    return SizedBox(
      height: 170, // hoặc Expanded nếu bạn dùng flex
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Header (KHÔNG scroll)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CHỌN NGƯỜI VẬN HÀNH',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Ca 1 - Sáng',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ✅ Chỉ phần này scroll
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...users.map((user) => _buildUserTile(user)),
                  const SizedBox(height: 8),
                  _buildGuestLogin(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, String?> user) {
    final bool isSelected = selectedUser == (user['name'] ?? '');
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedUser = user['name'];
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              // backgroundImage: AssetImage(user['avatar']!),
              backgroundColor: Colors.grey,
              radius: 24,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user['role'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blue)
            else
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestLogin() {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(12),
        dashPattern: const [8, 3],
        strokeWidth: 2,
        strokeCap: StrokeCap.round,
        color: Colors.grey.withValues(alpha: 0.5),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_rounded, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text(
                'Đăng Nhập Khách',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinEntry() {
    return Column(
      children: [
        const Text('Nhập mã PIN cho', style: TextStyle(color: Colors.grey)),
        Text(
          selectedUser ??
              'Người dùng', // Use ?? (fallback) instead of ! (force)
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                index < pin.length ? Icons.circle : Icons.circle_outlined,
                color: index < pin.length ? Colors.blue : Colors.grey,
                size: 16,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNumpad() {
    return SizedBox(
      height: 240,
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ...List.generate(9, (index) => _buildNumpadButton('${index + 1}')),
          _buildNumpadButton('X', isIcon: true),
          _buildNumpadButton('0'),
          _buildNumpadButton('✓', isIcon: true, isConfirm: true),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(
    String text, {
    bool isIcon = false,
    bool isConfirm = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.blue.withValues(alpha: 0.3),
        highlightColor: Colors.blue.withValues(alpha: 0.15),
        onTap: () {
          if (text == '✓') {
            // confirm entered PIN
            const String correctPin = '1111';
            if (pin == correctPin) {
              // find selected user map
              final selectedMap = users.firstWhere(
                (u) => u['name'] == selectedUser,
                orElse: () => {'name': selectedUser},
              );
              // navigate to dashboard and replace login
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(user: selectedMap),
                ),
              );
            } else {
              // show error and clear
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mã PIN không đúng')),
              );
              setState(() => pin = '');
            }
            return;
          }

          setState(() {
            if (!isIcon && pin.length < 4) {
              pin += text;
            } else if (text == 'X' && pin.isNotEmpty) {
              pin = pin.substring(0, pin.length - 1);
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isConfirm ? Colors.blue : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: isIcon
                ? Icon(
                    text == 'X' ? Icons.backspace : Icons.check,
                    color: text == 'X' ? Colors.red : Colors.white,
                    size: 20,
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ForgotPinScreen()),
            );
          },
          child: const Text(
            'Quên Mã PIN?',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        const Text('Đăng Nhập Quản Trị', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
