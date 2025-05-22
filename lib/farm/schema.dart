import '../crop/crop.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../gdrive/gdrive.dart';
import 'package:intl/intl.dart';

class Farm {
  String name;
  Crop crop;
  String address;
  String city;
  DocumentReference owner;
  List<DocumentReference<Map<String, dynamic>>> authorizedUser;

  Farm({
    required this.name,
    required this.crop,
    required this.address,
    required this.city,
    required this.owner,
    required this.authorizedUser,
  });

  factory Farm.fromMap(Map<String, dynamic> map) {
    return Farm(
      name: map["name"],
      crop: map["crop"],
      address: map["address"],
      city: map["city"],
      owner: map["owner"],
      authorizedUser: map["authorizedUser"],
    );
  }

  String id = "";

  DocumentReference<Map<String, dynamic>>? farmRef;
  final today = DateFormat('MM/dd').format(DateTime.now());
  Future<void> createFarm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not logged in');
    }
    farmRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('farms')
        .doc(name);
    await farmRef!.set({
      'name': name,
      'crop': crop.name,

      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFarm() async {
    if (farmRef == null) {
      throw Exception('Farm reference is not set');
    }
    await farmRef!.delete();
  }

  Future<void> processGDriveData(int group) async {
    List<List<dynamic>> data = await crop.processGDriveData(group, name);
    GoogleDriveClass gdrive = GoogleDriveClass.instance;
    await gdrive.signIn();
    if (gdrive.driveApi == null) {
      throw Exception('Google Drive API에 로그인하지 못했습니다.');
    }
    gdrive.createSpreadsheetAndInsertData(
      fileName: '${today}_${name}_생육원본',
      data: data,
      group: group,
    );
  }
}
