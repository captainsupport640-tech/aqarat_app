import 'dart:convert';
import 'dart:io' show File, Directory, Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../app_data.dart';
import 'local_storage_service.dart';
import 'google_drive_service.dart';
import 'cloud_sync_service.dart';
import 'security_manager.dart';

class FileBackupService {

  static Future<File?> _getBackupFile() async {
    if (kIsWeb) return null;

    Directory? directory;
    try {
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      }
      directory ??= await getApplicationSupportDirectory();

      final Directory backupFolder = Directory('${directory.path}/Aqarat_Backups');
      if (!await backupFolder.exists()) {
        await backupFolder.create(recursive: true);
      }
      return File('${backupFolder.path}/aqarat_backup.json');
    } catch (e) {
      debugPrint('خطأ في تحديد مسار المستندات: $e');
      try {
        directory = await getApplicationDocumentsDirectory();
        return File('${directory.path}/aqarat_backup.json');
      } catch (_) {
        return null;
      }
    }
  }

  static void _mergeDataIntoAppData(Map<String, dynamic> sourceData) {
    sourceData.forEach((sectionKey, newItemsList) {
      if (newItemsList is List) {
        if (!AppData.storage.containsKey(sectionKey) || AppData.storage[sectionKey] == null) {
          AppData.storage[sectionKey] = [];
        }

        List currentList = AppData.storage[sectionKey]!;

        for (var newItemRaw in newItemsList) {
          if (newItemRaw is Map) {
            Map<String, String> newItem = Map<String, String>.from(
              newItemRaw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
            );

            bool exists = currentList.any((existingItem) {
              if (existingItem is Map) {
                if (newItem.containsKey('كود الوحدة') && existingItem.containsKey('كود الوحدة')) {
                  return newItem['كود الوحدة'] == existingItem['كود الوحدة'] && (newItem['كود الوحدة'] ?? '').isNotEmpty;
                }
                if (newItem.containsKey('رقم التليفون 1') && existingItem.containsKey('رقم التليفون 1')) {
                  return newItem['رقم التليفون 1'] == existingItem['رقم التليفون 1'] && (newItem['رقم التليفون 1'] ?? '').isNotEmpty;
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
  }

  static Future<bool> backupToFile(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ جاري النسخ المحلي للبيانات والرفع على السحابة...'),
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      await LocalStorageService.saveLocally();

      if (!kIsWeb) {
        await LocalStorageService.exportBackupToDocumentsAuto();
        File? file = await _getBackupFile();
        if (file != null) {
          String jsonData = jsonEncode(AppData.storage);
          await file.writeAsString(jsonData);
        }
      }

      bool driveSuccess = await GoogleDriveService.uploadBackupToDrive();
      await CloudSyncService.syncToCloud(isAuto: true);

      String userPhone = SecurityManager.currentUsername.trim();
      if (userPhone.isEmpty) userPhone = '01200626469';

      String userEmail = await LocalStorageService.getPersonalGmail();
      if (userEmail.isEmpty) userEmail = await LocalStorageService.getStoredEmail();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              driveSuccess
                  ? '✅ تم النسخ الاحتياطي وتحديث Google Drive والفايربيس بنجاح!'
                  : '⚠️ تم حفظ البيانات محلياً، وتعذر اتصال الجيميل/السحابة.',
            ),
            backgroundColor: driveSuccess ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('خطأ في النسخ الاحتياطي: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل النسخ الاحتياطي: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    }
  }

  static Future<bool> restoreFromFile(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ جاري فحص واستعادة البيانات وتجميع أحدث نسخة...'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
      bool restoredFromAny = false;

      await LocalStorageService.loadLocally();

      if (!kIsWeb) {
        bool imported = await LocalStorageService.importBackupFromFile();
        if (imported) {
          restoredFromAny = true;
        } else {
          File? file = await _getBackupFile();
          if (file != null && await file.exists()) {
            try {
              String jsonString = await file.readAsString();
              Map<String, dynamic> localFileData = jsonDecode(jsonString);
              _mergeDataIntoAppData(localFileData);
              restoredFromAny = true;
            } catch (_) {}
          }
        }
      }

      try {
        bool driveRestored = await GoogleDriveService.restoreBackupFromDrive();
        if (driveRestored) {
          restoredFromAny = true;
        }
      } catch (e) {
        debugPrint('خطأ Google Drive: $e');
      }

      try {
        await CloudSyncService.syncFromCloud(isAuto: false);
        restoredFromAny = true;
      } catch (e) {
        debugPrint('خطأ الفايربيس: $e');
      }

      await LocalStorageService.saveLocally();
      await CloudSyncService.syncToCloud(isAuto: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restoredFromAny
                  ? '✅ تمت الاستعادة بنجاح وتجميع أحدث نسخة مكتملة!'
                  : '⚠️ لم يتم العثور على بيانات سابقة.',
            ),
            backgroundColor: restoredFromAny ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return restoredFromAny;
    } catch (e) {
      debugPrint('خطأ الاستعادة الشاملة: $e');
      return false;
    }
  }
}