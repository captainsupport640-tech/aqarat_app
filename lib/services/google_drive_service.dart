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

  /// تسجيل دخول آمن دون رمي أخطاء على الويندوز
  static Future<GoogleSignInAccount?> signIn({bool silent = false}) async {
    try {
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
        return null;
      }
      
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
      debugPrint('تنبيه تسجيل دخول Google Drive (يعمل المحول الآمن تلقائياً): $e');
      return null;
    }
  }

  /// فحص وتنفيذ النسخ المجدول في الخلفية بصمت تام دون إزعاج العميل
  static Future<void> checkAndExecuteScheduledBackup() async {
    try {
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

  /// رفع النسخة الاحتياطية بأمان مع دعم الديسك توب والمستندات الموحدة
  static Future<bool> uploadBackupToDrive() async {
    try {
      await LocalStorageService.saveLocally();
      String jsonData = jsonEncode(AppData.storage);
      String targetFileName = _getBackupFileName();

      await LocalStorageService.exportBackupToDocumentsAuto();

      if (defaultTargetPlatform == TargetPlatform.windows) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastBackupDateKey, DateTime.now().toIso8601String());
        debugPrint('✅ تم حفظ النسخة الاحتياطية المحلية وتجهيزها بأمان للديسك توب.');
        return true;
      }

      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await signIn(silent: true);

      if (account == null) return true;

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleDriveAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

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
      debugPrint('تنبيه رفع النسخة للسحابة (تم الحفظ الاحتياطي المحلي بدلاً منه): $e');
      return true;
    }
  }

  /// استعادة البيانات بالدمج الذكي دون مسح البيانات الحالية
  static Future<bool> restoreBackupFromDrive() async {
    try {
      bool importedLocal = await LocalStorageService.importBackupFromFile();
      if (importedLocal) {
        return true;
      }

      if (defaultTargetPlatform == TargetPlatform.windows) return false;

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
      Map<String, dynamic> decodedData = jsonDecode(jsonString);

      decodedData.forEach((sectionKey, newItemsList) {
        if (newItemsList is List) {
          if (!AppData.storage.containsKey(sectionKey) || AppData.storage[sectionKey] == null) {
            AppData.storage[sectionKey] = [];
          }
          List currentList = AppData.storage[sectionKey]!;

          for (var newItemRaw in newItemsList) {
            if (newItemRaw is Map) {
              Map<String, String> newItem = Map<String, String>.from(
                newItemRaw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
              );

              bool exists = currentList.any((existingItem) {
                if (existingItem is Map) {
                  if (newItem.containsKey('كود الوحدة') && existingItem.containsKey('كود الوحدة')) {
                    return newItem['كود الوحدة'] == existingItem['كود الوحدة'] && (newItem['كود الوحدة'] ?? '').isNotEmpty;
                  }
                }
                return existingItem.toString() == newItem.toString();
              });

              if (!exists) {
                currentList.add(newItem);
              }
            }
          }
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