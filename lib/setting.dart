import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Setting extends StatefulWidget {
  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  bool _isDarkMode = false;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 설정값 불러오기
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _username = prefs.getString('username') ?? '';
    });
  }

  // 다크 모드 설정 변경 및 저장
  Future<void> _toggleDarkMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
      prefs.setBool('darkMode', value); // 설정값 저장
    });
    // 테마 적용 코드 (예시)
    // if (value) {
    //   // 다크 모드 테마 적용
    // } else {
    //   // 라이트 모드 테마 적용
    // }
  }

  // 사용자 이름 변경 및 저장
  Future<void> _setUsername(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = value;
      prefs.setString('username', value); // 설정값 저장
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Settings',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(), // 다크 모드 적용
      home: Scaffold(
        appBar: AppBar(title: Text('설정')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SwitchListTile(
                title: Text('다크 모드'),
                value: _isDarkMode,
                onChanged: _toggleDarkMode,
              ),
              SizedBox(height: 20),
              Text('현재 사용자 이름: $_username'),
              TextField(
                decoration: InputDecoration(labelText: '새로운 사용자 이름'),
                onChanged: _setUsername,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
