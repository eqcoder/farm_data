import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'crop.dart';

class Apple extends Crop {
  Apple({required super.name, required super.farmRef});

  factory Apple.fromMap(Map<String, dynamic> map) {
    return Apple(name: map["name"], farmRef: map["farmRef"]);
  }
  Future<void> init() async {}

  Future<List<List<dynamic>>> processGDriveData(
    int group,
    String farmName,
  ) async {
    return [];
  }
}
