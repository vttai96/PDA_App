import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'barcode_fail_screen.dart';
import 'barcode_scanner_screen.dart';
import 'config/api_config.dart';
import 'manual_confirm_screen.dart';
import 'models/ingredient.dart';
import 'scan_complete_screen.dart';
import 'services/datawedge_service.dart';

enum _IngredientType { completed, waiting, neutral, warning }

class _IngredientConfig {
  final _IngredientType type;
  final String code;
  final String name;
  final double targetQty;
  final String unit;
  final double scannedQty;
  final String subtitle;
  final DateTime? scannedAt;

  const _IngredientConfig({
    required this.type,
    required this.code,
    required this.name,
    required this.targetQty,
    required this.unit,
    required this.scannedQty,
    required this.subtitle,
    this.scannedAt,
  });

  _IngredientConfig copyWith({
    _IngredientType? type,
    String? code,
    String? name,
    double? targetQty,
    String? unit,
    double? scannedQty,
    String? subtitle,
    DateTime? scannedAt,
  }) {
    return _IngredientConfig(
      type: type ?? this.type,
      code: code ?? this.code,
      name: name ?? this.name,
      targetQty: targetQty ?? this.targetQty,
      unit: unit ?? this.unit,
      scannedQty: scannedQty ?? this.scannedQty,
      subtitle: subtitle ?? this.subtitle,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }
}

class _ParsedIngredientScan {
  final String itemCode;
  final double weight;
  final String lot;
  final String weightBatch;
  final String labelId;

  const _ParsedIngredientScan({
    required this.itemCode,
    required this.weight,
    required this.lot,
    required this.weightBatch,
    required this.labelId,
  });
}

class _IngredientScanRecord {
  final String itemCode;
  final double weight;
  final String lot;
  final String weightBatch;
  final String labelId;
  final DateTime scannedAt;

  const _IngredientScanRecord({
    required this.itemCode,
    required this.weight,
    required this.lot,
    required this.weightBatch,
    required this.labelId,
    required this.scannedAt,
  });
}

class ScanDetailScreen extends StatefulWidget {
  final List<IngredientModel> ingredients;
  final String? tankNumber;
  final String? productionOrder;
  final String? batchNumber;
  final String? recipeName;
  final String? recipeVersion;
  final String? productCode;
  final String? productName;
  final String? shift;
  final String? plannedStart;

  const ScanDetailScreen({
    super.key,
    this.ingredients = const [],
    this.tankNumber,
    this.productionOrder,
    this.batchNumber,
    this.recipeName,
    this.recipeVersion,
    this.productCode,
    this.productName,
    this.shift,
    this.plannedStart,
  });

  @override
  State<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends State<ScanDetailScreen> {
  static const double _toleranceKg = 0.1;

  static const String _ingredientScanCompletePath = '/ingredient-scan/complete';
  static const String _tankCompletePath = '/tank-transfer/complete';

  late List<_IngredientConfig> _ingredients;
  final Map<int, List<_IngredientScanRecord>> _scanRecordsByIngredient = {};
  final Set<String> _usedLabelIds = <String>{};

  int? _selectedIndex;
  StreamSubscription? _scanSubscription;
  bool _isProcessingScan = false;
  bool _isOpeningCompletion = false;

  void _logIngredientScan(String message) {
    debugPrint('[SCAN][DETAIL] $message');
  }

  void _logApi(String message) {
    debugPrint('[API][DETAIL] $message');
  }

  @override
  void initState() {
    super.initState();
    _resetIngredients();
    _bindScanner();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  void _bindScanner() {
    _scanSubscription = DataWedgeService.instance.scanStream.listen((result) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route == null || !route.isCurrent) return;
      if (_isProcessingScan) return;

      final raw = result.data.trim();
      if (raw.isEmpty) return;

      _logIngredientScan('raw(DataWedge)="$raw"');
      _processIngredientScan(raw);
    });
  }

  void _resetIngredients() {
    _scanRecordsByIngredient.clear();
    _usedLabelIds.clear();

    if (widget.ingredients.isEmpty) {
      _ingredients = [];
      _selectedIndex = null;
      return;
    }

    _ingredients = List.generate(widget.ingredients.length, (index) {
      final ing = widget.ingredients[index];
      return _IngredientConfig(
        type: index == 0 ? _IngredientType.waiting : _IngredientType.neutral,
        code: ing.ingredientCode,
        name: ing.ingredientName,
        targetQty: ing.quantity,
        unit: ing.unitOfMeasurement,
        scannedQty: 0,
        subtitle: index == 0 ? 'Đang chờ quét...' : 'Chờ xử lý',
      );
    });

    _selectedIndex = 0;
  }

