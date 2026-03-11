import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/custom_bottom_nav.dart';
import 'history_detail_screen.dart';
import 'scan_detail_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // false = newest first (default), true = oldest first
  bool _ascending = false;

  // sample data for rendering
  final List<Map<String, String>> _records = [
    {
      'id': '402',
      'title': 'RECIPE A12',
      'time': '14:30 - 24/10/2023',
      'operator': 'Nguyễn Văn A',
      'status': 'HOÀN THÀNH',
      'day': 'today',
      'highlight': 'false',
    },
    {
      'id': '305',
      'title': 'MIX B-22',
      'time': '10:15 - 24/10/2023',
      'operator': 'Trần Thị B',
      'status': 'HOÀN THÀNH',
      'day': 'today',
      'highlight': 'false',
    },
    {
      'id': '112',
      'title': 'SOLVENT X',
      'time': '08:45 - 24/10/2023',
      'operator': 'Lê Văn C',
      'status': 'CẢNH BÁO',
      'day': 'today',
      'highlight': 'true',
    },
    {
      'id': '208',
      'title': 'BASE OIL 50',
      'time': '16:20 - 23/10/2023',
      'operator': 'Phạm Văn D',
      'status': 'HOÀN THÀNH',
      'day': 'yesterday',
      'highlight': 'false',
    },
  ];

  DateTime _parseRecordDate(Map<String, String> r) {
    // format: 'HH:mm - dd/MM/yyyy'
    final time = r['time'] ?? '';
    final parts = time.split('-');
    if (parts.length < 2) return DateTime(1970);

    final timePart = parts[0].trim(); // HH:mm
    final datePart = parts[1].trim(); // dd/MM/yyyy

    final timeSplit = timePart.split(':');
    final dateSplit = datePart.split('/');

    try {
      return DateTime(
        int.parse(dateSplit[2]), // year
        int.parse(dateSplit[1]), // month
        int.parse(dateSplit[0]), // day
        int.parse(timeSplit[0]), // hour
        int.parse(timeSplit[1]), // minute
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
      // ascending: oldest first, descending: newest first
      return _ascending ? da.compareTo(db) : db.compareTo(da);
    });
    return list;
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

  Widget _statusPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: text == 'HOÀN THÀNH'
            ? const Color(0xFF1A3935)
            : (text == 'CẢNH BÁO'
                  ? const Color(0xFFB7811B)
                  : const Color(0xFF17242C)),
        border: Border.all(
          color: text == 'HOÀN THÀNH'
              ? Colors.greenAccent.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.4),
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
              color: text == 'HOÀN THÀNH'
                  ? Colors.greenAccent.withValues(alpha: 0.4)
                  : (text == 'CẢNH BÁO'
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF17242C)),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _recordCard(
    BuildContext context, {
    required String id,
    required String title,
    required String time,
    required String operator,
    required Widget status,
    bool highlighted = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C395E),
          borderRadius: BorderRadius.circular(12),
          border: highlighted
              ? Border.all(color: const Color(0xFFB7811B), width: 2)
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: highlighted
                    ? const Color(0xFF494031)
                    : const Color(0xFF21364A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: !highlighted
                  ? const Icon(
                      Icons.local_mall,
                      color: Color(0xFF137FEC),
                      size: 28,
                    )
                  : const Icon(
                      Icons.warning_outlined,
                      color: Color(0xFFF59E0B),
                      size: 28,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '#$id',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '• $title',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          time,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      status,
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'NV: $operator',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          'Lịch Sử Đổ Liệu',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _ascending ? Icons.arrow_upward : Icons.arrow_downward,
              color: Colors.white,
            ),
            tooltip: _ascending ? 'Cũ nhất trước' : 'Mới nhất trước',
            onPressed: () {
              setState(() {
                _ascending = !_ascending;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // search field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF17242C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2B3942)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.white54),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tìm kiếm mã bồn...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // big scan button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    _slideRoute(const ScanDetailScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
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
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3EA0FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'QUÉT MÃ ĐỂ TÌM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tra cứu thông tin nhanh',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
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

            const SizedBox(height: 20),
            // data-driven history lists
            if (!_ascending) ...[
              // newest first: today section on top, then yesterday
              const Text(
                'HÔM NAY',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // render today's records (sorted)
              ...[
                for (var r in _sortedRecordsForDay('today'))
                  _recordCard(
                    context,
                    id: r['id']!,
                    title: r['title']!,
                    time: r['time']!,
                    operator: r['operator']!,
                    status: _statusPill(r['status']!),
                    highlighted: r['highlight'] == 'true',
                    onTap: () {
                      Navigator.push(
                        context,
                        _slideRoute(HistoryDetailScreen(record: r)),
                      );
                    },
                  ),
              ],

              const SizedBox(height: 12),
              const Text(
                'HÔM QUA',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // render yesterday's records (sorted)
              ...[
                for (var r in _sortedRecordsForDay('yesterday'))
                  _recordCard(
                    context,
                    id: r['id']!,
                    title: r['title']!,
                    time: r['time']!,
                    operator: r['operator']!,
                    status: _statusPill(r['status']!),
                    onTap: () {
                      Navigator.push(
                        context,
                        _slideRoute(HistoryDetailScreen(record: r)),
                      );
                    },
                  ),
              ],
            ] else ...[
              // oldest first: yesterday section on top, then today
              const Text(
                'HÔM QUA',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // render yesterday's records (sorted)
              ...[
                for (var r in _sortedRecordsForDay('yesterday'))
                  _recordCard(
                    context,
                    id: r['id']!,
                    title: r['title']!,
                    time: r['time']!,
                    operator: r['operator']!,
                    status: _statusPill(r['status']!),
                    onTap: () {
                      Navigator.push(
                        context,
                        _slideRoute(HistoryDetailScreen(record: r)),
                      );
                    },
                  ),
              ],

              const SizedBox(height: 12),
              const Text(
                'HÔM NAY',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // render today's records (sorted)
              ...[
                for (var r in _sortedRecordsForDay('today'))
                  _recordCard(
                    context,
                    id: r['id']!,
                    title: r['title']!,
                    time: r['time']!,
                    operator: r['operator']!,
                    status: _statusPill(r['status']!),
                    highlighted: r['highlight'] == 'true',
                    onTap: () {
                      Navigator.push(
                        context,
                        _slideRoute(HistoryDetailScreen(record: r)),
                      );
                    },
                  ),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: 2,
        onTap: (index) {
          if (index == 0) {
            // Về lại Dashboard gốc, xoá History khỏi stack nên không còn nút back
            Navigator.popUntil(context, (route) => route.isFirst);
            return;
          }
          if (index == 1) {
            Navigator.push(context, _slideRoute(const ScanDetailScreen()));
            return;
          }
          if (index == 2) {
            // Đang ở tab lịch sử, không cần xử lý
            return;
          }
          if (index == 3) {
            Navigator.push(context, _slideRoute(const SettingsScreen()));
            return;
          }
        },
      ),
    );
  }
}
