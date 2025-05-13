import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../database/database.dart'; // FarmDatabase 정의 필요
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Opinet extends StatefulWidget {
  @override
  _OpinetState createState() => _OpinetState();
}

class _OpinetState extends State<Opinet> {
  late InAppWebViewController _opinetController;
  InAppWebViewController? _mapController;
  late TextEditingController _dateController;
  List<Uint8List?> _capturedMap=List.generate(3, (_) => null);
  List<Uint8List?> _capturedOpinet=List.generate(3, (_) => null);
  DateTime? _selectedDate;
  int _selectedDuration = 0;
  List<String> farmNames = List.filled(3, '');
  String _mapUrl = 'https://map.naver.com/p/directions/-/-/-/car';
  String _opinetUrl = 'https://www.opinet.co.kr/user/dopospdrg/dopOsPdrgAreaSelect.do#';

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
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
            Spacer(flex:1),
            Expanded(flex:1, child:Row(children:[
              Spacer(flex:1),
            Expanded(flex:1, child:_buildDatePicker()),
            Expanded(flex:1, child:_buildDurationButtons())
            ,Spacer(flex:1)])),
            Spacer(flex:1),
            Divider(
      color: const Color.fromARGB(255, 96, 124, 139), // 선 색상
      thickness: 1,        // 선 두께
      height: 20,          // Divider의 전체 높이
      indent: 100,          // 왼쪽 여백
      endIndent: 100,       // 오른쪽 여백
    ),
            Expanded(flex:20, child:_selectedDate!=null?
            _buildWebsite():Center(child:Text("출발일을 선택하세요", style: TextStyle(fontSize: 40, color: const Color.fromARGB(255, 21, 110, 33))),)),
          ],
        );
  }

  Widget _buildDatePicker() {
    _dateController.text = _selectedDate != null 
      ? DateFormat('yyyy-MM-dd').format(_selectedDate!) 
      : '';

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
        setState(() {
          _selectedDate = picked;
          _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
        });
      }
    },
    controller: _dateController,
  );
  }

  Widget _buildDurationButtons() {
    const List<String> durations = ['당일', '1박2일', '2박3일'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min,
      children: durations.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedDuration == index 
                ? Colors.blue 
                : const Color.fromARGB(255, 219, 217, 217),
          ),
          onPressed: () => setState(() => _selectedDuration = index),
          child: Text(label, style: TextStyle(
            color: _selectedDuration == index 
                ? Colors.white 
                : const Color.fromARGB(255, 68, 65, 65),
          )),
        );
      }).toList(),
    );
  }

  Widget _buildWebsite() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_selectedDuration + 1, (index) {
        return 
          Column(
            children: [
              const SizedBox(height: 20),
              Text(DateFormat('M월 d일').format(_selectedDate!.add(Duration(days:index))).toString(), style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 30, color:Color.fromARGB(255, 17, 97, 70))),
              const SizedBox(height: 10),
              _captureMap(index),
              const SizedBox(height: 10),
              _captureOpinet(index),
              //_buildOpinetWebView(),
            ],
          );
      }),
    );
  }

  Widget _captureMap(int index) {

    void _openCaptureDialog() async {
      Uint8List? screenshot;
  final capturedImage = await showDialog<Uint8List>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
          width: 1500, // 화면 너비의 80%
          height: 1500, // 화면 높이의 50%
          padding: EdgeInsets.all(16),child:Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Spacer(flex:1),
          Expanded(flex:1, child:_buildFarmSelection()), // 기존 FarmSelection 위젯 재사용
          Spacer(flex:1),
          
          Expanded(flex:10, child: _buildMapWebView()),
          Spacer(flex:1),
          Expanded(flex:1, child:Row(mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,children:[ElevatedButton.icon(
      icon: const Icon(Icons.camera),
      label: const Text('캡처'),
      onPressed: ()async{
        screenshot  = await _mapController!.takeScreenshot(
        screenshotConfiguration: ScreenshotConfiguration(
          rect: InAppWebViewRect(x: 65, y: 0, width: 800, height: 550),
          compressFormat: CompressFormat.PNG,
          quality: 100,
        ),
      );
        if (screenshot != null) {// 캡처 후 WebView final settings = provider.SettingsProvider();파괴
    setState(() => _capturedMap[index] = screenshot);
    Navigator.pop(context,screenshot);
    
  }
      }),
      const SizedBox(width: 20), // 간격 추가
      ElevatedButton.icon(
      icon: const Icon(Icons.close),
      label: const Text('닫기'),
      onPressed: ()async{
     // 캡처 후 WebView 파괴
    Navigator.pop(context,screenshot);
    })])),
        ],
      ),)

  ));

  if (capturedImage != null) {
    setState(() => _capturedMap[index] = capturedImage);
  }
}
    return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [Stack(
                      alignment: Alignment.center,  // Stack이 부모의 크기를 채우도록 설정
                      children: [
                        Container(
                          
                          width: 650,
              height: 400,
               decoration: BoxDecoration(
            color: const Color.fromARGB(255, 226, 224, 224),
            
            borderRadius: BorderRadius.circular(10)
            ,image: _capturedMap[index]!=null?DecorationImage(
              image: MemoryImage(_capturedMap[index]!), // 배경 이미지
              fit: BoxFit.cover, // 이미지 크기 조정
            ):null
                          )),
                
        Positioned(
          child: IconButton(
            iconSize: 40,
            icon: Icon(Icons.camera_alt, color: const Color.fromARGB(255, 9, 109, 39)),
            onPressed:(){_openCaptureDialog();}, // 사진 선택 함수 호출
          ),
        ),
                    ]),
                    SizedBox(height:5),
                      Text(
                        "네이버지도",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 7, 80, 62)
                        ),
                        textAlign: TextAlign.center,
                      ),
        ]);
  }
  
