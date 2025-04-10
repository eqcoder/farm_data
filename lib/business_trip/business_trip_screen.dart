import 'package:farm_data/business_trip/crop_photo.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../database.dart';

class BusinessTripScreen extends StatefulWidget {
  @override
  _BusinessTripScreenState createState() => _BusinessTripScreenState();
}

class _BusinessTripScreenState extends State<BusinessTripScreen> {
  String? selectedFarm;
  Farm? farm;
  int selectedFarmIndex=0;
  String weatherInfo = "날씨 정보를 불러오는 중...";
  String farmAddress = "서울특별시 중구 세종대로"; // 예제 주소 (실제 데이터 사용 가능)
  List<String> farmNames = [];

  @override
  void initState() {
    super.initState();
    _loadFarmNames();
  }

  Future<void> _loadFarmNames() async {
    farmNames = await FarmDatabase.instance.getFarmNames();
    if (farmNames.isNotEmpty) {
      selectedFarm = farmNames.first;
      final _farm= await FarmDatabase.instance.getFarmByName(selectedFarm!);
      setState(() {
      farm=_farm;
    });
    }

  }


  Future<void> _openGoogleMaps() async {
    final url = "https://www.google.com/maps/search/?api=1&query=$farmAddress";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("길안내를 실행할 수 없습니다.");
    }
  }

  Future<void> _openOpinet() async {
    final url = "https://www.opinet.co.kr/searRgSelect.do";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("오피넷을 실행할 수 없습니다.");
    }
  }

  @override
  Widget build(BuildContext context) {
     final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: Text("출장")),
      body: selectedFarm==null?Center(child:Text("농가정보를 추가해주세요")):Column(
          mainAxisAlignment: MainAxisAlignment.center, // 세로축 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            Spacer(flex:1),
            Expanded(flex:1, child:
            Container(
            height: 50, // 버튼 높이 설정
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: farmNames.length,
              itemBuilder: (context, index) {
                return  Container(
              width: screenWidth / 3,
              padding: EdgeInsets.symmetric(horizontal: 8),
              
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      backgroundColor:
                          selectedFarmIndex == index ? Colors.blue : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async{
                        
                        final _farm=await FarmDatabase.instance.getFarmByName(farmNames[index]);

                      setState((){
                        selectedFarmIndex = index;
                        selectedFarm=farmNames[selectedFarmIndex];
                        farm=_farm;
                      });
                    },
                    child: Text(farmNames[index], style: TextStyle(fontSize:20),),
                  ),
                );
              },
            ),
          ),),
          Spacer(flex:1),
          Expanded(
            flex:3,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  Text(
                    '주소: ${farm!.address}',
                    style: TextStyle(fontSize: 25),
                  ),
                  const SizedBox(width: 25),
                  Text(
                    '작물: ${farm!.crop}',
                    style: TextStyle(fontSize: 25),
                  ),]))),
            Expanded(flex:15, child:ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => CropPhotoScreen(selectedFarm: selectedFarm!),
                  ),
                );
              },

              child: Row(mainAxisAlignment: MainAxisAlignment.center, // 세로축 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.center,children:[
                
                Icon(Icons.camera_alt, size:100),
                Text("조사사진 촬영", style: TextStyle(fontSize:50),),]
            ))),
            Spacer(flex:1)
        ]));
  }
}

/// 📌 로컬 데이터베이스 (농가명 저장 및 불러오기)
