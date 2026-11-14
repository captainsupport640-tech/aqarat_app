import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'services/local_storage_service.dart';
import 'services/licensing_service.dart';
import 'services/server_config.dart';

class AppStorageManager {
  static String currentUserRole = 'ضيف';
  static String currentUsername = '';
  static String currentEmail = '';
  static StreamSubscription<DatabaseEvent>? _masterDatabaseSubscription;

  static Future<bool> checkSettingsAccessAllowed(BuildContext context) async {
    if (LicensingService.isActivated && 
       (LicensingService.activationType == 'سنوي' || LicensingService.activationType == 'مدى الحياة')) {
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    String? installDateStr = prefs.getString('first_install_date');
    
    if (installDateStr == null) {
      installDateStr = DateTime.now().toIso8601String();
      await prefs.setString('first_install_date', installDateStr);
    }

    DateTime installDate = DateTime.parse(installDateStr);
    int daysUsed = DateTime.now().difference(installDate).inDays;

    if (daysUsed >= 7) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              title: const Row(
                children: [
                  Icon(Icons.lock_clock, color: Colors.amberAccent),
                  SizedBox(width: 8),
                  Text('إعدادات المنظومة مغلقة', style: TextStyle(color: Colors.amberAccent, fontSize: 16)),
                ],
              ),
              content: const Text(
                'انتهت مهلة الـ 7 أيام التجريبية الخاصة بإعدادات المنظومة والمزامنة والنسخ الاحتياطي وسلة المهملات.\n\nيرجى التفعيل (سنوي أو مدى الحياة) لفتح أدوات الضبط والتحكم.',
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً، فهمت', style: TextStyle(color: Colors.cyanAccent)),
                ),
              ],
            ),
          ),
        );
      }
      return false;
    }

    return true;
  }

  static bool get _useRestApi =>
      ServerConfig.activeProvider == 'custom_api' ||
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows;

  static Future<void> setCurrentUser({
    required String username,
    required String role,
    required String email,
  }) async {
    currentUsername = username;
    currentUserRole = role;
    currentEmail = email;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_username', username);
    await prefs.setString('current_role', role);
    await prefs.setString('current_email', email);

    await LocalStorageService.loadLocally();
  }

  static Future<void> loadLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUsername = prefs.getString('current_username') ?? '';
      currentUserRole = prefs.getString('current_role') ?? 'ضيف';
      currentEmail = prefs.getString('current_email') ?? '';

      await LocalStorageService.loadLocally();
    } catch (_) {}
  }

  static Future<String> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_email') ?? '';
  }

  static Future<void> loginWithEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stored_gmail', email);
    currentEmail = email;
  }

  static bool isGuestOrReadOnly() {
    return currentUserRole == 'ضيف';
  }

  static Future<void> autoSaveAllData() async {
    try {
      await LocalStorageService.saveLocally();
    } catch (_) {}
  }

  static Future<String?> exportBackupToDocuments() async {
    try {
      return await LocalStorageService.exportBackupToDocumentsAuto();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> importBackupFromDocuments() async {
    try {
      return await LocalStorageService.importBackupFromFile();
    } catch (_) {
      return false;
    }
  }

  static String _cleanCompanyKey(String adminEmail) {
    String emailToClean = adminEmail.trim().isEmpty ? 'captain.support640@gmail.com' : adminEmail.trim();
    return emailToClean.toLowerCase().replaceAll('@', '_at_').replaceAll('.', '_');
  }

  static String generateClientIdentifier(String phone) {
    String cleanPhone = phone.trim();
    if (cleanPhone.contains('@')) return cleanPhone;
    return '$cleanPhone@aqarat.com';
  }

  static Future<bool> syncMasterDatabase({
    required String companyAdminEmail,
    required String currentPhone,
    required Map<String, dynamic> appData,
  }) async {
    try {
      if (companyAdminEmail.isEmpty) return false;

      String companyKey = _cleanCompanyKey(companyAdminEmail);
      String nowIso = DateTime.now().toIso8601String();

      Map<String, dynamic> payload = {
        'data': appData,
        'last_updated': nowIso,
        'updated_by_phone': currentPhone,
      };

      if (_useRestApi) {
        final url = Uri.parse(ServerConfig.getCompanyDatabaseUrl(companyKey, "1_master_database"));
        final response = await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 10));

        return response.statusCode == 200 || response.statusCode == 204;
      } else {
        DatabaseReference companyRef = FirebaseDatabase.instance
            .ref()
            .child(ServerConfig.companiesRootNode)
            .child(companyKey);
        await companyRef.child('1_master_database').set(payload).timeout(const Duration(seconds: 10));
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<dynamic> fetchMasterDatabase(String companyAdminEmail) async {
    try {
      if (companyAdminEmail.isEmpty) return null;

      String companyKey = _cleanCompanyKey(companyAdminEmail);

      if (_useRestApi) {
        final url = Uri.parse(ServerConfig.getCompanyDatabaseUrl(companyKey, "1_master_database/data"));
        final response = await http.get(url).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200 && response.body != 'null') {
          return jsonDecode(response.body);
        }
        return null;
      } else {
        DataSnapshot snapshot = await FirebaseDatabase.instance
            .ref()
            .child(ServerConfig.companiesRootNode)
            .child(companyKey)
            .child('1_master_database')
            .child('data')
            .get()
            .timeout(const Duration(seconds: 8));

        if (snapshot.exists && snapshot.value != null) {
          return Map<String, dynamic>.from(snapshot.value as Map);
        }
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static void listenToMasterDatabase({
    required String companyAdminEmail,
    required Function(Map<String, dynamic> updatedData) onDataUpdated,
  }) async {
    if (companyAdminEmail.isEmpty) return;

    dynamic initialData = await fetchMasterDatabase(companyAdminEmail);
    if (initialData != null && initialData is Map) {
      try {
        Map<String, dynamic> parsedInitial = Map<String, dynamic>.from(initialData);
        onDataUpdated(parsedInitial);
      } catch (_) {}
    }

    if (_useRestApi) return;

    _masterDatabaseSubscription?.cancel();

    String companyKey = _cleanCompanyKey(companyAdminEmail);
    DatabaseReference masterDataRef = FirebaseDatabase.instance
        .ref()
        .child(ServerConfig.companiesRootNode)
        .child(companyKey)
        .child('1_master_database')
        .child('data');

    _masterDatabaseSubscription = masterDataRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          Map<String, dynamic> receivedData = Map<String, dynamic>.from(event.snapshot.value as Map);
          onDataUpdated(receivedData);
        } catch (_) {}
      }
    });
  }

  static void stopMasterDatabaseListener() {
    _masterDatabaseSubscription?.cancel();
    _masterDatabaseSubscription = null;
  }

  static Future<void> registerEmployeeInTree({
    required String companyAdminEmail,
    required String employeePhone,
    required String employeeName,
    required String password,
    required String role,
  }) async {
    try {
      String companyKey = _cleanCompanyKey(companyAdminEmail);
      String cleanPhone = employeePhone.trim();
      if (cleanPhone.isEmpty) return;
      
      Map<String, dynamic> dataToSave = {
        'name': employeeName.trim(),
        'phone': cleanPhone,
        'password': password,
        'role': role,
        'company_admin_email': companyAdminEmail.isEmpty ? 'captain.support640@gmail.com' : companyAdminEmail,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (_useRestApi) {
        final url = Uri.parse(ServerConfig.getCompanyDatabaseUrl(companyKey, "2_employees_tree/$cleanPhone"));
        await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(dataToSave),
        );
      } else {
        await FirebaseDatabase.instance
            .ref()
            .child(ServerConfig.companiesRootNode)
            .child(companyKey)
            .child('2_employees_tree')
            .child(cleanPhone)
            .set(dataToSave);
      }
    } catch (_) {}
  }

  static Future<bool> deleteEmployeeFromTree({
    required String companyAdminEmail,
    required String employeePhone,
  }) async {
    try {
      String companyKey = _cleanCompanyKey(companyAdminEmail);
      String cleanPhone = employeePhone.trim();
      if (cleanPhone.isEmpty) return false;

      if (_useRestApi) {
        final url = Uri.parse(ServerConfig.getCompanyDatabaseUrl(companyKey, "2_employees_tree/$cleanPhone"));
        final response = await http.delete(url);
        return response.statusCode == 200 || response.statusCode == 204;
      } else {
        await FirebaseDatabase.instance
            .ref()
            .child(ServerConfig.companiesRootNode)
            .child(companyKey)
            .child('2_employees_tree')
            .child(cleanPhone)
            .remove();
        return true;
      }
    } catch (_) {
      return false;
    }
  }
}