import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../gdrive/gdrive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../provider.dart' as provider;
import 'package:provider/provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheet;
import 'package:intl/intl.dart';

class CropField {
  final String label; // 항목 이름
  final Type type; // 자료형
  final double min; // 최소값
  final double max; // 최대값
  final double step; // 증가 단계

  CropField({
    required this.label,
    required this.type,
    required this.min,
    required this.max,
    required this.step,
  });
}

abstract class Crop {
  String name;
  String farmId;
  Crop({required this.name, required this.farmId});

  DocumentReference<Map<String, dynamic>>? currentEntity;
  List<Map<String, dynamic>> allEntities = [];
  List<String> entityNames = [];
  final today = DateFormat('MM/dd').format(DateTime.now());

  List<CropField> get fields => [];
  List<String> get imageTitles => [];
  Map<String, dynamic> basicSurvey = {};
  Future<void> init()async{
    
  };
  void addEntity(int entityNumber) {
    final entityRef = farmRef.collection(name).doc(entityNumber.toString());
  }

  void deleteEntity(int entityNumber) {
    final entityRef = farmRef.collection(name).doc(entityNumber.toString());
    entityRef.delete();
  }

  Future<List<List<dynamic>>> processGDriveData(int group, String farmName);
}
