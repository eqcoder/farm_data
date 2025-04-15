import 'package:farm_data/business_trip/business_trip_screen.dart';
import 'package:farm_data/database.dart';
import 'package:farm_data/extract_data/main_screen.dart';
import 'package:farm_data/farm_info/farm_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../extract_data/main_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import '../business_trip/business_trip_screen.dart';
import '../farm_info/farm_info_screen.dart';
import 'form.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../business_trip/opinet.dart';
import '../home/windows_home_screen.dart';
import '../setting.dart';
import '../provider.dart' as provider;
import 'package:provider/provider.dart';


class WindowsScreen extends StatelessWidget {
   WindowsScreen({super.key});
  final settings = provider.SettingsProvider();
Widget build(BuildContext context) {
    return MaterialApp(
      title: '스마트농업데이터조사',
      theme: settings.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: const WindowsMainScreen(),
    );
  }
}

class WindowsMainScreen extends StatefulWidget {
  const WindowsMainScreen({super.key});

  @override
  State<WindowsMainScreen> createState() => _WindowsMainScreenState();
}

class _WindowsMainScreenState extends State<WindowsMainScreen> {
int _selectedIndex = 0;
Widget build(BuildContext context) {
  List<Widget> _screens = [
    WindowsHomeScreen(), EnterDataScreen(), FarmInfoScreen(),Opinet(), // 각 화면을 리스트로 관리
  ];
  
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(30.0),child:AppBar(
        backgroundColor: const Color.fromARGB(255, 3, 77, 40),
        title: const Text(''),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              windowManager.close();
            },
          ),
        ],
      ),),
      body: Row(
        children: [
          // 좌측 드로어 (고정 너비)
          Container(
            width: 240,
            color: Colors.grey[200],
            child: Column(
              children: [
                // 드로어 상단

                // 드로어 항목 리스트
                Expanded(
                  child:ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Color.fromARGB(255, 9, 112, 60)),
                  child: Center(child:Text('스마트농업데이터', style: TextStyle(color: Colors.white, fontSize: 24))),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('홈'),
                  selected: _selectedIndex == 0,
                  onTap: () => _updateScreen(0),
                ),
                ListTile(
                  leading: const Icon(Icons.query_stats),
                  title: const Text('야장추출'),
                  selected: _selectedIndex == 1,
                  onTap: () => _updateScreen(1),
                ),
                ListTile(
                  leading: const Icon(Icons.manage_search),
                  title: const Text('농가정보'),
                  selected: _selectedIndex == 2,
                  onTap: () => _updateScreen(2),
                ),
                ListTile(
                  leading: const Icon(Icons.payments),
                  title: const Text('여비운임비'),
                  selected: _selectedIndex == 2,
                  onTap: () => _updateScreen(3),
                ),
              ],
            ),
          ),
          Container(
                  padding: const EdgeInsets.all(16.0),
                  child: InkWell(
                    onTap: () {
                      // 환경설정 클릭 시 동작
                      showDialog(
                        context: context,
                        builder: (context) => SettingsDialog(),
                      );
                    },
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.settings, color: Colors.grey),
                        const Text('환경설정',
                            style:
                                TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
          )])),
          

          // 우측 콘텐츠 영역
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  // 화면 업데이트 메서드
  void _updateScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}