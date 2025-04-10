import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../database.dart';

class FarmInfoScreen extends StatefulWidget {
  @override
  _FarmInfoScreenState createState() => _FarmInfoScreenState();
}

class _FarmInfoScreenState extends State<FarmInfoScreen> {
  List<Farm> farms = [];
  Farm? selectedFarm;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  String? _crop;
  TextEditingController _cropController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  int? selectedIndex;
  @override
  void initState() {
    super.initState();
    _loadFarms();
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

  Future<void> _loadFarms() async {
    farms = await FarmDatabase.instance.getAllFarms();
    if(mounted){}
    setState(() {});
  }

  _openFarmDialog({Farm? farm}) {
    final List<String> crops = ["토마토", "파프리카", "사과", "배추", "콩", "옥수수"];
    if (farm != null) {
      _nameController.text = farm.name;
      _crop = farm.crop;
      _addressController.text = farm.address;
      selectedFarm = farm;
    } else {
      _nameController.clear();
      _addressController.clear();
      selectedFarm = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(farm == null ? '농가 추가' : '농가 수정'),
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
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: '주소'),
                  validator: (value) => value!.isEmpty ? '주소를 입력하세요' : null,
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
              child: Text(farm == null ? '추가' : '수정'),
            ),
          ],
        );
      },
    );
  }

  _saveFarm() async {
    String name = _nameController.text;
    String crop = _crop!;
    String address = _addressController.text;
    String city= _extractCity(address);
    if (selectedFarm == null) {
      // 새로운 농가 추가
      Farm newFarm = Farm(name: name, crop: crop, address: address, city:city);
      await FarmDatabase.instance.insertFarm(newFarm);
    } else {
      // 기존 농가 수정
      Farm updatedFarm = Farm(
        id: selectedFarm!.id,
        name: name,
        crop: crop,
        address: address,
        city:city
      );
      await FarmDatabase.instance.updateFarm(updatedFarm);
    }

    _loadFarms(); // 데이터 다시 로드
  }

  _deleteFarm(BuildContext context) async{
    await FarmDatabase.instance.deleteData(selectedFarm!.id!);
    Navigator.pop(context, true);
  }

  _confirmDelete(BuildContext context) async {
  final bool? confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('삭제 확인'),
      content: Text('정말로 ${selectedFarm!.name} 농가를 삭제하시겠습니까?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소')),
        TextButton(onPressed: () =>_deleteFarm(context), child: Text('확인'))
      ],
    ),

  );
  _loadFarms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('농가 데이터')),
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
                  () => _openFarmDialog(farm: selectedFarm!), // 농가 수정 다이얼로그
              child: Text('정보 수정'),
            )),Spacer(flex:1),if (selectedFarm != null)Expanded(flex:5, child:ElevatedButton(
              onPressed:
                  () => _confirmDelete(context), // 농가 수정 다이얼로그
              child: Text('농가 삭제'),
            )),Spacer(flex:1)]),),
          Expanded(
            flex:30,
            child: ListView(
              children: [
                DataTable(
                  showCheckboxColumn: false, 
                  columns: [
                    DataColumn(label: Text('농가명')),
                    DataColumn(label: Text('작물')),
                    DataColumn(label: Text('주소')),
                  ],
                  rows:
                      farms.asMap().entries.map((entry) {
                        return DataRow(
                          selected: selectedIndex == entry.key, // 선택 상태 설정
                          onSelectChanged: (isSelected) { setState(() {
      selectedFarm = entry.value;
      selectedIndex = entry.key;
    });},
                          cells: [
                            DataCell(Text(entry.value.name)),
                            DataCell(Text(entry.value.crop)),
                            DataCell(Text(entry.value.address)),
                          ],
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 📌 농가 정보 입력/수정 다이얼로그
class FarmDialog extends StatefulWidget {
  final Map<String, dynamic>? farm;
  final Function(Map<String, dynamic>) onSave;

  FarmDialog({this.farm, required this.onSave});

  @override
  _FarmDialogState createState() => _FarmDialogState();
}

class _FarmDialogState extends State<FarmDialog> {
  final _formKey = GlobalKey<FormState>();
  String? name, crop, address;
  final List<String> crops = ["토마토", "파프리카", "사과", "배추", "콩"];

  @override
  void initState() {
    super.initState();
    if (widget.farm != null) {
      name = widget.farm!['name'];
      crop = widget.farm!['crop'];
      address = widget.farm!['address'];
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      widget.onSave({
        'id': widget.farm?['id'],
        'name': name,
        'crop': crop,
        'lastSurveyDate':
            widget.farm?['lastSurveyDate'] ??
            DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'address': address,
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.farm == null ? "농가 추가" : "농가 수정"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              decoration: InputDecoration(labelText: "농가명"),
              validator: (value) => value!.isEmpty ? "농가명을 입력하세요" : null,
              onSaved: (value) => name = value,
            ),
            DropdownButtonFormField<String>(
              value: crop,
              decoration: InputDecoration(labelText: "작물명"),
              items:
                  crops
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
              onChanged: (value) => setState(() => crop = value),
              validator: (value) => value == null ? "작물명을 선택하세요" : null,
            ),
            TextFormField(
              initialValue: address,
              decoration: InputDecoration(labelText: "주소"),
              validator: (value) => value!.isEmpty ? "주소를 입력하세요" : null,
              onSaved: (value) => address = value,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("취소"),
        ),
        ElevatedButton(onPressed: _save, child: Text("저장")),
      ],
    );
  }
}
