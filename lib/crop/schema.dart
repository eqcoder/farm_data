import 'package:google_generative_ai/google_generative_ai.dart';
import 'tomato.dart' as tomato;
import 'pepper.dart' as pepper;

class CropField {
  final String label; // 항목 이름 (예: "엽수", "엽장")
  final Type type; // 자료형 (int 또는 double)
  final double min; // 최소값
  final double max; // 최대값
  final double step; // 증가 단계 (1 or 0.1)

  CropField({
    required this.label,
    required this.type,
    required this.min,
    required this.max,
    required this.step,
  });
}

final cropSchema = {
  "배추": {
    '이미지제목': ["재배전경", "온습도", "1번개체", "기상환경센서", "조사사진", "기타특이사항"],
  },
  "콩": {
    '이미지제목': ["재배전경", "온습도", "1번개체", "기상환경센서", "조사사진", "기타특이사항"],
  },
  "옥수수": {
    '이미지제목': ["재배전경", "온습도", "1번개체", "기상환경센서", "조사사진", "기타특이사항"],
  },
  "사과": {
    '이미지제목': ["재배전경", "온습도", "1번개체", "기상환경센서", "조사사진", "기타특이사항"],
  },
};

Schema schema = Schema.object(
  nullable: false,

  properties: {
    '작물명': Schema.string(nullable: false, description: "작물명"),
    '조사자': Schema.string(nullable: false),
    '농가명': Schema.string(nullable: false),
    '지난_조사일': Schema.string(description: "지난 조사일", nullable: false),
    '조사일': Schema.string(nullable: false),
    'data': Schema.object(
      nullable: false,
      properties: {'파프리카': pepper.schema},
      requiredProperties: ['토마토', '파프리카'],
    ),
  },
  requiredProperties: ['작물명', '조사자', '농가명', '지난_조사일', '조사일', 'data'],
);

class Crop {
  String cropName;
  String name;
  String farmName;
  String lastDate;
  Object data;
  Crop.fromJson(Map<String, dynamic> json)
    : farmName = json['farmName'],
      name = json['name'],
      cropName = json['cropName'],
      lastDate = json['lastDate'],
      data = json['data'];
  Crop({
    required this.cropName,
    required this.name,
    required this.farmName,
    required this.lastDate,
    required this.data,
  });
}
