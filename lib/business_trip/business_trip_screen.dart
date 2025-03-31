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
  List<File?> _photos = List.generate(4, (_) => null);
  String? selectedFarm;
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
      await _fetchWeather();
    }
    setState(() {});
  }

  Future<void> _fetchWeather() async {
    String apiKey = "YOUR_OPENWEATHERMAP_API_KEY";
    String apiUrl =
        "https://api.openweathermap.org/data/2.5/weather?q=$farmAddress&appid=$apiKey&units=metric&lang=kr";

      final response = await http.get(Uri.parse(apiUrl));
        setState(() {
          weatherInfo = "날씨 정보를 가져오지 못했습니다.";});
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
    return Scaffold(
      appBar: AppBar(title: Text(selectedFarm ?? "농가 선택")),
      body: Expanded(
        child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 세로축 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            DropdownButton<String>(
              value: selectedFarm,
              hint: Text("농가 선택"),
              items:
                  farmNames.map((String farm) {
                    return DropdownMenuItem<String>(
                      value: farm,
                      child: Text(farm),
                    );
                  }).toList(),
              onChanged: (value) async {
                setState(() {
                  selectedFarm = value;
                });
                await _fetchWeather();
              },
            ),
            Text("현재 날씨: $weatherInfo"),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => CropPhotoScreen(selectedFarm: selectedFarm!),
                  ),
                );
              },

              child: Text("조사사진 촬영"),
            ),
            ElevatedButton(onPressed: _openOpinet, child: Text("길안내")),
            ElevatedButton(onPressed: _openGoogleMaps, child: Text("오피넷")),
          ],
        ),)
      ),
    );
  }
}

/// 📌 로컬 데이터베이스 (농가명 저장 및 불러오기)
