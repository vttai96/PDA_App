import 'dart:convert';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'config/api_config.dart';
import 'dashboard_screen.dart';
import 'services/update_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _usersPath = '/users/list';
  static const String _loginPath = '/auth/login';

  String pin = '';
  bool _isAuthenticating = false;
  bool _isLoadingUsers = true;
  String? _selectedUserId;
  String? _loadError;

  final TextEditingController _adminPasswordController =
      TextEditingController();

  List<Map<String, String?>> _users = const [];

  void _logApi(String message) {
    debugPrint('[API][LOGIN] $message');
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  @override
  void dispose() {
    _adminPasswordController.dispose();
    super.dispose();
  }

  String _currentShiftBadge() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) return 'Ca 1 - 06:00-14:00';
    if (hour >= 14 && hour < 22) return 'Ca 2 - 14:00-22:00';
    return 'Ca 3 - 22:00-06:00';
  }

  String _currentShiftCode() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) return 'Ca1';
    if (hour >= 14 && hour < 22) return 'Ca2';
    return 'Ca3';
  }

  bool _isSuccessResponse(Map<String, dynamic> body) {
    final message = body['Message']?.toString().trim().toLowerCase();
    return message == 'success';
  }

  void _setFallbackAdmin(String reason) {
    _users = const [
      {
        'id': 'LOCAL_ADMIN',
        'name': 'Admin',
        'role': 'Quản lý hệ thống',
        'roleLevel': '99999',
        'isLocalAdmin': 'true',
      },
    ];
    _selectedUserId = 'LOCAL_ADMIN';
    _loadError = '$reason Đang dùng Admin mặc định.';
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _loadError = null;
    });

    try {
      final uri = ApiConfig.endpoint(_usersPath);
      final req = jsonEncode({'Shift': _currentShiftCode()});
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
          _isLoadingUsers = false;
          _setFallbackAdmin(
            'Không tải được danh sách user (HTTP ${response.statusCode}).',
          );
        });
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (!_isSuccessResponse(body)) {
        setState(() {
          _isLoadingUsers = false;
          _setFallbackAdmin(
            body['Error']?.toString() ?? 'Không tải được danh sách user.',
          );
        });
        return;
      }

      final data = body['Data'];
      final listRaw = data is Map<String, dynamic>
          ? data['Users']
          : (data is List ? data : null);

      if (listRaw is! List) {
        setState(() {
          _isLoadingUsers = false;
          _setFallbackAdmin('Dữ liệu user API không đúng.');
        });
        return;
      }

      final users = listRaw
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .map<Map<String, String?>>((u) {
            final id = (u['UserId'] ?? u['UserCode'] ?? '').toString().trim();
            final userName =
                (u['UserName'] ?? u['Name'] ?? '')
                    .toString()
                    .trim();
            final roleName =
                (u['RoleName'] ?? u['Role'] ?? '')
                    .toString()
                    .trim();
            final employeeId =
                (u['EmployeeId'] ?? '').toString().trim();
            final roleLevel = (u['RoleLevel'] ?? '0').toString().trim();
            final role = roleName.isEmpty
                ? (employeeId.isEmpty ? '' : 'ID: $employeeId')
                : (employeeId.isEmpty
                      ? roleName
                      : '$roleName - ID: $employeeId');

            return {
              'id': id,
              'name': userName,
              'role': role,
              'roleLevel': roleLevel,
              'isLocalAdmin': 'false',
            };
          })
          .where(
            (u) =>
                (u['id'] ?? '').isNotEmpty && (u['name'] ?? '').isNotEmpty,
          )
          .toList();

      if (users.isEmpty) {
        setState(() {
          _isLoadingUsers = false;
          _setFallbackAdmin('Danh sách user trong API rỗng.');
        });
        return;
      }

      setState(() {
        _users = users;
        _isLoadingUsers = false;
        _selectedUserId = users.first['id'];
        _loadError = null;
      });
    } catch (e) {
      _logApi('ERROR _loadUsers: $e');
      setState(() {
        _isLoadingUsers = false;
        _setFallbackAdmin('Lỗi kết nối khi tải user: $e.');
      });
    }
  }

  Map<String, String?>? _selectedUserMap() {
    if (_selectedUserId == null) return null;
    for (final u in _users) {
      if (u['id'] == _selectedUserId) return u;
    }
    return null;
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await UpdateService.instance.checkForUpdate();
    if (!mounted) return;
    if (updateInfo.hasUpdate) {
      _showUpdateDialog(updateInfo);
    }
  }

  void _showUpdateDialog(UpdateInfo info) {
    showDialog(
      context: context,
      barrierDismissible: !info.isForceUpdate,
      builder: (context) {
        return PopScope(
          canPop: !info.isForceUpdate,
          child: AlertDialog(
            title: const Text('Bản cập nhật mới', style: TextStyle(color: Colors.black)),
            content: Text(
              'Đã có phiên bản ${info.latestVersion}.\n\n${info.releaseNotes}',
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              if (!info.isForceUpdate)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Bỏ qua'),
                ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _startDownload(info.downloadUrl);
                },
                child: const Text('Cập nhật ngay'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startDownload(String downloadUrl) {
    double progress = 0.0;
    bool isDownloading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!isDownloading) {
              isDownloading = true;
              UpdateService.instance.downloadAndInstall(
                downloadUrl,
                (p) {
                  if (mounted) {
                    setState(() {
                      progress = p;
                    });
                  }
                },
              ).then((_) {
                 if (mounted && Navigator.of(context).canPop()) {
                   Navigator.of(context).pop();
                 }
              }).catchError((e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi tải xuống: $e')),
                  );
                }
              });
            }

            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('Đang tải bản cập nhật', style: TextStyle(color: Colors.black)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 16),
                    Text('${(progress * 100).toStringAsFixed(1)} %', style: const TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitPin() async {
    if (_isAuthenticating) return;
    final selected = _selectedUserMap();
    if (selected == null) return;

    if (selected['isLocalAdmin'] == 'true') {
      final envPassword = (dotenv.env['ADMIN_PASSWORD'] ??
              dotenv.env['DEFAULT_ADMIN_PASSWORD'] ??
              'TANTIEN@123')
          .trim();
      final input = _adminPasswordController.text.trim();

      if (input == envPassword) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              user: const {
                'id': 'LOCAL_ADMIN',
                'name': 'Admin',
                'role': 'Quản lý hệ thống',
                'roleLevel': '99999',
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu Admin không đúng.')),
        );
      }
      return;
    }

    setState(() => _isAuthenticating = true);

    try {
      final body = {
        'UserId': selected['id'] ?? '',
        'Pin': pin,
        'Shift': _currentShiftCode(),
        'DeviceTime': DateTime.now().toIso8601String(),
      };
      final uri = ApiConfig.endpoint(_loginPath);
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

      if (!mounted) return;

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại (HTTP ${response.statusCode}).'),
          ),
        );
        setState(() {
          pin = '';
          _isAuthenticating = false;
        });
        return;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (!_isSuccessResponse(payload)) {
        final msg = payload['Error']?.toString() ?? 'Đăng nhập thất bại.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        setState(() {
          pin = '';
          _isAuthenticating = false;
        });
        return;
      }

      final data = payload['Data'];
      final userData = data is Map<String, dynamic>
          ? (data['User'] is Map
                ? (data['User'] as Map).cast<String, dynamic>()
                : null)
          : null;

      final roleLevel =
          (userData?['RoleLevel'] ?? selected['roleLevel'] ?? '0')
              .toString()
              .trim();

      final userToDashboard = <String, String?>{
        'id': (userData?['UserId'] ?? selected['id'] ?? '').toString(),
        'name': (userData?['UserName'] ?? selected['name'] ?? '').toString(),
        'role': (userData?['RoleName'] ?? selected['role'] ?? '').toString(),
        'token':
            (data is Map<String, dynamic> ? (data['Token'] ?? '') : '')
                .toString(),
        'roleLevel': roleLevel,
      };

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(user: userToDashboard)),
      );
    } catch (e) {
      _logApi('ERROR _submitPin: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối đăng nhập: $e')),
      );
      setState(() => pin = '');
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _onDigitTap(String digit) {
    if (_isAuthenticating || pin.length >= 4) return;
    setState(() => pin += digit);
    if (pin.length == 4) {
      Future.microtask(_submitPin);
    }
  }

  void _onBackspaceTap() {
    if (_isAuthenticating || pin.isEmpty) return;
    setState(() => pin = pin.substring(0, pin.length - 1));
  }

  void _onClearTap() {
    if (_isAuthenticating || pin.isEmpty) return;
    setState(() => pin = '');
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedUserMap();
    final isLocalAdmin = selected?['isLocalAdmin'] == 'true';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              Expanded(child: _buildUserSelection()),
              const SizedBox(height: 12),
              if (_selectedUserId != null) ...[
                _buildPinEntry(),
                if (!isLocalAdmin) ...[
                  const SizedBox(height: 12),
                  _buildNumpad(),
                ],
              ],
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
              'Masan MMB',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text('Sản xuất', style: TextStyle(color: Colors.grey)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CHỌN NGƯỜI VẬN HÀNH',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentShiftBadge(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : (_users.isEmpty && _loadError != null)
              ? _buildLoadError()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_loadError != null) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            _loadError!,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      ..._users.map(_buildUserTile),
                      const SizedBox(height: 8),
                      _buildGuestLogin(),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _loadError ?? 'Có lỗi',
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _loadUsers,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, String?> user) {
    final isSelected = _selectedUserId == (user['id'] ?? '');
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserId = user['id'];
          pin = '';
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
            const CircleAvatar(backgroundColor: Colors.grey, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
            ),
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
              Icon(Icons.person_outline, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text(
                'Đăng nhập khách (tắt)',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinEntry() {
    final selected = _selectedUserMap();
    final selectedName = selected?['name'] ?? 'Người dùng';
    final isLocalAdmin = selected?['isLocalAdmin'] == 'true';

    if (isLocalAdmin) {
      return Column(
        children: [
          Text(
            selectedName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adminPasswordController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu Admin',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitPin,
              child: const Text('Đăng nhập Admin'),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          selectedName,
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
      height: 220,
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ...List.generate(9, (index) => _buildNumpadButton('${index + 1}')),
          _buildNumpadButton('X', isIcon: true, iconData: Icons.backspace),
          _buildNumpadButton('0'),
          _buildNumpadButton('C', isIcon: true, iconData: Icons.close),
        ],
      ),
    );
  }

  Widget _buildNumpadButton(
    String text, {
    bool isIcon = false,
    IconData? iconData,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.blue.withValues(alpha: 0.3),
        highlightColor: Colors.blue.withValues(alpha: 0.15),
        onTap: () {
          if (isIcon) {
            if (text == 'X') {
              _onBackspaceTap();
            } else {
              _onClearTap();
            }
            return;
          }
          _onDigitTap(text);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: isIcon
                ? Icon(iconData ?? Icons.close, color: Colors.red, size: 20)
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
}
