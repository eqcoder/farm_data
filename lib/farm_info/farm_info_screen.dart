import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../database/database.dart';
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
  TextEditingController _farmNameController = TextEditingController();
  TextEditingController _cropController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  int? selectedIndex;
  String uid = FirebaseAuth.instance.currentUser!.uid;

  List<Map<String, dynamic>> myFarms = [];
  List<Map<String, dynamic>> managedFarms = [];
  List<Map<String, dynamic>> allFarms = [];

  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    loadFarms();
  }

  String _extractCity(String address){

  // 공백으로 문자열 분리
  List<String> parts = address.split(' ');

  // '군' 또는 '시'로 끝나는 단어 찾기
  String cityName = parts.firstWhere(
    (part) => part.endsWith('군') || part.endsWith('시'),
    orElse: () => '',
  );
  if (cityName.isEmpty) {
    return ""; // '군' 또는 '시'가 없으면 원래 주소 반환
  }
  else{
  return cityName.substring(0, cityName.length - 1);}
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

      if (data['owner'] == uid) {
        my.add(data);
      } else if ((data['authorizedUsers'] as List<dynamic>?)?.contains(uid) == true) {
        managed.add(data);
      }
    }

    // 전체 농가: 내가 소유/관리하는 농가를 제외한 나머지
    final myOrManagedIds = {...my.map((e) => e['id']), ...managed.map((e) => e['id'])};
    final others = all.where((farm) => !myOrManagedIds.contains(farm['id'])).toList();

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
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
              onChanged: (value) => setState(() => _crop = value),
              validator: (value) => value == null ? "작물명을 선택하세요" : null,
            ),
            DropdownButtonFormField<int>(
  value: _selectedStemCount,
  decoration: InputDecoration(labelText: '줄기개수'),
  items: _stemCounts.map((count) {
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
                  validator: (value)  {
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
    String city= _extractCity(address);
    int stem_count = _selectedStemCount!;
    if (selectedFarm == null) {
       final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final farmRef = FirebaseFirestore.instance.collection('farms').doc();
  
  // 기본 데이터 저장
  await farmRef.set({
    'owner': user.uid,
    'authorizedUsers':[],
    'farmName': farmName,
    'crop': crop,
    'address': address,
    'city': city,
    'stem_count': stem_count,
    'createdAt': FieldValue.serverTimestamp(),
    'photosURLs': List.filled((schema.cropSchema[crop] as Map<String, dynamic>)['photosURLs'].length, '')
  });

  // 기본 개체(1번) 생성
  final individualRef = farmRef.collection('individuals').doc('1');

  // stem_count만큼 줄기 생성
  for (int stemNum = 1; stemNum <= stem_count; stemNum++) {
    final stemRef = individualRef.collection('stems').doc(stemNum.toString());
    await stemRef.set({
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 각 줄기에 기본 마디(1번) 생성
    final nodeRef = stemRef.collection('nodes').doc('1');
    await nodeRef.set({
      'status': '개화',
      '개화': null,
      '착과':null,
      '열매':null,
      '수확':null,
      '낙과과':null
    });
  }}
     else {
    }

    loadFarms(); // 데이터 다시 로드
  }


  _confirmDelete(BuildContext context) async {
  void _confirmDeleteFarm(Map<String, dynamic> farm) {
    String name = farm['farmName'];
    bool isMatched = false;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 32),
          SizedBox(width: 8),
          Text('정말 삭제하시겠습니까?', style: TextStyle(color: Colors.red)),
        ],
      ),
      content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text(
        '이 작업은 되돌릴 수 없습니다!\n정말로 ${name} 농가를 삭제하시겠습니까?',
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
                  decoration: InputDecoration(
                    hintText: name,
                  ),
                  onChanged: (value) {
                    setState((){
                      isMatched = value == name;});
                    })])
                ,
      actions: [
        TextButton(
          child: Text('취소'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton(
          child: Text('삭제', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(

            foregroundColor: isMatched ? Colors.red : Colors.grey,
          ),
          
          onPressed: isMatched?(){Navigator.of(context).pop(true);}:null,
        ),
      ],
    ),
    );
  }
  loadFarms();
  }

  void _showPermissionDialog(Map<String, dynamic> farm) {
    // 권한 부여 로직 구현 (Firestore의 authorizedUsers 필드 업데이트)
  }


  Widget buildDataTable(String title, List<Map<String, dynamic>> farms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('농가명')),
              DataColumn(label: Text('작물')),
              DataColumn(label: Text('줄기개수')),
              DataColumn(label: Text('주소')),
              DataColumn(label: Text('담당자')),
            ],
            rows: farms.map((farm) {
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
                  DataCell(Text(farm['stem_count']?.toString() ?? '')),
                  DataCell(Text(farm['address'] ?? '')),
                  DataCell(Text(farm['owner'] ?? '')), // 담당자: owner UID
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
    final isOwner = selectedFarm?['owner'] == uid;
    return Scaffold(
      body: Column(children:[Spacer(flex:1),Expanded(flex:1, child:Row(
        children: [Spacer(flex:1),
          Expanded(flex:5, child:ElevatedButton(
            onPressed: () => _openFarmDialog(), // 농가 추가 다이얼로그
            child: Text('농가 추가'),
          )),
          Spacer(flex:1),
          if (selectedFarm != null)
            Expanded(flex:5, child:ElevatedButton(
              onPressed:
                  () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => GrowthSurveyScreen(farm:selectedFarm!),
                  ),
                ),// 농가 수정 다이얼로그
              child: Text('개체정보'),
            )),Spacer(flex:1),
            if (selectedFarm != null)Expanded(flex:5, child:ElevatedButton(
              onPressed:
                  () => _confirmDelete(context),
              child: Text('농가 삭제'),
            ))
            ,Spacer(flex:1),
            if (selectedFarm != null&&isOwner)Expanded(flex:5, child:ElevatedButton(
              onPressed:
                  () => _showPermissionDialog(selectedFarm!),
              child: Text('권한 부여'),
            ))]),),
          Expanded(
            flex:30,
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

