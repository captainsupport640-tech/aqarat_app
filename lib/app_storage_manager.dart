import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/local_storage_service.dart';

class AppStorageManager {
  static String currentUserRole = 'ضيف';
  static String currentUsername = '';
  static String currentEmail = '';
  static StreamSubscription<DatabaseEvent>? _masterDatabaseSubscription;

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

    // [تعديل جذري هامة جداً]: استدعاء التحميل المحلي فور ضبط المستخدم لملء الذاكرة بالبيانات المحفوظة مسبقاً
    await LocalStorageService.loadLocally();
  }

  static Future<void> loadLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      currentUsername = prefs.getString('current_username') ?? '';
      currentUserRole = prefs.getString('current_role') ?? 'ضيف';
      currentEmail = prefs.getString('current_email') ?? '';

      // ضمان استرجاع البيانات المحلية للجداول فور تشغيل الملف
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
    return adminEmail.trim().toLowerCase().replaceAll('@', '_at_').replaceAll('.', '_');
  }

  /// توليد معرف العميل الموحد بالدومين
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
      DatabaseReference companyRef = FirebaseDatabase.instance.ref().child('companies_storage').child(companyKey);

      String nowIso = DateTime.now().toIso8601String();

      await companyRef.child('1_master_database').set({
        'data': appData,
        'last_updated': nowIso,
        'updated_by_phone': currentPhone,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<dynamic> fetchMasterDatabase(String companyAdminEmail) async {
    try {
      if (companyAdminEmail.isEmpty) return null;

      String companyKey = _cleanCompanyKey(companyAdminEmail);
      DataSnapshot snapshot = await FirebaseDatabase.instance
          .ref()
          .child('companies_storage')
          .child(companyKey)
          .child('1_master_database')
          .child('data')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// -------------------------------------------------------------
  /// المزامنة اللحظية السحابية الشاملة (Real-time Stream Listener + Initial Fetch)
  /// -------------------------------------------------------------
  static void listenToMasterDatabase({
    required String companyAdminEmail,
    required Function(Map<String, dynamic> updatedData) onDataUpdated,
  }) async {
    if (companyAdminEmail.isEmpty) return;

    // جلب البيانات القديمة فوراً عند الفتح لضمان التزامن الثنائي
    dynamic initialData = await fetchMasterDatabase(companyAdminEmail);
    if (initialData != null && initialData is Map) {
      try {
        Map<String, dynamic> parsedInitial = Map<String, dynamic>.from(initialData);
        onDataUpdated(parsedInitial);
      } catch (_) {}
    }

    // إلغاء أي استماع سابق لتجنب التكرار
    _masterDatabaseSubscription?.cancel();

    String companyKey = _cleanCompanyKey(companyAdminEmail);
    DatabaseReference masterDataRef = FirebaseDatabase.instance
        .ref()
        .child('companies_storage')
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

  /// تسجيل الموظف أوتوماتيكياً في فرع الحسابات والشجرة مع الصلاحية وكلمة المرور ورقم التليفون
  static Future<void> registerEmployeeInTree({
    required String companyAdminEmail,
    required String employeePhone,
    required String employeeName,
    required String password,
    required String role,
  }) async {
    try {
      if (companyAdminEmail.isEmpty || employeePhone.isEmpty) return;
      String companyKey = _cleanCompanyKey(companyAdminEmail);
      String cleanPhone = employeePhone.trim();
      
      Map<String, dynamic> dataToSave = {
        'name': employeeName.trim(),
        'phone': cleanPhone,
        'password': password,
        'role': role, // الصلاحية مباشرة بجانب البيانات
        'created_at': DateTime.now().toIso8601String(),
      };

      await FirebaseDatabase.instance
          .ref()
          .child('companies_storage')
          .child(companyKey)
          .child('2_employees_tree')
          .child(cleanPhone)
          .set(dataToSave);
    } catch (_) {}
  }
}