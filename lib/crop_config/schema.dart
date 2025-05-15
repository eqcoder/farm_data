import 'package:google_generative_ai/google_generative_ai.dart';
import 'tomato.dart' as tomato;
import 'pepper.dart' as pepper;


final cropSchema={
  '파프리카':{
    '이미지제목':[
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
  '마디정보':{
    "status":"개화",
    "개화":null,
    "착과":null,
    "열매":null,
    "수확":null,
    "낙과":null,
    "과중":null,
    "과폭":null,
    "과고":null,
  }
  },
  '토마토':{
    '이미지제목':[
    
      "1개체 22화방",
      "재배전경",
      "1개체",
      "특이사항"
    "pH",
    "온습도",
    ],
    '마디정보':{
    "꽃대":null,
    "개화수":null,
    "착과":null,
    "수확":null,
    "과중":null,
    "과폭":null,
    "과고":null,
    "당도":null,
    "산도":null,
  }
    
  },
  "배추":{'이미지제목':[
    "재배전경",
    "온습도",
    "1번개체",
    "기상환경센서",
    "조사사진",
    "기타특이사항"
  ] },
  "콩":{'이미지제목':[
    "재배전경",
    "온습도",
    "1번개체",
    "기상환경센서",
    "조사사진",
    "기타특이사항"
  ] },
  "옥수수":{'이미지제목':[
    "재배전경",
    "온습도",
    "1번개체",
    "기상환경센서",
    "조사사진",
    "기타특이사항"
  ] },
  "사과":{'이미지제목':[
    "재배전경",
    "온습도",
    "1번개체",
    "기상환경센서",
    "조사사진",
    "기타특이사항"
  ]}
};

Schema schema = Schema.object(nullable: false,

  properties: {
    '작물명': Schema.string(nullable: false, description: "작물명", ),
    '조사자': Schema.string(nullable: false),
    '농가명': Schema.string(nullable: false),
    '지난_조사일': Schema.string(description: "지난 조사일", nullable: false),
    '조사일': Schema.string(nullable: false),
    'data': Schema.object(nullable: false,
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
