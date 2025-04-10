import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database.dart'; // FarmDatabase 정의 필요
import 'package:intl/intl.dart';

class Opinet extends StatefulWidget {
  @override
  _OpinetState createState() => _OpinetState();
}

class _OpinetState extends State<Opinet> {
  late InAppWebViewController _opinetController;
  late InAppWebViewController _mapController;
  List<Uint8List?> _capturedMap=List.generate(3, (_) => null);
  DateTime? _selectedDate;
  int _selectedDuration = 0;
  List<String> farmNames = List.filled(3, '');
  String _mapUrl = 'https://map.naver.com/p/directions/-/-/-/car';
  String _opinetUrl = 'https://www.opinet.co.kr/user/dopospdrg/dopOsPdrgAreaSelect.do#';

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    final FarmDatabase db = await FarmDatabase.instance;
    final names = await db.getFarmNames();
    setState(() {
      farmNames = names;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex:1, child:
            _buildDatePicker()),
            Expanded(flex:1, child:
            _buildDurationButtons()),
            Expanded(flex:1, child:
            _buildFarmSelection()),
            Expanded(flex:20, child:
            _buildTripDays()),
          ],
        );
  }

  Widget _buildDatePicker() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: '출발일 선택',
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      controller: TextEditingController(
        text: _selectedDate != null 
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!) 
            : '',
      ),
    );
  }

  Widget _buildDurationButtons() {
    const List<String> durations = ['당일', '1박2일', '2박3일'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: durations.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedDuration == index 
                ? Colors.blue 
                : Colors.grey,
          ),
          onPressed: () => setState(() => _selectedDuration = index),
          child: Text(label),
        );
      }).toList(),
    );
  }

  Widget _buildTripDays() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_selectedDuration + 1, (index) {
        return Expanded(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text('Day ${index + 1}', style: const TextStyle(fontSize: 20)),
              _captureMap(index),
              const SizedBox(height: 10),
              _buildOpinetWebView(),
            ],
          ),
        );
      }),
    );
  }

  Widget _captureMap(int index) {

    void _openCaptureDialog() async {
      late final screenshot;
  final capturedImage = await showDialog<Uint8List>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFarmSelection(), // 기존 FarmSelection 위젯 재사용
          const SizedBox(height: 20),
          _buildMapWebView(),
          const SizedBox(height: 20),
          ElevatedButton.icon(
      icon: const Icon(Icons.camera),
      label: const Text('캡처'),
      onPressed: ()async{
        screenshot = await _mapController.takeScreenshot();
      }),
      ElevatedButton(
          onPressed: () => Navigator.pop(context,screenshot),
          child: const Text('이미지 적용'),
        ),
        ],
      ),
    ),
  ));

  if (capturedImage != null) {
    setState(() => _capturedMap[index] = capturedImage);
  }
}
    return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Expanded(child:Stack(
                      alignment: Alignment.center,  // Stack이 부모의 크기를 채우도록 설정
                      children: [
                        Container(
          child:
          _capturedMap[index]!=null?
                          Image.memory(_capturedMap[index]!) // Uint8List를 이미지로 변환
                          :null
                          ),
                
        Positioned(
          child: IconButton(
            iconSize: 40,
            icon: Icon(Icons.camera_alt, color: const Color.fromARGB(255, 9, 109, 39)),
            onPressed:(){_openCaptureDialog();}, // 사진 선택 함수 호출
          ),
        ),
                    ])),
                    SizedBox(height:5),
                      Expanded(flex:1,child:// 🔹 사진 파일명 or 기본 제목 표시
                      Text(
                        "지도",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),)
        ]);
  }
  

  Widget _buildFarmSelection() {
    return Column(
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: _updateMapWithAgriculturalCenter,
              child: const Text('강원도 농업기술원'),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: farmNames.map((farm) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Chip(label: Text(farm)),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapWebView() {
    return SizedBox(
      height: 600,
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_mapUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: true,
          mediaPlaybackRequiresUserGesture: false,
          useOnDownloadStart: true,
          useOnLoadResource: true,
        ),
        onUpdateVisitedHistory: (controller, url, isReload) {
          setState(() => _mapUrl = url.toString());
        },
        onCreateWindow: (controller, createWindowAction) async {
    if (createWindowAction.request != null) {
      final url = createWindowAction.request!.url.toString();
      controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
    return true; // 팝업 생성 처리 완료
  },
      ),
    );
  }

  Widget _buildOpinetWebView() {
    return SizedBox(
      height: 600,
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_opinetUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: true,
        ),
        onUpdateVisitedHistory: (controller, url, isReload) {
          setState(() => _mapUrl = url.toString());
        },
        onWebViewCreated: (controller) {
          _opinetController = controller;
        },
        onCreateWindow: (controller, createWindowAction) async {
    if (createWindowAction.request != null) {
      final url = createWindowAction.request!.url.toString();
      controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
    return false; // 팝업 생성 처리 완료
  },
  onLoadStop: (controller, url) async {
    
  await _autoFillForm();
  await controller.evaluateJavascript(source: '''
      (function() {
        const btn = document.getElementById("btn_Print");
        if (btn) {
          btn.addEventListener("click", function(e) {
            e.preventDefault();

            // 유효성 검사
            if (typeof validate === "function" && !validate()) return;
            if (typeof fn_validate === "function" && !fn_validate()) return;

            // NetFunnel 무시하고 form submit만 하도록
            const form = document.getElementById("search_form");
            if (form) {
              form.setAttribute("target", "_self");
              form.setAttribute("action", "/user/dopospdrg/dopOsPdrgAreaPrint.do");

              const chkgu = document.getElementById("chkgu");
              if (chkgu) chkgu.value = "N";

              form.submit();
            }
          }, true);
        }
      })();
    ''');
},

      ),
    );
  }

  void _updateMapWithAgriculturalCenter() {
    const centerCoords = '37.7749,128.9226'; // 기술원 좌표
    setState(() {
      _mapUrl = 'https://m.map.naver.com/directions/$centerCoords';
    });
  }
   Future<void> _autoFillForm() async {
    // 체크박스 자동 선택
    await _opinetController.evaluateJavascript(
      source: '''
        // 지역 전체 선택
        document.querySelectorAll('.chk_area').forEach(checkbox => {
          checkbox.checked = false;
        });
        document.querySelector('input[name="AREA_CD_03"]').checked = true;
        // 유종 전체 선택
        document.querySelectorAll('.chk_oil').forEach(checkbox => {
          checkbox.checked = false;
        });
        document.querySelector('input[name="sltProcdCd"]').checked = true;
      ''',
    );

    // 날짜 입력 자동 설정
    await _opinetController.evaluateJavascript(
      source: '''
        document.querySelector('input[name="STA_Y"]').value = ${_selectedDate?.year.toString()};
        document.querySelector('input[name="STA_M"]').value = ${_selectedDate?.month.toString()};
        document.querySelector('input[name="STA_D"]').value = ${_selectedDate?.day.toString()};
      ''',
    );
  }

}
