import 'package:farm_data/business_trip/business_trip_screen.dart';
import 'package:farm_data/database.dart';
import 'package:farm_data/extract_data/main_screen.dart';
import 'package:farm_data/farm_info/farm_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../extract_data/main_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import '../business_trip/business_trip_screen.dart';
import '../farm_info/farm_info_screen.dart';
import 'form.dart';


class WindowsMainScreen extends StatelessWidget {

Widget build(BuildContext context) {
    return Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Spacer(flex: 2),
                  Expanded(
                    flex: 7, // 가로 공간의 2/3 차지
                    child: RoundedButton(text:'출장', onpressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (BuildContext context) => BusinessTripScreen()
                        ),
                      );
                      print('출장버튼 클릭');
                    }),
                  ),
                  Spacer(flex: 1),
                  Expanded(
                    flex: 7,
                    child: RoundedButton(text: '야장추출', onpressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => EnterDataScreen(),
                        ),
                      );
                      print('데이터 입력 클릭');
                    }),
                  ),
                  Spacer(flex: 1),
                  Expanded(
                    flex: 7,
                    child: RoundedButton(text: '농가정보', onpressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => FarmInfoScreen(),
                        ),
                      );
                      print('버튼 2 클릭');
                    }),
                  ),
                  Spacer(flex: 1),
                  Expanded(
                    flex: 7,
                    child: RoundedButton(text:'버튼 2', onpressed:() {
                      print('버튼 2 클릭');
                    }),
                  ),
                  Spacer(flex: 1),
                  Expanded(
                    flex: 7,
                    child: RoundedButton(text:'버튼 2', onpressed: () {
                      print('버튼 2 클릭');
                    }),
                  ),
                  Spacer(flex: 2),
                ],
              ),
            ),
          ),
          Spacer(flex:1),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Spacer(flex: 2),
                Expanded(
                    flex: 7,
                    child: RoundedButton(text:'버튼 2', onpressed:() {
                      print('버튼 2 클릭');
                    }),
                  ),
                Spacer(flex: 1),
                Expanded(
                    flex: 7,
                    child: RoundedButton(text:'버튼 2', onpressed:() {
                      print('버튼 2 클릭');
                    }),
                  ),
                Spacer(flex: 1),
                Expanded(
                    flex: 7,
                    child: RoundedButton(text:'버튼 2', onpressed:() {
                      print('버튼 2 클릭');
                    }),
                  ),
                Spacer(flex: 1),
                Expanded(
                    flex: 7,
                    child: RoundedButton(text:'버튼 2', onpressed:() {
                      print('버튼 2 클릭');
                    }),
                  ),
                Spacer(flex: 1),
                Expanded(
                    flex: 7,
                    child: RoundedButton(text:'버튼 2', onpressed:() {
                      print('버튼 2 클릭');
                    }),
                  ),
                Spacer(flex: 2),
              ],
            ),
          ),
          Spacer(flex:4)
        ],
      );}}