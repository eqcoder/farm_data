import 'dart:io';
import 'package:farm_data/appbar.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../gdrive/gdrive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider.dart' as provider;
import 'package:saver_gallery/saver_gallery.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../farm/schema.dart';
import '../utils/logger.dart';

class CropPhotoScreen extends StatefulWidget {
  final Farm selectedFarm;

  const CropPhotoScreen({super.key, required this.selectedFarm});
  @override
  State<CropPhotoScreen> createState() => _CropPhotoState();
}

class _CropPhotoState extends State<CropPhotoScreen> {
  bool _isLoading = true;
  String today = DateFormat('yyyyMMdd').format(DateTime.now());
  late Farm selectedFarm;
  late List<dynamic> photosURLs;
  late List<File?> _photos;
  late DocumentReference<Map<String, dynamic>> farmRef;
  late List<String> imageTitles;
  late int imageNum;
  String city = "";
  String name = "";
  String id = "";
  String crop = "";
  @override
  void initState() {
    super.initState();
    selectedFarm = widget.selectedFarm;
    name = selectedFarm.name;
    id = selectedFarm.id;
    crop = selectedFarm.crop.name;
    city = selectedFarm.city;
    imageTitles = selectedFarm.crop.imageTitles;
    imageNum = imageTitles.length;

    farmRef = FirebaseFirestore.instance.collection('farms').doc(id);

    _initAsync();
  }

  Future<void> _initAsync() async {
    final farmDoc = await farmRef.get();
    setState(() {
      photosURLs = (farmDoc.data()?['photosURLs'] ?? []).toList();
    });
    final photos = await getPhotos();
    setState(() {
      _photos = photos;
    });
  }

  Future<List<File?>> getPhotos() async {
    final List<File?> files = [];
    final cacheManager = DefaultCacheManager();

    for (String url in photosURLs) {
      try {
        // 1. 캐시에서 파일 확인
        final cachedFile = await cacheManager.getFileFromCache(url);

        if (cachedFile != null) {
          // 캐시된 파일이 있으면 사용
          files.add(cachedFile.file);
        } else {
          // 2. 캐시 없으면 다운로드 및 캐시 저장
          final file = await cacheManager.getSingleFile(url);
          files.add(file);
        }
      } catch (e) {
        // 에러 발생 시 null 추가
        files.add(null);
      }
    }

    setState(() {
      _isLoading = false; // 초기화 완료 후 로딩 상태 변경
    });
    return files;
  }

  Future<File?> _compressImage(File file) async {
    final targetPath =
        "${file.parent.path}/compressed_${file.uri.pathSegments.last}";

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

  Future<void> uploadFarmImage({
    required File imageFile,
    required int index,
  }) async {
    try {
      // 1. Storage에 업로드할 경로 지정
      final String fileName =
          '${today}_${city}_${crop}_${name}_${imageTitles[index]}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(
        'farms/$name/$fileName',
      );

      // 2. 파일 업로드 (contentType 지정 권장)
      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // 3. 업로드된 파일의 다운로드 URL 가져오기
      final photoUrl = await storageRef.getDownloadURL();

      // 4. Firestore에 이미지 URL 저장 (예시: farms 컬렉션의 farmId 문서에 배열로 추가)

      photosURLs[index] = photoUrl;
      await farmRef.update({'photosURLs': photosURLs});
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> _takePhoto(int index) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );

    // 이미지 압축

    if (pickedFile != null) {
      File? originalImage = File(pickedFile!.path);
      File? compressedImage = await _compressImage(originalImage);
      setState(() {
        _photos[index] = File(compressedImage!.path);
      });
    }
    // 갤러리 기본 경로 가져오기
    Directory? externalStorageDirectory = await getExternalStorageDirectory();
    if (externalStorageDirectory == null) {
      logger.e("외부 저장소 경로를 찾을 수 없습니다.");
      return;
    }

    // "3조" 폴더 생성 또는 가져오기d

    if (_photos[index] != null) {
      final saveFolder = Directory(
        '${externalStorageDirectory.path}/${today}_${city}_${crop}_$name',
      );
      if (!saveFolder.existsSync()) {
        saveFolder.createSync();
      }
      final imagePath = File(
        '${saveFolder.path}/${today}_${imageTitles[index]}',
      );
      imagePath.writeAsBytesSync(_photos[index]!.readAsBytesSync());
      final result = await SaverGallery.saveImage(
        _photos[index]!.readAsBytesSync(),
        quality: 97, // 이미지 품질 (JPEG만 해당)
        fileName:
            '${today}_${city}_${crop}_${name}_${imageTitles[index]}.jpg', // 파일 이름
        androidRelativePath:
            "Pictures/${today}_${city}_${widget.selectedFarm}/", // 갤러리 내 폴더 경로
        skipIfExists: false,
      );
      uploadFarmImage(imageFile: _photos[index]!, index: index);
    }
  }

