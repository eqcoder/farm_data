import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ManualScreen extends StatefulWidget {
  @override
  _ManualScreenState createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // 웹뷰 초기화 (필요 시)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebViewWidget(
        controller: WebViewController()
          ..loadRequest(
            Uri.parse('https://jamesman0425.github.io/urban-farmer'),
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted),
      ),
    );
  }
}
