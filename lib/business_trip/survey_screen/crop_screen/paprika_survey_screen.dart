import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import '../../../appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../provider.dart' as provider;
import '../../../crop/paprika.dart';
import '../../../crop/crop.dart';
import '../../../farm/schema.dart';
import '../widget.dart';

class PaprikaSurveyScreen extends StatefulWidget {
  final Farm farm;
  const PaprikaSurveyScreen({super.key, required this.farm});
  @override
  State<PaprikaSurveyScreen> createState() => _PaprikaSurveyScreenState();
}

class _PaprikaSurveyScreenState extends State<PaprikaSurveyScreen> {
  final PageController _pageController = PageController();
  late Farm farm;
  late Crop paprika;
  String farmName = "";
  int currentPage = 0;
  int currentEntity = 0;
  int currentStem = 0;
  final today = DateFormat('MM/dd').format(DateTime.now());
  late int stemCount;

  late QuerySnapshot<Map<String, dynamic>> entities;
  late Future<QuerySnapshot<Map<String, dynamic>>> _nodesFuture;
  String entityName = "";
  List<String> stemNames = [];
  final Map<String, dynamic> basicSurvey = {};

  final List<String> statuses = ['개화', '착과', '열매', '수확'];

  @override
  void initState() {
    super.initState();
    farm = widget.farm;
    paprika = farm.crop;
    farmName = farm.name;
    stemCount = (paprika as Paprika).stemCount;
    refresh();
  }

