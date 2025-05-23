import 'package:googleapis/chromepolicy/v1.dart';

import 'crop_screen/paprika_survey_screen.dart';
import 'package:flutter/material.dart';
import '../../../farm/schema.dart';
import '../../../crop/crop.dart';
import 'package:flutter/cupertino.dart';

class GrowthSurveyScreen extends StatelessWidget {
  final Farm farm; // 농가 정보
  final bool isEditMode;
  const GrowthSurveyScreen({required this.farm, required this.isEditMode});
  void showDevelopingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('알림'),
            content: Text('개발중입니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('확인'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 작물 타입에 따라 다른 화면 반환
    switch (farm.crop) {
      case '파프리카':
        return PaprikaSurveyScreen(farm: farm);
      case '옥수수':
      case '토마토':
      case '배추':
      case '콩':
      case '사과':
        return Center(child: Text('개발중입니다.'));
      default:
        return Center(child: Text('지원하지 않는 작물입니다.'));
    }
  }
}
