import 'package:farm_data/gdrive/gdrive.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;
AuthProvider() {
    // 앱 시작 시 로그인 상태 자동 동기화
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });}
  void setUser(User? user) {
    _user = user;
    notifyListeners(); // 상태 변경 알림
  }
  

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    setUser(null);
  }
}


class SettingsProvider with ChangeNotifier {
  String _originfolderPath = '';
  String _customfolderPath = '';
  int _selectedGroup = 1;
  List<String> _groupMembers = [];
  bool _isDarkMode = false;

  // Getter
  String get originfolderPath => _originfolderPath;
  String get customfolderPath => _customfolderPath;
  int get selectedGroup => _selectedGroup;
  List<String> get groupMembers => _groupMembers;
  bool get isDarkMode => _isDarkMode;

  // Load settings
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _originfolderPath = prefs.getString('originfolderPath') ?? '';
    _customfolderPath = prefs.getString('customfolderPath') ?? '';
    _selectedGroup = prefs.getInt('selectedGroup') ?? 1;
    _groupMembers = prefs.getStringList('groupMembers') ?? [];
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  // Save settings
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('originfolderPath', _originfolderPath);
    await prefs.setString('customfolderPath', _customfolderPath);
    await prefs.setInt('selectedGroup', _selectedGroup);
    await prefs.setStringList('groupMembers', _groupMembers);
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Setters
  void setOriginFolderPath(String path) {
    _originfolderPath = path;
    notifyListeners();
  }
  void setCustomFolderPath(String path) {
    _customfolderPath = path;
    notifyListeners();
  }

  void setSelectedGroup(int group) {
    _selectedGroup = group;
    notifyListeners();
  }

  void setGroupMembers(List<String> members) {
    _groupMembers = members;
    notifyListeners();
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}