import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'crop.dart';

class Tomato extends Crop {
  final int stemCount;
  Tomato({
    required super.name,
    required super.farmRef,
    required this.stemCount,
  });

  factory Tomato.fromMap(Map<String, dynamic> map) {
    return Tomato(
      name: map["name"],
      farmRef: map["farmRef"],
      stemCount: map["stemCount"],
    );
  }
  Future<void> init() async {}

  Future<List<List<dynamic>>> processGDriveData(
    int group,
    String farmName,
  ) async {
    return [];
  }
}
