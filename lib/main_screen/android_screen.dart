import 'package:farm_data/appbar.dart';
import 'package:farm_data/business_trip/business_trip_screen.dart';
<<<<<<< HEAD
import 'package:farm_data/database.dart';
=======
import '../../database/database.dart';
>>>>>>> ec509ac02e3f67dbf917d9324c1461cf57618522
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
import 'package:provider/provider.dart';
import '../provider.dart' as provider;
import '../home/android_home_screen.dart';
import '../manual/manualscreen.dart';

class AndroidMainScreen extends StatefulWidget {
  @override
  _AndroidMainScreenState createState() => _AndroidMainScreenState();
}

class _AndroidMainScreenState extends State<AndroidMainScreen> {
 int _currentIndex = 2; // 초기 선택된 인덱스 (가운데 홈 화면)
 final List<String> _titles = [
    '농가정보',
    '출장',
    '홈',
    '야장추출',
    '매뉴얼',
  ];
 String title="home";
  final List<Widget> _screens = [
    FarmInfoScreen(), // 농가정보 (인덱스 0)
    BusinessTripScreen(), // 출장 (인덱스 1)
    AndroidHomeScreen(), // 홈 (인덱스 2)
    EnterDataScreen(), // 야장추출 (인덱스 3)
    ManualScreen(), // 매뉴얼 (인덱스 4)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:CustomAppBar(title:_titles[_currentIndex]),
     // 타이틀 중앙 정렬
      
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 102, 148, 117),
        selectedItemColor: Colors.white,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // 5개 이상의 아이템을 표시
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture),
            label: '농가정보',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: '출장',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: '야장추출',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: '매뉴얼',
          ),
        ],
      ),
    );
  }
}