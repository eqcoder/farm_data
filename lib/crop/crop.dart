import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Crop {
  String name;
  DocumentReference<Map<String, dynamic>> farmRef;
  Crop({required this.name, required this.farmRef});

  DocumentReference<Map<String, dynamic>>? currentEntity;

  void addEntity(int entityNumber) {
    final entityRef = farmRef.collection(name).doc(entityNumber.toString());
  }

  void deleteEntity(int entityNumber) {
    final entityRef = farmRef.collection(name).doc(entityNumber.toString());
    entityRef.delete();
  }
}
