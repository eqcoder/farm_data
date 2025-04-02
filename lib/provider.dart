import 'package:farm_data/gdrive/gdrive.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  void setUser(User? user) {
    _user = user;
    notifyListeners(); // 상태 변경 알림
  }
}


class SettingsProvider with ChangeNotifier {
  String _folderPath = '';
  int _selectedGroup = 1;
  List<String> _groupMembers = [];
  bool _isDarkMode = false;

  // Getter
  String get folderPath => _folderPath;
  int get selectedGroup => _selectedGroup;
  List<String> get groupMembers => _groupMembers;
  bool get isDarkMode => _isDarkMode;

  // Load settings
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _folderPath = prefs.getString('folderPath') ?? '';
    _selectedGroup = prefs.getInt('selectedGroup') ?? 1;
    _groupMembers = prefs.getStringList('groupMembers') ?? [];
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  // Save settings
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('folderPath', _folderPath);
    await prefs.setInt('selectedGroup', _selectedGroup);
    await prefs.setStringList('groupMembers', _groupMembers);
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Setters
  void setFolderPath(String path) {
    _folderPath = path;
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