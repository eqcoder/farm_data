import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'android_screen.dart';
import 'package:provider/provider.dart';
import '../provider.dart' as provider;

class LoginScreen extends StatelessWidget {
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return; // 사용자가 로그인 취소

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      Provider.of<provider.AuthProvider>(context, listen: false).setUser(userCredential.user);
    } catch (e) {
      print("Google 로그인 오류: $e");
    }
      // 로그인 성공 시 AndroidMainScreen으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AndroidMainScreen()),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _signInWithGoogle(context),
          child: Text('Sign in with Google'),
        ),
      ),
    );
  }
}