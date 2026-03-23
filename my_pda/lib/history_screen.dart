import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'barcode_scanner_screen.dart';
import 'config/api_config.dart';
import 'history_detail_screen.dart';
import 'scan_detail_screen.dart';
import 'services/datawedge_service.dart';
import 'widgets/custom_bottom_nav.dart';

class HistoryScreen extends StatefulWidget {
  final Map<String, String?>? user;

  const HistoryScreen({super.key, this.user});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const String _historySearchPath = '/history/search';

  bool _ascending = false;
  bool _isLoading = false;
  bool _isProcessingScan = false;
  String _filterText = 'Tất cả';
  String? _error;
  List<Map<String, String>> _records = const [];
  StreamSubscription? _scanSubscription;

  void _logApi(String message) {
    debugPrint('[API][HISTORY] $message');
  }

  @override
  void initState() {
    super.initState();
    _bindScanner();
    _loadHistory();
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
      _handleScannedCode(raw);
    });
  }

  bool _isSuccessResponse(Map<String, dynamic> body) {
    final message = body['Message']?.toString().trim().toLowerCase();
    return message == 'success';
  }

  String _formatTime(String isoOrText) {
    final date = DateTime.tryParse(isoOrText);
    if (date == null) return isoOrText;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.hour)}:${two(date.minute)} - ${two(date.day)}/${two(date.month)}/${date.year}';
  }

  String _dayTag(String isoOrText) {
    final date = DateTime.tryParse(isoOrText);
    if (date == null) return 'older';
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'today';
    }
    return 'older';
  }

  Future<void> _loadHistory({String? queryType, String? queryValue}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final body = {
      'QueryType': (queryType ?? 'ALL').toUpperCase(),
      'QueryValue': (queryValue ?? '').trim(),
      'DateFrom': '',
      'DateTo': '',
      'Limit': 100,
    };

    try {
      final uri = ApiConfig.endpoint(_historySearchPath);
      final req = jsonEncode(body);
      _logApi('POST $uri');
      _logApi('REQ $req');
      final response = await http
          .post(
            uri,
            headers: ApiConfig.defaultHeaders,
            body: req,
          )
          .timeout(const Duration(seconds: 12));
      _logApi('RES status=${response.statusCode}');
      _logApi('RES body=${response.body}');

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = 'Không lấy được lịch sử (HTTP ${response.statusCode}).';
        });
        return;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (!_isSuccessResponse(payload)) {
        setState(() {
          _isLoading = false;
          _error = payload['Error']?.toString() ?? 'Không lấy được lịch sử.';
        });
        return;
      }

      final data = payload['Data'];
      final listRaw = data is Map<String, dynamic> ? data['Records'] : null;
      if (listRaw is! List) {
        setState(() {
          _records = const [];
          _isLoading = false;
          _error = null;
        });
        return;
      }

      final mapped = listRaw.whereType<Map>().map((raw) {
        final item = raw.map((k, v) => MapEntry(k.toString(), v));
        final status = (item['Status'] ?? '').toString().trim();
        final completedAt = (item['CompletedAt'] ?? item['Time'] ?? '').toString().trim();
        final warning = item['HasWarning'] == true || status.toUpperCase() == 'WARNING';

        return <String, String>{
          'id': (item['RecordId'] ?? item['Id'] ?? '').toString(),
          'title': (item['Title'] ?? item['BatchNumber'] ?? item['TankNumber'] ?? '').toString(),
          'time': _formatTime(completedAt),
          'operator': (item['OperatorName'] ?? item['Operator'] ?? '').toString(),
          'status': status.isEmpty ? 'UNKNOWN' : status.toUpperCase(),
          'day': _dayTag(completedAt),
          'highlight': warning ? 'true' : 'false',
        };
      }).toList();

      setState(() {
        _records = mapped;
        _isLoading = false;
      });
    } catch (e) {
      _logApi('ERROR _loadHistory: $e');
      setState(() {
        _isLoading = false;
        _error = 'Lỗi kết nối lịch sử: $e';
      });
    }
  }

  ({String type, String value, String label})? _parseHistoryScan(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final tankMatch = RegExp(r'^AIT10\s+(.+)$', caseSensitive: false).firstMatch(text);
    if (tankMatch != null) {
      final tank = (tankMatch.group(1) ?? '').trim();
      if (tank.isNotEmpty) {
        return (type: 'TANK', value: tank, label: 'Tank: $tank');
      }
    }

    final tokens = text.split(RegExp(r'\s+'));
    if (tokens.length >= 6 && tokens.first.toUpperCase() == 'AIT01') {
      final labelId = tokens.sublist(5).join(' ').trim();
      if (labelId.isNotEmpty) {
        return (type: 'LABEL', value: labelId, label: 'Tem: $labelId');
      }
    }

    return null;
  }

  Future<void> _handleScannedCode(String raw) async {
    if (_isProcessingScan) return;
    _isProcessingScan = true;

    try {
      final parsed = _parseHistoryScan(raw);
      if (parsed == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã quét không hợp lệ. Dùng AIT10 <Tank> hoặc AIT01 ... <id tem>.'),
          ),
        );
        return;
      }

      setState(() => _filterText = parsed.label);
      await _loadHistory(queryType: parsed.type, queryValue: parsed.value);
    } finally {
      _isProcessingScan = false;
    }
  }

  Future<void> _triggerScan() async {
    if (DataWedgeService.instance.isSupported) {
      await DataWedgeService.instance.softTrigger();
      return;
    }

    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen(fromDashboard: true)),
    );

    if (raw == null || !mounted) return;
    await _handleScannedCode(raw);
  }

  DateTime _parseRecordDate(Map<String, String> r) {
    final text = r['time'] ?? '';
    final parts = text.split('-');
    if (parts.length < 2) return DateTime(1970);

    final timePart = parts[0].trim();
    final datePart = parts[1].trim();
    final timeSplit = timePart.split(':');
    final dateSplit = datePart.split('/');

    try {
      return DateTime(
        int.parse(dateSplit[2]),
        int.parse(dateSplit[1]),
        int.parse(dateSplit[0]),
        int.parse(timeSplit[0]),
        int.parse(timeSplit[1]),
      );
    } catch (_) {
      return DateTime(1970);
    }
  }

  List<Map<String, String>> _sortedRecordsForDay(String day) {
    final list = _records.where((e) => e['day'] == day).toList();
    list.sort((a, b) {
      final da = _parseRecordDate(a);
      final db = _parseRecordDate(b);
      return _ascending ? da.compareTo(db) : db.compareTo(da);
    });
    return list;
  }

  Route _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOut;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  Widget _statusPill(String text) {
    final normalized = text.toUpperCase();
    final isDone = normalized == 'COMPLETED' || normalized == 'HOAN THANH';
    final isWarn = normalized == 'WARNING' || normalized == 'CANH BAO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDone
            ? const Color(0xFF1A3935)
            : (isWarn ? const Color(0xFFB7811B) : const Color(0xFF17242C)),
        border: Border.all(
          color: isDone ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.4),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _recordCard(BuildContext context, Map<String, String> r) {
    final highlighted = r['highlight'] == 'true';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, _slideRoute(HistoryDetailScreen(record: r)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C395E),
          borderRadius: BorderRadius.circular(12),
          border: highlighted ? Border.all(color: const Color(0xFFB7811B), width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: highlighted ? const Color(0xFF494031) : const Color(0xFF21364A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                highlighted ? Icons.warning_outlined : Icons.local_mall,
                color: highlighted ? const Color(0xFFF59E0B) : const Color(0xFF137FEC),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${r['id'] ?? ''} • ${r['title'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(r['time'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('NV: ${r['operator'] ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _statusPill(r['status'] ?? 'UNKNOWN'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _loadHistory, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final today = _sortedRecordsForDay('today');
    final older = _sortedRecordsForDay('older');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF17242C),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2B3942)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bộ lọc: $_filterText',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _filterText = 'Tất cả');
                    _loadHistory();
                  },
                  icon: const Icon(Icons.clear, color: Colors.white54),
                  tooltip: 'Xóa bộ lọc',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _triggerScan,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B78FF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'QUÉT MÃ TANK / TEM NGUYÊN LIỆU ĐỂ TÌM LỊCH SỬ',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('HÔM NAY', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (today.isEmpty)
            const Text('Không có dữ liệu.', style: TextStyle(color: Colors.white54)),
          ...today.map((r) => _recordCard(context, r)),
          const SizedBox(height: 12),
          const Text('TRƯỚC ĐÓ', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (older.isEmpty)
            const Text('Không có dữ liệu.', style: TextStyle(color: Colors.white54)),
          ...older.map((r) => _recordCard(context, r)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF243241),
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'Lịch Sử Dữ Liệu',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white),
            tooltip: _ascending ? 'Cũ nhất trước' : 'Mới nhất trước',
            onPressed: () {
              setState(() => _ascending = !_ascending);
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
            return;
          }
          if (index == 1) {
            Navigator.push(context, _slideRoute(const ScanDetailScreen()));
            return;
          }
        },
      ),
    );
  }
}
