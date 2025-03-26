import 'dart:io';
import 'dart:typed_data';
import 'package:farm_data/provider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import '../gdrive/gdrive.dart';
import 'package:camera/camera.dart';
//import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database.dart';
import 'dart:convert';


class CropPhotoScreen extends StatefulWidget {
  final String selectedFarm;

  const CropPhotoScreen({super.key, required this.selectedFarm});
  @override
  _CropPhotoState createState() => _CropPhotoState();
}

class _CropPhotoState extends State<CropPhotoScreen> {

  List<String> farmNames=[];
  String? cropname;
  String? excelFilePath;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late List<CameraDescription> _cameras;
  late CameraDescription _camera;
  final List<String> imageTitles = [
    "재배전경",
    "1-1 개체생장점 사진",
    "1-1 개체 마디 진행상황",
    "pH",
    "백엽상 내부",
    "온습도",
    "1 개체 근권부 사진(좌)",
    "1개체 근권부 사진(우)",
    "특이사항",
  ]; // DB에서 불러올 값
  List<File?> _photos = List.generate(9, (_) => null);
Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _camera = _cameras.first; // 첫 번째 카메라 선택 (보통 뒤쪽 카메라)
    _controller = CameraController(
      _camera,
      ResolutionPreset.high,
    );

    await _controller.initialize();
    setState(() {});
  }
 @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  Future<void> getPhotos(String farmName) async {
    final db = await FarmDatabase.instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'farms',
      columns: ['survey_photos'],
      where: 'farm_name = ?',
      whereArgs: [farmName],
    );

    if (result.isNotEmpty && result.first['survey_photos'] != null) {
      final photos= List<String>.from(jsonDecode(result.first['survey_photos']));
      for(int index=0;index<imageTitles.length;index++){
        if (photos[index].isNotEmpty) {
        try {
          File file = File(photos[index]);
          if (await file.exists()) {
            _photos[index]=file;
          } else {
            print('Warning: Image file not found at path: $photos[index]');
          }
        } catch (e) {
          print('Error creating File object for path: $photos[index] - $e');
        }
      }
    }
  }

    // 에러 발생 시 빈 리스트를 반환하거나 에러 처리를 수행할 수 있습니다.
  }
  
  

  

  Future<void> _takePhoto(int index) async {
    try {
      final XFile image = await _controller.takePicture();
      setState(() {
        _photos[index]=File(image.path);
      });
      if (await _requestPermission()) {
        //final result = await ImageGallerySaver.saveFile(image.path);
        FarmDatabase.instance.updateSurveyPhotos(widget.selectedFarm, [image.path]);
        //print("갤러리 저장 결과: $result");
      }
      print("사진 촬영 완료: ${image.path}");
      // 사진 촬영 후 할 작업 추가 (예: 파일을 앱 내에서 사용하거나 서버로 업로드 등)
    } catch (e) {
      print("사진 찍기 오류: $e");
    }
      
    }
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  Widget _cameraPreview() {
    if (!_controller.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_controller);
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  // 이미지 선택 및 업로드 함수
  Future<void> uploadCropImage() async {
    // Googledrive 클래스의 uploadImage 호출
    await GoogleDrive.instance.uploadFileToGoogleDrive(_photos, "조사사진");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("이미지 업로드 완료!")));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("조사사진 업로드")),
      body: Column(
        children: [
Text("농가 : ${widget.selectedFarm}")
          ,
          Expanded(
          child: LayoutBuilder(
        builder: (context, constraints) {
          // 화면 크기에 맞춰서 그리드의 항목 수를 계산합니다.
          double width = constraints.maxWidth;
          double height = constraints.maxHeight;
          int crossAxisCount=3;
          // 그리드 항목의 크기 (예: 3x3 그리드)
          double itemSize = width / crossAxisCount;
          return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child:Expanded(child:Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Stack(
                      fit: StackFit.expand, // Stack이 부모의 크기를 채우도록 설정
                      children: [
                      _photos[index] != null
                          ? Image.file(
                            _photos[index]!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                          : Icon(Icons.image, size: 80, color: Colors.grey),
                          Center(
                            child:ElevatedButton(
                        onPressed:
                            () => _takePhoto(index), // 특정 index에 대한 사진 촬영
                        child: Icon(Icons.camera_alt),
                      ),
                          )]
                    ),

                      SizedBox(height: 10),

                      // 🔹 사진 파일명 or 기본 제목 표시
                      Text(
                        imageTitles[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),


                      // 📸 카메라 촬영 버튼
                      
                    ],
                  ),
                )));
              });
            })),
          
          SizedBox(height: 10),
          ElevatedButton(onPressed: uploadCropImage, child: Text("수정된 엑셀 업로드")),
        ],
      ),
    );
  }
}
