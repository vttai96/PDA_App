import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/datawedge_service.dart';
import 'config/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Lỗi load file .env: $e');
  }

  await DataWedgeService.instance.initialize();
  await ApiConfig.loadSavedUrl();

  // runApp(
  //   DevicePreview(
  //     enabled: kDebugMode && kIsWeb,
  //     builder: (context) => const MyApp(),
  //   ),
  // );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: 'PDA App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: const Color(0xFF1A202C),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
