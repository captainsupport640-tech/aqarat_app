import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import '../app_data.dart';
import 'local_storage_service.dart';
import 'security_manager.dart';
import 'google_drive_service.dart';

class CloudSyncService {
  static const String _dbUrl = "https://aqarat-captain-default-rtdb.firebaseio.com";
  static StreamSubscription? _realtimeSubscription;
  static Timer? _restPollingTimer;

  /// فحص هل البيئة تعمل برست API (على الويب أو على الويندوز لمنع خطأ MissingPluginException)
  static bool get _useRestApi => kIsWeb || defaultTargetPlatform == TargetPlatform.windows;

  /// 0️⃣ تهيئة دعم الأوفلاين بأمان تام
  static void initOfflineSupport() {
    try {
      if (!_useRestApi) {
        FirebaseDatabase.instance.setPersistenceEnabled(true);
      }
    } catch (e) {
      debugPrint('تنبيه دعم الأوفلاين: $e');
    }
  }

  /// توليد مفتاح الشركة الثنائي النظيف
  static Future<String> _getDualSyncKey() async {
    String email = await LocalStorageService.getPersonalGmail();
    if (email.isEmpty) email = await LocalStorageService.getStoredEmail();
    email = email.trim();

    if (email.isEmpty || !email.contains('@')) {
      email = 'captain.support640@gmail.com';
    }

    return email.toLowerCase().replaceAll('.', '_').replaceAll('@', '_at_');
  }

