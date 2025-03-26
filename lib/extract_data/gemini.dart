import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../crop_config/schema.dart';

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

    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: schema,
    ),
  );

  // Load the image file and encode it in base64
  final prompt = '이미지의 모든 텍스트를 추출해주세요. 숫자는 소수점에 유의하여 주어진 형식에 맞춰서 추출해주세요.';
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
