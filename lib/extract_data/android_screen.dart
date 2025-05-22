import 'package:farm_data/crop/crop.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'gemini.dart';
import 'clean_image.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'clean_image.dart';
import '../crop/schema.dart';
import '../crop/tomato.dart';
import '../crop/pepper.dart';
import 'gemini.dart';
import 'dart:convert';
import 'package:gallery_saver_plus/gallery_saver.dart';
import '../gdrive/gdrive.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../provider.dart' as provider;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/googleapis_auth.dart' as google_auth;
import 'package:googleapis/drive/v3.dart' as drive;

class AndroidEnterDataLayout extends StatefulWidget {
  _AndroidEnterDataWidgetState createState() => _AndroidEnterDataWidgetState();
}

class _AndroidEnterDataWidgetState extends State<AndroidEnterDataLayout> {
  File? selectedImage;
  List<Map<String, dynamic>>? _data;
  Uint8List? editedImage;
  Map<String, dynamic>? crop;
  bool isLoading = false;
  String? _spreadsheetId;
  final GoogleDriveClass gdrive = GoogleDriveClass.instance;

  final TextEditingController farmNameController = TextEditingController();
  final TextEditingController cropNameController = TextEditingController();
  final TextEditingController surveyDateController = TextEditingController();

  Future<void> getImage(ImageSource source) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> extractImage() async {
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
                Text("이미지에서 데이터를 추출하는 중입니다...", style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
    Uint8List img = await cleanImage(selectedImage!);
    Map<String, dynamic> _crop = await extractData(img);
    if (selectedImage != null) {
      setState(() {
        editedImage = img;
        crop = _crop;
        if (crop!["작물명"] == "파프리카") {
          _data = List<Map<String, dynamic>>.from(
            crop!["data"]["파프리카"]["생육조사"],
          );
        }
        farmNameController.text = crop!["농가명"];
        cropNameController.text = crop!["작물명"];
        surveyDateController.text = crop!["조사일"];
        isLoading = false;
      });
    }
    Navigator.of(context).pop();
  }

  Future<void> writeToExcel() async {
    final pythonScript = 'pepper.py'; // Python 스크립트 경로
    await Process.run('python', [
      pythonScript,
      json.encode(_data),
      "D:/Desktop/farm_data/25년_파프리카_강원_생육기본_김관섭_1작기.xlsm",
      farmNameController.text,
      crop!["지난_조사일"],
      surveyDateController.text,
    ]);
    // Python 스크립트를 실행하고, 데이터 전달

    // Python에서 반환된 결과
  }

  Future<void> checkExcelFile() async {
    final group =
        Provider.of<provider.SettingsProvider>(
          context,
          listen: false,
        ).selectedGroup;
    gdrive.signIn();
    if (gdrive.driveApi != null) {
      final driveApi = gdrive.driveApi!;
      final rootFolderId = await gdrive.createFolder("$group조", null);
      final dataFolderId = await gdrive.createFolder(
        "$group조_생육원본",
        rootFolderId,
      );
      final fileName =
          '25년_${cropNameController.text}_생육원본_${farmNameController.text}.xlsm';
      final fileResponse = await driveApi.files.list(
        q: "'$dataFolderId' in parents and name='$fileName' and mimeType='application/vnd.ms-excel.sheet.macroEnabled.12' and trashed=false",
      );

      if (fileResponse.files!.isEmpty) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('파일 없음'),
                content: Text(
                  '$fileName 파일이 $group조/$group조_생육원본에 존재하지 않습니다. 구글드라이브에 파일을 추가해주세요',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('확인'),
                  ),
                ],
              ),
        );
      } else {
        _spreadsheetId = fileResponse.files!.first.id;

        _writeDataToSheet();
      }
    }
  }

  Future<void> _writeDataToSheet() async {
    final sheetsApi = gdrive.sheetsApi;
    final data = [
      ['이름', '나이', '성별'],
      ['홍길동', '30', '남'],
      ['김철수', '25', '남'],
    ];

    await sheetsApi!.spreadsheets.values.append(
      sheets.ValueRange.fromJson({'values': data}),
      _spreadsheetId!,
      'A1',
      valueInputOption: 'USER_ENTERED',
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('데이터가 저장되었습니다')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          // 좌측 영역
          SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                SizedBox(width: 16),
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
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: () {
                    getImage(ImageSource.camera);
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
          SizedBox(height: 12),
          // 이미지를 띄우는 컨테이너
          Expanded(
            flex: 15,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child:
                  selectedImage != null
                      ? Image.file(selectedImage!, fit: BoxFit.fill)
                      : Center(child: Text('이미지를 로드하세요')),
            ),
          ),
          Spacer(flex: 1),
          // 야장추출 버튼
          ElevatedButton.icon(
            onPressed: () {
              if (selectedImage != null) {
                extractImage();
              } else {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        contentPadding: EdgeInsets.fromLTRB(0, 40, 0, 20),
                        content: Text(
                          '사진을 먼저 추가해주세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 25),
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('확인', textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                );
              }
              // Map<String, dynamic> extractData(_editedImage!);
              // 여기에 텍스트 버튼 클릭 시 수행할 동작을 작성합니다.
            },
            icon: Icon(Icons.download_rounded, color: Colors.white, size: 20),
            label: Text(
              '데이터 추출',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 101, 107, 189),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              elevation: 6,
            ),
          ),
          Spacer(flex: 1),
          // 우측 영역
          Expanded(
            flex: 2,
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
          Spacer(flex: 1),
          // 표를 띄우는 컨테이너
          Expanded(
            flex: 15,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child:
                  _data != null
                      ? PepperWidget(data: _data!)
                      : Center(child: Text("야장추출 버튼을 클릭하세요")),
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    checkExcelFile();
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
                SizedBox(width: 16),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
