import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'crop.dart';

class Paprika extends Crop {
  Paprika({
    required name,
    required farmRef,
  }) : super(name: name, farmRef: farmRef);

  int stemCount=0;
  List<String> stemNames=[];
  List<Map<String, dynamic>> allStems = [];
  late DocumentReference<Map<String, dynamic>> stemRef;

  DocumentReference<Map<String, dynamic>>? currentStem;
  int currentIndex=0;
  Future<QuerySnapshot<Map<String, dynamic>>> _loadNodes() {
    return stemRef.collection('node').orderBy('node_number').get();
  }
  Future<void> _loadStemData(int index) async {
      currentIndex = index;
      currentStem = allStems[currentIndex];
      stemRef = currentStem["stemRef"];
      _nodesFuture = _loadNodes();
    });
  }

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
  void _addStem(int entityNum) async {
    final individualRef = farmRef.collection('개체').doc(entityNum.toString());
    individualRef.set(Map<String, dynamic>.from({"개체번호": entityNum}));
    // stem_count만큼 줄기 생성
    for (int stemNum = 1; stemNum <= stemCount; stemNum++) {
      final stemRef = individualRef.collection('줄기').doc(stemNum.toString());
      stemRef.set(Map<String, dynamic>.from({"줄기번호": stemNum}));
      // 각 줄기에 기본 마디(1번) 생성
      final nodeRef = stemRef.collection('마디').doc('1');
      final Map<String, dynamic> nodeData = {
        ...(schema.cropSchema[farm["crop"]] as Map<String, dynamic>)['마디정보'],
        '마디번호': 1,
      };
      await nodeRef.set(nodeData);
      _loadAllStems();
    }
    final lastIndex = allStems.length - stemCount;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        lastIndex,
        duration: const Duration(milliseconds: 100),
        curve: Curves.ease,
      );
    }
  }

  Future<void> deleteStem(
    String entityId,
    String stemId,
    DocumentReference<Map<String, dynamic>> stemRef,
  ) async {
    try {
      // 줄기의 모든 마디 삭제
      final nodes = await stemRef.collection('마디').get();

      for (final node in nodes.docs) {
        await node.reference.delete();
        _loadAllStems();
      }

      // 줄기 문서 삭제
      await stemRef.delete();
    } catch (e) {
      print('줄기 삭제 실패: $e');
      rethrow;
    }
  }
}
