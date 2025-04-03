import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'extract_data/main_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'business_trip/business_trip_screen.dart';
import 'farm_info/farm_info_screen.dart';
import 'main_screen.dart/android_screen.dart';
import 'main_screen.dart/windows_screen.dart';
import 'main_screen.dart/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'main_screen.dart/auth_rapper.dart';
import 'package:provider/provider.dart';
import 'provider.dart' as provider;
import 'setting.dart';
import 'appbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid){
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);}
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    initWindows();
    windowManager.setFullScreen(true);
  }
  await dotenv.load(fileName: '.env');
  final settings = provider.SettingsProvider();
  await settings.loadSettings();
  // await extractData('D:/Desktop/farm/farm_data/tomato1.JPG');

  runApp( MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => provider.AuthProvider()),
        ChangeNotifierProvider(
      create: (_) => settings,
    ),
      ],child:AgriculturalBigdataApp()));
}

// 클래스 추

Future<void> initWindows() async {
  // `window_manager` 초기화

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(2400, 1200),
    minimumSize: Size(800, 160),
    center: true,
    backgroundColor: Color.fromARGB(255, 0, 0, 0),
    titleBarStyle: TitleBarStyle.hidden,
  );

  // 윈도우가 준비된 후 보여주기
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize();
  });
}

class AgriculturalBigdataApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<provider.SettingsProvider>(context);
    return MaterialApp(
      title: '농업빅데이터조사',
      theme: settings.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "농업빅데이터조사"),
      body: Platform.isAndroid
          ? AuthWrapper() // 안드로이드 화면
          : WindowsMainScreen(), // 윈도우 화면// 스플래시 화면을 기본 화면으로 설정
      bottomNavigationBar: const BottomAppBar(
        // BottomAppBar를 사용하여 바닥에 공간 확보
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              '© 2025 농업기술원 스마트농업데이터조사. All rights reserved.',
              style: TextStyle(
                fontSize: 12.0,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
