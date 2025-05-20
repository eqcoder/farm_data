import '../../../crop_config/schema.dart' as schema;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../appbar.dart';
import '../../../database/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheet;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import '../../../provider.dart' as provider;

class PaprikaSurveyScreen extends StatefulWidget {
  final Map<String, dynamic> farm;
  final bool isEditMode; // 예시
  const PaprikaSurveyScreen({
    super.key,
    required this.farm,
    required this.isEditMode,
  });
  @override
  _PaprikaSurveyScreenState createState() => _PaprikaSurveyScreenState();
}

class _PaprikaSurveyScreenState extends State<PaprikaSurveyScreen> {
  late bool isEditMode;
  final PageController _pageController = PageController();
  late Map<String, dynamic> farm;
  int _currentPage = 0;
  Map<String, dynamic> _currentStem = <String, dynamic>{};
  late DocumentReference<Map<String, dynamic>> farmRef;
  late DocumentReference<Map<String, dynamic>> stemRef;
  late int stemCount;
  late QuerySnapshot<Map<String, dynamic>> entities;
  late List<Map<String, dynamic>> allStems = [];
  bool _isLoading = true;
  late Future<QuerySnapshot<Map<String, dynamic>>> _nodesFuture;
  String entityName = "";
  List<String> stemNames = [];
  final Map<String, dynamic> basicSurvey = {};

