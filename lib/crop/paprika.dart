import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'crop.dart';

class Paprika extends Crop {
  Paprika({
    required String name,
    required DocumentReference<Map<String, dynamic>> farmRef,
  }) : super(name: name, farmRef: farmRef);

  DocumentReference<Map<String, dynamic>>? currentEntity;

  Future<void> loadAllStems() async {
    List<Map<String, dynamic>> allStems = [];

    QuerySnapshot<Map<String, dynamic>> entities =
        await farmRef.collection('entity').orderBy('entity_number').get();

    for (final entity in entities.docs) {
      final stemsSnapshot =
          await farmRef
              .collection('entity')
              .doc(entity["entity_number"].toString())
              .collection('stem')
              .orderBy('stem_number')
              .get();

      for (final stem in stemsSnapshot.docs) {
        allStems.add(
          Map<String, dynamic>.from({
            "stemRef": stem.reference,
            "entity_number": entity["entity_number"],
            "stem_number": stem["stem_number"],
          }),
        );
      }
      stemNames =
          allStems
              .map((item) => "${item['entity_number']}-${item['stem_number']}")
              .toList();

      if (allStems.isNotEmpty) {
        await _loadStemData(_currentPage);
      }

      _isLoading = false;
    }
  }
}
