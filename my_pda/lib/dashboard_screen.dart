import 'dart:async';
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
import 'services/datawedge_service.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, String?>? user;

  const DashboardScreen({super.key, this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription? _scanSubscription;

  String? scannedCode;
  String? _currentTankNumber;
  String? _currentProductionOrder;
  String? _currentBatchNumber;
  String? _currentRecipeName;
  String? _currentRecipeVersion;
  String? _currentProductCode;
  String? _currentProductName;
  String? _currentShift;
  String? _currentPlannedStart;
  List<IngredientModel> _recipeIngredients = const [];
  bool _isLoadingIngredients = false;
  bool _isProcessingDashboardScan = false;

  void _logTankScan(String message) {
    debugPrint('[SCAN][DASHBOARD] $message');
  }

  void _logApi(String message) {
    debugPrint('[API][DASHBOARD] $message');
  }

  @override
  void initState() {
    super.initState();
    _bindGlobalScanner();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  void _bindGlobalScanner() {
    _scanSubscription = DataWedgeService.instance.scanStream.listen((result) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) return;
      if (_isProcessingDashboardScan) return;

      final code = result.data.trim();
      if (code.isEmpty) return;

      _logTankScan('raw(DataWedge)="$code"');
      _processTankScan(code);
    });
  }

  Future<void> _triggerSoftScanFromDashboard() async {
    if (DataWedgeService.instance.isSupported) {
      await DataWedgeService.instance.softTrigger();
      return;
    }

    final result = await Navigator.push(
      context,
      _slideRoute(const BarcodeScannerScreen(fromDashboard: true)),
    );
    if (result != null) {
      final raw = result.toString().trim();
      _logTankScan('raw(Camera)="$raw"');
      _processTankScan(raw);
    }
  }

  Future<void> _processTankScan(String code) async {
    if (_isProcessingDashboardScan) return;
    _isProcessingDashboardScan = true;
    try {
      _logTankScan('start process raw="$code"');
      final tankNumber = _extractTankNumber(code);
      if (tankNumber == null) {
        _logTankScan('parse failed: invalid format, expect AIT10 <TankNumber>');
        await _showNotificationDialog(
          context,
          message:
              'Mã quét không đúng định dạng. Cần dạng: AIT10 <TankNumber>.',
          autoClose: true,
        );
        return;
      }

      _currentTankNumber = null;
      _currentProductionOrder = null;
      _currentBatchNumber = null;
      _currentRecipeName = null;
      _currentRecipeVersion = null;
      _currentProductCode = null;
      _currentProductName = null;
      _currentShift = null;
      _currentPlannedStart = null;

      setState(() {
        scannedCode = tankNumber;
        _isLoadingIngredients = true;
        _recipeIngredients = const [];
      });
      _logTankScan('parse success tankNumber="$tankNumber"');

      final recipeDetails = await _getRecipeDetails(tankNumber);
      if (!mounted) return;

      setState(() {
        _recipeIngredients = recipeDetails ?? [];
        _isLoadingIngredients = false;
      });

      if (recipeDetails != null) {
        _logTankScan(
          'recipe loaded count=${recipeDetails.length} PO="${_currentProductionOrder ?? ''}" Batch="${_currentBatchNumber ?? ''}"',
        );
        await Navigator.push(
          context,
          _slideRoute(
            ScanDetailScreen(
              ingredients: _recipeIngredients,
              tankNumber: _currentTankNumber ?? tankNumber,
              productionOrder: _currentProductionOrder ?? '',
              batchNumber: _currentBatchNumber ?? '',
              recipeName: _currentRecipeName ?? '',
              recipeVersion: _currentRecipeVersion ?? '',
              productCode: _currentProductCode ?? '',
              productName: _currentProductName ?? '',
              shift: _currentShift ?? '',
              plannedStart: _currentPlannedStart ?? '',
            ),
          ),
        );
        return;
      }

      await _showNotificationDialog(
        context,
        message:
            'Không lấy được danh sách nguyên liệu cho tank $tankNumber.',
        autoClose: true,
      );
    } finally {
      _logTankScan('end process');
      _isProcessingDashboardScan = false;
    }
  }

  String? _extractTankNumber(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final match = RegExp(
      r'^AIT10\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;

    final tankNumber = (match.group(1) ?? '').trim();
    _logTankScan('extract tankNumber="$tankNumber" from "$text"');
    return tankNumber.isEmpty ? null : tankNumber;
  }

  Future<void> _showNotificationDialog(
    BuildContext context, {
    required String message,
    bool autoClose = false,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    if (autoClose) {
      Future.delayed(const Duration(seconds: 3), () {
        if (navigator.mounted && navigator.canPop()) {
          navigator.pop();
        }
      });
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
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
                    const Icon(Icons.notifications_active, color: Colors.white),
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
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
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
  }

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

  bool _isSuccessResponse(Map<String, dynamic> body) {
    final message = body['Message']?.toString().trim().toLowerCase();
    return message == 'success';
  }

  Future<Map<String, String>> _getTankInfo(String code) async {
    try {
      debugPrint('>>> Đang quét mã Tank: $code');
      final requestBody = {'TankNumber': code};
      final uri = ApiConfig.endpoint('/getTankInfo');
      final req = jsonEncode(requestBody);
      _logApi('POST $uri');
      _logApi('REQ $req');
      debugPrint('API URL [/getTankInfo]: $uri');
      debugPrint('API Request [/getTankInfo]: ${jsonEncode(requestBody)}');
      final response = await http
          .post(
            uri,
            headers: ApiConfig.defaultHeaders,
            body: req,
          )
          .timeout(const Duration(seconds: 10)); // Tranh treo app
      _logApi('RES status=${response.statusCode}');
      _logApi('RES body=${response.body}');

      if (response.statusCode == 200) {
        debugPrint('API Response [/getTankInfo]: ${response.body}');
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        if (!_isSuccessResponse(body)) {
          debugPrint('getTankInfo fail: ${body['Error'] ?? body['Message']}');
          return {};
        }

        final payload = body['Data'];
        if (payload is! Map) {
          debugPrint('getTankInfo fail: Data phải là object.');
          return {};

        }
        final data = Map<String, dynamic>.from(payload);

        final productionOrder =
            data['ProductionOrder']?.toString().trim() ?? '';
        final batchNumber = data['BatchNumber']?.toString().trim() ?? '';
        final recipeName = data['RecipeName']?.toString().trim() ?? '';
        final recipeVersion = data['RecipeVersion']?.toString().trim() ?? '';
        final productCode = data['ProductCode']?.toString().trim() ?? '';
        final productName = data['ProductName']?.toString().trim() ?? '';
        final shift = data['Shift']?.toString().trim() ?? '';
        final plannedStart = data['PlannedStart']?.toString().trim() ?? '';

        return {
          'ProductionOrder': productionOrder,
          'BatchNumber': batchNumber,
          'RecipeName': recipeName,
          'RecipeVersion': recipeVersion,
          'ProductCode': productCode,
          'ProductName': productName,
          'Shift': shift,
          'PlannedStart': plannedStart,
        };
      } else {
        debugPrint('Lỗi Server getTankInfo: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      debugPrint('Lỗi kết nối getTankInfo: $e');
      return {};
    }
  }

  Future<List<IngredientModel>?> _getRecipeDetails(String code) async {
    try {
      // Bước 1: Lấy thông tin định danh
      final idData = await _getTankInfo(code);
      final String po = idData['ProductionOrder'] ?? '';
      final String batch = idData['BatchNumber'] ?? '';

      if (po.isEmpty || batch.isEmpty) {
        debugPrint(
          'Không tìm thấy đơn hàng hoặc lô cho mã này.',
        );
        return null;
      }
      _currentTankNumber = code;
      _currentProductionOrder = po;
      _currentBatchNumber = batch;
      _currentRecipeName = idData['RecipeName'] ?? '';
      _currentRecipeVersion = idData['RecipeVersion'] ?? '';
      _currentProductCode = idData['ProductCode'] ?? '';
      _currentProductName = idData['ProductName'] ?? '';
      _currentShift = idData['Shift'] ?? '';
      _currentPlannedStart = idData['PlannedStart'] ?? '';

      // Bước 2: Lấy chi tiết công thức
      debugPrint(
        '>>> Đang lấy chi tiết cho PO: $po, Batch: $batch',
      );
      final requestBody = {'ProductionOrder': po, 'BatchNumber': batch};
      final uri = ApiConfig.endpoint('/getRecipeDetails');
      final req = jsonEncode(requestBody);
      _logApi('POST $uri');
      _logApi('REQ $req');
      debugPrint('API URL [/getRecipeDetails]: $uri');
      debugPrint('API Request [/getRecipeDetails]: ${jsonEncode(requestBody)}');
      final response = await http
          .post(
            uri,
            headers: ApiConfig.defaultHeaders,
            body: req,
          )
          .timeout(const Duration(seconds: 10));
      _logApi('RES status=${response.statusCode}');
      _logApi('RES body=${response.body}');

      if (response.statusCode == 200) {
        debugPrint('API Response [/getRecipeDetails]: ${response.body}');
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        if (!_isSuccessResponse(body)) {
          debugPrint(
            'getRecipeDetails fail: ${body['Error'] ?? body['Message']}',
          );
          return null;
        }

        final payload = body['Data'];
        if (payload is! Map) {
          debugPrint('getRecipeDetails fail: Data phải là object.');
          return null;
        }
        final data = Map<String, dynamic>.from(payload);
        final ingredientsJson = data['ingredients'] as List? ?? const [];

        return ingredientsJson
            .whereType<Map>()
            .map(
              (item) =>
                  IngredientModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      } else {
        debugPrint('Lỗi Server getRecipeDetails: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Lỗi xử lý RecipeDetails: $e');
      return null;
    }
  }

  Map<String, String> _currentShiftInfo() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) {
      return {'name': 'CA 1', 'time': '06:00 - 14:00'};
    }
    if (hour >= 14 && hour < 22) {
      return {'name': 'CA 2', 'time': '14:00 - 22:00'};
    }
    return {'name': 'CA 3', 'time': '22:00 - 06:00'};
  }

  @override
  Widget build(BuildContext context) {
    final hasTankInfo = (scannedCode ?? '').trim().isNotEmpty;
    final compactDashboard = hasTankInfo;

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
                  Navigator.push(context, _slideRoute(SettingsScreen(user: widget.user)));
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
                  _showNotificationDialog(
                    context,
                    message:
                        'Hiện tại bạn chưa có thông báo mới.',
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
            // --- 1. Current Shift Info (Moved to top) ---
            Builder(
              builder: (context) {
                final shiftInfo = _currentShiftInfo();
                final bool isRunning =
                    (_currentShift ?? '').toUpperCase() != 'OFF';
                final String shiftName = shiftInfo['name']!;
                final String shiftTime = shiftInfo['time']!;

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1620),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: compactDashboard ? 68 : 84,
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
                          padding: EdgeInsets.symmetric(
                            vertical: compactDashboard ? 8.0 : 12.0,
                            horizontal: 16.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CA LÀM VIỆC HIỆN TẠI',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: compactDashboard ? 11 : 12,
                                      ),
                                    ),
                                    SizedBox(height: compactDashboard ? 4 : 6),
                                    Text(
                                      shiftName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: compactDashboard ? 17 : 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: compactDashboard ? 10 : 12,
                                      vertical: compactDashboard ? 4 : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isRunning
                                          ? const Color(0xFF1A3935)
                                          : const Color(0xFF23303A),
                                      border: Border.all(
                                        color: isRunning
                                            ? Colors.greenAccent.withOpacity(
                                                0.4,
                                              )
                                            : Colors.grey.withOpacity(
                                                0.4,
                                              ),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isRunning
                                                ? Colors.greenAccent.withOpacity(
                                                    0.4,
                                                  )
                                                : Colors.grey.withOpacity(
                                                    0.4,
                                                  ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isRunning
                                              ? 'ĐANG CHẠY'
                                              : 'ĐANG DỪNG',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: compactDashboard ? 11 : 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: compactDashboard ? 6 : 8),
                                  Text(
                                    shiftTime,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: compactDashboard ? 11 : 14,
                                    ),
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

            // --- 2. Redesigned Tank Information ---
            if (hasTankInfo) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(hasTankInfo ? 8 : 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.storage,
                              color: Colors.blue, size: hasTankInfo ? 24 : 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TANK: ${_currentTankNumber ?? ''}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: hasTankInfo ? 20 : 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'PO: ${_currentProductionOrder ?? ''}',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Batch: ${_currentBatchNumber ?? ''}',
                                style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    _buildTankDetailRow(
                        Icons.inventory_2_outlined,
                        'Product',
                        '${_currentProductCode ?? ''} - ${_currentProductName ?? ''}'),
                    const SizedBox(height: 6),
                    _buildTankDetailRow(
                        Icons.receipt_long_outlined,
                        'Recipe',
                        '${_currentRecipeName ?? ''}'),
                    const SizedBox(height: 6),
                    _buildTankDetailRow(
                        Icons.numbers_outlined,
                        'Version',
                        '${_currentRecipeVersion ?? ''}'),
                    const SizedBox(height: 6),
                    _buildTankDetailRow(Icons.schedule_outlined, 'Planned',
                        _currentPlannedStart ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Big scan card (styled with corner markers, circular icon and pill)
            Expanded(
              child: Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _triggerSoftScanFromDashboard,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B78FF),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(hasTankInfo ? 8 : 10),
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
                                  width: hasTankInfo ? 64 : 100,
                                  height: hasTankInfo ? 64 : 100,
                                  margin: EdgeInsets.only(
                                    bottom: hasTankInfo ? 4 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3EA0FF),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(
                                          0.25,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.qr_code_scanner,
                                      size: hasTankInfo ? 26 : 36,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: hasTankInfo ? 1 : 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: double.infinity,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      scannedCode ?? 'QUÉT MÃ TANK',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: hasTankInfo ? 16 : 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: hasTankInfo ? 1.0 : 5.0,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: hasTankInfo ? 2 : 5),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _isLoadingIngredients
                                      ? Container(
                                          key: const ValueKey('loading-state'),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D63C9),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height: 14,
                                                width: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Đang gọi API...',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(
                                          key: const ValueKey('idle-state'),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: hasTankInfo ? 18 : 40,
                                            vertical: hasTankInfo ? 6 : 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1D63C9),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const SizedBox.shrink(),
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
            if (_currentTankNumber == null ||
                _currentProductionOrder == null ||
                _currentBatchNumber == null) {
              _showNotificationDialog(
                context,
                message:
                    'Vui lòng quét mã tank trước khi vào màn hình chi tiết.',
                autoClose: true,
              );
              return;
            }
            Navigator.push(
              context,
              _slideRoute(
                ScanDetailScreen(
                  ingredients: _recipeIngredients,
                  tankNumber: _currentTankNumber ?? '',
                  productionOrder: _currentProductionOrder ?? '',
                  batchNumber: _currentBatchNumber ?? '',
                  recipeName: _currentRecipeName ?? '',
                  recipeVersion: _currentRecipeVersion ?? '',
                  productCode: _currentProductCode ?? '',
                  productName: _currentProductName ?? '',
                  shift: _currentShift ?? '',
                  plannedStart: _currentPlannedStart ?? '',
                ),
              ),
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
        },
      ),
    );
  }

  Widget _buildTankDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: Colors.blue.withOpacity(0.6), size: 16),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