  Future<void> uploadToGoogleDrive(BuildContext context) async {
    try {
      // 1. Google 로그인
      final GoogleDriveClass gdrive = GoogleDriveClass.instance;
      await gdrive.signIn();
      if (gdrive.driveApi == null) {
        Exception('Google Drive API에 로그인하지 못했습니다.');
        return;
      }
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
                  Text("파일을 업로드 하는 중입니다", style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        },
      );
      // 3. 오늘 날짜 폴더 생성
      final group =
          Provider.of<provider.SettingsProvider>(
            context,
            listen: false,
          ).selectedGroup;
      final rootFolderId = await gdrive.createFolder("$group조", null);
      final imageFolderId = await gdrive.createFolder(
        "$group조_생육사진",
        rootFolderId,
      );
      final farmImageFolderId = await gdrive.createFolder(
        "${today}_${city}_${crop}_${name}",
        imageFolderId,
      );

      // 4. 사진 업로드
      for (var i = 0; i < _photos.length; i++) {
        if (_photos[i] != null) {
          gdrive.uploadPhotoToDrive(
            folderId: farmImageFolderId,
            fileName: '${today}_${city}_${crop}_${name}_${imageTitles[i]}',
            imageFile: _photos[i]!,
          );
        }
      }

      logger.i('성공적으로 업로드되었습니다!');
    } catch (e) {
      logger.e(e);
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('파일 업로드가 완료되었습니다!')));
  }

  Future<void> _deleteImages() async {
    final storage = FirebaseStorage.instance;
    final List<Future<void>> deleteFutures = [];

    for (final url in photosURLs) {
      try {
        final ref = storage.refFromURL(url);
        deleteFutures.add(ref.delete());
      } catch (e) {
        print('$url 삭제 실패: $e');
      }
    }
    await Future.wait(deleteFutures);
    await farmRef.update({'photosURLs': []});
    setState(() {
      _photos = List.generate(imageNum, (_) => null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "조사사진 촬영"),
      body:
          _isLoading
              ? Column(
                mainAxisAlignment: MainAxisAlignment.center, // 세로축 중앙 정렬
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(child: CircularProgressIndicator()),
                  Text("지난 데이터를 불러오는 중입니다.."),
                ],
              )
              : Column(
                children: [
                  Spacer(flex: 1),
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
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoItem("농가명", name),
                        _buildInfoItem("지역", city),
                        _buildInfoItem("작물", crop),
                      ],
                    ),
                  ),
                  Spacer(flex: 1),
                  Expanded(
                    flex: 20,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // 3개의 열
                        crossAxisSpacing: 10, // 열 간격
                        mainAxisSpacing: 0, // 행
                        childAspectRatio: 0.6,
                      ),
                      itemCount: imageNum,
                      itemBuilder: (context, index) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Stack(
                                alignment:
                                    Alignment.center, // Stack이 부모의 크기를 채우도록 설정
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    height:
                                        MediaQuery.of(context).size.height / 3 +
                                        50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300], // 기본 배경색
                                      borderRadius: BorderRadius.circular(10),
                                      image:
                                          _photos[index] != null
                                              ? DecorationImage(
                                                image: FileImage(
                                                  _photos[index]!,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                              : null,
                                    ),
                                  ),
                                  Positioned(
                                    child: IconButton(
                                      iconSize: 40,
                                      icon: Icon(
                                        Icons.camera_alt,
                                        color: const Color.fromARGB(
                                          255,
                                          218,
                                          105,
                                          129,
                                        ),
                                      ),
                                      onPressed: () {
                                        _takePhoto(index);
                                      }, // 사진 선택 함수 호출
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: // 🔹 사진 파일명 or 기본 제목 표시
                                  Text(
                                imageTitles[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  wordSpacing: -0.5,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Spacer(flex: 1),
                        Expanded(
                          flex: 5,
                          child: ElevatedButton(
                            onPressed: () {
                              _deleteImages();
                            },
                            child: Text("모두지우기"),
                          ),
                        ),
                        Spacer(flex: 1),

                        Expanded(
                          flex: 5,
                          child: ElevatedButton(
                            onPressed: () {
                              uploadToGoogleDrive(context);
                            },
                            child: Text("드라이브에 올리기"),
                          ),
                        ),
                        Spacer(flex: 1),
                      ],
                    ),
                  ),
                  Spacer(flex: 1),
                ],
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
