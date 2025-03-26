import 'package:google_generative_ai/google_generative_ai.dart';
import 'tomato.dart' as tomato;
import 'pepper.dart' as pepper;

Schema schema = Schema.object(nullable: false,
  properties: {

    '작물명': Schema.string(nullable: false),
    '조사자': Schema.string(nullable: false),
    '농가명': Schema.string(nullable: false),
    '지난_조사일': Schema.string(description: "지난 조사일", nullable: false),
    '조사일': Schema.string(nullable: false),
    'data': Schema.object(nullable: false,
      properties: {'토마토': tomato.schema, '파프리카': pepper.schema},
    ),
  },
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
