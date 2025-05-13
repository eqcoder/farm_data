import 'dart:io';
import 'dart:typed_data';
import 'package:farm_data/appbar.dart';
import 'package:farm_data/provider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import '../gdrive/gdrive.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../database/database.dart';
import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:provider/provider.dart';
import '../provider.dart' as provider;
import 'package:saver_gallery/saver_gallery.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';




class CropPhotoScreen extends StatefulWidget {
  final Farm selectedFarm;
  

  const CropPhotoScreen({super.key, required this.selectedFarm});
  @override
  _CropPhotoState createState() => _CropPhotoState();
}

class _CropPhotoState extends State<CropPhotoScreen> {
  bool _isLoading = true; 
  String today=DateFormat('yyyyMMdd').format(DateTime.now());
  List<String> farmNames=[];
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late List<CameraDescription> _cameras;
  late CameraDescription _camera;
  late FarmDatabase farm;
  late Database db;
  late String crop;
  late String city;
  late String name;
  
  
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
 @override
  void initState() {
    super.initState();
    farm=FarmDatabase.instance;
    getPhotos();

  }
  
  Future<void> getPhotos() async {
    db = await farm.database;
    List<Map<String, dynamic>> tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
  
  for (var table in tables) {
    String tableName = table['name'];
    print('테이블 이름: $tableName');
    List<Map<String, dynamic>> rows = await db.query(tableName);
    print('테이블 $tableName 내용: $rows');
  }
  name=widget.selectedFarm.name.toString();
  crop=widget.selectedFarm.crop.toString();
  city=widget.selectedFarm.city.toString();
  if(widget.selectedFarm.survey_photos!=null){
    List<String?> fileList=List<String?>.from(jsonDecode(widget.selectedFarm.survey_photos as String));
    setState(() {
      
    _photos=fileList.map((path) {
    return path != null ? File(path) : null; // null이면 그대로 유지, 아니면 File 객체 생성
  }).toList();
   }); // 에러 발생 시 빈 리스트를 반환하거나 에러 처리를 수행할 수 있습니다.
  }
  setState(() {
      _isLoading = false; // 초기화 완료 후 로딩 상태 변경
    });
  }
  Future<File?> _compressImage(File file) async {
  final targetPath = "${file.parent.path}/compressed_${file.uri.pathSegments.last}";

  // flutter_image_compress를 사용한 압축
  XFile? result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    targetPath,
    quality: 97, // 품질 설정 (0-100)
    minWidth: 720, // 최소 너비 설정
    minHeight: 1080, // 최소 높이 설정
  );

  if (result != null) {
    return File(result.path); // XFile을 File로 변환하여 반환
  }
  return null; // 압축 실패 시 null 반환
}

  Future<void> _takePhoto(int index) async {
  final ImagePicker _picker = ImagePicker();
  final XFile? pickedFile = await _picker.pickImage(source:ImageSource.camera);
  

      // 이미지 압축
      
  if (pickedFile != null) {
    File? originalImage = File(pickedFile!.path);
    File? compressedImage = await _compressImage(originalImage);
    setState(() {
      
      _photos[index]=File(compressedImage!.path);
    });
  }
    // 갤러리 기본 경로 가져오기
    Directory? externalStorageDirectory = await getExternalStorageDirectory();
    if (externalStorageDirectory == null) {
      print("외부 저장소 경로를 찾을 수 없습니다.");
      return;
    }


    // "3조" 폴더 생성 또는 가져오기
    

  if (_photos[index] != null) {
    final saveFolder = Directory('${externalStorageDirectory.path}/${today}_${city}_${crop}_${widget.selectedFarm}');
    if (!saveFolder.existsSync()) {
      saveFolder.createSync();
      print('"3조" 폴더가 생성되었습니다.');
    }
    final imagePath = File('${saveFolder.path}/${today}_${imageTitles[index]}');
    imagePath.writeAsBytesSync(_photos[index]!.readAsBytesSync());
        final result = await SaverGallery.saveImage(
          _photos[index]!.readAsBytesSync(),
          quality: 97, // 이미지 품질 (JPEG만 해당)
          fileName: '${today}_${city}_${crop}_${widget.selectedFarm}_${imageTitles[index]}.jpg', // 파일 이름
          androidRelativePath: "Pictures/${today}_${city}_${widget.selectedFarm}/", // 갤러리 내 폴더 경로
          skipIfExists: false
        );
  farm.updateSurveyPhotos(widget.selectedFarm.id!, _photos.map((file){return  file?.path;}).toList());
  }
  }
  

  