  /// 1️⃣ المزامنة التلقائية اللحظية "رايح جاي" بين الموبايل والكمبيوتر
  static Future<void> startAutoSyncListener(Function() onDataUpdated) async {
    try {
      _realtimeSubscription?.cancel();
      _restPollingTimer?.cancel();

      String syncKey = await _getDualSyncKey();

      if (!_useRestApi) {
        DatabaseReference ref = FirebaseDatabase.instance.ref("companies_storage/$syncKey/1_master_database/data");
        _realtimeSubscription = ref.onValue.listen((event) async {
          if (event.snapshot.exists && event.snapshot.value != null) {
            bool hasChanges = _updateLocalMemorySmart(event.snapshot.value.toString());
            if (hasChanges) {
              await LocalStorageService.saveLocally();
              onDataUpdated();
            }
          }
        });
      } else {
        // فحص دوري فورس وسريع بين الأجهزة لضمان عدم وجود أي تأخير في الاستماع
        _restPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
          await _fetchRemoteDataSilently(onUpdated: onDataUpdated);
        });
      }
    } catch (e) {
      debugPrint('خطأ في الاستماع اللحظي للتحديثات: $e');
    }
  }

  /// 2️⃣ رفع البيانات الموحدة لـ Firebase
  static Future<String?> syncToCloudWithError({bool isAuto = false}) async {
    try {
      String companyEmail = await LocalStorageService.getPersonalGmail();
      if (companyEmail.isEmpty) companyEmail = await LocalStorageService.getStoredEmail();
      companyEmail = companyEmail.trim();

      String syncKey = await _getDualSyncKey();
      String jsonData = jsonEncode(AppData.storage);
      String nowIso = DateTime.now().toIso8601String();
      String currentPhone = SecurityManager.currentUsername;

      Map<String, dynamic> masterPayload = {
        'data': jsonData,
        'last_updated': nowIso,
        'updated_by_phone': currentPhone,
        'email': companyEmail,
      };

      // تنفيذ النسخ الاحتياطي المجدول حصرياً لمدير الشركة في الخلفية بصمت
      if (SecurityManager.isAdmin) {
        GoogleDriveService.checkAndExecuteScheduledBackup();
      }

      // استخدام REST API على الويب وعلى الويندوز لمنع MissingPluginException
      if (_useRestApi) {
        final masterUrl = Uri.parse("$_dbUrl/companies_storage/$syncKey/1_master_database.json");
        final response = await http.put(
          masterUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(masterPayload),
        ).timeout(const Duration(seconds: 10));

        final accountStoreUrl = Uri.parse("$_dbUrl/companies_storage/$syncKey/3_accounts_store.json");
        await http.post(
          accountStoreUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_phone': currentPhone,
            'user_email': '$currentPhone@aqarat.com',
            'timestamp': nowIso,
            'action': 'مزامنة وتحديث البيانات عبر REST API',
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 204) {
          debugPrint('✅ تم الرفع والمزامنة الموحدة بنجاح عبر REST API.');
          return null;
        } else {
          return 'خطأ سيرفر فايربيس (كود ${response.statusCode}): ${response.body}';
        }
      } else {
        FirebaseDatabase db = FirebaseDatabase.instance;
        db.goOnline();
        
        DatabaseReference companyRef = db.ref("companies_storage/$syncKey");
        
        await companyRef.child("1_master_database").set(masterPayload).timeout(const Duration(seconds: 10));

        await companyRef.child("3_accounts_store").push().set({
          'user_phone': currentPhone,
          'user_email': '$currentPhone@aqarat.com',
          'timestamp': nowIso,
          'action': 'مزامنة وتحديث البيانات الموحدة أونلاين',
        }).timeout(const Duration(seconds: 10));

        return null;
      }
    } catch (e) {
      debugPrint('❌ السبب الحقيقي للخطأ عند الرفع: $e');
      return e.toString();
    }
  }

  static Future<bool> syncToCloud({bool isAuto = false}) async {
    String? err = await syncToCloudWithError(isAuto: isAuto);
    return err == null;
  }

  /// 3️⃣ سحب البيانات الذكي: تحميل البيانات المحلية أولاً فوراً ثم التحديث السحابي في الخلفية
  static Future<bool> syncFromCloud({bool isAuto = false}) async {
    await LocalStorageService.loadLocally();
    _fetchRemoteDataSilently();
    return true;
  }

  /// دالة جلب البيانات من السحابة في الخلفية
  static Future<void> _fetchRemoteDataSilently({Function()? onUpdated}) async {
    try {
      String syncKey = await _getDualSyncKey();
      Map? rawData;

      if (_useRestApi) {
        final url = Uri.parse("$_dbUrl/companies_storage/$syncKey/1_master_database.json");
        final response = await http.get(url).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200 && response.body != 'null') {
          rawData = jsonDecode(response.body) as Map?;
        }
      } else {
        FirebaseDatabase db = FirebaseDatabase.instance;
        db.goOnline();
        DatabaseReference ref = db.ref("companies_storage/$syncKey/1_master_database");
        DataSnapshot snapshot = await ref.get().timeout(const Duration(seconds: 6));
        if (snapshot.exists && snapshot.value != null) {
          rawData = Map.from(snapshot.value as Map);
        }
      }

      if (rawData != null && rawData.containsKey('data')) {
        bool changed = _updateLocalMemorySmart(rawData['data'].toString());
        if (changed) {
          await LocalStorageService.saveLocally();
          if (onUpdated != null) onUpdated();
          debugPrint('✅ تم تحديث البيانات السحابية ومزامنتها لحظياً في الخلفية.');
        }
      }
    } catch (e) {
      debugPrint('⚠️ المزامنة السحابية تعمل أوفلاين أو تعذرت في الخلفية: $e');
    }
  }

  /// تحديث الذاكرة المحلية بالدمج الذكي المباشر دون أخطاء تنميط
  static bool _updateLocalMemorySmart(String rawJson) {
    try {
      Map decodedData = jsonDecode(rawJson);
      bool hasChanges = false;

      decodedData.forEach((key, value) {
        if (value is List) {
          List tempNewList = [];
          for (var item in value) {
            if (item is Map) {
              Map<String, String> singleMap = {};
              item.forEach((k, v) {
                singleMap[k.toString()] = v?.toString() ?? '';
              });
              tempNewList.add(singleMap);
            } else {
              tempNewList.add(<String, String>{});
            }
          }

          if (jsonEncode(AppData.storage[key]) != jsonEncode(tempNewList)) {
            AppData.storage[key] = tempNewList;
            hasChanges = true;
          }
        }
      });

      return hasChanges;
    } catch (e) {
      debugPrint('خطأ تحديث الذاكرة المحلية: $e');
      return false;
    }
  }

  /// 4️⃣ الدالة التي ينادي عليها الزر اليدوي في شاشة الإعدادات
  static Future<void> performCloudSync(BuildContext context, {bool isAuto = false}) async {
    String? errorDetails = await syncToCloudWithError(isAuto: isAuto);

    if (!isAuto && context.mounted) {
      bool success = errorDetails == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            success
                ? '✅ تمت مزامنة ورفع البيانات الموحدة أونلاين بنجاح إلى السحابة!'
                : '❌ فشل الاتصال بالسحابة! السبب:\n$errorDetails',
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  static Future<void> saveAndSyncInstant() async {
    await LocalStorageService.saveLocally();
    await syncToCloud(isAuto: true);
  }

  /// إرسال إشعار لحظي لجميع الأجهزة بالتعديل القادم وطابور الدور
  static Future<void> notifyDeviceSyncing({
    required BuildContext context,
    required String actionUser,
    required String actionRole,
  }) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 6,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, left: 15, right: 15),
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
          ),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🔄 جاري استلام ومزامنة تعديل جديد بواسطة: $actionUser ($actionRole)',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}