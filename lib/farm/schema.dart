import '../crop/crop.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../gdrive/gdrive.dart';

class Farm {
  String name;
  Crop crop;
  Farm({required this.name, required this.crop});
  String id = "";
  DocumentReference<Map<String, dynamic>>? farmRef;

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
    final driveApi = gdrive.driveApi;
    final rootFolderId = await gdrive.createFolder(
      driveApi!,
      name,
      parentId: gdrive.rootFolderId,
    );
  }
}
