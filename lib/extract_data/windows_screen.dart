import 'package:camera/camera.dart';
import 'package:farm_data/crop_config/crop_default.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'gemini.dart';
import 'clean_image.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import '../crop_config/schema.dart';
import '../crop_config/tomato.dart';
import '../crop_config/pepper.dart';
import 'enter_data.dart';
import '../gdrive/gdrive.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:camera_windows/camera_windows.dart';
import '../camera/camera.dart';
import 'dart:convert';
import 'dart:collection';
class WindowsEnterDataLayout extends StatefulWidget {

  _WindowsEnterDataWidgetState createState() => _WindowsEnterDataWidgetState();
}

class _WindowsEnterDataWidgetState extends State<WindowsEnterDataLayout> {
  BackUpRepository backUpRepository = BackUpRepository.instance;
  File? selectedImage;
  Uint8List? editedImage;
  bool isLoading = false;

  Map<String, dynamic>? crop;
  List<Map<String, dynamic>>? _data;
  final TextEditingController farmNameController = TextEditingController();
  final TextEditingController cropNameController = TextEditingController();
  final TextEditingController surveyDateController = TextEditingController();
  
  Future<void> getImage(ImageSource source) async {
  final ImagePicker _picker = ImagePicker();
  final XFile? pickedFile = await _picker.pickImage(source: source);
  if (pickedFile != null) {
    setState(() {
      selectedImage=File(pickedFile.path);
    });
  }
  }

 CameraController? _controller;
  bool _isCameraInitialized = false;

  // 카메라 초기화
  Future<void> _initializeCamera() async {
    try {
      if (_controller != null) {
        print(_controller);
        await _controller!.dispose();
      }
      final camera = await CameraWindows().availableCameras();
      // 카메라 장치 검색 및 초기화
      print("camera:   $camera");
      _controller = CameraController(camera[0], ResolutionPreset.high);
      
      // 카메라 초기화
      await _controller!.initialize();
      CameraPreview(_controller!);
      setState(() {

        _isCameraInitialized = true; // 카메라가 초기화되면 상태 변경
      });
    } catch (e) {
      print('카메라 초기화 실패: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller!.dispose(); // 카메라 컨트롤러 리소스 해제
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('카메라가 초기화되지 않았습니다.');
      return;
    }
    try {

      // 사진 찍기
      XFile photo =await _controller!.takePicture();

      setState(() {
        selectedImage=File(photo.path);
      });

    } catch (e) {
      print('사진 찍기 실패: $e');
    }
  }

  
Future<void> extractImage(BuildContext context) async {

  setState(() {
      isLoading = true;
    });
  Uint8List img=await cleanImage(selectedImage!);
  Map<String, dynamic> _crop=await extractData(img);
  if (selectedImage!=null){
    setState(() {
      editedImage=img;
      crop= _crop;
      if (crop!["작물명"]=="파프리카"){
        _data= List<Map<String, dynamic>>.from(crop!["data"]["파프리카"]["생육조사"]);
      }
      farmNameController.text=crop!["농가명"];
      cropNameController.text=crop!["작물명"];
      surveyDateController.text=crop!["조사일"];
      isLoading=false;
    });

  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("작업 완료!")),
    );
  }
}

Future<void> writeToExcel() async{
  print(_data);
  final pythonScript = 'pepper.py'; // Python 스크립트 경로
  await Process.run('python', [pythonScript, json.encode(_data),"D:/Desktop/farm_data/25년_파프리카_강원_생육기본_김관섭_1작기.xlsm", farmNameController.text, crop!["지난_조사일"],surveyDateController.text]);
    // Python 스크립트를 실행하고, 데이터 전달
    

    // Python에서 반환된 결과

}


@override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(1.0),
    child: Row(
      children: [
        // 좌측 영역
        Expanded(
          flex: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        getImage(ImageSource.gallery);
                      },
                      icon: const Icon(Icons.photo),
                      label: const Text('사진 선택'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(width:16),
                    ElevatedButton.icon(
                      onPressed: () {
                        _initializeCamera();
                        selectedImage=null;
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('사진 촬영'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
    
                  ],
                ),
              ),
              // 이미지를 띄우는 컨테이너
              Expanded(
                flex: 7,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child:
                      selectedImage!= null
                          ? Image.file(selectedImage!, fit: BoxFit.fill)
                          : _isCameraInitialized? AspectRatio(aspectRatio: _controller!.value.aspectRatio,
                    child: Stack(children:[CameraPreview(_controller!),Align(
              alignment: Alignment.center,
              child: IconButton(
                icon: Icon(
                  Icons.camera_alt,
                  size: 50,
                  color: Colors.white,
                ),
                onPressed: _takePicture,
              ),
                  )]))
                :Center(child: Text('이미지를 로드하세요')),
                ),
              ),
              Expanded(flex: 2, child: SizedBox()),
            ],
          ),
        ),
        // 야장추출 버튼
        Expanded(
          flex: 1,
          child: TextButton(
            onPressed: () {
              if(selectedImage !=null){
              extractImage(context);}
              // Map<String, dynamic> extractData(_editedImage!);
              print('Text Button pressed!');
              // 여기에 텍스트 버튼 클릭 시 수행할 동작을 작성합니다.
            },
            child: Column(
              mainAxisSize: MainAxisSize.min, // 내용물에 맞게 크기 조절
              children: <Widget>[
                Center(child:Text('야장추출')),
                SizedBox(height:10), // 텍스트와 아이콘 사이 간격
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ),
        // 우측 영역
        Expanded(
          flex: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: farmNameController,
                        decoration: const InputDecoration(
                          labelText: '농가명',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: cropNameController,
                        decoration: const InputDecoration(
                          labelText: '작물명',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: surveyDateController,
                        decoration: const InputDecoration(
                          labelText: '조사일',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 표를 띄우는 컨테이너
              
              Expanded(
                flex: 7,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: _data!=null
                  ?PepperWidget(data: _data!)
                  :isLoading?
                  Center(child:Column(mainAxisAlignment: MainAxisAlignment.center,
              children:[CircularProgressIndicator(),
              SizedBox(height:10), Text("이미지를 추출하는 중...")]))
                  :Center(child:Text("야장추출 버튼을 클릭하세요"))
                )),
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        writeToExcel();
                        print('엑셀에 입력하기 클릭');
                      },
                      child: const Text('엑셀에 입력하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        print('드라이브에 업로드하기 클릭');
                        backUpRepository.signIn();
                      },
                      child: const Text('드라이브에 업로드하기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}