import 'dart:convert';
import 'dart:io' show File, Directory, Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../app_data.dart';
import 'local_storage_service.dart';
import 'google_drive_service.dart';
import 'security_manager.dart';

class FileBackupService {

  /// تحديد مسار النسخ الاحتياطي محلياً بشكل آمن داخل مجلد Documents
  /// تحديد مسار النسخ الاحتياطي محلياً بشكل آمن داخل مجلد التطبيق المخصص
  static Future<File?> _getBackupFile() async {
    if (kIsWeb) {
      return null;
    }

    Directory? directory;
    
    try {
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      }
      directory ??= await getApplicationDocumentsDirectory();

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

  /// إنشاء وتحديث النسخة الاحتياطية محلياً وعلى Google Drive مع رسائل تفاعلية حسب الحالة
  static Future<bool> backupToFile(BuildContext context) async {
    // 1. رسالة البدء والتحضير الفورية للمستخدم
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
      // 2. حفظ البيانات محلياً في ذاكرة التطبيق
      await LocalStorageService.saveLocally();

      // 3. إنشاء وتحديث ملف JSON محلياً في مجلد Documents
      if (!kIsWeb) {
        await LocalStorageService.exportBackupToDocumentsAuto();
        File? file = await _getBackupFile();
        if (file != null) {
          String jsonData = jsonEncode(AppData.storage);
          await file.writeAsString(jsonData);
          debugPrint('تم إنشاء النسخة الاحتياطية في مسار المستندات الآمن: ${file.path}');
        }
      }

      // 4. الرفع والتحديث التلقائي على Google Drive في الخلفية
      bool driveSuccess = await GoogleDriveService.uploadBackupToDrive();

      String userPhone = SecurityManager.currentUsername.trim();
      if (userPhone.isEmpty) userPhone = '01200626469';

      String userEmail = await LocalStorageService.getPersonalGmail();
      if (userEmail.isEmpty) userEmail = await LocalStorageService.getStoredEmail();

      // 5. إظهار رسالة النجاح أو التنبيه حسب حالة الاتصال والرفع بدقة
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              driveSuccess
                  ? '✅ تم النسخ الاحتياطي السحابي وتحديث Google Drive بنجاح!\n(الحساب: $userPhone | $userEmail)'
                  : '⚠️ تم حفظ البيانات محلياً في مجلد Documents بنجاح، ولكن تعذر الاتصال بالسحابة (تأكد من اتصال الإنترنت).',
            ),
            backgroundColor: driveSuccess ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('خطأ في النسخ الاحتياطي الشامل: $e');
      
      // 6. رسالة الخطأ الواضحة في حال حدوث أي استثناء تقني
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل النسخ الاحتياطي بسبب مشكلة في الملفات أو الاتصال: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return false;
    }
  }

  /// استعادة البيانات حصرياً من الملف المحلي أو من Google Drive
  static Future<bool> restoreFromFile(BuildContext context) async {
    try {
      bool success = false;

      // 1. محاولة الاستعادة محلياً من مجلد Documents
      if (!kIsWeb) {
        success = await LocalStorageService.importBackupFromFile();
        if (!success) {
          File? file = await _getBackupFile();
          if (file != null && await file.exists()) {
            String jsonString = await file.readAsString();
            Map<String, dynamic> decodedData = jsonDecode(jsonString);

            AppData.storage.clear();
            decodedData.forEach((key, value) {
              if (value is List) {
                AppData.storage[key] = value.map((item) {
                  if (item is Map) {
                    return Map<String, String>.from(
                      item.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
                    );
                  }
                  return <String, String>{};
                }).toList();
              }
            });
            await LocalStorageService.saveLocally();
            success = true;
            debugPrint('تمت استعادة البيانات بنجاح من مجلد المستندات: ${file.path}');
          }
        }
      }

      // 2. إذا لم يوجد الملف محلياً أو كنا على الويب، يتم الاستعادة سحابياً من Google Drive
      if (!success) {
        success = await GoogleDriveService.restoreBackupFromDrive();
      }

      // 3. إذا لم يتوفر Google Drive يتم الاستعادة من ذاكرة التخزين الداخلي
      if (!success) {
        success = await LocalStorageService.loadLocally();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'تمت استعادة البيانات بنجاح!'
                  : 'لا توجد نسخة احتياطية محفوظة أو على السحابة لهذا الحساب.',
            ),
            backgroundColor: success ? Colors.blue : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return success;
    } catch (e) {
      debugPrint('خطأ أثناء الاستعادة الشاملة: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء استعادة البيانات.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }
}