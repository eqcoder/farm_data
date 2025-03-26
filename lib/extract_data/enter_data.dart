import 'package:farm_data/crop_config/crop_default.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'gemini.dart';
import 'clean_image.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'clean_image.dart';
import 'gemini.dart';
import '../crop_config/schema.dart';
import 'android_screen.dart';
import 'windows_screen.dart';

class EnterData {

  Uint8List? _editedImage;
  Crop? crop;

  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _cropNameController = TextEditingController();
  final TextEditingController _surveyDateController = TextEditingController();
  Future<void> _getImage(ImageSource source) async {
  final ImagePicker _picker = ImagePicker();
  final XFile? pickedFile = await _picker.pickImage(source: source);
  if (pickedFile != null) {
    _editedImage=(await pickedFile.readAsBytes());
  }

  
Future<Map<String, dynamic>> _extractImage() async {
  crop= await extractData(_editedImage!);
  if (crop!.cropName=="파프리카"){
    
  }
}
}
}

class EnterDataScreen extends StatefulWidget {
  const EnterDataScreen({super.key});

  @override
  State<EnterDataScreen> createState() => _EnterDataScreenState();
}

class _EnterDataScreenState extends State<EnterDataScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('야장추출'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child:
            Platform.isAndroid
                ? AndroidEnterDataLayout()
                : WindowsEnterDataLayout(),
      ),
    );
  }

  // CropDefault setCrop(Map<String, dynamic> data){
  //   if data["작물명"]=="토마토"
  // }
}



class WindowsEnterDataLayout extends StatefulWidget {
  @override
  _WindowsEnterWidgetState createState() => _WindowsEnterWidgetState();
}

class _WindowsEnterWidgetState extends State<WindowsEnterDataLayout> {
  Uint8List? _editedImage;
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _cropNameController = TextEditingController();
  final TextEditingController _surveyDateController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Row(
        children: [
          // 좌측 영역
          Expanded(
            flex: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _getImage(ImageSource.gallery);
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
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _getImage(ImageSource.camera);
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
                        _editedImage != null
                            ? Image.memory(_editedImage!, fit: BoxFit.fill)
                            : Center(child: Text('이미지를 로드하세요')),
                  ),
                ),
                const SizedBox(width: 16),
                // 야장추출 버튼
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          cleanImage(filePath)
                          // Map<String, dynamic> extractData(_editedImage!);
                          print('Text Button pressed!');
                          // 여기에 텍스트 버튼 클릭 시 수행할 동작을 작성합니다.
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // 내용물에 맞게 크기 조절
                          children: <Widget>[
                            Text('야장추출'),
                            SizedBox(width: 8), // 텍스트와 아이콘 사이 간격
                            Icon(Icons.arrow_downward),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 우측 영역
                Expanded(
                  flex: 15,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _farmNameController,
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
                          controller: _cropNameController,
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
                          controller: _surveyDateController,
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
                    child: const Center(child: Text('표 표시 영역')),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
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
