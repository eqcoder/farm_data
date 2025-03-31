import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'android_screen.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // 사용자가 이미 로그인된 상태라면 AndroidMainScreen으로 이동
          return AndroidMainScreen();
        } else {
          // 로그인이 필요하면 LoginScreen으로 이동
          return LoginScreen();
        }
      },
    );
  }
}