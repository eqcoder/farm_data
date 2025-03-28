import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as google_auth;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

const _clientId =
    "455278327943-k1o8o9nm6bs41trsbppuoaof19c136eb.apps.googleusercontent.com";
const _scopes = ['https://www.googleapis.com/auth/drive.file'];


class BackUpRepository {
  static final BackUpRepository instance = BackUpRepository._internal();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );
  BackUpRepository._internal();
  drive.DriveApi? _driveApi;
  
  //로그인
  Future<void> signIn() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      print('사용자 로그인 취소');
      return;
    }

    final GoogleSignInAuthentication authentication = await account.authentication;

  // AccessCredentials 객체 생성
  final google_auth.AccessCredentials credentials = google_auth.AccessCredentials(
    google_auth.AccessToken(
      'Bearer',  // 토큰 타입
      authentication.accessToken!, // String을 AccessToken으로 변환
      DateTime.now().add(Duration(hours: 1)), // 만료 시간 (예제)
    ),
    authentication.idToken,  // ID 토큰 (nullable)
    [], // 권한 범위 (여기서는 빈 배열)
  );

    final GoogleSignInAuthentication auth = await account.authentication;
    final google_auth.AuthClient client = google_auth.authenticatedClient(
      http.Client(),
      credentials,
    );

    _driveApi = drive.DriveApi(client);
    print('✅ 로그인 성공: ${account.email}');
  }

 //로그아웃
  Future<void> signOut() async {
    GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

  Future<void> getDriveApi(
      GoogleSignInAccount googleSignInAccount) async {
    final header = await googleSignInAccount.authHeaders;
    GoogleAuthClient googleAuthClient = GoogleAuthClient(header: header);
    _driveApi= drive.DriveApi(googleAuthClient);
  }

  Future<drive.File?> upLoad(
      {required drive.DriveApi driveApi,
      required File file,
      String? driveFileId}) async {
    // 드라이브 업로드용 파일 정보
    drive.File driveFile = drive.File();

    //앱에 저장된 파일 이름 추출
    driveFile.name = path.basename(file.absolute.path);

    late final response;
    if (driveFileId != null) {
      response = await driveApi.files.update(driveFile, driveFileId,
          uploadMedia: drive.Media(file.openRead(), file.lengthSync()));
    } else {
      driveFile.parents = ["appDataFolder"];
      response = await driveApi.files.create(driveFile,
          uploadMedia: drive.Media(file.openRead(), file.lengthSync()));
    }
    return response;
  }
   Future<File> downLoad(
      {required String driveFileId,
      required drive.DriveApi driveApi,
      required String localPath}) async {
    drive.Media media = await driveApi.files.get(driveFileId,
        downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

    List<int> data = [];

    await media.stream.forEach((element) {
      data.addAll(element);
    });

    File file = File(localPath);
    file.writeAsBytesSync(data);

    return file;
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> header;
  final http.Client client = http.Client();

  GoogleAuthClient({required this.header});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(header);
    return client.send(request);
  }}


class SecureStorage {
  final storage = FlutterSecureStorage();

  //Save Credentials
  Future saveCredentials(AccessToken token, String refreshToken) async {
    print(token.expiry.toIso8601String());
    await storage.write(key: "type", value: token.type);
    await storage.write(key: "data", value: token.data);
    await storage.write(key: "expiry", value: token.expiry.toString());
    await storage.write(key: "refreshToken", value: refreshToken);
  }

  //Get Saved Credentials
  Future<Map<String, dynamic>?> getCredentials() async {
    var result = await storage.readAll();
    if (result.isEmpty) return null;
    return result;
  }

  //Clear Saved Credentials
  Future clear() {
    return storage.deleteAll();
  }
}

class GoogleDrive {
  static final GoogleDrive instance = GoogleDrive._internal();
  GoogleDrive._internal();
  final storage = SecureStorage();
  //Get Authenticated Http Client
  Future<http.Client> getHttpClient() async {
    //Get Credentials
    var credentials = await storage.getCredentials();
    if (credentials == null) {
      //Needs user authentication
      var authClient = await clientViaUserConsent(
        ClientId(_clientId),
        _scopes,
        (url) {
          //Open Url in Browser
          launch(url);
        },
      );
      //Save Credentials
      await storage.saveCredentials(
        authClient.credentials.accessToken,
        authClient.credentials.refreshToken!,
      );
      return authClient;
    } else {
      print(credentials["expiry"]);
      //Already authenticated
      return authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken(
            credentials["type"],
            credentials["data"],
            DateTime.tryParse(credentials["expiry"])!,
          ),
          credentials["refreshToken"],
          _scopes,
        ),
      );
    }
  }

  // check if the directory forlder is already available in drive , if available return its id
  // if not available create a folder in drive and return id
  //   if not able to create id then it means user authetication has failed
  Future<String?> _getFolderId(
    drive.DriveApi driveApi,
    String folderName,
  ) async {
    final mimeType = "application/vnd.google-apps.folder";

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName'",
        $fields: "files(id, name)",
      );
      final files = found.files;
      if (files == null) {
        print("Sign-in first Error");
        return null;
      }

      // The folder already exists
      if (files.isNotEmpty) {
        return files.first.id;
      }

      // Create a folder
      drive.File folder = drive.File();
      folder.name = folderName;
      folder.mimeType = mimeType;
      final folderCreation = await driveApi.files.create(folder);
      print("Folder ID: ${folderCreation.id}");

      return folderCreation.id;
    } catch (e) {
      print(e);
      return null;
    }
  }

  uploadFileToGoogleDrive(List<File?> files, String folderName) async {
    var client = await getHttpClient();
    var gdrive = drive.DriveApi(client);
    String? folderId = await _getFolderId(gdrive, folderName);
    if (folderId == null) {
      print("Sign-in first Error");
    } else {
      drive.File fileToUpload = drive.File();
      fileToUpload.parents = [folderId];
      for (var file in files) {
        fileToUpload.name = path.basename(file!.absolute.path);
        var response = await gdrive.files.create(
          fileToUpload,
          uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
        );
        print(response);
      }
      ;
    }
  }
}
