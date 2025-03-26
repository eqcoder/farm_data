import 'package:farm_data/crop_config/crop_default.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final Schema schema = Schema.object(
  properties: {
    '생육조사': Schema.array(
      items: Schema.object(
        properties: {
          '개체': Schema.integer(),
          '줄기번호': Schema.integer(),
          '생장길이': Schema.number(),
          '엽수': Schema.integer(),
          '엽장': Schema.number(),
          '엽폭': Schema.number(),
          '줄기굵기': Schema.number(),
          '화방높이': Schema.number(),
          '개화마디': Schema.integer(),
          '착과마디': Schema.integer(),
          '열매마디': Schema.integer(),
          '수확마디': Schema.integer(),
          '개화수': Schema.integer(),
          '착과수': Schema.integer(),
          '열매수': Schema.integer(),
          '수확수': Schema.integer(),
        },
      ),
    ),
  },
);

class Tomato {
  int entity;
  int stemNumber;
  double growthLength;
  int leafNumber;
  double leafLength;
  double leafWidth;
  double stemThickness;
  double flowerHeight;
  int floweringNode;
  int fruitingNode;
  int fruitNode;
  int harvestNode;
  int floweringNumber;
  int fruitingNumber;
  int fruitNumber;
  int harvestNumber;
  Tomato({
    required this.entity,
    required this.stemNumber,
    required this.growthLength,
    required this.leafNumber,
    required this.leafLength,
    required this.leafWidth,
    required this.stemThickness,
    required this.flowerHeight,
    required this.floweringNode,
    required this.fruitingNode,
    required this.fruitNode,
    required this.harvestNode,
    required this.floweringNumber,
    required this.fruitingNumber,
    required this.fruitNumber,
    required this.harvestNumber,
  });
}

class PepperWidget extends StatefulWidget {
  @override
  State<_PepperWidgetState> createState() => _PepperWidgetState();
}

class _PepperWidgetState extends State<PepperWidget> {
  final List<Tomato> data;
  _PepperWidgetState({required this.data});

  
}
