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
import 'package:provider/provider.dart';
import '../provider.dart' as provider;


class AndroidMainScreen extends StatelessWidget {
Widget build(BuildContext context) {
  final user = Provider.of<provider.AuthProvider>(context).user;
    return Column(
        children: [
          Expanded(
            flex: 4,
            child: Container(color: const Color.fromARGB(255, 255, 255, 255)),
          ),
          Expanded(flex:1,
          child:user!=null?Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Logged in as: ${user.displayName ?? "Unknown"}', style:TextStyle(fontSize:24)),
                  Text('Email: ${user.email ?? "Unknown"}'),
                  CircleAvatar(
                    backgroundImage: NetworkImage(user.photoURL ?? ""),
                  ),
                ],
              ):Text("로그인을 해주세요"),),
          Expanded(
            flex: 2,child:Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Spacer(flex: 1),
                  Expanded(
                    flex: 5, // 가로 공간의 2/3 차지
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
                    flex: 5,
                    child: RoundedButton(text: '야장추출', onpressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => EnterDataScreen(),
                        ),
                      );
                      print('데이터 입력 클릭');
                    }),
                  ),
                  Spacer(flex:1),
                ],
              ),
          ),
          Spacer(flex:1),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Spacer(flex: 1),
                Expanded(
                    flex: 5,
                    child: RoundedButton(text:'농가정보', onpressed:() {
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
                    flex: 5,
                    child: RoundedButton(text:'버튼 2', onpressed:() {
                      print('버튼 2 클릭');
                    }),
                  ),
                
                Spacer(flex: 1),
              ],
            ),
          ),
          Spacer(flex:1),
          Expanded(flex:2, child:Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,children: [Spacer(flex: 1),
                Expanded(
                    flex: 5,
                    child: RoundedButton(text:'버튼 2', onpressed:() {
                      print('버튼 2 클릭');
                    }),
                  ),
                Spacer(flex: 1),
                Expanded(
                    flex: 5,
                    child: RoundedButton(text:'버튼 2', onpressed:() {
                      print('버튼 2 클릭');
                    }),
                  ),Spacer(flex:1)],),),
                  Spacer(flex:1),
          Expanded(
            flex: 4,
            child: Container(color: const Color.fromARGB(255, 255, 255, 255)),
          ),
        ],
      );}}