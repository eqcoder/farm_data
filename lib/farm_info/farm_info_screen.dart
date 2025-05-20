import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../crop_config/schema.dart' as schema;
import '../business_trip/survey_screen/growth_survey.dart';

class FarmInfoScreen extends StatefulWidget {
  @override
  _FarmInfoScreenState createState() => _FarmInfoScreenState();
}

class _FarmInfoScreenState extends State<FarmInfoScreen> {
  Map<String, dynamic>? selectedFarm;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  String? _crop;
  int? _selectedStemCount;
  final List<int> _stemCounts = [1, 2, 3];
  final TextEditingController _farmNameController = TextEditingController();
  TextEditingController _cropController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  int? selectedIndex;
  late String uid;
  late DocumentReference<Map<String, dynamic>> userRef;
  late DocumentReference<Map<String, dynamic>> farmRef;

  List<Map<String, dynamic>> myFarms = [];
  List<Map<String, dynamic>> managedFarms = [];
  List<Map<String, dynamic>> allFarms = [];

  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    loadFarms();
    uid = FirebaseAuth.instance.currentUser!.uid;
    userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    farmRef = FirebaseFirestore.instance.collection('farms').doc();
  }

  String _extractCity(String address) {
    // 공백으로 문자열 분리
    List<String> parts = address.split(' ');

    // '군' 또는 '시'로 끝나는 단어 찾기
    String cityName = parts.firstWhere(
      (part) => part.endsWith('군') || part.endsWith('시'),
      orElse: () => '',
    );
    if (cityName.isEmpty) {
      return ""; // '군' 또는 '시'가 없으면 원래 주소 반환
    } else {
      return cityName.substring(0, cityName.length - 1);
    }
  }

  Future<void> loadFarms() async {
    final farmsSnapshot =
        await FirebaseFirestore.instance.collection('farms').get();

    List<Map<String, dynamic>> all = [];
    List<Map<String, dynamic>> my = [];
    List<Map<String, dynamic>> managed = [];

    for (final doc in farmsSnapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      all.add(data);

      final ownerRef = data['owner'] as DocumentReference;
      final authorizedRefs =
          (data['authorizedUsers'] as List<dynamic>?)
              ?.cast<DocumentReference>() ??
          [];

      // 1. 소유주 확인 (DocumentReference의 ID가 현재 UID와 같은지)
      if (ownerRef.id == uid) {
        my.add(data);
      }
      // 2. 권한 유저 확인 (DocumentReference 리스트의 ID 중에 현재 UID가 있는지)
      else if (authorizedRefs.any((ref) => ref.id == uid)) {
        managed.add(data);
      }
    }

    // 전체 농가: 내가 소유/관리하는 농가를 제외한 나머지
    final myOrManagedIds = {
      ...my.map((e) => e['id']),
      ...managed.map((e) => e['id']),
    };
    final others =
        all.where((farm) => !myOrManagedIds.contains(farm['id'])).toList();

    setState(() {
      myFarms = my;
      managedFarms = managed;
      allFarms = others;
      isLoading = false;
    });
  }

  Future<void> deleteFarm(String farmId) async {
    // Firestore 문서 삭제
    await FirebaseFirestore.instance.collection('farms').doc(farmId).delete();
    // Storage 이미지 삭제 (필요 시 추가)
    await loadFarms(); // 목록 새로고침
  }

  _openFarmDialog() {
    final List<String> crops = schema.cropSchema.keys.toList();
    _nameController.clear();
    _addressController.clear();
    selectedFarm = null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('농가 추가'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: '농가명'),
                  validator: (value) => value!.isEmpty ? '농가명을 입력하세요' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _crop,
                  decoration: InputDecoration(labelText: "작물명"),
                  items:
                      crops
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged: (value) => setState(() => _crop = value),
                  validator: (value) => value == null ? "작물명을 선택하세요" : null,
                ),
                DropdownButtonFormField<int>(
                  value: _selectedStemCount,
                  decoration: InputDecoration(labelText: '줄기개수'),
                  items:
                      _stemCounts.map((count) {
                        return DropdownMenuItem<int>(
                          value: count,
                          child: Text('$count'),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStemCount = value;
                    });
                  },
                  validator: (value) => value == null ? '줄기개수를 선택하세요' : null,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: '주소'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '주소를 입력하세요';
                    }
                    // 시/군/구가 포함되어 있는지 정규식으로 체크 (예시: '시' 또는 '군' 또는 '구'가 포함되어야 함)
                    if (!(value.contains('시') || value.contains('군'))) {
                      return '주소에 시/군/구 정보를 포함해주세요';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _saveFarm();
                  Navigator.of(context).pop();
                }
              },
              child: Text('추가'),
            ),
          ],
        );
      },
    );
  }

  _saveFarm() async {
    String farmName = _nameController.text;
    String crop = _crop!;
    String address = _addressController.text;
    String city = _extractCity(address);
    int stem_count = _selectedStemCount!;
    if (selectedFarm == null) {
      // 기본 데이터 저장
      await farmRef.set({
        'owner': FirebaseFirestore.instance.collection('users').doc(uid),
        'authorizedUsers': [],
        'farmName': farmName,
        'crop': crop,
        'address': address,
        'city': city,
        'stem_count': stem_count,
        'createdAt': FieldValue.serverTimestamp(),
        'photosURLs': List.filled(
          (schema.cropSchema[crop] as Map<String, dynamic>)['이미지제목'].length,
          '',
        ),
      });

      // 기본 개체(1번) 생성
      final individualRef = farmRef.collection('개체').doc('1');
      individualRef.set({'개체번호': 1});
      // stem_count만큼 줄기 생성
      for (int stemNum = 1; stemNum <= stem_count; stemNum++) {
        final stemRef = individualRef.collection('줄기').doc(stemNum.toString());
        ;
        stemRef.set({'줄기번호': stemNum});
        // 각 줄기에 기본 마디(1번) 생성
        final nodeRef = stemRef.collection('마디').doc('1');
        final Map<String, dynamic> nodeData = {
          ...(schema.cropSchema[crop] as Map<String, dynamic>)['마디정보'],
          '마디번호': 1,
        };
        await nodeRef.set(nodeData);
      }
    } else {}

    loadFarms(); // 데이터 다시 로드
  }

  _confirmDelete(BuildContext context) async {
    String name = selectedFarm!['farmName'];
    bool isMatched = false;
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
                    '이 작업은 되돌릴 수 없습니다!\n정말로 $name 농가를 삭제하시겠습니까?',
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
                  child: Text(
                    '삭제',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: isMatched ? Colors.red : Colors.grey,
                  ),

                  onPressed:
                      isMatched
                          ? () {
                            Navigator.of(context).pop(true);
                          }
                          : null,
                ),
              ],
            );
          },
        );
      },
    );
    if (confirm == true) {
      await deleteFarm(selectedFarm!["id"]);
    }
    loadFarms();
  }

  void _showPermissionDialog(Map<String, dynamic> selectedFarm) async {
    final farmRef = FirebaseFirestore.instance
        .collection('farms')
        .doc(selectedFarm["id"]);
    final farmSnap = await farmRef.get();
    List<DocumentReference<Map<String, dynamic>>> authorizedRefs =
        (farmSnap['authorizedUsers'] as List<dynamic>?)
            ?.cast<DocumentReference<Map<String, dynamic>>>() ??
        [];
    Set<String> authorizedUids = authorizedRefs.map((ref) => ref.id).toSet();

    await showDialog(
      context: context,
      builder:
          (context) => PermissionManagementDialog(
            farmRef: farmRef,
            authorizedUids: authorizedUids,
            onUpdate: loadFarms,
            farmname: selectedFarm["farmName"],
          ),
    );
  }

  Widget buildDataTable(String title, List<Map<String, dynamic>> farms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('농가명')),
              DataColumn(label: Text('작물')),
              DataColumn(label: Text('주소')),
              DataColumn(label: Text('담당자')),
            ],
            rows:
                farms.map((farm) {
                  return DataRow(
                    selected: selectedFarm?['id'] == farm['id'],
                    onSelectChanged: (selected) {
                      setState(() {
                        selectedFarm = selected! ? farm : null;
                      });
                    },
                    cells: [
                      DataCell(Text(farm['farmName'] ?? '')),
                      DataCell(Text(farm['crop'] ?? '')),
                      DataCell(Text(farm['address'] ?? '')),
                      DataCell(
                        FutureBuilder<DocumentSnapshot>(
                          future: farm['owner'].get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text('로딩...');
                            }
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return Text('미지정');
                            }
                            return Text(
                              snapshot.data!.get('displayName') ?? '',
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = selectedFarm?['owner'].id == uid;
    return Scaffold(
      body: Column(
        children: [
          Spacer(flex: 1),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                SizedBox(width: 8),
                if (selectedFarm == null)
                  Expanded(
                    flex: 5,
                    child: ElevatedButton(
                      onPressed: () => _openFarmDialog(), // 농가 추가 다이얼로그
                      child: Text('농가 추가'),
                    ),
                  ),
                SizedBox(width: 8),

                if (selectedFarm != null)
                  Expanded(
                    flex: 5,
                    child: ElevatedButton(
                      onPressed: () => _confirmDelete(context),
                      child: Text('농가 삭제'),
                    ),
                  ),
                SizedBox(width: 8),
                if (selectedFarm != null)
                  Expanded(
                    flex: 5,
                    child: ElevatedButton(
                      onPressed:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (BuildContext context) => GrowthSurveyScreen(
                                    farm: selectedFarm!,
                                    isEditMode: false,
                                  ),
                            ),
                          ), // 농가 수정 다이얼로그
                      child: Text('개체정보'),
                    ),
                  ),
                SizedBox(width: 8),
                if (selectedFarm != null && isOwner)
                  Expanded(
                    flex: 5,
                    child: ElevatedButton(
                      onPressed: () => _showPermissionDialog(selectedFarm!),
                      child: Text('권한 부여'),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 30,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildDataTable('my농가', myFarms),
                    buildDataTable('관리중인 농가', managedFarms),
                    buildDataTable('전체농가', allFarms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PermissionManagementDialog extends StatefulWidget {
  final DocumentReference farmRef;
  final Set<String> authorizedUids;
  final VoidCallback onUpdate;
  final String farmname;

  const PermissionManagementDialog({
    required this.farmRef,
    required this.authorizedUids,
    required this.onUpdate,
    required this.farmname,
  });

  @override
  _PermissionManagementDialogState createState() =>
      _PermissionManagementDialogState();
}

class _PermissionManagementDialogState
    extends State<PermissionManagementDialog> {
  List<Map<String, dynamic>> _allUsers = [];
  late Set<String> _selectedToAdd;
  late Set<String> _selectedToRemove;
  late String uid;
  late DocumentReference<Map<String, dynamic>> userRef;

  @override
  void initState() {
    super.initState();
    _selectedToAdd = Set();
    _selectedToRemove = Set();
    _loadUsers();
    uid = FirebaseAuth.instance.currentUser!.uid;
    userRef = FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Future<List<Map<String, dynamic>>> fetchAllUsersExceptMe() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs
        .where((doc) => doc.id != uid)
        .map((doc) => doc.data()..['uid'] = doc.id)
        .toList();
  }

  Future<void> _loadUsers() async {
    _allUsers = await fetchAllUsersExceptMe();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authorized =
        _allUsers
            .where((u) => widget.authorizedUids.contains(u['uid']))
            .toList();
    final unauthorized =
        _allUsers
            .where((u) => !widget.authorizedUids.contains(u['uid']))
            .toList();

    return AlertDialog(
      title: Text('${widget.farmname} 농가 권한 관리'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            _buildUserSection(
              '권한이 있는 사용자',
              authorized,
              _selectedToRemove,
              true,
            ),
            Divider(),
            _buildUserSection(
              '권한이 없는 사용자',
              unauthorized,
              _selectedToAdd,
              false,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
        ElevatedButton(onPressed: _saveChanges, child: Text('저장')),
      ],
    );
  }

  Widget _buildUserSection(
    String title,
    List<Map<String, dynamic>> users,
    Set<String> selectedSet,
    bool isRemoval,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final String name = user['name'] ?? user['uid'];
                final String? photoURL = user['photoURL'];

                return CheckboxListTile(
                  title: Text(name),
                  value: selectedSet.contains(user['uid']),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedSet.add(user['uid']);
                      } else {
                        selectedSet.remove(user['uid']);
                      }
                    });
                  },
                  subtitle: Text(isRemoval ? '권한 해제 선택' : '권한 부여 선택'),
                  secondary: CircleAvatar(
                    backgroundImage:
                        (photoURL != null && photoURL.isNotEmpty)
                            ? NetworkImage(photoURL)
                            : null,
                    child:
                        (photoURL == null || photoURL.isEmpty)
                            ? Text(
                              name.isNotEmpty ? name[0] : '?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )
                            : null,
                    backgroundColor: Colors.grey[300],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    // DocumentReference로 변환
    final toAddRefs =
        _selectedToAdd
            .map(
              (uid) => FirebaseFirestore.instance.collection('users').doc(uid),
            )
            .toList();

    final toRemoveRefs =
        _selectedToRemove
            .map(
              (uid) => FirebaseFirestore.instance.collection('users').doc(uid),
            )
            .toList();

    final batch = FirebaseFirestore.instance.batch();

    if (toAddRefs.isNotEmpty) {
      batch.update(widget.farmRef, {
        'authorizedUsers': FieldValue.arrayUnion(toAddRefs),
      });
    }

    if (toRemoveRefs.isNotEmpty) {
      batch.update(widget.farmRef, {
        'authorizedUsers': FieldValue.arrayRemove(toRemoveRefs),
      });
    }

    await batch.commit();
    widget.onUpdate();
    Navigator.pop(context);
  }
}
