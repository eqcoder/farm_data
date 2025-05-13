import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'android_screen.dart';


class EnterNameScreen extends StatefulWidget {
  @override
  _EnterNameScreenState createState() => _EnterNameScreenState();
}

class _EnterNameScreenState extends State<EnterNameScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // displayName을 기본값으로 입력란에 세팅
    _nameController.text = user?.displayName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '어서오세요, ${user?.displayName ?? ''}님',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Icon(Icons.account_circle, size: 80)
                  : null,
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '이름을 입력하세요',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveName,
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveName() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      // Firebase Auth displayName 업데이트
      await user?.updateDisplayName(name);

      // Firestore에도 저장 (예시)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .set({
        'displayName': name,
        'photoURL': user?.photoURL,
        'email': user?.email,
        'uid': user?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인에 성공하였습니다!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AndroidMainScreen()),
      );
    }
  }
}