Widget _captureOpinet(int index) {
    
    void _openCaptureDialog() async {
      Uint8List? screenshot;
  final capturedImage = await showDialog<Uint8List>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
          width: 1500, // 화면 너비의 80%
          height: 1500, // 화면 높이의 50%
          padding: EdgeInsets.all(16),child:Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [// 기존 FarmSelection 위젯 재사용
          Spacer(flex:1),
          
          Expanded(flex:10, child: _buildOpinetWebView(_selectedDate!.add(Duration(days:index)))),
          Spacer(flex:1),
          Expanded(flex:1, child:Row(mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,children:[ElevatedButton.icon(
      icon: const Icon(Icons.camera),
      label: const Text('캡처'),
      onPressed: ()async{
        screenshot  = await _opinetController!.takeScreenshot(
        screenshotConfiguration: ScreenshotConfiguration(
          rect: InAppWebViewRect(x: 0, y: 0, width: 800, height: 600),
          compressFormat: CompressFormat.PNG,
          quality: 100,
        ),
      );
        if (screenshot != null) {// 캡처 후 WebView final settings = provider.SettingsProvider();파괴
    setState(() => _capturedOpinet[index] = screenshot);
    Navigator.pop(context,screenshot);
    
  }
      }),
      const SizedBox(width: 20), // 간격 추가
      ElevatedButton.icon(
      icon: const Icon(Icons.close),
      label: const Text('닫기'),
      onPressed: ()async{
     // 캡처 후 WebView 파괴
    Navigator.pop(context,screenshot);
    })])),
        ],
      ),)

  ));

  if (capturedImage != null) {
    setState(() => _capturedOpinet[index] = capturedImage);
  }
}
    return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [Stack(
                      alignment: Alignment.center,  // Stack이 부모의 크기를 채우도록 설정
                      children: [
                        Container(
                          
                          width: 650,
              height: 550,
               decoration: BoxDecoration(
            color: const Color.fromARGB(255, 240, 239, 227),
            
            borderRadius: BorderRadius.circular(10)
            ,image: _capturedOpinet[index]!=null?DecorationImage(
              image: MemoryImage(_capturedOpinet[index]!), // 배경 이미지
              fit: BoxFit.cover, // 이미지 크기 조정
            ):null
                          )),
                
        Positioned(
          child: IconButton(
            iconSize: 40,
            icon: Icon(Icons.camera_alt, color: const Color.fromARGB(255, 9, 109, 39)),
            onPressed:(){_openCaptureDialog();}, // 사진 선택 함수 호출
          ),
        ),
                    ]),
                    SizedBox(height:5),
                      Text(
                        "오피넷",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 7, 80, 62)
                        ),
                        textAlign: TextAlign.center,
                      ),
        ]);
  }
  Widget _buildFarmSelection() {
    return 
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            ElevatedButton(
              onPressed: ()async {
              },
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
        );
  }

  Widget _buildMapWebView() {
    return Container(width:1500, height:1500, child:InAppWebView(
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
        onWebViewCreated: (controller) {
          _mapController = controller;
        },
        onCreateWindow: (controller, createWindowAction) async {
    if (createWindowAction.request != null) {
      final url = createWindowAction.request.url.toString();
      controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    }
    return false; // 팝업 생성 처리 완료
  },
    ));
  }

  Widget _buildOpinetWebView(DateTime currentDate) {
    return Container(width:1500, height:1500, 
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_opinetUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: true,
        ),
        onUpdateVisitedHistory: (controller, url, isReload) {
          setState(() => ());
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

   Future<void> _autoFillForm(DateTime currentDate) async {
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
        document.querySelector('input[name="OIL_CD_B027"]').checked = true;
        var select = document.getElementById("STA_Y");
  if (select) {
    select.value = "${currentDate.year.toString()}";
    select.dispatchEvent(new Event("change", { bubbles: true }));
  }
  var select = document.getElementById("STA_M");
  if (select) {
    select.value = "${currentDate.month.toString().padLeft(2, '0')}";
    select.dispatchEvent(new Event("change", { bubbles: true }));
  }
  var select = document.getElementById("STA_D");
  if (select) {
    select.value = "${currentDate.day.toString().padLeft(2, '0')}";
    select.dispatchEvent(new Event("change", { bubbles: true }));
  }
  var select = document.getElementById("END_Y");
if (select) {
    select.value = "${currentDate.year.toString()}";
    select.dispatchEvent(new Event("change", { bubbles: true }));
  }
  var select = document.getElementById("END_M");
  if (select) {
    select.value = "${currentDate.month.toString().padLeft(2, '0')}";
    select.dispatchEvent(new Event("change", { bubbles: true }));
  }
  var select = document.getElementById("END_D");
  if (select) {
    select.value = "${currentDate.day.toString().padLeft(2, '0')}";
    select.dispatchEvent(new Event("change", { bubbles: true }));
  }
      ''',
    );

  }
  
  Future<Map<String, double>?> getCoordsFromPlace(String placeName) async {
  final clientId = 'YOUR_CLIENT_ID';
  final clientSecret = 'YOUR_CLIENT_SECRET';

  final encodedPlace = Uri.encodeComponent(placeName);
  final url = Uri.parse(
      'https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode?query=$encodedPlace');

  final response = await http.get(
    url,
    headers: {
      'X-NCP-APIGW-API-KEY-ID': clientId,
      'X-NCP-APIGW-API-KEY': clientSecret,
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final addresses = data['addresses'] as List;

    if (addresses.isNotEmpty) {
      final first = addresses.first;
      return {
        'lat': double.parse(first['y']),
        'lng': double.parse(first['x']),
      };
    } else {
      print('주소 결과 없음');
    }
  } else {
    print('API 호출 실패: ${response.statusCode}');
  }

  return null;
}
}
