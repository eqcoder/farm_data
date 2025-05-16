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

CropField leafCount = CropField(
  label: '엽수',
  type: int,
  min: 1,
  max: 50,
  step: 1,
);

CropField leafLength = CropField(
  label: '엽장',
  type: double,
  min: 5,
  max: 50.0,
  step: 0.1,
);

CropField leafWidth = CropField(
  label: '엽폭',
  type: double,
  min: 5,
  max: 50.0,
  step: 0.1,
);

CropField growth = CropField(
  label: '생장길이',
  type: double,
  min: 1,
  max: 200,
  step: 0.1,
);

CropField flowerHeight = CropField(
  label: '화방높이',
  type: double,
  min: 1,
  max: 50,
  step: 0.1,
);

CropField stemThikness = CropField(
  label: '줄기굵기',
  type: double,
  min: 1,
  max: 20,
  step: 0.1,
);
final cropSchema = {
  '파프리카': {
    '이미지제목': [
      "재배전경",
      "1-1 개체생장점 사진",
      "1-1 개체 마디 진행상황",
      "pH",
      "백엽상 내부",
      "온습도",
      "1 개체 근권부 사진(좌)",
      "1개체 근권부 사진(우)",
      "특이사항",
    ],
    '마디정보': {
      "번호": null,
      "status": "개화",
      "개화": null,
      "착과": null,
      "열매": null,
      "수확": null,
      "낙과": null,
      "과중": null,
      "과폭": null,
      "과고": null,
    },
    '기본조사': [
      leafCount,
      leafLength,
      leafWidth,
      growth,
      flowerHeight,
      stemThikness,
    ],
  },
  '토마토': {
    '이미지제목': [
      "1개체 22화방",
      "재배전경",
      "1개체",
      "특이사항"
          "pH",
      "온습도",
    ],
    '마디정보': {
      "꽃대": null,
      "개화수": null,
      "착과": null,
      "수확": null,
      "과중": null,
      "과폭": null,
      "과고": null,
      "당도": null,
      "산도": null,
    },
    '기본조사': [
      leafCount,
      leafLength,
      leafWidth,
      growth,
      flowerHeight,
      stemThikness,
    ],
  },
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
      properties: {'토마토': tomato.schema, '파프리카': pepper.schema},
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
