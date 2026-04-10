import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:my_pda/presentation/screens/auth/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_pda/data/services/datawedge_service.dart';
import 'package:my_pda/core/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:my_pda/logic/providers/auth_provider.dart';
import 'package:my_pda/logic/providers/scanner_provider.dart';
import 'package:my_pda/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Lỗi load file .env: $e');
  }

  await DataWedgeService.instance.initialize();
  await ApiConfig.loadSavedUrl();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScannerProvider()),
      ],
      child: MaterialApp(
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        debugShowCheckedModeBanner: false,
        title: 'PDA App',
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
