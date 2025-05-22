import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'crop.dart';

class Cabbage extends Crop {
  Cabbage({required super.name, required super.farmRef});

  factory Cabbage.fromMap(Map<String, dynamic> map) {
    return Cabbage(name: map["name"], farmRef: map["farmRef"]);
  }
  Future<void> init() async {}

  Future<List<List<dynamic>>> processGDriveData(
    int group,
    String farmName,
  ) async {
    return [];
  }
}
