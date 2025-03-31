import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Farm {
  final int? id;
  final String name;
  final String crop;
  final String address;

  Farm({this.id, required this.name, required this.crop, required this.address});

  
  // 농가 데이터를 Map 형태로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'crop': crop,
      'address': address,
    };
  }

  // Map 데이터를 Farm 객체로 변환
  factory Farm.fromMap(Map<String, dynamic> map) {
    return Farm(
      id: map['id'],
      name: map['name'],
      crop: map['crop'],
      address: map['address'],
    );
  }
}

class FarmDatabase {
  static final FarmDatabase instance = FarmDatabase._init();
  static Database? _database;

  FarmDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('farm_data.db');
    return _database!;
  }

  Future<Database> _initDB(String path) async {
    final dbPath = await getDatabasesPath();
    final fullpath = join(dbPath, path);
    
    return await openDatabase(
      fullpath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE farms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            crop TEXT,
            address TEXT
            survey_photos TEXT
          )
        ''');
      },
    );
  }


  Future<List<String>> getFarmNames() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query('farms');
    return result.map((row) => row['name'] as String).toList();
  }

  Future<int> insertFarm(Farm farm) async {
  final db = await instance.database;
  return await db.insert('farms', farm.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
}

  Future<void> updateFarm(Farm farm) async {
    final db = await instance.database;
    await db.update(
      'farms',
      farm.toMap(),
      where: 'id = ?',
      whereArgs: [farm.id],
    );
  }

  Future<List<Farm>> getAllFarms() async {
    final db = await instance.database;
    
    final List<Map<String, dynamic>> maps = await db.query('farms');

    return List.generate(maps.length, (i) {
      return Farm.fromMap(maps[i]);
    });
  }

  Future<int> updateSurveyPhotos(String farmName, List<String?> newPhotos) async {
  final db = await FarmDatabase.instance.database;

  return await db.update(
    'farms',
    {
      'survey_photos': jsonEncode(newPhotos), // 리스트를 JSON 문자열로 변환 후 저장
    },
    where: 'name = ?',
    whereArgs: [farmName],
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}
Future<void> deleteData(int id) async {
    final db = await FarmDatabase.instance.database;
    await db.delete(
      'farms',
      where: 'id = ?', // ID 기준으로 삭제
      whereArgs: [id], // 삭제할 ID 값
    );
  }
}
