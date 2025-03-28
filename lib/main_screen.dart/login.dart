import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'android_screen.dart';
import 'windows_screen.dart';
import 'dart:io';
import 'package:window_manager/window_manager.dart';


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    User? user = _auth.currentUser; // 현재 로그인된 사용자 확인

    if (user == null) {
      // 로그인되지 않았다면 Google 로그인 페이지로 이동
      await _signInWithGoogle();
    } else {
      // 이미 로그인된 사용자라면, 기존의 사용자 정보로 앱 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
      );
    }
  }

  // Google 로그인
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자가 로그인 취소하면 앱 종료
        print("로그인 취소");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase 인증을 위한 자격 증명
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase 로그인
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context)=> AndroidMainScreen()));}
    } catch (e) {
      print("Google 로그인 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final User user;

  HomeScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('홈 화면')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('환영합니다, ${user.displayName}!', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text('이메일: ${user.email}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut(); // 로그아웃
                await GoogleSignIn().signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SplashScreen()), // 로그아웃 후 스플래시 화면으로 돌아가기
                );
              },
              child: Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}