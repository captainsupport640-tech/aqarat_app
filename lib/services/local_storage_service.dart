import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../app_data.dart';
import 'security_manager.dart';

class LocalStorageService {
  static const String _isLoggedInKey = 'user_is_logged_in';
  static const String _companyEmailKey = 'company_primary_gmail';
  static const String _personalGmailKey = 'user_personal_gmail';
  static const String _backupFrequencyKey = 'backup_frequency_setting';
  static const String _appUsersMapKey = 'saved_app_users_map';

  static Future<String> _getStorageKey() async {
    String phone = SecurityManager.currentUsername.trim();
    if (phone.isEmpty) phone = 'master_user';

    String email = await getStoredEmail();
    if (email.isEmpty) email = await getPersonalGmail();
    if (email.isEmpty) email = 'admin@aqarat.com';

    String cleanPhone = phone.toLowerCase();
    String cleanEmail = email.toLowerCase();

    return 'local_app_data_${cleanPhone}_$cleanEmail';
  }

  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      debugPrint('خطأ فحص تسجيل الدخول: $e');
      return false;
    }
  }

  static Future<String> getStoredEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_companyEmailKey) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<bool> savePersonalGmail(String personalGmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_personalGmailKey, personalGmail.trim());
      await prefs.setString(_companyEmailKey, personalGmail.trim());
      return true;
    } catch (e) {
      debugPrint('خطأ حفظ الإيميل: $e');
      return false;
    }
  }

  static Future<String> getPersonalGmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_personalGmailKey) ?? prefs.getString(_companyEmailKey) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<bool> loginWithEmail(String email) async {
    try {
      final trimmedEmail = email.trim();
      if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_companyEmailKey, trimmedEmail);
      await prefs.setString(_personalGmailKey, trimmedEmail);
      await prefs.setBool(_isLoggedInKey, true);
      return true;
    } catch (e) {
      debugPrint('خطأ تسجيل الدخول بالإيميل: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.setString(_companyEmailKey, '');
      await prefs.setString(_personalGmailKey, '');
      await prefs.remove(_companyEmailKey);
      await prefs.remove(_personalGmailKey);
    } catch (e) {
      debugPrint('خطأ تسجيل الخروج: $e');
    }
  }

  /// فحص صلاحية الـ Master Admin بناءً على رقمي الموبايل والإيميلات الاستثنائية
  static bool isMasterAdmin(String email) {
    const String masterAdminEmail = 'admin@aqarat.com';
    const String programmerEmail = 'captain.support640@gmail.com';
    String lowerEmail = email.trim().toLowerCase();
    
    String currentUsername = SecurityManager.currentUsername.trim();
    
    bool isMasterPhone = (currentUsername == '01200626469' || currentUsername == '01004026247');

    return isMasterPhone || lowerEmail == masterAdminEmail.toLowerCase() || lowerEmail == programmerEmail.toLowerCase();
  }

  static Future<bool> saveAppUsers(Map<String, Map<String, String>> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String jsonString = jsonEncode(users);
      await prefs.setString(_appUsersMapKey, jsonString);
      return true;
    } catch (e) {
      debugPrint('خطأ حفظ المستخدمين: $e');
      return false;
    }
  }

  static Future loadAppUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_appUsersMapKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        Map<String, dynamic> decoded = jsonDecode(jsonString);
        Map<String, Map<String, String>> result = {};
        decoded.forEach((key, value) {
          if (value is Map) {
            result[key] = value.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
          }
        });
        return result;
      }
    } catch (e) {
      debugPrint('خطأ تحميل المستخدمين: $e');
    }
    return {};
  }

  static Future<bool> saveLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String storageKey = await _getStorageKey();
      String jsonString = jsonEncode(AppData.storage);
      await prefs.setString(storageKey, jsonString);

      await prefs.setString('local_app_data_fallback_master', jsonString);
      return true;
    } catch (e) {
      debugPrint('خطأ الحفظ المحلي: $e');
      return false;
    }
  }

  static Future<bool> loadLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String storageKey = await _getStorageKey();
      String? jsonString = prefs.getString(storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        final allKeys = prefs.getKeys();
        for (String key in allKeys) {
          if (key.startsWith('local_app_data_')) {
            String? candidate = prefs.getString(key);
            if (candidate != null && candidate.isNotEmpty && candidate != '{}') {
              jsonString = candidate;
              break;
            }
          }
        }
      }

      jsonString ??= prefs.getString('local_app_data_fallback_master');

      if (jsonString != null && jsonString.isNotEmpty) {
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

        await saveLocally();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('خطأ التحميل المحلي: $e');
      return false;
    }
  }

  static Future<String> getBackupFrequency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_backupFrequencyKey) ?? 'يدوياً';
    } catch (_) {
      return 'يدوياً';
    }
  }

  static Future<void> setBackupFrequency(String frequency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupFrequencyKey, frequency);
    } catch (e) {
      debugPrint('خطأ ضبط تكرار النسخ: $e');
    }
  }

  // ==========================================================
  //  مسار موحد ومحدث للحفظ والاسترجاع الآمن
  // ==========================================================

  static Future<Directory> _getUnifiedDocumentsFolder() async {
    Directory? folder;
    try {
      if (Platform.isAndroid) {
        folder = Directory('/storage/emulated/0/Documents');
        if (!await folder.exists()) {
          folder = await getExternalStorageDirectory();
        }
      } else {
        folder = await getApplicationDocumentsDirectory();
      }

      final Directory backupFolder = Directory('${folder!.path}/Aqarat_Backups');
      if (!await backupFolder.exists()) {
        await backupFolder.create(recursive: true);
      }
      return backupFolder;
    } catch (e) {
      Directory docs = await getApplicationDocumentsDirectory();
      final Directory backupFolder = Directory('${docs.path}/Aqarat_Backups');
      if (!await backupFolder.exists()) {
        await backupFolder.create(recursive: true);
      }
      return backupFolder;
    }
  }

  static Future<String?> exportBackupToDocumentsAuto() async {
    try {
      final Directory backupFolder = await _getUnifiedDocumentsFolder();
      String filePath = '${backupFolder.path}/aqarat_backup.json';

      String jsonString = jsonEncode(AppData.storage);
      File file = File(filePath);
      await file.writeAsString(jsonString);

      debugPrint('تم الحفظ بنجاح في المسار الموحد: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('خطأ الحفظ في Documents: $e');
    }
    return null;
  }

  static Future<bool> importBackupFromFile() async {
    try {
      final Directory backupFolder = await _getUnifiedDocumentsFolder();
      String filePath = '${backupFolder.path}/aqarat_backup.json';

      File file = File(filePath);
      if (await file.exists()) {
        String jsonString = await file.readAsString();
        Map<String, dynamic> decodedData = jsonDecode(jsonString);

        AppData.storage.clear();
        decodedData.forEach((key, value) {
          if (value is List) {
            AppData.storage[key] = value.map((item) {
              if (item is Map) {
                return Map<String, String>.from(
                  item.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
                );
              }
              return <String, String>{};
            }).toList();
          }
        });

        await saveLocally();
        return true;
      }
    } catch (e) {
      debugPrint('خطأ استرجاع النسخة من المسار الموحد: $e');
    }
    return false;
  }
}