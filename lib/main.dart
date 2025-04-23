import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'main_screen/auth_rapper.dart';
import 'package:provider/provider.dart';
import 'provider.dart' as provider;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'business_trip/survey_screen/growth_survey.dart';
import 'package:flutter/gestures.dart';
import 'main_screen/windows_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid){
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);}
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    initWindows();
    windowManager.setFullScreen(true);
    sqfliteFfiInit();

  // global databaseFactory를 FFI 구현으로 설정
  databaseFactory = databaseFactoryFfi;
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
    ChangeNotifierProvider(
      create: (_) => SurveyState(farmId: 1)),
      ],child:AgriculturalBigdataApp()));
}

// 클래스 추
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,       // 마우스 드래그 허용
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
    PointerDeviceKind.trackpad,    // 트랙패드도 명시적으로 추가 가능
  };
}
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
      scrollBehavior: AppScrollBehavior(),
      title: '농업빅데이터조사',
      theme: settings.isDarkMode ? ThemeData.dark() : ThemeData(
        brightness: Brightness.light, // 라이트 모드 설정
        scaffoldBackgroundColor: Colors.white),
      home: Platform.isAndroid?AuthWrapper():WindowsMainScreen(),

      builder: (context, child) {
        // 최신 Flutter에서는 textScaler 사용
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0), // 텍스트 크기 고정
          ),
          child: child!,
        );
      },
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