Future<void> uploadToGoogleDrive(BuildContext context) async {
  try {
    // 1. Google 로그인
    final GoogleDriveClass gdrive=GoogleDriveClass.instance;
    final GoogleSignInAccount? account = await gdrive.googleSignIn.signIn();
    
    if (account == null) return;

    // 2. Drive API 클라이언트 생성
    final authHeaders = await account.authHeaders;
    final client = GoogleAuthClient(header:authHeaders);
    final driveApi = drive.DriveApi(client);
    showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 외부 클릭 방지
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(), // 로딩 인디케이터
                SizedBox(height: 16),
                Text(
                  "파일을 업로드 하는 중입니다",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
    // 3. 오늘 날짜 폴더 생성
    final group = Provider.of<provider.SettingsProvider>(context, listen: false).selectedGroup;
    final rootFolderId = await gdrive.createFolder(driveApi, "$group조", null);
    final imageFolderId = await gdrive.createFolder(driveApi, "$group조_생육사진", rootFolderId);
    final farmImageFolderId = await gdrive.createFolder(driveApi, "${today}_${city}_${crop}_${widget.selectedFarm}", imageFolderId);

    // 4. 사진 업로드
    for(var i=0;i<_photos.length;i++){
      if(_photos[i]!=null){
        
        gdrive.uploadPhotoToDrive(driveApi: driveApi, folderId: farmImageFolderId, fileName: '${today}_${city}_${crop}_${widget.selectedFarm}_${imageTitles[i]}', imageFile: _photos[i]!);
      }
    }

    print('성공적으로 업로드되었습니다!');
  } catch (e) {
    print('오류 발생: $e');
  }
  Navigator.of(context).pop();
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('파일 업로드가 완료되었습니다!')),
    );
}

_deleteImages(){
  setState(() {
    _photos=List.generate(9, (_) => null);
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "조사사진 촬영"),
      body: _isLoading?Column(mainAxisAlignment: MainAxisAlignment.center, // 세로축 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.center,children:[Center(
        child: CircularProgressIndicator()), Text("지난 데이터를 불러오는 중입니다..")])
        :Column(
        children: [
          Spacer(flex:1),
Container(
  margin: EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),child:Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem("농가명", name),
                _buildInfoItem("지역", city),
                _buildInfoItem("작물", crop),
              ],
            ),),
          Spacer(flex:1),
          Expanded(
            flex:20,
          child:GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3개의 열
        crossAxisSpacing: 10, // 열 간격
        mainAxisSpacing: 0, // 행 
        childAspectRatio: 0.6,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                
                return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Expanded(flex:5, child:Stack(
                      alignment: Alignment.center,  // Stack이 부모의 크기를 채우도록 설정
                      children: [
                        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height /3+50,
          decoration: BoxDecoration(
            color: Colors.grey[300], // 기본 배경색
            borderRadius: BorderRadius.circular(10),
                    image:  _photos[index] != null
                          ? DecorationImage(
                    image: FileImage(_photos[index]!),
                    fit: BoxFit.cover,
                          ):null,
                          ),
                
        ),Positioned(
          child: IconButton(
            iconSize: 40,
            icon: Icon(Icons.camera_alt, color: const Color.fromARGB(255, 218, 105, 129)),
            onPressed:(){_takePhoto(index);}, // 사진 선택 함수 호출
          ),
        ),
                    ])),
                      Expanded(flex:1,child:// 🔹 사진 파일명 or 기본 제목 표시
                      Text(
                        imageTitles[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          wordSpacing: -0.5,
                          letterSpacing: -0.5
                        ),
                        textAlign: TextAlign.center,
                      ),)
        ]);
              })),Expanded(flex:1, child:Row(children: [
                Spacer(flex:1),
              Expanded(flex:5, child:ElevatedButton(onPressed: (){_deleteImages();
          }, child: Text("모두지우기")),),Spacer(flex:1),
          
          Expanded(flex:5, child:ElevatedButton(onPressed: (){uploadToGoogleDrive(context);
          }, child: Text("드라이브에 올리기")),),Spacer(flex:1)])),
        Spacer(flex:1)],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
