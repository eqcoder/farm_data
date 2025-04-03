import 'dart:io';
import 'dart:typed_data';
import 'package:farm_data/provider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import '../gdrive/gdrive.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database.dart';
import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';


final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/drive.file',
  ],
);

class CropPhotoScreen extends StatefulWidget {
  final String selectedFarm;
  

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
    final db = await farm.database;
    final maps = await db.query(
    'farms',
    where: 'name = ?',
    whereArgs: [widget.selectedFarm],
  );
  if(maps.first['survey_photos']!=null){
    List<String?> fileList=List<String?>.from(jsonDecode(maps.first['survey_photos'] as String));
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
  Future<void> _takePhoto(int index) async {
  final ImagePicker _picker = ImagePicker();
  final XFile? pickedFile = await _picker.pickImage(source:ImageSource.camera);
  if (pickedFile != null) {
    setState(() {
      _photos[index]=File(pickedFile.path);
    });
  }
  if (_photos[index] != null) {
      await ImageGallerySaver.saveImage(_photos[index]!.readAsBytesSync(), name:'${today}_${imageTitles[index]}');
  farm.updateSurveyPhotos(widget.selectedFarm, _photos.map((file){return  file?.path;}).toList());
  }
  }
  
  Future<String> createTodayFolder(drive.DriveApi driveApi) async {
    final today = DateFormat('yyyyMMdd').format(DateTime.now()); // YYYY-MM-DD
    final query = "mimeType = 'application/vnd.google-apps.folder' and name = '$today'";
    final fileList = await driveApi.files.list(q: query, spaces: 'drive');
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      final folderId = fileList.files!.first.id;
      if (folderId != null) {
        return folderId; // ID
    }
    else {
        throw Exception('폴더 ID가 null입니다.');
      }
    }
  
  final folder = drive.File()
    ..name = today
    ..mimeType = 'application/vnd.google-apps.folder';

  final response = await driveApi.files.create(folder);
  if (response.id!=null){
  return response.id!;}
  else {
        throw Exception('폴더 ID가 null입니다.');
      }
  }
  

  // 이미지 선택 및 업로드 함수
  Future<void> uploadPhotoToDrive({
  required drive.DriveApi driveApi,
  required String folderId,
  required String fileName,
  required File imageFile,
}) async {
  final existingFiles = await driveApi.files.list(
      q: "'$folderId' in parents and name='$fileName'",
    );

    if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
      // 기존 파일 삭제 (덮어쓰기)
      for (var file in existingFiles.files!) {
        await driveApi.files.delete(file.id!);
      }
    }
  final file = drive.File()
    ..name = fileName
    ..parents = [folderId];

  final media = drive.Media(
    imageFile.openRead(),
    imageFile.lengthSync(),
  );

  await driveApi.files.create(
    file,
    uploadMedia: media,
  );
}
Future<void> uploadToGoogleDrive(BuildContext context) async {
  try {
    // 1. Google 로그인
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
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
    final folderId = await createTodayFolder(driveApi);

    // 4. 사진 업로드
    for(var i=0;i<_photos.length;i++){
      if(_photos[i]!=null){
        
        uploadPhotoToDrive(driveApi: driveApi, folderId: folderId, fileName: '${today}_${imageTitles[i]}', imageFile: _photos[i]!);
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
      appBar: AppBar(title: Text("조사사진 업로드")),
      body: _isLoading?Column(mainAxisAlignment: MainAxisAlignment.center, // 세로축 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.center,children:[Center(
        child: CircularProgressIndicator()), Text("지난 데이터를 불러오는 중입니다..")]):Column(
        children: [
          Spacer(flex:1),
Expanded(flex:1, child:Text("농가 : ${widget.selectedFarm}", style:TextStyle(fontSize:24)))
          ,
          Expanded(
            flex:20,
          child:GridView.builder(
            shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3개의 열
        crossAxisSpacing: 10, // 열 간격
        mainAxisSpacing: 50, // 행 
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
          height: MediaQuery.of(context).size.width /3+200,
          decoration: BoxDecoration(
            color: Colors.grey[300], // 기본 배경색
            borderRadius: BorderRadius.circular(16),
                    image:  _photos[index] != null
                          ? DecorationImage(
                    image: FileImage(_photos[index]!),
                    fit: BoxFit.cover,
                          ):null,
                          ),
                child: _photos[index] == null
              ? Icon(Icons.image, size: 50, color: Colors.grey[700]) // 기본 아이콘
              : null,
        ),Positioned(
          child: IconButton(
            iconSize: 50,
            icon: Icon(Icons.camera_alt, color: Colors.white),
            onPressed:(){_takePhoto(index);}, // 사진 선택 함수 호출
          ),
        ),
                    ])),
                      Expanded(flex:1,child:// 🔹 사진 파일명 or 기본 제목 표시
                      Text(
                        imageTitles[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),)
        ]);
              })),Expanded(flex:1, child:Row(children: [
                Spacer(flex:1),
              Expanded(flex:5, child:ElevatedButton(onPressed: (){_deleteImages();
          }, child: Text("모두지우기")),),Spacer(flex:1),
          Expanded(flex:5, child:ElevatedButton(onPressed: (){uploadToGoogleDrive(context);
          }, child: Text("저장하기")),),Spacer(flex:1),
          Expanded(flex:5, child:ElevatedButton(onPressed: (){uploadToGoogleDrive(context);
          }, child: Text("드라이브에 올리기")),),Spacer(flex:1)])),
        Spacer(flex:1)],
      ),
    );
  }
}
