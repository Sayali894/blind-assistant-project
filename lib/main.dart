import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  WakelockPlus.enable();
  runApp(const BlindAssistantApp());
}

class BlindAssistantApp extends StatelessWidget {
  const BlindAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blind Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFFFFD600),
          surface: Color(0xFF0A0A0A),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
