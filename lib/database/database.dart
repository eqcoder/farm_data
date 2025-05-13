import 'dart:async';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class Farm {
  final int? id;
  final String name;
  final String crop;
  final String address;
  final String? city;
  final int stem_count;
  final String? survey_photos;

  Farm({this.id, required this.name, required this.crop, required this.address, required this.city, required this.stem_count, required this.survey_photos});

  
  // 농가 데이터를 Map 형태로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'crop': crop,
      'address': address,
      'city': city,
      'stem_count' : stem_count,
      'survey_photos': survey_photos,
    };
  }

  // Map 데이터를 Farm 객체로 변환
  factory Farm.fromMap(Map<String, dynamic> map) {
    return Farm(
      id: map['id'],
      name: map['name'],
      crop: map['crop'],
      address: map['address'],
      city: map['city'],
      stem_count: map['stem_count'],
      survey_photos: map['survey_photos'],
    );
  }
}

class Node {
  final int id;           // 마디의 고유 ID (DB PK)
  final int stemId;       // 소속 줄기(stem)의 ID (FK)
  final int nodeNumber;   // 마디 번호 (1~30 등)
  final String status;    // 상태 (예: '개화', '착과', '열매', '수확', '낙과')

  Node({
    required this.id,
    required this.stemId,
    required this.nodeNumber,
    required this.status,
  });

  // DB에서 가져온 Map을 Node 객체로 변환
  factory Node.fromMap(Map<String, dynamic> map) {
    return Node(
      id: map['id'],
      stemId: map['stem_id'],
      nodeNumber: map['node_number'],
      status: map['status'],
    );
  }

  // Node 객체를 DB에 저장할 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stem_id': stemId,
      'node_number': nodeNumber,
      'status': status,
    };
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
      version:10,
      fullpath,
      onCreate: (db, version) async {
      // 1. farms 테이블
      await db.execute('''
        CREATE TABLE farms (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          crop TEXT,
          address TEXT,
          survey_photos TEXT,
          city TEXT,
          stem_count INTEGER
        )
      ''');

      // 2. entities 테이블
      await db.execute('''
        CREATE TABLE entities (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          farm_id INTEGER,
          entity_number INTEGER,
          FOREIGN KEY(farm_id) REFERENCES farms(id)
        )
      ''');

      // 3. stems 테이블
      await db.execute('''
        CREATE TABLE stems (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entity_id INTEGER,
          stem_number INTEGER,
          FOREIGN KEY(entity_id) REFERENCES entities(id)
        )
      ''');

      // 4. nodes 테이블
      await db.execute('''
        CREATE TABLE nodes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          stem_id INTEGER,
          node_number INTEGER,
          status TEXT,
          FOREIGN KEY(stem_id) REFERENCES stems(id)
        )
      ''');

      // 인덱스 생성
      await db.execute('CREATE INDEX idx_entities_farm ON entities(farm_id)');
      await db.execute('CREATE INDEX idx_stems_entity ON stems(entity_id)');
      await db.execute('CREATE INDEX idx_nodes_stem ON nodes(stem_id)');
    },
      onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 6) {
  await db.execute('ALTER TABLE farms ADD COLUMN stem_count INTEGER');
}
    },
    );
  }

  Future<void> addEntity(int farmId, int entityNumber) async {
    final db = await database;
    final farms = await db.query(
      'farms',
      where: 'id = ?',
      whereArgs: [farmId],
    );
    if (farms.isEmpty) return;
    final stemCount = farms.first['stem_count'] as int;
    final entityId = await db.insert('entities', {
      'farm_id': farmId,
      'entity_number': entityNumber,
    });
    for (int i = 1; i <= stemCount; i++) {
      int stemId=await db.insert('stems', {
        'entity_id': entityId,
        'stem_number': i,
      });
      await addNode(stemId, 1); // 첫 번째 마디 추가
    }

  }
  Future<int> addStem(int entityId, int stemNumber) async {
    final db = await database;
    return await db.insert('stems', {
      'entity_id': entityId,
      'stem_number': stemNumber,
    });
  }
  Future<int> addNode(int stemId, int nodeNumber) async {
    final db = await database;
    return await db.insert('nodes', {
      'stem_id': stemId,
      'node_number': nodeNumber,
      'status': '개화',
    });
  }Future<int> deleteStem(int stemId) async {
    final db = await database;
    return await db.delete(
      'stems',
      where: 'id = ?', // ID 기준으로 삭제
      whereArgs: [stemId], // 삭제할 ID 값
    );
  }
  Future<int> deleteNode(int nodeId) async {
    final db = await database;
    return await db.delete(
      'nodes',
      where: 'id = ?', // ID 기준으로 삭제
      whereArgs: [nodeId], // 삭제할 ID 값
    );
  }
  Future<void> updateNodeStatus(int nodeId, String newStatus) async {
    final db = await database;
    await db.update(
      'nodes',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [nodeId],
    );
  }
  Future<Farm?> getFarmByName(String farmName) async {
    final db = await FarmDatabase.instance.database;

    // 쿼리 실행
    final List<Map<String, dynamic>> result = await db.query(
      'farms',
      where: 'name = ?',
      whereArgs: [farmName],
    );

    if (result.isNotEmpty) {
      return Farm.fromMap(result.first);
    } else {
      return null; // 데이터가 없을 경우 null 반환
    }
  }
  Future<List<Node>> getNodesByStem({
  required int farmId,
  required int entityNumber,
  required int stemNumber
}) async {
  final db = await database;
  
  // 1. 개체와 줄기 ID 찾기
  final stem = await db.rawQuery('''
    SELECT stems.id 
    FROM stems
    INNER JOIN entities ON stems.entity_id = entities.id
    WHERE 
      entities.farm_id = ? 
      AND entities.entity_number = ?
      AND stems.stem_number = ?
  ''', [farmId, entityNumber, stemNumber]);

  if (stem.isEmpty) return [];

  // 2. 해당 줄기의 모든 마디 조회
  final nodes = await db.query(
    'nodes',
    where: 'stem_id = ?',
    whereArgs: [stem.first['id']],
    orderBy: 'node_number ASC'
  );

  return nodes.map((e) => Node.fromMap(e)).toList();
}
  Future<Farm?> getFarmById(int id) async {
    final db = await FarmDatabase.instance.database;

    // 쿼리 실행
    final List<Map<String, dynamic>> result = await db.query(
      'farms',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Farm.fromMap(result.first);
    } else {
      return null; // 데이터가 없을 경우 null 반환
    }
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

  Future<int> updateSurveyPhotos(int id, List<String?> newPhotos) async {
  final db = await FarmDatabase.instance.database;

  return await db.update(
    'farms',
    {
      'survey_photos': jsonEncode(newPhotos), // 리스트를 JSON 문자열로 변환 후 저장
    },
    where: 'id = ?',
    whereArgs: [id],
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
