import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../setting.dart';
import '../provider.dart';
import 'package:provider/provider.dart';
import '../main_screen/login.dart';
import 'package:one_clock/one_clock.dart';


class AndroidHomeScreen extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return Scaffold(
      body: Center(child:Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [ 
                  Spacer(flex:3),
                  Expanded(flex:2, child:DigitalClock(
                    
            isLive: true,           // 실시간 갱신
            showSeconds: true,      // 초 표시
            textScaleFactor: 2.0,
            digitalClockTextColor:  const Color.fromARGB(255, 7, 85, 42),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 230, 231, 222),
              borderRadius: BorderRadius.circular(10),
              
            ),)),
        Expanded(flex:12, child:
                  CircleAvatar(
                    backgroundImage: user!= null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    radius: 150,
                  )),
                  Expanded(flex:2, child:Text('${user?.displayName ?? ''} 조사원님 반갑습니다.', style: TextStyle(fontSize: 30, color:const Color.fromARGB(255, 20, 90, 55), fontWeight: FontWeight.bold),),
                  ), Expanded(flex:2, child:ElevatedButton.icon(
  onPressed: () async{
    Provider.of<AuthProvider>(context, listen: false).signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  },
  icon: Icon(Icons.logout, color: const Color.fromARGB(255, 51, 17, 17)),
  label: Text('로그아웃', style: TextStyle(fontSize: 20)),
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color.fromARGB(255, 231, 218, 157),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
    elevation: 4,
  ),
)), Spacer(flex:1)
                ],
              )));
  }
}
