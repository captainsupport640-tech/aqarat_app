import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../app_data.dart';
import 'local_storage_service.dart';
import 'security_manager.dart';

class GoogleDriveAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleDriveAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      drive.DriveApi.driveFileScope,
      drive.DriveApi.driveAppdataScope,
    ],
  );

  static const String _lastBackupDateKey = 'last_google_drive_backup_date';

  static String _getBackupFileName() {
    String phone = SecurityManager.currentUsername.trim();
    if (phone.isEmpty) {
      phone = 'default_company';
    }
    return 'aqarat_backup_$phone.json';
  }

  // تم تعديل الدالة لمسح الجلسة القديمة وإجبار اختيار الحساب الجديد
  static Future<GoogleSignInAccount?> signIn({bool silent = false}) async {
    try {
      if (kIsWeb) return null;
      
      // مسح أي جلسة أو إيميل قديم معلق لضمان عدم تداخل الحسابات
      await _googleSignIn.signOut();

      GoogleSignInAccount? account;
      if (silent) {
        account = await _googleSignIn.signInSilently();
      }
      account ??= await _googleSignIn.signIn();
      
      if (account != null) {
        await LocalStorageService.savePersonalGmail(account.email);
      }
      return account;
    } catch (e) {
      debugPrint('خطأ في تسجيل دخول Google Drive: $e');
      return null;
    }
  }

  static Future<void> checkAndExecuteScheduledBackup() async {
    try {
      if (kIsWeb) return;

      String frequency = await LocalStorageService.getBackupFrequency();
      if (frequency == 'يدوياً' || frequency == 'أبداً') return;

      final prefs = await SharedPreferences.getInstance();
      String? lastBackupStr = prefs.getString(_lastBackupDateKey);
      
      bool shouldBackup = false;
      DateTime now = DateTime.now();

      if (lastBackupStr == null) {
        shouldBackup = true;
      } else {
        DateTime lastBackup = DateTime.parse(lastBackupStr);
        int daysPassed = now.difference(lastBackup).inDays;

        if (frequency == 'يومياً' && daysPassed >= 1) {
          shouldBackup = true;
        } else if (frequency == 'أسبوعياً' && daysPassed >= 7) {
          shouldBackup = true;
        } else if (frequency == 'شهرياً' && daysPassed >= 30) {
          shouldBackup = true;
        }
      }

      if (shouldBackup) {
        bool success = await uploadBackupToDrive();
        if (success) {
          await prefs.setString(_lastBackupDateKey, now.toIso8601String());
        }
      }
    } catch (e) {
      debugPrint('خطأ فحص النسخ المجدول: $e');
    }
  }

  static Future<bool> uploadBackupToDrive() async {
    try {
      await LocalStorageService.saveLocally();
      String jsonData = jsonEncode(AppData.storage);
      String targetFileName = _getBackupFileName();

      if (kIsWeb) {
        debugPrint('✅ كود الويب متوافق وحفظ البيانات يتم عبر المزامنة السحابية.');
        return true;
      }

      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await signIn(silent: false);

      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleDriveAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      await LocalStorageService.exportBackupToDocumentsAuto();

      var bytes = utf8.encode(jsonData);

      final query = "name = '$targetFileName' and trashed = false";
      final fileList = await driveApi.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final existingFileId = fileList.files!.first.id!;
        var media = drive.Media(Stream.value(bytes), bytes.length, contentType: 'application/json');
        await driveApi.files.update(drive.File(), existingFileId, uploadMedia: media);
      } else {
        var driveFile = drive.File();
        driveFile.name = targetFileName;
        driveFile.description = 'Aqarat App Backup File';
        var media = drive.Media(Stream.value(bytes), bytes.length, contentType: 'application/json');
        await driveApi.files.create(driveFile, uploadMedia: media);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupDateKey, DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      debugPrint('خطأ رفع النسخة إلى جوجل درايف: $e');
      return false;
    }
  }

  static Future<bool> restoreBackupFromDrive() async {
    try {
      if (kIsWeb) {
        debugPrint('تم تجاوز استعادة Google Drive على بيئة الويب.');
        return false;
      }

      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await signIn(silent: false);

      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleDriveAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      String targetFileName = _getBackupFileName();
      final query = "name = '$targetFileName' and trashed = false";
      final fileList = await driveApi.files.list(q: query);

      if (fileList.files == null || fileList.files!.isEmpty) return false;

      final fileId = fileList.files!.first.id!;
      drive.Media media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;

      List<int> dataBytes = [];
      await for (var chunk in media.stream) {
        dataBytes.addAll(chunk);
      }

      String jsonString = utf8.decode(dataBytes);
      Map decodedData = jsonDecode(jsonString);

      AppData.storage.clear();
      decodedData.forEach((key, value) {
        if (value is List) {
          AppData.storage[key.toString()] = value.map((item) {
            if (item is Map) {
              return Map<String, String>.from(
                item.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
              );
            }
            return <String, String>{};
          }).toList();
        }
      });

      await LocalStorageService.saveLocally();
      await LocalStorageService.exportBackupToDocumentsAuto();
      return true;
    } catch (e) {
      debugPrint('خطأ استعادة النسخة من جوجل درايف: $e');
      return false;
    }
  }
}