  final List<String> statuses = ['개화', '착과', '열매', '수확'];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isEditMode = widget.isEditMode;
    farm = widget.farm;
    farmRef = FirebaseFirestore.instance.collection('farms').doc(farm["id"]);
    _loadAllStems();
    stemCount = farm["stem_count"];
  }

  @override
  void dispose() {
    _pageController.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _loadNodes() {
    return stemRef.collection('마디').orderBy('마디번호').get();
  }

  Future<void> _loadStemData(int index) async {
    // final doc = await allStems[index]["stemRef"].get();
    setState(() {
      // _currentStemData = doc.data();
      _currentPage = index;
      _currentStem = allStems[_currentPage];
      stemRef = _currentStem["stemRef"];
      _nodesFuture = _loadNodes();
    });
  }

  Future<void> _loadAllStems() async {
    setState(() {
      _isLoading = true;
      allStems = [];
    });
    // 1. 모든 개체 가져오기 (entity_number 오름차순)
    entities = await farmRef.collection('개체').orderBy('개체번호').get();
    // 2. 각 개체의 줄기 가져오기 (stem_number 오름차순)
    for (final entity in entities.docs) {
      final stemsSnapshot =
          await farmRef
              .collection('개체')
              .doc(entity["개체번호"].toString())
              .collection('줄기')
              .orderBy('줄기번호')
              .get();

      for (final stem in stemsSnapshot.docs) {
        allStems.add(
          Map<String, dynamic>.from({
            "stemRef": stem.reference,
            "entity_number": entity["개체번호"],
            "stem_number": stem["줄기번호"],
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

  void EnterBasicSurvey() async {
    final result = await showCropInputDialog(
      context: context,
      fields: (schema.cropSchema[farm["crop"]] as Map<String, dynamic>)["기본조사"],
    );

    // 2. Firestore에 저장
    if (result != null) {
      try {
        final stemDocRef = FirebaseFirestore.instance
            .collection('farms')
            .doc(farm["id"])
            .collection('개체')
            .doc(_currentStem['entity_number'].toString())
            .collection('줄기')
            .doc(_currentStem['stem_number'].toString());

        // 문서가 없으면 생성, 있으면 crops 필드 업데이트
        await stemDocRef.set(result, SetOptions(merge: true));

        print('저장 성공!');
      } catch (e) {
        print('저장 실패: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> showCropInputDialog({
    required BuildContext context,
    required List<schema.CropField> fields,
  }) async {
    // 각 필드의 초기값 설정 (최소값)
    for (final field in fields) {
      basicSurvey[field.label] = field.min;
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: Text('${stemNames[_currentPage]}개체 기본조사 입력'),
              content: SizedBox(
                height: 600,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 각 필드별 Picker 생성
                      for (final field in fields)
                        _buildFieldPicker(field, basicSurvey, setState),
                    ],
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('취소'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoDialogAction(
                  child: const Text('입력'),
                  onPressed: () => Navigator.pop(context, basicSurvey),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFieldPicker(
    schema.CropField field,
    Map<String, dynamic> values,
    StateSetter setState,
  ) {
    // 값 리스트 생성 (정수/소수 구분)
    final List<double> valueList = [];
    for (double i = field.min; i <= field.max; i += field.step) {
      valueList.add(i);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            field.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(width: 10),
        SizedBox(
          width: 100,
          height: 150,
          child: CupertinoPicker(
            itemExtent: 40,
            onSelectedItemChanged: (index) {
              setState(() {
                values[field.label] =
                    field.type == int
                        ? valueList[index]
                            .toInt() // 정수 변환
                        : valueList[index]; // 소수 유지
              });
            },
            children:
                valueList.map((value) {
                  return Center(
                    child: Text(
                      field.type == int
                          ? value
                              .toInt()
                              .toString() // 정수 표시
                          : value.toStringAsFixed(1), // 소수점 1자리 표시
                      style: const TextStyle(fontSize: 20),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  void deleteDialog() async {
    {
      bool isMatched = false;
      String name = farm["farmName"];
      final String entityNumber = _currentStem["entity_number"];
      final String stemNumber = _currentStem["stem_number"];
      final TextEditingController _farmNameController = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // 바깥 터치로 닫히지 않게
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 32),
                    SizedBox(width: 8),
                    Text('정말 삭제하시겠습니까?', style: TextStyle(color: Colors.red)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '이 작업은 되돌릴 수 없습니다!\n정말로 $entityNumber-$stemNumber 개체를 삭제하시겠습니까?',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '농가명($name)을 입력해야 삭제할 수 있습니다.',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextField(
                      controller: _farmNameController,
                      autofocus: true,
                      decoration: InputDecoration(hintText: name),
                      onChanged: (value) {
                        setState(() {
                          isMatched = value == name;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: Text('취소'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: isMatched ? Colors.red : Colors.grey,
                    ),
                    onPressed:
                        isMatched
                            ? () {
                              Navigator.of(context).pop(true);
                            }
                            : null,
                    child: Text(
                      '삭제',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
      if (confirm == true) {
        deleteStem(entityNumber, stemNumber.toString(), stemRef);
        await _loadAllStems();
      }
    }
  }

  Future<void> _addNode(BuildContext context, int nodeNum) async {
    // 자동 생성 ID로 문서 참조 생성
    final nodeRef = stemRef.collection('마디').doc(nodeNum.toString());
    final nodeInfo =
        (schema.cropSchema[farm["crop"]] as Map<String, dynamic>)["마디정보"];
    nodeInfo["마디번호"] = nodeNum;
    await nodeRef.set(nodeInfo);
    setState(() {
      _nodesFuture = _loadNodes(); // Future를 새로 할당
    });
  }

  Future<void> _deleteNode(BuildContext context, int nodeNum) async {
    final nodeRef = stemRef.collection('마디').doc(nodeNum.toString());
    nodeRef.delete();
    setState(() {
      _nodesFuture = _loadNodes(); // Future를 새로 할당
    });
  }

  Widget _editNodeButton(BuildContext context, int nodeNum) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('마디 추가'),
            onPressed: () async {
              _addNode(context, nodeNum + 1);
            },
          ),
        ),
        nodeNum > 0
            ? Container(
              margin: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('마디 삭제'),
                onPressed: () async {
                  _deleteNode(context, nodeNum);
                },
              ),
            )
            : SizedBox.shrink(),
      ],
    );
  }

  Widget _pageDropdown() {
    final List<String> _items =
        allStems
            .map((item) => "${item['entity_number']}-${item['stem_number']}")
            .toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _currentPage + 1 > stemCount
            ? Expanded(
              flex: 2,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_left,
                  size: 30,
                  color: Color.fromARGB(255, 11, 65, 19),
                ),
                onPressed: () {
                  _pageController.animateToPage(
                    _currentPage - stemCount,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            )
            : Spacer(flex: 2),

        Expanded(
          flex: 2,
          child: Text(
            '개체',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: const Color.fromARGB(255, 11, 65, 19),
              letterSpacing: 1.5,
            ),
          ),
        ),

        Expanded(
          flex: 3,
          child: DropdownButton<int>(
            isExpanded: true,
            value: _currentPage,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            items: List.generate(
              _items.length,
              (index) => DropdownMenuItem<int>(
                value: index,
                child: Center(child: Text(_items[index])),
              ),
            ),
            onChanged: (int? newIndex) {
              if (newIndex != null) {
                setState(() {
                  _currentPage = newIndex;
                });
                // 페이지 이동
                _pageController.animateToPage(
                  newIndex,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
        _currentPage + stemCount < allStems.length
            ? Expanded(
              flex: 2,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_right,
                  size: 30,
                  color: const Color.fromARGB(255, 11, 65, 19),
                ),
                onPressed: () {
                  _pageController.animateToPage(
                    _currentPage + stemCount,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            )
            : Spacer(flex: 2),
        _currentPage + stemCount < allStems.length && isEditMode
            ? Expanded(
              flex: 4,
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.delete,
                  color: const Color.fromARGB(255, 138, 37, 37),
                ),
                label: Text(
                  '개체삭제',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color.fromARGB(255, 97, 15, 15),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 234, 240, 183),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () async {
                  deleteDialog();
                },
              ),
            )
            : Spacer(flex: 2),
        SizedBox(width: 8),
        _currentPage >= allStems.length - stemCount && isEditMode
            ? Expanded(
              flex: 4,
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.add,
                  color: const Color.fromARGB(255, 138, 37, 37),
                ),
                label: Text(
                  '개체추가',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color.fromARGB(255, 97, 15, 15),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 234, 240, 183),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () async {
                  _addStem(int.parse(_currentStem["entity_number"]) + 1);
                },
              ),
            )
            : Spacer(flex: 4),

        SizedBox(width: 8),
      ],
    );
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

  Future<void> _updateNodeStatus(
    DocumentReference nodeRef,
    String newStatus,
  ) async {
    try {
      await nodeRef.update({'status': newStatus});
    } catch (e) {
      print('상태 업데이트 실패: $e');
    }
  }

  Widget _nodeItem(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> nodeRef,
  ) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: nodeRef.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('마디 데이터가 없습니다.'));
        }

        final node = snapshot.data!.data()!;
        String status = node['status'] as String;
        final number = node['마디번호'];
        final screenHeight = MediaQuery.of(context).size.height;
        final List<String> statuses = ['개화', '착과', '열매', '수확', '낙과'];

        return Container(
          height: screenHeight / 5,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/paprika_$status.png"),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(0),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number 번 마디',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: const Color.fromARGB(255, 11, 65, 19),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                children:
                    statuses.map((s) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: s,
                            groupValue: status,
                            onChanged: (value) async {
                              if (value == null) return;
                              await _updateNodeStatus(nodeRef, value);
                              setState(() {
                                status = value; // UI 상태도 같이 변경!
                              });
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                          Text(
                            s,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 11, 65, 19),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stemPage(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: _nodesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('마디 데이터가 없습니다.'));
              }
              final nodes = snapshot.data!.docs;
              return ListView.builder(
                itemCount:
                    isEditMode ? nodes.length + 1 : nodes.length, // 마지막에 버튼 추가
                itemBuilder: (context, index) {
                  if (index == nodes.length) {
                    // 마지막에 추가 버튼

                    return _editNodeButton(
                      context,
                      nodes.isNotEmpty ? nodes.last['마디번호'] : 1,
                    );
                  }
                  final nodeDoc = nodes[index];
                  return _nodeItem(context, nodeDoc.reference);
                },
                reverse: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            icon: Icon(
              Icons.assignment,
              color: const Color.fromARGB(255, 119, 41, 96),
            ),
            label: Text(
              '기본조사',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 220, 233, 175),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // ← 원하는 둥글기 값
              ),
            ),
            onPressed: () async {
              EnterBasicSurvey();
            },
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 90, 73, 42), // 원하는 배경색
              borderRadius: BorderRadius.circular(12),
            ),
            child: Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  '${_currentStem["entity_number"]}-${_currentStem["stem_number"]} 개체',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        // 오른쪽 삭제 버튼
        isEditMode
            ? Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  '업로드',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 181, 214, 233),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // ← 원하는 둥글기 값
                  ),
                ),
                onPressed: () async {
                  _processAndUpload(context);
                },
              ),
            )
            : Spacer(flex: 2),
        SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            icon: Icon(Icons.add, color: Colors.white),
            label: Text(
              '조사표',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 181, 214, 233),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // ← 원하는 둥글기 값
              ),
            ),
            onPressed: () async {},
          ),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Map<String, dynamic> getStemCounts(DocumentSnapshot stemDoc) {
    Map<String, dynamic> map = Map<String, dynamic>.from({
      "개화마디": null,
      "착과마디": null,
      "열매마디": null,
      "수확마디": null,
    });
    statuses.map(
      (status) =>
          map['$status수'] = // 또는 '${status}수'로 키를 바꿀 수도 있음
              (stemDoc.data() as Map<String, dynamic>)['$status수'] ?? 0,
    );
    return map;
  }

  Future<String> getOrCreateFolder(
    drive.DriveApi driveApi,
    String folderName, {
    String? parentId,
  }) async {
    // 1. 폴더 존재 확인
    final q =
        "name='${folderName}' and mimeType='application/vnd.google-apps.folder'" +
        (parentId != null ? " and '$parentId' in parents" : "");
    final folderList = await driveApi.files.list(q: q);
    if (folderList.files != null && folderList.files!.isNotEmpty) {
      return folderList.files!.first.id!;
    }
    // 2. 폴더가 없으면 생성
    final folder =
        drive.File()
          ..name = folderName
          ..mimeType = 'application/vnd.google-apps.folder'
          ..parents = parentId != null ? [parentId] : null;
    final created = await driveApi.files.create(folder);
    return created.id!;
  }

  Future<void> _uploadToGoogleSheets(List<List<dynamic>> data) async {
    final _credentials = dotenv.env['GOOGLE_CREDENTIALS']!;

    final accountCredentials = ServiceAccountCredentials.fromJson(
      json.decode(_credentials),
    );
    final scopes = [
      drive.DriveApi.driveScope,
      sheet.SheetsApi.spreadsheetsScope,
    ];
    final client = await clientViaServiceAccount(accountCredentials, scopes);

    // 1. 드라이브 API 인스턴스
    final driveApi = drive.DriveApi(client);
    final group =
        Provider.of<provider.SettingsProvider>(
          context,
          listen: false,
        ).selectedGroup;
    // 2. '3조' 폴더 찾기
    final folderList = await driveApi.files.list(
      q: "name='$group조' and mimeType='application/vnd.google-apps.folder'",
    );
    if (folderList.files == null || folderList.files!.isEmpty)
      throw Exception("$group조 폴더를 찾을 수 없습니다.");
    final folder3Id = folderList.files!.first.id!;

    // 3. '3조생육원본' 하위폴더 찾기
    final subFolderList = await driveApi.files.list(
      q: "name='$group조생육원본' and mimeType='application/vnd.google-apps.folder' and '${folder3Id}' in parents",
    );
    if (subFolderList.files == null || subFolderList.files!.isEmpty)
      throw Exception("$group조생육원본 폴더를 찾을 수 없습니다.");
    final subFolderId = subFolderList.files!.first.id!;

    // 4. 시트 생성
    final file = drive.File();
    file.name = '${farm["farmName"]}생육원본';
    file.mimeType = 'application/vnd.google-apps.spreadsheet';
    file.parents = [subFolderId];
    final createdFile = await driveApi.files.create(file);

    final spreadsheetId = createdFile.id!;
    print('생성된 시트 ID: $spreadsheetId');

    // 5. 시트에 데이터 입력
    final sheetsApi = sheet.SheetsApi(client);
    final valueRange = sheet.ValueRange.fromJson({'values': data});
    await sheetsApi.spreadsheets.values.append(
      valueRange,
      spreadsheetId,
      'Sheet1',
      valueInputOption: 'USER_ENTERED',
    );

    client.close();
    // 여기에 구글 시트 API 연동 코드 구현
    // 예: Google Sheets API 패키지 사용
  }

  Future<void> _processAndUpload(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final today = DateFormat('MM/dd').format(DateTime.now());
    final List<String> statuses = ['개화', '착과', '열매', '수확'];
    List<List<dynamic>> sheetData = [];
    sheetData.add([
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
      "수확수수",
    ]);
    for (final entity in entities.docs) {
      final stemsSnapshot =
          await farmRef
              .collection('개체')
              .doc(entity["개체번호"].toString())
              .collection('줄기')
              .orderBy('줄기번호')
              .get();

      for (final stemDoc in stemsSnapshot.docs) {
        // 2. 각 줄기의 마디 데이터 처리

        Map<String, dynamic> counts = getStemCounts(stemDoc);
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
          counts["$status수"] =
              (counts["$status수"] ?? 0) + emptyNodes.docs.length;

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
          farm["farmName"],
          today,
          entity["개체번호"],
          (stemDoc.data())["줄기번호"],
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
        await batch.commit();
        sheetData.add(columndata);
      }
    }

    // 9. 구글 시트 업로드 (별도 구현 필요)
    _uploadToGoogleSheets(sheetData);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('데이터 업로드 완료!')));
  }

  @override
  Widget build(BuildContext context) {
    if (allStems.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(title: '${farm["farmName"]} 농가 마디조사'),
        body: Center(
          child:
              isEditMode
                  ? ElevatedButton.icon(
                    icon: Icon(
                      Icons.add,
                      color: Color.fromARGB(255, 138, 37, 37),
                    ),
                    label: Text(
                      '개체추가',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color.fromARGB(255, 97, 15, 15),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 234, 240, 183),
                    ),
                    onPressed: () async {
                      _addStem(1);
                    },
                  )
                  : Center(child: Text("개체가 없습니다.")),
        ),
      );
    }
    return Scaffold(
      appBar: CustomAppBar(title: '${farm["farmName"]} 농가 마디조사'),
      body: Column(
        children: [
          Expanded(flex: 1, child: _pageDropdown()),
          Expanded(
            flex: 10,
            child: PageView.builder(
              controller: _pageController,
              itemCount: allStems.length,
              onPageChanged: (int pageIndex) {
                setState(() {
                  if (pageIndex < allStems.length) {
                    _currentPage = pageIndex; // 마지막 페이지
                  } // 페이지가 바뀌면 드롭다운 선택값 변경
                  _loadStemData(pageIndex);
                });
              },
              itemBuilder: (ctx, index) {
                return _stemPage(context);
              },
            ),
          ),

          Expanded(flex: 1, child: _bottomBar(context)),
          SizedBox(height: 4),
        ],
      ),
    );
  }
}
