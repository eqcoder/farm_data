import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:camera_windows/camera_windows.dart';
class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // 카메라 초기화
  Future<void> _initializeCamera() async {
    try {
      // 기존 카메라가 있다면 해제
      if (_controller != null) {
        await _controller!.dispose();
      }

      // CameraDescription 객체를 통해 카메라 초기화
      final List<CameraDescription> camera = await CameraWindows().availableCameras();

      if (camera.isNotEmpty) {
        // 첫 번째 카메라 장치 선택
        _controller = CameraController(camera[0], ResolutionPreset.high);

        // 카메라 초기화
        await _controller!.initialize();

        // 초기화가 완료되면 화면에 표시
        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        print('사용 가능한 카메라가 없습니다.');
      }
    } catch (e) {
      print('카메라 초기화 실패: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose(); // 카메라 컨트롤러 리소스 해제
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Windows 카메라")),
      body: Center(
        child: _isCameraInitialized
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,  // 카메라 화면 비율에 맞추기
                child: CameraPreview(_controller!), // 카메라 스트리밍을 화면에 표시
              )
            : CircularProgressIndicator(), // 카메라 초기화 중 로딩 표시
      ),
    );
  }
}