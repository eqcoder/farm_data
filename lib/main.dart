import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'extract_data/main_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'business_trip/business_trip_screen.dart';
import 'farm_info/farm_info_screen.dart';
import 'main_screen.dart/android_screen.dart';
import 'main_screen.dart/windows_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    initWindows();
    windowManager.setFullScreen(true);
  }
  await dotenv.load(fileName: '.env');
  // await extractData('D:/Desktop/farm/farm_data/tomato1.JPG');

  runApp(const AgriculturalBigdataApp());
}

// 클래스 추

Future<void> initWindows() async {
  // `window_manager` 초기화

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(2400, 1200),
    minimumSize: Size(800, 160),
    center: true,
    backgroundColor: Color.fromARGB(255, 255, 255, 255),
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
  const AgriculturalBigdataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '농업빅데이터조사',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto', // 원하는 폰트로 변경 가능
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
      appBar: AppBar(
        title: const Text('농업빅데이터조사'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              windowManager.close();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            color: Colors.grey[700],
            onPressed: () {
              // 환경설정 기능 구현
              print('환경설정 버튼 클릭');
            },
          ),
        ],
      ),
      body: Platform.isAndroid
                ? AndroidMainScreen()
                : WindowsMainScreen(),
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
