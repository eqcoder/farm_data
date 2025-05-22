import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../gdrive/gdrive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../provider.dart' as provider;
import 'package:provider/provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheet;
import 'package:intl/intl.dart';

class CropField {
  final String label; // 항목 이름
  final Type type; // 자료형
  final double min; // 최소값
  final double max; // 최대값
  final double step; // 증가 단계

  CropField({
    required this.label,
    required this.type,
    required this.min,
    required this.max,
    required this.step,
  });
}

abstract class Crop {
  String name;
  DocumentReference<Map<String, dynamic>> farmRef;
  Crop({required this.name, required this.farmRef});

  DocumentReference<Map<String, dynamic>>? currentEntity;
  List<Map<String, dynamic>> allEntities=[];
  List<String> entityNames=[];
  final today = DateFormat('MM/dd').format(DateTime.now());

  List<CropField> get fields => [];
  Map<String, dynamic> basicSurvey = {};

  void addEntity(int entityNumber) {
    final entityRef = farmRef.collection(name).doc(entityNumber.toString());
  }

  void deleteEntity(int entityNumber) {
    final entityRef = farmRef.collection(name).doc(entityNumber.toString());
    entityRef.delete();
  }

  Future<List<List<dynamic>>> processGDriveData(int group, String farmName);

  void uploadToGoogleSheets(int group,List<List<dynamic>>sheetData)async{
    final GoogleDriveClass gdrive = GoogleDriveClass.instance;
    await gdrive.signIn();
      if (gdrive.driveApi == null) {
        Exception('Google Drive API에 로그인하지 못했습니다.');
        return;
      }
      final driveApi = gdrive.driveApi;
      final rootFolderId = await gdrive.createFolder(
        driveApi!,
        "$group조",
        null,
      );
      final dataFolderId = await gdrive.createFolder(
        driveApi,
        "$group조_생육원본",
        rootFolderId,
      );
      
      final file = drive.File();
    file.name = '$today_';
    file.mimeType = 'application/vnd.google-apps.spreadsheet';
    file.parents = [subFolderId];
    final createdFile = await driveApi.files.create(file);

    final spreadsheetId = createdFile.id!;
    print('생성된 시트 ID: $spreadsheetId');

    // 5. 시트에 데이터 입력
    final sheetsApi = sheet.SheetsApi(client);
    final valueRange = sheet.ValueRange.fromJson({'values': data});
    await sheetsApi.spreadsheets.values.append(
      valueRange,
      spreadsheetId,
      'Sheet1',
      valueInputOption: 'USER_ENTERED',
    );

    client.close();
}
