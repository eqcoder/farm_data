import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

// 1. 구글드라이브에서 xlsm 파일 다운로드
Future<File> downloadXlsmFile({
  required drive.DriveApi driveApi,
  required String fileId,
  required String fileName,
}) async {
  final media =
      await driveApi.files.get(
            fileId,
            downloadOptions: drive.DownloadOptions.fullMedia,
          )
          as drive.Media;

  final bytes = <int>[];
  await for (var chunk in media.stream) {
    bytes.addAll(chunk);
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

// 2. 로컬에서 xlsm 파일 수정 (예: 첫 번째 시트의 A1 셀 값 변경)
Future<File> editXlsmFile(File file) async {
  final bytes = await file.readAsBytes();
  final workbook = xlsio.Workbook.fromStream(bytes);

  // 예시: 첫 번째 시트의 A1 셀을 "수정됨"으로 변경
  final sheet = workbook.worksheets[0];
  sheet.getRangeByName('A1').setText('수정됨');

  // 저장 (xlsm 확장자 유지)
  final newBytes = workbook.saveAsStream();
  final newFile = await file.writeAsBytes(newBytes, flush: true);
  workbook.dispose();
  return newFile;
}

// 3. 수정된 파일을 구글드라이브에 업로드(덮어쓰기)
Future<void> uploadXlsmFile({
  required drive.DriveApi driveApi,
  required String fileId,
  required File file,
}) async {
  final media = drive.Media(
    file.openRead(),
    await file.length(),
    contentType: 'application/vnd.ms-excel.sheet.macroEnabled.12',
  );
  final updated = drive.File();
  await driveApi.files.update(updated, fileId, uploadMedia: media);
}