  bool _isSuccessResponse(Map<String, dynamic> body) {
    final message = body['Message']?.toString().trim().toLowerCase();
    return message == 'success';
  }

  int? _findNextIncompleteIndex() {
    for (var i = 0; i < _ingredients.length; i++) {
      if (_ingredients[i].type != _IngredientType.completed) return i;
    }
    return null;
  }

  _ParsedIngredientScan? _parseScan(String raw) {
    final tokens = raw.trim().split(RegExp(r'\s+'));
    _logIngredientScan('tokens=${tokens.length} -> ${tokens.join(' | ')}');
    if (tokens.length < 6) {
      _logIngredientScan('parse failed: tokens < 6');
      return null;
    }
    if (tokens.first.toUpperCase() != 'AIT01') {
      _logIngredientScan('parse failed: prefix "${tokens.first}" != AIT01');
      return null;
    }

    final weight = double.tryParse(tokens[2].replaceAll(',', '.'));
    if (weight == null || weight <= 0) {
      _logIngredientScan('parse failed: invalid weight "${tokens[2]}"');
      return null;
    }

    final itemCode = tokens[1].trim();
    final lot = tokens[3].trim();
    final weightBatch = tokens[4].trim();
    final labelId = tokens.sublist(5).join(' ').trim();

    if (itemCode.isEmpty ||
        lot.isEmpty ||
        weightBatch.isEmpty ||
        labelId.isEmpty) {
      _logIngredientScan('parse failed: empty field item/lot/weightBatch/label');
      return null;
    }

    _logIngredientScan(
      'parse success item="$itemCode" weight=$weight lot="$lot" meCan="$weightBatch" label="$labelId"',
    );

    return _ParsedIngredientScan(
      itemCode: itemCode,
      weight: weight,
      lot: lot,
      weightBatch: weightBatch,
      labelId: labelId,
    );
  }

  Future<void> _showFail({
    required String ingredientName,
    required String title,
    required String message,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BarcodeFailScreen(
          ingredientName: ingredientName,
          title: title,
          message: message,
        ),
      ),
    );
  }

  Future<bool> _postJson(String path, Map<String, dynamic> body) async {
    final uri = ApiConfig.endpoint(path);
    final requestJson = jsonEncode(body);
    _logApi('POST $uri');
    _logApi('REQ $requestJson');

    try {
      final response = await http
          .post(
            uri,
            headers: ApiConfig.defaultHeaders,
            body: requestJson,
          )
          .timeout(const Duration(seconds: 12));

      _logApi('RES status=${response.statusCode}');
      _logApi('RES body=${response.body}');

      if (response.statusCode != 200) return false;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final success = _isSuccessResponse(payload);
      _logApi('RES success=$success');
      return success;
    } catch (e) {
      _logApi('ERROR $e');
      return false;
    }
  }

  Future<bool> _submitIngredientScanComplete(int ingredientIndex) async {
    final ingredient = _ingredients[ingredientIndex];
    final records = _scanRecordsByIngredient[ingredientIndex] ?? const [];

    final body = {
      'TankNumber': widget.tankNumber ?? '',
      'ProductionOrder': widget.productionOrder ?? '',
      'BatchNumber': widget.batchNumber ?? '',
      'IngredientCode': ingredient.code,
      'IngredientName': ingredient.name,
      'TargetQty': ingredient.targetQty,
      'ActualQty': ingredient.scannedQty,
      'Scans': records
          .map(
            (r) => {
              'ItemCode': r.itemCode,
              'Weight': r.weight,
              'Lot': r.lot,
              'WeightBatch': r.weightBatch,
              'LabelId': r.labelId,
              'ScannedAt': r.scannedAt.toIso8601String(),
            },
          )
          .toList(),
    };

    _logApi(
      'submit ingredient complete code="${ingredient.code}" scans=${records.length}',
    );
    return _postJson(_ingredientScanCompletePath, body);
  }

