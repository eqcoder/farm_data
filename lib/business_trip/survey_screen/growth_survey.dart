import 'dart:ffi';
import '../../crop_config/schema.dart' as schema;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../appbar.dart';
import '../../database/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class GrowthSurveyScreen extends StatefulWidget {
  final Map<String, dynamic> farm;

  const GrowthSurveyScreen({super.key, required this.farm});
  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<GrowthSurveyScreen> {
  final PageController _pageController = PageController();
  late Map<String, dynamic> farm;
  late DocumentReference<Map<String, dynamic>> farmRef;
  late int stem_count;
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _allStems = [];
  bool _isLoading = true;
  late DocumentReference<Map<String, dynamic>> stemRef;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    farm = widget.farm;
    farmRef = FirebaseFirestore.instance.collection('farms').doc(farm["id"]);
    _loadAllStems();
  }

  Future<void> _loadAllStems() async {
    setState(() => _isLoading = true);
    final List<Map<String, dynamic>> stems = [];
    // 1. 모든 개체 가져오기 (entity_number 오름차순)
    final entities =
        await FirebaseFirestore.instance
            .collection('farms')
            .doc(farm["id"])
            .collection('개체')
            .orderBy('entity_number')
            .get();

    // 2. 각 개체의 줄기 가져오기 (stem_number 오름차순)
    for (final entity in entities.docs) {
      final stemsSnapshot =
          await FirebaseFirestore.instance
              .collection('farms')
              .doc(farm["id"])
              .collection('개체')
              .doc(entity.id)
              .collection('줄기')
              .orderBy('stem_number')
              .get();

      for (final stem in stemsSnapshot.docs) {
        stems.add(
          Map<String, dynamic>.from({
            "entity_num": entity.id,
            "stem_num": stem.id,
          }),
        );
      }

      _isLoading = false;
    }
  }

  void EnterBasicSurvey() async {
    final stem = _allStems[_selectedIndex];
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
            .doc(stem['entity_number'].toString())
            .collection('줄기')
            .doc(stem['stem_number'].toString());

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
    final Map<String, dynamic> selectedValues = {};

    // 각 필드의 초기값 설정 (최소값)
    for (final field in fields) {
      selectedValues[field.label] = field.min;
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: const Text('작물 정보 입력'),
              content: SizedBox(
                height: 300,
                child: Column(
                  children: [
                    // 각 필드별 Picker 생성
                    for (final field in fields)
                      _buildFieldPicker(field, selectedValues, setState),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('취소'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoDialogAction(
                  child: const Text('확인'),
                  onPressed: () => Navigator.pop(context, selectedValues),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            field.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
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
      final stem = _allStems[_selectedIndex];
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
                      '이 작업은 되돌릴 수 없습니다!\n정말로 ${stem['entity_number']}-${stem['stem_number']} 개체를 삭제하시겠습니까?',
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
        final farmInstance = FarmDatabase.instance;
        await farmInstance.deleteStem(stem['id']);
        await _loadAllStems();
      }
    }
  }

  Future<void> _addNode(BuildContext context, int nodeNum) async {
    // 자동 생성 ID로 문서 참조 생성
    final nodeRef = stemRef.collection('마디').doc();
    await nodeRef.set({
      '번호': nodeNum,
      'status': '정상', // 기본값 예시
      // 필요한 다른 필드 추가 가능
    });
  }

  Future<void> _deleteNode(BuildContext context, int nodeNum) async {
    final nodeRef = stemRef.collection('마디').doc(nodeNum.toString());
    nodeRef.delete();
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
              _addNode(context, nodeNum+1)
            },
          ),
        ),
        nodeNum>0
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
        _allStems
            .map((item) => "${item['entity_num']}-${item['stem_num']}")
            .toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _selectedIndex + 1 > widget.farm["stem_count"]
            ? Expanded(
              flex: 2,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_left,
                  size: 70,
                  color: const Color.fromARGB(255, 11, 65, 19),
                ),
                onPressed: () {
                  _pageController.animateToPage(
                    _selectedIndex - stem_count,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            )
            : Spacer(flex: 2),

        Expanded(
          flex: 3,
          child: Text(
            '개체이동',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 30,
              color: const Color.fromARGB(255, 11, 65, 19),
              letterSpacing: 1.5,
            ),
          ),
        ),

        Expanded(
          flex: 2,
          child: DropdownButton<int>(
            isExpanded: true,
            value: _selectedIndex,
            style: TextStyle(
              fontSize: 25,
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
                  _selectedIndex = newIndex;
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
        _selectedIndex + stem_count < _allStems.length
            ? Expanded(
              flex: 2,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_right,
                  size: 70,
                  color: const Color.fromARGB(255, 11, 65, 19),
                ),
                onPressed: () {
                  _pageController.animateToPage(
                    _selectedIndex + stem_count,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            )
            : Spacer(flex: 2),
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            icon: Icon(
              Icons.delete,
              color: const Color.fromARGB(255, 138, 37, 37),
            ),
            label: Text(
              '개체삭제',
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
              deleteDialog();
            },
          ),
        ),
        SizedBox(width: 16),
        _selectedIndex >= _allStems.length - 2
            ? Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.add,
                  color: const Color.fromARGB(255, 138, 37, 37),
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
                  _addStem(
                    farmId,
                    state.stems[_selectedIndex]["entity_number"] + 1,
                    state,
                  );
                },
              ),
            )
            : Spacer(flex: 3),

        SizedBox(width: 16),
      ],
    );
  }

  Future<void> deleteStem(String entityId, String stemId) async {
    try {
      // 줄기의 모든 마디 삭제
      final nodes =
          await FirebaseFirestore.instance
              .collection('farms')
              .doc(farm["id"])
              .collection('개체')
              .doc(entityId)
              .collection('줄기')
              .doc(stemId)
              .collection('마디')
              .get();

      for (final node in nodes.docs) {
        await node.reference.delete();
      }

      // 줄기 문서 삭제
      await FirebaseFirestore.instance
          .collection('farms')
          .doc(farm["id"])
          .collection('개체')
          .doc(entityId)
          .collection('줄기')
          .doc(stemId)
          .delete();
    } catch (e) {
      print('줄기 삭제 실패: $e');
      rethrow;
    }
  }

  void _addStem(String farmId, int entityNum) async {
    await state._loadStems();
    final lastIndex = state.stems.length - stem_count;
    if (state.stemPageController.hasClients) {
      state.stemPageController.animateToPage(
        lastIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    }
  }

  Widget _stemPage(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '개체 $stemRef["entity_num"] - 줄기 $stemRef["stem_num]',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                stemRef
                    .collection('마디')
                    .orderBy('번호') // 예시: 마디 순서 필드
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final nodes = snapshot.data!.docs;
              if (nodes.isEmpty) {
                return const Center(child: Text('마디 데이터가 없습니다.'));
              }
              return ListView.builder(
                itemCount: nodes.length,
                itemBuilder: (context, index) {
                  if (index >= nodes.length) {
                    return _editNodeButton(context, nodes[index]['번호']);
                  }
                  final nodeRef = stemRef
                      .collection('마디')
                      .doc(index.toString());
                  return _nodeItem(context, nodeRef);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _nodeItem(BuildContext context, DocumentReference<Map<String, dynamic>> nodeRef) {
    final node = nodeRef.get().then((value) => value.data());
    final screenHeight = MediaQuery.of(context).size.height;
    final List<String> statuses = ['개화', '착과', '열매', '수확', '낙과'];
    String status = nodeRef.get()['status'] ?? '개화';
    return Container(
      height: screenHeight / 6, // ListTile의 높이에 맞게 지정
      decoration: BoxDecoration(
        image: DecorationImage(
          image: _getStatusImage(status), // 에셋 이미지 경로
          fit: BoxFit.cover, // 전체를 채우도록
        ),
        borderRadius: BorderRadius.circular(0), // Card 스타일을 원하면
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${node['node_number']} 번 마디',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: const Color.fromARGB(255, 11, 65, 19),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),

        trailing: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1000), // 최대 너비 제한 (필요에 따라 조절)
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children:
                statuses.map((status) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: status,
                        groupValue: node['status'],
                        onChanged: (value) async {
                          if (value == null) return;
                          await state.updateNodeStatus(node['id'], value);
                          status = value;
                        },
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 11, 65, 19),
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_allStems.isEmpty) {
      return const Scaffold(body: Center(child: Text('줄기 데이터가 없습니다.')));
    }
    return Scaffold(
      appBar: CustomAppBar(title: '${farm["farmName"]} 농가 마디조사'),
      body: Column(
        children: [
          Expanded(flex: 1, child: _pageDropdown()),
          Expanded(
            flex: 15,
            child: PageView.builder(
              itemCount: _allStems.length,
              onPageChanged: (int pageIndex) {
                setState(() {
                  if (pageIndex < _allStems.length) {
                    _selectedIndex = pageIndex; // 마지막 페이지
                  } // 페이지가 바뀌면 드롭다운 선택값 변경
                });
              },
              itemBuilder: (ctx, index) {
                final stem = _allStems[index];
                stemRef =
                    FirebaseFirestore.instance
                        .collection('farms')
                        .doc(farm["id"])
                        .collection('개체')
                        .doc(stem["entity_num"])
                        .collection('줄기')
                        .doc(stem["stem_num"]);
                return _stemPage(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StemView extends StatelessWidget {
  final Map<String, dynamic> stem;

  const _StemView({required this.stem});

  @override
  Widget build(BuildContext context) {
    state._loadNodes(stem['id'] as int); // 줄기 ID에 해당하는 마디 로드

    return Column(
      children: [
        // 마디 리스트
        Expanded(
          flex: 10,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            reverse: true,
            itemCount: state.nodes.length + 1,
            itemBuilder: (ctx, index) {
              if (index >= state.nodes.length)
                return _AddNodeButton(stemId: stem['id'] as int);
              final node = state.nodes[index];
              return _NodeItem(node: node);
            },
          ),
        ),

        Expanded(
          flex: 1,
          child: Row(
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 220, 233, 175),
                  ),
                  onPressed: () async {},
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 90, 73, 42), // 원하는 배경색
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Expanded(
                    flex: 2,
                    child: Center(
                      child: Text(
                        '${stem['entity_number']}-${stem['stem_number']} 개체',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 오른쪽 삭제 버튼
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    '마디조사 업로드',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 141, 216, 144),
                  ),
                  onPressed: () async {},
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text(
                    '마디조사표',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 131, 209, 134),
                  ),
                  onPressed: () async {},
                ),
              ),
              SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _NodeItem extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> node;

  const _NodeItem({required this.node});

  @override
  

  ImageProvider _getStatusImage(String status) {
    return AssetImage("assets/paprika_$status.png");
  }
}

// ... (나머지 위젯들)
