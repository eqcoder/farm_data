import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'android_screen.dart';
import 'package:provider/provider.dart';
import '../provider.dart' as provider;
import 'entername.dart';

class LoginScreen extends StatelessWidget {
  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return; // 사용자가 로그인 취소

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      Provider.of<provider.AuthProvider>(
        context,
        listen: false,
      ).setUser(userCredential.user);

      // 로그인 성공 시 AndroidMainScreen으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EnterNameScreen()),
      );
    } catch (e) {
      print("Google 로그인 오류: $e");
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      Provider.of<provider.AuthProvider>(context, listen: false).setUser(null);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그아웃 되었습니다.')));
    } catch (e) {
      print("로그아웃 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<provider.AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(title: Text('Google Login')),
      body: Center(
        child:
            user == null
                ? ElevatedButton(
                  onPressed: () => _signInWithGoogle(context),
                  child: Text('구글 로그인'),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundImage:
                          user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : null,
                      radius: 30,
                    ),
                  ],
                ),
      ),
    );
  }
}