  Future<bool> _submitTankComplete() {
    final body = {
      'TankNumber': widget.tankNumber ?? '',
      'ProductionOrder': widget.productionOrder ?? '',
      'BatchNumber': widget.batchNumber ?? '',
      'Status': 'Completed',
      'CompletedAt': DateTime.now().toIso8601String(),
    };

    final expectedTank = (widget.tankNumber ?? '').trim().toUpperCase();
    final expectedPo = (widget.productionOrder ?? '').trim().toUpperCase();
    final expectedBatch = (widget.batchNumber ?? '').trim().toUpperCase();

    _logApi(
      'submit tank complete tank="${widget.tankNumber ?? ''}" PO="${widget.productionOrder ?? ''}" Batch="${widget.batchNumber ?? ''}"',
    );

    final uri = ApiConfig.endpoint(_tankCompletePath);
    final requestJson = jsonEncode(body);
    _logApi('POST $uri');
    _logApi('REQ $requestJson');

    return http
        .post(
          uri,
          headers: ApiConfig.defaultHeaders,
          body: requestJson,
        )
        .timeout(const Duration(seconds: 12))
        .then((response) {
          _logApi('RES status=${response.statusCode}');
          _logApi('RES body=${response.body}');

          if (response.statusCode != 200) return false;

          final decoded = jsonDecode(response.body);
          if (decoded is! Map<String, dynamic>) {
            _logApi('tank complete reject: response is not JSON object');
            return false;
          }

          final messageOk = _isSuccessResponse(decoded);
          final data = decoded['Data'];
          if (!messageOk || data is! Map) {
            _logApi('tank complete reject: Message!=success or Data not object');
            return false;
          }

          final status = (data['Status'] ?? '').toString().trim().toLowerCase();
          final transferCompleted = data['TransferCompleted'] == true;
          final completed = data['Completed'] == true;
          final semanticOk =
              transferCompleted || completed || status == 'completed';
          if (!semanticOk) {
            _logApi(
              'tank complete reject: missing completion marker (TransferCompleted/Completed/Status)',
            );
            return false;
          }

          final dataTank = (data['TankNumber'] ?? '').toString().trim().toUpperCase();
          final dataPo = (data['ProductionOrder'] ?? '').toString().trim().toUpperCase();
          final dataBatch = (data['BatchNumber'] ?? '').toString().trim().toUpperCase();

          if (dataTank.isNotEmpty && dataTank != expectedTank) {
            _logApi('tank complete reject: TankNumber mismatch "$dataTank" != "$expectedTank"');
            return false;
          }
          if (dataPo.isNotEmpty && dataPo != expectedPo) {
            _logApi('tank complete reject: ProductionOrder mismatch "$dataPo" != "$expectedPo"');
            return false;
          }
          if (dataBatch.isNotEmpty && dataBatch != expectedBatch) {
            _logApi('tank complete reject: BatchNumber mismatch "$dataBatch" != "$expectedBatch"');
            return false;
          }

          _logApi('tank complete accepted');
          return true;
        })
        .catchError((e) {
          _logApi('ERROR $e');
          return false;
        });
  }

  Future<void> _openCompletionScreen() async {
    if (_isOpeningCompletion) return;
    _isOpeningCompletion = true;
    try {
      final summaryItems = _ingredients
          .map(
            (ing) => ScanCompleteItem(
              name: ing.name,
              target: '${ing.scannedQty.toStringAsFixed(2)} ${ing.unit}',
              scannedAt: ing.scannedAt,
            ),
          )
          .toList();

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ScanCompleteScreen(
            items: summaryItems,
            onConfirmComplete: _submitTankComplete,
            tankNumber: widget.tankNumber ?? '',
            productionOrder: widget.productionOrder ?? '',
            batchNumber: widget.batchNumber ?? '',
            recipeName: widget.recipeName ?? '',
            recipeVersion: widget.recipeVersion ?? '',
            productCode: widget.productCode ?? '',
            productName: widget.productName ?? '',
            shift: widget.shift ?? '',
            plannedStart: widget.plannedStart ?? '',
          ),
        ),
      );

      if (!mounted) return;
      _logApi('ScanCompleteScreen result=$result');

