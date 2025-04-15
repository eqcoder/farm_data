import 'package:farm_data/business_trip/crop_photo.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessTripScreen extends StatefulWidget {
  @override
  _BusinessTripScreenState createState() => _BusinessTripScreenState();
}

class _BusinessTripScreenState extends State<BusinessTripScreen> {
  bool _loadingMap = false;
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


  Future<void> _openNaverMaps(BuildContext context, String address, String placeName) async {
  
    setState(() => _loadingMap = true);

    try {
      // 1. 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double slat = position.latitude;
      double slng = position.longitude;

      // 2. 목적지 주소를 위도/경도로 변환
      List<Location> locations = await locationFromAddress(address);
      double dlat = locations.first.latitude;
      double dlng = locations.first.longitude;

      // 3. 네이버 지도 길찾기 URL 생성
      String url =
          'nmap://route/car?dlat=$dlat&dlng=$dlng&dname=${Uri.encodeComponent(address)}&appname=${Uri.encodeComponent("com.example.yourapp")}';

      // 4. 네이버 지도 앱 실행, 없으면 웹으로 fallback
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        // 앱이 없으면 웹으로
        String webUrl =
            'https://map.naver.com/v5/directions/${slat},${slng},내위치,START/${dlat},${dlng},${Uri.encodeComponent(address)},END?c=${dlat},${dlng},15,0,0,0,dh';
        await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('길찾기 실행에 실패했습니다: $e')),
      );
    } finally {
      setState(() => _loadingMap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
     final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
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
          Expanded(flex:1, child:Text(
                    '작물: ${farm!.crop}',
                    style: TextStyle(fontSize: 25),
                  )),
          Expanded(
            flex:2,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    color: const Color.fromARGB(255, 199, 227, 243),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            Icon(Icons.location_on, color: const Color.fromARGB(255, 95, 16, 42)),
            SizedBox(width: 10),
              Text(
                '${farm!.address}',
                style: TextStyle(fontSize: 20, color: const Color.fromARGB(255, 9, 4, 58), fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(width: 4),
                  
          ],))),
          SizedBox(width:4),
          ElevatedButton.icon(style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 218, 226, 181),
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),),
          onPressed: _loadingMap ? null : ()async{_openNaverMaps(context, farm!.address, "");},
          icon: Icon(Icons.directions, size:30),
          label: Text('길찾기', style:TextStyle(fontSize:20)),
        ),
                  
                  ]))),
                  SizedBox(height:16),
                  Expanded(flex:10, child:Card(
                    color: const Color.fromARGB(255, 239, 243, 189),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sunny, color: const Color.fromARGB(255, 95, 16, 42)),
            SizedBox(width: 10),
              Text(
                '날씨정보를 불러오는 중...',
                style: TextStyle(fontSize: 25, color: const Color.fromARGB(255, 9, 4, 58), fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(width: 25),
                  
          ],)))),
                  Spacer(flex:1),
            Expanded(flex:3, child:
            Padding(
  padding: EdgeInsets.symmetric(horizontal: 40), child:ElevatedButton(
              style: ElevatedButton.styleFrom(
    backgroundColor: const Color.fromARGB(255, 210, 240, 210),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(100),
    ),
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    elevation: 3,
  ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => CropPhotoScreen(selectedFarm: selectedFarm!),
                  ),
                );
              },

              child: Row(mainAxisAlignment: MainAxisAlignment.center, // 세로축 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.center,children:[
              
                
                Icon(Icons.camera_alt, size:40, color:const Color.fromARGB(255, 44, 22, 122)),
                SizedBox(width:16),
                Text("조사사진 촬영", style: TextStyle(fontSize:40, color:const Color.fromARGB(255, 44, 22, 122), fontWeight: FontWeight.bold),),]
            )))),
            Spacer(flex:1)
        ]));
  }
}

/// 📌 로컬 데이터베이스 (농가명 저장 및 불러오기)
