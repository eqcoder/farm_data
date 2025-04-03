import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../crop_config/schema.dart';
import 'dart:collection';
import 'package:http/http.dart' as http;


class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;

  LoggingHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print('Request: ${request.method} ${request.url}');
    print('Headers: ${request.headers}');
    if (request is http.Request) {
      print('Body: ${request.body}');
    }
    
    final response = await _inner.send(request);
    print('Response Status Code: ${response.statusCode}');
    
    return response;
  }
}

Future<Map<String, dynamic>> extractData(Uint8List imageBytes) async {
  await dotenv.load(); // Load environment variables
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? ''; // Fetch API key
  if (apiKey.isEmpty) {
    throw Exception(
      'API key is missing. Please set GEMINI_API_KEY in your .env file.',
    );
  }
  final model = GenerativeModel(
    
    model: 'gemini-2.0-flash',
    apiKey: apiKey,
    httpClient: LoggingHttpClient(http.Client()),
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: schema,
    ),
  );

  // Load the image file and encode it in base64
  final prompt = '이 표의 글자와 손글씨를 OCR로 변환해주세요. 표 안에 빈칸이 있으면 0으로 채워주시고, 모든 숫자는 소수점을 정확하게 인식해서 다음과 같은 형태로 추출해주세요. 행과 열에 유의하여 해주세요.';
  final response = await model.generateContent([
    Content.multi([
      TextPart(prompt), // 텍스트 추출을 명시하는 프롬프트
      DataPart('image/jpeg', imageBytes),
    ]),
  ]);
  print(response.text!);
  Map<String, dynamic> jsonData = jsonDecode(response.text!);
  return jsonData;
}