      if (result == true) {
        Navigator.of(context).pop();
      }
    } finally {
      _isOpeningCompletion = false;
    }
  }

  Future<void> _processIngredientScan(String raw) async {
    if (_isProcessingScan) return;
    _isProcessingScan = true;

    try {
      _logIngredientScan('start process raw="$raw"');
      if (_ingredients.isEmpty) return;

      _selectedIndex ??= _findNextIncompleteIndex();
      final fallbackIndex = _selectedIndex ?? 0;
      final fallback = _ingredients[fallbackIndex];
      final parsed = _parseScan(raw);

      if (parsed == null) {
        await _showFail(
          ingredientName: fallback.name,
          title: 'Sai định dạng',
          message:
              'Mã cân theo mẫu: AIT01 <itemCode> <khối lượng> <Lot> <mẻ cân> <id tem>.',
        );
        return;
      }

      final scannedCode = parsed.itemCode.trim().toUpperCase();
      final currentIndex = _ingredients.indexWhere(
        (ing) => ing.code.trim().toUpperCase() == scannedCode,
      );
      if (currentIndex == -1) {
        _logIngredientScan(
          'reject itemCode: scanned="${parsed.itemCode}" not found in ingredient list',
        );
        await _showFail(
          ingredientName: parsed.itemCode,
          title: 'Sai itemCode',
          message: 'ItemCode quét được không nằm trong danh sách ingredient.',
        );
        return;
      }

      final current = _ingredients[currentIndex];
      _logIngredientScan(
        'matched ingredient idx=$currentIndex code="${current.code}" target=${current.targetQty} scanned=${current.scannedQty}',
      );

      if (current.type == _IngredientType.completed) {
        _logIngredientScan('reject: ingredient idx=$currentIndex already completed');
        await _showFail(
          ingredientName: current.name,
          title: 'Đã hoàn thành',
          message: 'Nguyên liệu này đã đạt khối lượng yêu cầu.',
        );
        return;
      }

      if (_selectedIndex != currentIndex) {
        setState(() {
          _selectedIndex = currentIndex;
          for (var i = 0; i < _ingredients.length; i++) {
            final ing = _ingredients[i];
            if (ing.type == _IngredientType.completed) continue;
            _ingredients[i] = ing.copyWith(
              type: i == currentIndex
                  ? _IngredientType.waiting
                  : _IngredientType.neutral,
              subtitle: i == currentIndex ? 'Đang chờ quét...' : 'Chờ xử lý',
            );
          }
        });
      }

      final normalizedLabel = parsed.labelId.trim().toUpperCase();
      if (_usedLabelIds.contains(normalizedLabel)) {
        _logIngredientScan('reject duplicate label="$normalizedLabel"');
        await _showFail(
          ingredientName: current.name,
          title: 'Trùng ID tem',
          message: 'ID tem đã tồn tại, vui lòng quét tem khác.',
        );
        return;
      }

      final nextScanned = current.scannedQty + parsed.weight;
      final maxAllowed = current.targetQty + _toleranceKg;
      _logIngredientScan(
        'calc nextScanned=$nextScanned target=${current.targetQty} maxAllowed=$maxAllowed',
      );

      if (nextScanned > maxAllowed) {
        final existing = _scanRecordsByIngredient[currentIndex] ?? const [];
        for (final r in existing) {
          _usedLabelIds.remove(r.labelId.trim().toUpperCase());
        }
        _scanRecordsByIngredient[currentIndex] = [];

        setState(() {
          _ingredients[currentIndex] = current.copyWith(
            type: _IngredientType.waiting,
            scannedQty: 0,
            subtitle: 'Vượt khối lượng, quét lại từ đầu.',
            scannedAt: null,
          );
        });
        _logIngredientScan(
          'overweight -> reset all records for ingredient idx=$currentIndex',
        );

        await _showFail(
          ingredientName: current.name,
          title: 'Vượt khối lượng',
          message:
              'Tổng khối lượng vượt ngưỡng cho phép. Đã xóa bản ghi của nguyên liệu này để quét lại.',
        );
        return;
      }

      _scanRecordsByIngredient.putIfAbsent(
        currentIndex,
        () => <_IngredientScanRecord>[],
      );
      _scanRecordsByIngredient[currentIndex]!.add(
        _IngredientScanRecord(
          itemCode: parsed.itemCode,
          weight: parsed.weight,
          lot: parsed.lot,
          weightBatch: parsed.weightBatch,
          labelId: parsed.labelId,
          scannedAt: DateTime.now(),
        ),
      );
      _usedLabelIds.add(normalizedLabel);

      final reached = (nextScanned - current.targetQty).abs() <= _toleranceKg;
      _logIngredientScan('reached=$reached tolerance=$_toleranceKg');

      setState(() {
        _ingredients[currentIndex] = current.copyWith(
          scannedQty: nextScanned,
          type: reached ? _IngredientType.completed : _IngredientType.waiting,
          subtitle: reached
              ? 'Đã đạt ${nextScanned.toStringAsFixed(2)}/${current.targetQty.toStringAsFixed(2)} ${current.unit}'
              : 'Đã quét ${nextScanned.toStringAsFixed(2)}/${current.targetQty.toStringAsFixed(2)} ${current.unit}',
          scannedAt: DateTime.now(),
        );
      });

      if (!reached) return;

      final ingredientApiOk = await _submitIngredientScanComplete(currentIndex);
      _logIngredientScan('submit ingredient complete apiOk=$ingredientApiOk');
      if (!mounted) return;

      if (!ingredientApiOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không gửi được dữ liệu quét nguyên liệu.'),
          ),
        );
      }

      setState(() {
        final next = _findNextIncompleteIndex();
        _selectedIndex = next;

        for (var i = 0; i < _ingredients.length; i++) {
          final ing = _ingredients[i];
          if (ing.type == _IngredientType.completed) continue;
          _ingredients[i] = ing.copyWith(
            type: i == next ? _IngredientType.waiting : _IngredientType.neutral,
            subtitle: i == next ? 'Đang chờ quét...' : 'Chờ xử lý',
          );
        }
      });

      final allCompleted =
          _ingredients.isNotEmpty &&
          _ingredients.every((ing) => ing.type == _IngredientType.completed);
      _logIngredientScan('allCompleted=$allCompleted');
      if (allCompleted) {
        await _openCompletionScreen();
      }
    } finally {
      _logIngredientScan('end process');
      _isProcessingScan = false;
    }
  }

  Future<void> _handleScanTap() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có nguyên liệu để quét.')),
      );
      return;
    }

    _selectedIndex ??= _findNextIncompleteIndex();
    if (_selectedIndex == null) return;

    if (DataWedgeService.instance.isSupported) {
      await DataWedgeService.instance.softTrigger();
      return;
    }

    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerScreen(fromDashboard: true),
      ),
    );

    if (raw == null || !mounted) return;
    _logIngredientScan('raw(Camera)="${raw.trim()}"');
    await _processIngredientScan(raw);
  }

  @override
  Widget build(BuildContext context) {

    final totalTarget = _ingredients.fold<double>(
      0,
      (sum, ing) => sum + ing.targetQty,
    );
    final totalScanned = _ingredients.fold<double>(
      0,
      (sum, ing) => sum + ing.scannedQty,
    );

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTankHeaderCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'MỤC TIÊU',
                    value: totalTarget.toStringAsFixed(2),
                    unit: 'kg',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'HIỆN TẠI',
                    value: totalScanned.toStringAsFixed(2),
                    unit: 'kg',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'CÒN LẠI',
                    value: _ingredients
                        .where((ing) => ing.type != _IngredientType.completed)
                        .length
                        .toString(),
                    unit: 'mục',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildScanStatusCard(),
            const SizedBox(height: 16),
            const Text(
              'Nguyên Liệu Yêu Cầu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_ingredients.isEmpty)
              const Text(
                'Không có dữ liệu ingredient.',
                style: TextStyle(color: Colors.white70),
              ),
            for (var i = 0; i < _ingredients.length; i++) ...[
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                child: _buildIngredientCard(
                  ing: _ingredients[i],
                  selected: _selectedIndex == i,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Bỏ qua',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
                  icon: const Icon(Icons.keyboard, size: 20),
                  label: const Text(
                    'Nhập thủ công',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTankHeaderCard() {
    final tank = widget.tankNumber ?? '---';
    final batch = widget.batchNumber ?? '---';
    final po = widget.productionOrder ?? '---';
    final recipeName = widget.recipeName ?? '---';
    final recipeVersion = widget.recipeVersion ?? '---';
    final productCode = widget.productCode ?? '---';
    final productName = widget.productName ?? '---';
    final shift = widget.shift ?? '---';
    final plannedStart = widget.plannedStart ?? '---';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tank: $tank',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text('Lo: $batch', style: const TextStyle(color: Colors.white70)),
          Text('PO: $po', style: const TextStyle(color: Color(0xFF38BDF8))),
          const SizedBox(height: 6),
          Text(
            'Product: $productCode - $productName',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Recipe: $recipeName v$recipeVersion',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Shift: $shift | PlannedStart: $plannedStart',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildScanStatusCard() {
    return InkWell(
      onTap: _handleScanTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF137FEC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isProcessingScan
                    ? 'Đang xử lý kết quả quét...'
                    : 'Nhấn để mở máy quét',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientCard({
    required _IngredientConfig ing,
    required bool selected,
  }) {
    Color statusColor;
    String statusText;

    switch (ing.type) {
      case _IngredientType.completed:
        statusColor = const Color(0xFF16A34A);
        statusText = 'Đã hoàn thành';
        break;
      case _IngredientType.waiting:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Đang xử lý';
        break;
      case _IngredientType.warning:
        statusColor = const Color(0xFFDC2626);
        statusText = 'Cần xử lý';
        break;
      case _IngredientType.neutral:
        statusColor = const Color(0xFF64748B);
        statusText = 'Chờ';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF22C55E) : const Color(0xFF1F2937),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${ing.code} - ${ing.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mục tiêu: ${ing.targetQty.toStringAsFixed(2)} ${ing.unit} | Đã quét: ${ing.scannedQty.toStringAsFixed(2)} ${ing.unit}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            ing.subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
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

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
