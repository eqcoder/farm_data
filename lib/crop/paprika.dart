import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'crop.dart';

class Paprika extends Crop {
  final int stemCount;
  Paprika({
    required DocumentReference<Map<String, dynamic>> farmRef,
    required this.stemCount,
  }) : super(name: "파프리카", farmRef: farmRef);

  @override
  get fields => [
    CropField(label: '엽수', type: int, min: 1, max: 50, step: 1),
    CropField(label: '엽장', type: double, min: 5, max: 50.0, step: 0.1),
    CropField(label: '엽폭', type: double, min: 5, max: 50.0, step: 0.1),
    CropField(label: '생장길이', type: double, min: 1, max: 200, step: 0.1),
    CropField(label: '화방높이', type: double, min: 1, max: 50, step: 0.1),
    CropField(label: '줄기굵기', type: double, min: 1, max: 20, step: 0.1),
  ];

  final Map<String, dynamic> nodeInfo = {
    "nodeNumber": null,
    "status": "개화",
    "개화": null,
    "착과": null,
    "열매": null,
    "수확": null,
    "낙과": null,
    "과중": null,
    "과폭": null,
    "과고": null,
  };

  final List<String> imageTitles = [
    "재배전경",
    "1-1 개체생장점 사진",
    "1-1 개체 마디 진행상황",
    "pH",
    "백엽상 내부",
    "온습도",
    "1 개체 근권부 사진(좌)",
    "1개체 근권부 사진(우)",
    "특이사항",
  ];

  final List<String> statuses = ['flower', 'fruitSet', 'fruit', 'harvest'];
  // #region 줄기
  Future<void> loadAllStems() async {
    QuerySnapshot<Map<String, dynamic>> entities =
        await farmRef.collection('entity').orderBy('entity_number').get();
    for (final entity in entities.docs) {
      final stemsSnapshot =
          await farmRef
              .collection('entity')
              .doc(entity["entityNumber"].toString())
              .collection('stem')
              .orderBy('stemNumber')
              .get();

      for (final stem in stemsSnapshot.docs) {
        allEntities.add(
          Map<String, dynamic>.from({
            "stemDoc": stem,
            "entityNumber": entity["entityNumber"],
            "stemNumber": stem["stemNumber"],
          }),
        );
      }
      entityNames =
          allEntities
              .map((item) => "${item['entity_number']}-${item['stem_number']}")
              .toList();
    }
  }

  Map<String, dynamic> getStemInfo(DocumentSnapshot stemDoc) {
    Map<String, dynamic> map = Map<String, dynamic>.from({
      "flowerNode": null,
      "fruitSetNode": null,
      "fruitNode": null,
      "harvestNode": null,
    });
    statuses.map(
      (status) =>
          map['$status수'] = // 또는 '${status}수'로 키를 바꿀 수도 있음
              (stemDoc.data() as Map<String, dynamic>)['$status수'] ?? 0,
    );
    return map;
  }

  Map<String, dynamic> calculateStemInfo()

  void addStem(int entityNum, int stemNum) async {
    final individualRef = farmRef
        .collection('entity')
        .doc(entityNum.toString());
    individualRef.set(Map<String, dynamic>.from({"entityNumber": entityNum}));
    // stem_count만큼 줄기 생성
    final stemRef = individualRef.collection('stem').doc(stemNum.toString());
    stemRef.set(Map<String, dynamic>.from({"stemNumber": stemNum}));
    // 각 줄기에 기본 마디(1번) 생성
    addNode(stemRef, 1);
  }

  Future<void> deleteStem(
    String entityId,
    String stemId,
    DocumentReference<Map<String, dynamic>> stemRef,
  ) async {
    try {
      // 줄기의 모든 마디 삭제
      final nodes = await stemRef.collection('node').get();

      for (final node in nodes.docs) {
        await node.reference.delete();
      }

      // 줄기 문서 삭제
      await stemRef.delete();
    } catch (e) {
      print('줄기 삭제 실패: $e');
      rethrow;
    }
  }

  // #endregion
  // #region 마디
  Future<QuerySnapshot<Map<String, dynamic>>> loadNodes(
    DocumentReference<Map<String, dynamic>> stemRef,
  ) {
    return stemRef.collection('node').orderBy('nodeNumber').get();
  }

  Future<void> updateNodeStatus(
    DocumentReference nodeRef,
    String newStatus,
  ) async {
    try {
      await nodeRef.update({'status': newStatus});
    } catch (e) {
      print('상태 업데이트 실패: $e');
    }
  }

  Future<void> addNode(
    DocumentReference<Map<String, dynamic>> stemRef,
    int nodeNum,
  ) async {
    // 자동 생성 ID로 문서 참조 생성
    final nodeRef = stemRef.collection('node').doc(nodeNum.toString());
    nodeInfo["nodeNumber"] = nodeNum;
    await nodeRef.set(nodeInfo);
  }

  Future<void> deleteNode(
    DocumentReference<Map<String, dynamic>> stemRef,
    int nodeNum,
  ) async {
    final nodeRef = stemRef.collection('node').doc(nodeNum.toString());
    nodeRef.delete();
  }

  // #endregion
  @override
  Future<List<List<dynamic>>> processGDriveData(
    int group,
    String farmName,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final columnName = [
      "농가명",
      "조사일자",
      "개체번호",
      "줄기번호",
      "초장",
      "생장길이",
      "엽수",
      "엽장",
      "엽폭",
      "줄기굵기",
      "화방높이",
      "본주구분",
      "개화마디",
      "착과마디",
      "열매마디",
      "수확마디",
      "개화수",
      "착과수",
      "열매수",
      "수확수",
    ];

    List<List<dynamic>> sheetData = [];
    sheetData.add([columnName]);
    for (final stem in allEntities) {
      final stemDoc = stem["stemDoc"] as DocumentSnapshot<Map<String, dynamic>>;
      final entity = stem["entityNumber"];
      // 2. 각 줄기의 마디 데이터 처리

      Map<String, dynamic> counts = getStemInfo(stem["stemDoc"]);
      for (final String status in statuses) {
        final emptyNodes =
            await stemDoc.reference
                .collection('nodes')
                .where('status', isEqualTo: status)
                .where(status, isEqualTo: null)
                .get();
        for (final nodeDoc in emptyNodes.docs) {
          batch.update(nodeDoc.reference, {status: today});
        }
        counts["$status수"] = (counts["$status수"] ?? 0) + emptyNodes.docs.length;

        final nodesQuery =
            await stemDoc.reference
                .collection('nodes')
                .where('status', isEqualTo: status)
                .orderBy('마디번호', descending: true)
                .limit(1)
                .get();
        int order = 0;
        if (nodesQuery.docs.isNotEmpty) {
          final node = nodesQuery.docs.first;
          order = node.data()['마디번호'] ?? 0;
        }
        counts["$status마디"] = order;
        // 5. 최대값 마디 찾기
      }
      batch.update(stemDoc.reference, counts);
      List<dynamic> columndata = [
        farmName,
        today,
        stem["entityNumber"],
        (stemDoc.data())!["줄기번호"],
        "",
        basicSurvey["생장길이"],
        basicSurvey["엽수"],
        basicSurvey["엽장"],
        basicSurvey["엽폭"],
        basicSurvey["줄기굵기"],
        basicSurvey["화방높이"],
        "본주",
      ];
      columndata.addAll(counts.values.toList());

      sheetData.add(columndata);
    }
    await batch.commit();
    return sheetData;
  }

  // 9. 구글 시트 업로드 (별도 구현 필요)
}
