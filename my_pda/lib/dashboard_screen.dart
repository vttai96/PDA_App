import 'package:flutter/material.dart';
import 'package:my_pda/models/ingredient.dart';
import 'widgets/custom_bottom_nav.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'scan_detail_screen.dart';
import 'barcode_scanner_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, String?>? user;

  const DashboardScreen({super.key, this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? scannedCode;
  List<IngredientModel> _recipeIngredients = const [];
  bool _isLoadingIngredients = false;

  Route _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // from right
        const end = Offset.zero;
        const curve = Curves.easeOut;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  Future<Map<String, String>> _getRecipeId(String code) async {
    try {
      debugPrint('>>> Đang quét mã Tank: $code');
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/getRecipeId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'TankNumber': code}),
          )
          .timeout(const Duration(seconds: 10)); // Tránh treo app

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Kiểm tra status từ Server
        if (data['status'] == 'success') {
          return {
            'ProductionOrder': data['ProductionOrder']?.toString() ?? '',
            'BatchNumber': data['BatchNumber']?.toString() ?? '',
          };
        }
        return {};
      } else {
        debugPrint('Lỗi Server getRecipeId: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      debugPrint('Lỗi kết nối getRecipeId: $e');
      return {};
    }
  }

  Future<List<IngredientModel>?> _getRecipeDetails(String code) async {
    try {
      // Bước 1: Lấy thông tin định danh
      final idData = await _getRecipeId(code);
      final String po = idData['ProductionOrder'] ?? '';
      final String batch = idData['BatchNumber'] ?? '';

      if (po.isEmpty || batch.isEmpty) {
        debugPrint('⚠️ Không tìm thấy đơn hàng hoặc lô cho mã này.');
        return null;
      }

      // Bước 2: Lấy chi tiết công thức
      debugPrint('>>> Đang lấy chi tiết cho PO: $po, Batch: $batch');
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/getRecipeDetails'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'ProductionOrder': po, 'BatchNumber': batch}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Chuyển đổi sang RecipeResponse
        final recipeResponse = RecipeResponse.fromJson(data);
        return recipeResponse.ingredients;
      } else {
        debugPrint('Lỗi Server getRecipeDetails: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Lỗi xử lý RecipeDetails: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    _slideRoute(SettingsScreen(user: widget.user)),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
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
                    widget.user?['name'] ?? 'Người dùng',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if ((widget.user?['role'] ?? '').isNotEmpty)
                    Text(
                      widget.user?['role'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return Dialog(
                        backgroundColor: const Color(0xFF111827),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_active,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Thông báo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Hiện tại bạn chưa có thông báo mới.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('ĐÓNG'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text(
              'Bảng Điều Khiển',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                                      border: Border.all(
                                        color: isRunning
                                            ? Colors.greenAccent.withValues(
                                                alpha: 0.4,
                                              )
                                            : Colors.grey.withValues(
                                                alpha: 0.4,
                                              ),
                                        width: 1.5,
                                      ),
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
                                                ? Colors.greenAccent.withValues(
                                                    alpha: 0.4,
                                                  )
                                                : Colors.grey.withValues(
                                                    alpha: 0.4,
                                                  ),
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
            const SizedBox(height: 8),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
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
            SizedBox(height: 8),
            // Big scan card (styled with corner markers, circular icon and pill)
            Expanded(
              child: Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        _slideRoute(
                          const BarcodeScannerScreen(fromDashboard: true),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          scannedCode = result;
                          _isLoadingIngredients = true;
                        });

                        final recipeDetails = await _getRecipeDetails(result);

                        if (!context.mounted) return;

                        setState(() {
                          _recipeIngredients = recipeDetails ?? [];
                          _isLoadingIngredients = false;
                        });

                        final hasIngredients = recipeDetails != null;
                        final ingredientCount = _recipeIngredients.length;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              hasIngredients
                                  ? ingredientCount > 0
                                        ? 'Đã tải $ingredientCount nguyên liệu. Vào Chi tiết để bắt đầu quét.'
                                        : 'Công thức không có nguyên liệu. Vào Chi tiết để xem thông tin.'
                                  : 'Không lấy được danh sách nguyên liệu cho tank này.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
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
                      padding: const EdgeInsets.all(10),
                      child: Stack(
                        children: [
                          // corner markers
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.white24,
                                    width: 5,
                                  ),
                                  left: BorderSide(
                                    color: Colors.white24,
                                    width: 5,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
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
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white24,
                                    width: 5,
                                  ),
                                  left: BorderSide(
                                    color: Colors.white24,
                                    width: 5,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
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
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3EA0FF),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.25,
                                        ),
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
                                const SizedBox(height: 4),
                                Text(
                                  scannedCode ?? 'QUÉT MÃ TANK',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 5.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (_isLoadingIngredients)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 10),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  )
                                else if (scannedCode != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      _recipeIngredients.isEmpty
                                          ? 'Chưa có nguyên liệu được tải'
                                          : 'Đã tải ${_recipeIngredients.length} nguyên liệu',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
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
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              _slideRoute(ScanDetailScreen(ingredients: _recipeIngredients)),
            );
            return;
          }
          if (index == 2) {
            Navigator.push(
              context,
              _slideRoute(HistoryScreen(user: widget.user)),
            );
            return;
          }
          if (index == 3) {
            Navigator.push(
              context,
              _slideRoute(SettingsScreen(user: widget.user)),
            );
            return;
          }
        },
      ),
    );
  }
}
