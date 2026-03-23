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

class _IngredientProgressPayload {
  final double actualQty;
  final bool isCompleted;
  final DateTime? lastScannedAt;
  final List<_IngredientScanRecord> scans;

  const _IngredientProgressPayload({
    required this.actualQty,
    required this.isCompleted,
    required this.lastScannedAt,
    required this.scans,
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
  static const String _ingredientProgressPath = '/ingredient-scan/progress';
  static const String _tankCompletePath = '/tank-transfer/complete';

  late List<_IngredientConfig> _ingredients;
  final Map<int, List<_IngredientScanRecord>> _scanRecordsByIngredient = {};
  final Set<String> _usedLabelIds = <String>{};

  int? _selectedIndex;
  StreamSubscription? _scanSubscription;
  bool _isProcessingScan = false;
  bool _isOpeningCompletion = false;
  bool _isLoadingExistingProgress = false;

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
    _loadExistingProgress();
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
        subtitle: index == 0 ? 'Äang chá» quÃ©t...' : 'Chá» xá»­ lÃ½',
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

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return 0;
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  String _toText(dynamic value) => value?.toString().trim() ?? '';

  DateTime? _toDateTime(dynamic value) {
    final text = _toText(value);
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  Future<Map<String, _IngredientProgressPayload>> _fetchExistingProgress() async {
    final tank = (widget.tankNumber ?? '').trim();
    final po = (widget.productionOrder ?? '').trim();
    final batch = (widget.batchNumber ?? '').trim();

    if (tank.isEmpty || po.isEmpty || batch.isEmpty) {
      _logApi('skip progress fetch: missing Tank/PO/Batch');
      return const {};
    }

    final uri = ApiConfig.endpoint(_ingredientProgressPath);
    final body = {
      'TankNumber': tank,
      'ProductionOrder': po,
      'BatchNumber': batch,
    };
    final requestJson = jsonEncode(body);

    _logApi('POST $uri');
    _logApi('REQ $requestJson');

    try {
      final response = await http
          .post(uri, headers: ApiConfig.defaultHeaders, body: requestJson)
          .timeout(const Duration(seconds: 12));
      _logApi('RES status=${response.statusCode}');
      _logApi('RES body=${response.body}');

      if (response.statusCode != 200) return const {};

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return const {};
      if (!_isSuccessResponse(decoded)) return const {};

      final data = decoded['Data'];
      if (data is! Map) return const {};

      final normalizedData = Map<String, dynamic>.from(data);
      final rowsRaw =
          normalizedData['Ingredients'] ?? normalizedData['ingredients'] ?? const [];
      if (rowsRaw is! List) return const {};

      final result = <String, _IngredientProgressPayload>{};

      for (final row in rowsRaw) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);
        final ingredientCode = _toText(m['IngredientCode']).isNotEmpty
            ? _toText(m['IngredientCode'])
            : _toText(m['ingredientCode']);
        if (ingredientCode.isEmpty) continue;

        final scansRaw = m['Scans'] ?? m['scans'] ?? const [];
        final scanRecords = <_IngredientScanRecord>[];
        if (scansRaw is List) {
          for (final scan in scansRaw) {
            if (scan is! Map) continue;
            final s = Map<String, dynamic>.from(scan);
            final labelId = _toText(s['LabelId']).isNotEmpty
                ? _toText(s['LabelId'])
                : _toText(s['labelId']);
            if (labelId.isEmpty) continue;

            scanRecords.add(
              _IngredientScanRecord(
                itemCode: _toText(s['ItemCode']).isNotEmpty
                    ? _toText(s['ItemCode'])
                    : ingredientCode,
                weight: _toDouble(s['Weight']),
                lot: _toText(s['Lot']),
                weightBatch: _toText(s['WeightBatch']).isNotEmpty
                    ? _toText(s['WeightBatch'])
                    : _toText(s['weightBatch']),
                labelId: labelId,
                scannedAt: _toDateTime(s['ScannedAt']) ?? DateTime.now(),
              ),
            );
          }
        }

        scanRecords.sort((a, b) => a.scannedAt.compareTo(b.scannedAt));

        final actualQty = _toDouble(m['ActualQty']) > 0
            ? _toDouble(m['ActualQty'])
            : scanRecords.fold<double>(0, (sum, r) => sum + r.weight);
        final isCompleted = m['IsCompleted'] == true ||
            m['Completed'] == true ||
            _toText(m['Status']).toLowerCase() == 'completed';
        final lastScannedAt =
            _toDateTime(m['LastScannedAt']) ??
            (scanRecords.isNotEmpty ? scanRecords.last.scannedAt : null);

        result[ingredientCode.toUpperCase()] = _IngredientProgressPayload(
          actualQty: actualQty,
          isCompleted: isCompleted,
          lastScannedAt: lastScannedAt,
          scans: scanRecords,
        );
      }

      _logApi('progress loaded ingredients=${result.length}');
      return result;
    } catch (e) {
      _logApi('progress fetch error: $e');
      return const {};
    }
  }

  Future<void> _loadExistingProgress() async {
    if (_ingredients.isEmpty) return;

    setState(() {
      _isLoadingExistingProgress = true;
    });

    final progressByCode = await _fetchExistingProgress();
    if (!mounted) return;

    if (progressByCode.isEmpty) {
      setState(() {
        _isLoadingExistingProgress = false;
      });
      return;
    }

    setState(() {
      _scanRecordsByIngredient.clear();
      _usedLabelIds.clear();

      for (var i = 0; i < _ingredients.length; i++) {
        final current = _ingredients[i];
        final payload = progressByCode[current.code.trim().toUpperCase()];
        if (payload == null) continue;

        final restoredQty = payload.actualQty;
        final overTarget = restoredQty > (current.targetQty + _toleranceKg);
        final reached = payload.isCompleted ||
            (restoredQty - current.targetQty).abs() <= _toleranceKg;

        _scanRecordsByIngredient[i] = List<_IngredientScanRecord>.from(payload.scans);
        for (final r in payload.scans) {
          final normalized = r.labelId.trim().toUpperCase();
          if (normalized.isNotEmpty) {
            _usedLabelIds.add(normalized);
          }
        }

        _ingredients[i] = current.copyWith(
          type: overTarget
              ? _IngredientType.warning
              : (reached ? _IngredientType.completed : _IngredientType.neutral),
          scannedQty: restoredQty,
          subtitle: overTarget
              ? 'Du lieu da luu vuot muc tieu, can kiem tra.'
              : (reached
                    ? 'Da dat ${restoredQty.toStringAsFixed(2)}/${current.targetQty.toStringAsFixed(2)} ${current.unit}'
                    : 'Da quet ${restoredQty.toStringAsFixed(2)}/${current.targetQty.toStringAsFixed(2)} ${current.unit}'),
          scannedAt: payload.lastScannedAt,
        );
      }

      final next = _findNextIncompleteIndex();
      _selectedIndex = next;
      for (var i = 0; i < _ingredients.length; i++) {
        final ing = _ingredients[i];
        if (ing.type == _IngredientType.completed || ing.type == _IngredientType.warning) {
          continue;
        }
        _ingredients[i] = ing.copyWith(
          type: i == next ? _IngredientType.waiting : _IngredientType.neutral,
          subtitle: i == next ? 'Dang cho quet...' : 'Cho xu ly',
        );
      }

      _isLoadingExistingProgress = false;
    });
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
    if (_isLoadingExistingProgress) return;
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
              'Mã cân theo mẫu: AIT01  <khối lượng> <Lot> <mẻ cân> <id tem>.',
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
          title: 'ÄÃ£ hoÃ n thÃ nh',
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
              subtitle: i == currentIndex ? 'Äang chá» quÃ©t...' : 'Chá» xá»­ lÃ½',
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
              'Tá»•ng khá»‘i lÆ°á»£ng vÆ°á»£t ngÆ°á»¡ng cho phÃ©p. ÄÃ£ xÃ³a báº£n ghi cá»§a nguyÃªn liá»‡u nÃ y Ä‘á»ƒ quÃ©t láº¡i.',
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
              ? 'ÄÃ£ Ä‘áº¡t ${nextScanned.toStringAsFixed(2)}/${current.targetQty.toStringAsFixed(2)} ${current.unit}'
              : 'ÄÃ£ quÃ©t ${nextScanned.toStringAsFixed(2)}/${current.targetQty.toStringAsFixed(2)} ${current.unit}',
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
            subtitle: i == next ? 'Äang chá» quÃ©t...' : 'Chá» xá»­ lÃ½',
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
    if (_isLoadingExistingProgress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải tiến độ đã quét, vui lòng đợi.')),
      );
      return;
    }

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
        automaticallyImplyLeading: false,
        toolbarHeight: 0, // Hide AppBar but keep status bar background
      ),
      body: Column(
        children: [
          // Pinned Metrics Region
          Container(
            color: const Color(0xFF111827),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'MỤC TIÊU',
                    value: totalTarget.toStringAsFixed(2),
                    unit: 'Kgs',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    label: 'HIỆN TẠI',
                    value: totalScanned.toStringAsFixed(2),
                    unit: 'Kgs',
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
          ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTankHeaderCard(),
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
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  label: const Text(
                    'Quay lại',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ManualConfirmScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.keyboard_outlined, size: 20),
                  label: const Text(
                    'Nhập T.Công',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.white10),
                    ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storage_outlined,
                    color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TANK: ${widget.tankNumber ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PO: ${widget.productionOrder ?? ''}',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Batch: ${widget.batchNumber ?? ''}',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white10, height: 1),
          ),
          _buildInfoRow(
              Icons.inventory_2_outlined,
              'Product',
              '${widget.productCode ?? ''} - ${widget.productName ?? ''}'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildInfoRow(Icons.receipt_long_outlined, 'Recipe',
                    widget.recipeName ?? ''),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  'Ver: ${widget.recipeVersion ?? ''}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildInfoRow(Icons.schedule_outlined, 'Planned',
              widget.plannedStart ?? ''),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: Colors.white54),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
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

  Widget _buildScanStatusCard() {
    return InkWell(
      onTap: _isLoadingExistingProgress ? null : _handleScanTap,
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
                _isLoadingExistingProgress
                    ? 'Đang tải tiến độ đã quét...'
                    : (_isProcessingScan
                          ? 'Đang xử lý kết quả quét...'
                          : 'Nhấn để mở máy quét'),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
          ),
        ],
      ),
    );
  }
}


