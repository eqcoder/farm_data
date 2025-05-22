import 'crop_photo.dart';
import 'package:flutter/material.dart';
import 'dart:core';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:map_launcher/map_launcher.dart';
import 'survey_screen/growth_survey.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../farm/schema.dart';

class BusinessTripScreen extends StatefulWidget {
  const BusinessTripScreen({super.key});
  @override
  State<BusinessTripScreen> createState() => _BusinessTripScreenState();
}

class _BusinessTripScreenState extends State<BusinessTripScreen> {
  bool _loadingMap = false;
  String selectedFarm = "";
  int selectedFarmIndex = 0;
  String weatherInfo = "날씨 정보를 불러오는 중...";
  String farmAddress = ""; // 예제 주소 (실제 데이터 사용 가능)
  List<Farm> farmList = [];
  List<String> farmNames = [];
  late Farm farm;
  late String uid;
  late DocumentReference<Map<String, dynamic>> userRef;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    _loadMyFarms();
  }

  Future<void> _loadMyFarms() async {
    QuerySnapshot ownerSnap =
        await FirebaseFirestore.instance
            .collection('farms')
            .where('owner', isEqualTo: userRef)
            .get();

    final QuerySnapshot authUserSnap =
        await FirebaseFirestore.instance
            .collection('farms')
            .where('authorizedUsers', arrayContains: userRef)
            .get();
    final allFarms = [...ownerSnap.docs, ...authUserSnap.docs].toList();
    setState(() {
      farmList =
          allFarms.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Farm.fromMap({
              'id': doc.id, // 문서 ID 추가
              ...data, // 나머지 필드
            });
          }).toList();
      farmNames = farmList.map((doc) => doc.name).whereType<String>().toList();
    });
    if (farmNames.isNotEmpty) {
      selectedFarm = farmNames[selectedFarmIndex];
      farm = farmList[selectedFarmIndex];
    }
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      // 권한 허용됨: 위치 정보 사용 가능
    } else if (status.isDenied) {
      // 권한 거부됨: 안내 메시지 등 처리
    } else if (status.isPermanentlyDenied) {
      // 영구적으로 거부됨: 설정에서 직접 허용 유도
      openAppSettings();
    }
  }

  Future<void> _openNaverMaps(
    BuildContext context,
    String address,
    String placeName,
  ) async {
    setState(() => _loadingMap = true);

    await requestLocationPermission();
    // 1. 현재 위치 가져오기
    Position position = await Geolocator.getCurrentPosition();

    // 2. 주소를 좌표로 변환
    List<Location> locations = await locationFromAddress(address);
    double destLat = locations.first.latitude;
    double destLng = locations.first.longitude;

    // 3. 설치된 지도앱 리스트 가져오기
    final availableMaps = await MapLauncher.installedMaps;

    // 4. 첫 번째 지도앱으로 길안내 실행 (예: 구글지도)
    await MapLauncher.showDirections(
      mapType: MapType.naver,
      destination: Coords(destLat, destLng),
      destinationTitle: '목적지',
      origin: Coords(position.latitude, position.longitude),
      originTitle: '현재 위치',
      directionsMode: DirectionsMode.driving,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body:
          selectedFarm == ""
              ? Center(child: Text("농가정보를 추가해주세요"))
              : Column(
                mainAxisAlignment: MainAxisAlignment.center, // 세로축 중앙 정렬
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Spacer(flex: 1),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50, // 버튼 높이 설정
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: farmNames.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: screenWidth / 3,
                            padding: EdgeInsets.symmetric(horizontal: 8),

                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor:
                                    selectedFarmIndex == index
                                        ? Colors.blue
                                        : Colors.grey,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                setState(() {
                                  selectedFarmIndex = index;
                                  selectedFarm = farmNames[selectedFarmIndex];
                                  farm = farmList[selectedFarmIndex];
                                });
                              },
                              child: Text(
                                farmNames[index],
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '작물: ${farm.crop.name}',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        color: const Color.fromARGB(255, 11, 128, 30),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    flex: 2,
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
                                  Icon(
                                    Icons.location_on,
                                    color: const Color.fromARGB(
                                      255,
                                      95,
                                      16,
                                      42,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    farm.address,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: const Color.fromARGB(
                                        255,
                                        9,
                                        4,
                                        58,
                                      ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                218,
                                226,
                                181,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed:
                                _loadingMap
                                    ? null
                                    : () async {
                                      _openNaverMaps(context, farm.address, "");
                                    },
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions, size: 24),
                                // 아이콘과 텍스트 사이 간격
                                Text('길찾기', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    flex: 8,
                    child: Card(
                      color: const Color.fromARGB(255, 253, 253, 250),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sunny,
                              color: const Color.fromARGB(255, 95, 16, 42),
                            ),
                            SizedBox(width: 10),
                            Text(
                              '날씨정보를 불러오는 중...',
                              style: TextStyle(
                                fontSize: 25,
                                color: const Color.fromARGB(255, 9, 4, 58),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 25),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            241,
                            240,
                            160,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (BuildContext context) => GrowthSurveyScreen(
                                    farm: farm,
                                    isEditMode: true,
                                  ),
                            ),
                          );
                        },

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // 세로축 중앙 정렬
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 40,
                              color: const Color.fromARGB(255, 44, 22, 122),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "생육조사",
                              style: TextStyle(
                                fontSize: 30,
                                color: const Color.fromARGB(255, 44, 22, 122),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            228,
                            173,
                            101,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {},

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // 세로축 중앙 정렬
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 40,
                              color: const Color.fromARGB(255, 44, 22, 122),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "수확조사",
                              style: TextStyle(
                                fontSize: 30,
                                color: const Color.fromARGB(255, 44, 22, 122),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            210,
                            240,
                            210,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (BuildContext context) =>
                                      CropPhotoScreen(selectedFarm: farm),
                            ),
                          );
                        },

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center, // 세로축 중앙 정렬
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: const Color.fromARGB(255, 44, 22, 122),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "조사사진 촬영",
                              style: TextStyle(
                                fontSize: 30,
                                color: const Color.fromARGB(255, 44, 22, 122),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                ],
              ),
    );
  }
}

/// 📌 로컬 데이터베이스 (농가명 저장 및 불러오기)