  @override
  void dispose() {
    _pageController.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  void refresh() async {
    await (paprika as Paprika).loadAllStems();
    setState(() {});
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
              (paprika as Paprika).addNode(
                currentEntity,
                currentStem,
                nodeNum + 1,
              );
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
                  (paprika as Paprika).deleteNode(
                    currentEntity,
                    currentStem,
                    nodeNum,
                  );
                },
              ),
            )
            : SizedBox.shrink(),
      ],
    );
  }

  List<String> getAvailableEntityStemOptions({required List<String> existing}) {
    final entityStemMap = <int, Set<int>>{};

    // 기존 데이터 파싱: {1: {1}, 2: {1}}
    for (final item in existing) {
      final parts = item.split('-');
      if (parts.length != 2) continue;
      final entity = int.tryParse(parts[0]);
      final stem = int.tryParse(parts[1]);
      if (entity == null || stem == null) continue;
      entityStemMap.putIfAbsent(entity, () => <int>{}).add(stem);
    }

    final result = <String>[];

    // 1. 기존 개체의 빠진 줄기 추가
    for (final entity in entityStemMap.keys) {
      final existingStems = entityStemMap[entity]!;
      for (int stem = 1; stem <= stemCount; stem++) {
        if (!existingStems.contains(stem)) {
          result.add('$entity-$stem');
        }
      }
    }

    // 2. 다음 개체 번호의 모든 줄기 추가
    final maxEntity =
        entityStemMap.isEmpty
            ? 0
            : entityStemMap.keys.reduce((a, b) => a > b ? a : b);
    final nextEntity = maxEntity + 1;
    for (int stem = 1; stem <= stemCount; stem++) {
      result.add('$nextEntity-$stem');
    }

    return result;
  }

  void addStem(BuildContext context) async {
    final entityStemOptions = getAvailableEntityStemOptions(
      existing: paprika.entityNames,
    );
    final selectedEntityStem = await showAddEntityDialog(
      context: context,
      entities: entityStemOptions,
      title: '줄기 추가',
    );
    if (selectedEntityStem != null) {
      final parts = selectedEntityStem.split('-');
      if (parts.length == 2) {
        final entityNumber = int.parse(parts[0]);
        final stemNumber = int.parse(parts[1]);
        (paprika as Paprika).addStem(entityNumber, stemNumber);
        refresh();
      }
    }
  }

  Widget pageDropdown(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        currentPage + 1 > stemCount
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
                    currentPage - stemCount,
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
            value: currentPage,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            items: List.generate(
              stemNames.length,
              (index) => DropdownMenuItem<int>(
                value: index,
                child: Center(child: Text(stemNames[index])),
              ),
            ),
            onChanged: (int? newIndex) {
              if (newIndex != null) {
                setState(() {
                  currentPage = newIndex;
                });
                // 페이지 이동
                _pageController.animateToPage(
                  currentPage,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
        currentPage + stemCount < stemNames.length
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
                    currentPage + stemCount,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            )
            : Spacer(flex: 2),
        currentPage + stemCount < stemNames.length
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
                  showDeleteConfirmDialog(
                    context: context,
                    description: '${stemNames[currentPage]}개체',
                    hintText: farmName,
                  );
                },
              ),
            )
            : Spacer(flex: 2),
        SizedBox(width: 8),
        currentPage >= stemNames.length - stemCount
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
                  addStem(context);
                  final lastIndex = stemNames.length - stemCount;
                  if (_pageController.hasClients) {
                    _pageController.animateToPage(
                      lastIndex,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.ease,
                    );
                  }
                },
              ),
            )
            : Spacer(flex: 4),

        SizedBox(width: 8),
      ],
    );
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
        final number = node['nodeNumber'] as int;
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
                              await (paprika as Paprika).updateNodeStatus(
                                nodeRef,
                                value,
                              );
                              setState(() {
                                status = value;
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
                itemCount: nodes.length + 1,
                itemBuilder: (context, index) {
                  if (index == nodes.length) {
                    // 마지막에 추가 버튼

                    return _editNodeButton(
                      context,
                      nodes.isNotEmpty ? nodes.last['nodeNumber'] : 1,
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

  Widget buildNodeDataTable(List<Map<String, dynamic>> nodeList) {
    if (nodeList.isEmpty) {
      return Text('데이터가 없습니다.');
    }

    // 모든 열 이름 추출 (마디번호는 제외)
    final allKeys = nodeList.first.keys.where((k) => k != '마디번호').toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('마디번호')), // 첫 번째 열: 마디번호
          ...allKeys.map((key) => DataColumn(label: Text(key))),
        ],
        rows:
            nodeList.map((node) {
              return DataRow(
                cells: [
                  DataCell(Text(node['마디번호'].toString())),
                  ...allKeys.map(
                    (key) => DataCell(Text(node[key]?.toString() ?? '')),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  void showNodeDataTableDialog(
    BuildContext context,
    List<Map<String, dynamic>> nodeList,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('마디 데이터'),
          content: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: buildNodeDataTable(nodeList),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('닫기'),
            ),
          ],
        );
      },
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
              final result = await showBasicSurveyInputDialog(
                context: context,
                crop: paprika,
              );
              if (result != null) {
                paprika.basicSurvey = result;
                // Firestore 저장, 상태 업데이트 등 추가 작업
              } else {}
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
                  '$stemNames[_currentPage]',
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
        Expanded(
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
              final group =
                  Provider.of<provider.SettingsProvider>(
                    context,
                    listen: false,
                  ).selectedGroup;
              farm.processGDriveData(group);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('데이터 업로드 완료!')));
            },
          ),
        ),
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
            onPressed: () async {
              List<Map<String, dynamic>> nodeList = await (paprika as Paprika)
                  .nodeSuveryTable(currentEntity, currentStem);

              showNodeDataTableDialog(context, nodeList);
            },
          ),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (paprika.allEntities.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(title: '$farmName 농가 마디조사'),
        body:
            stemNames.isNotEmpty
                ? Center(
                  child: ElevatedButton.icon(
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
                      addStem(context);
                    },
                  ),
                )
                : Center(child: Text("개체가 없습니다.")),
      );
    }
    return Scaffold(
      appBar: CustomAppBar(title: '$farmName} 농가 마디조사'),
      body: Column(
        children: [
          Expanded(flex: 1, child: pageDropdown(context)),
          Expanded(
            flex: 10,
            child: PageView.builder(
              controller: _pageController,
              itemCount: paprika.allEntities.length,
              onPageChanged: (int pageIndex) {
                setState(() {
                  if (pageIndex < paprika.allEntities.length) {
                    currentPage = pageIndex;
                    currentEntity =
                        paprika.allEntities[pageIndex]["entityNumber"];
                    currentStem = paprika.allEntities[pageIndex]["stemNumber"];
                  } // 페이지가 바뀌면 드롭다운 선택값 변경
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
