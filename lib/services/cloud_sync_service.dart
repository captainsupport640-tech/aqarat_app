import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import '../app_data.dart';
import 'local_storage_service.dart';
import 'security_manager.dart';

class CloudSyncService {

  static const String _dbUrl = "https://aqarat-captain-default-rtdb.firebaseio.com";
  static StreamSubscription? _realtimeSubscription;

  /// 0️⃣ تهيئة دعم الأوفلاين بأمان تام مع تفعيل الـ Cache المحلي
  static void initOfflineSupport() {
    try {
      if (!kIsWeb) {
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
      email = 'admin@aqarat.com';
    }

    return email.toLowerCase().replaceAll('.', '_').replaceAll('@', '_at_');
  }

  /// 1️⃣ المزامنة التلقائية اللحظية عند حدوث أي تغيير في السحابة
  static Future<void> startAutoSyncListener(Function() onDataUpdated) async {
    try {
      _realtimeSubscription?.cancel();
      String syncKey = await _getDualSyncKey();

      if (!kIsWeb) {
        DatabaseReference ref = FirebaseDatabase.instance.ref("companies_storage/$syncKey/1_master_database/data");
        _realtimeSubscription = ref.onValue.listen((event) async {
          if (event.snapshot.exists && event.snapshot.value != null) {
            _updateLocalMemory(event.snapshot.value.toString());
            await LocalStorageService.saveLocally();
            onDataUpdated();
          }
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

      if (kIsWeb) {
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
            'action': 'مزامنة وتحديث البيانات من الويب',
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 204) {
          debugPrint('✅ تم الرفع والمزامنة الموحدة بنجاح عبر REST API للويب.');
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
    // ⚡ أولاً: قراءة البيانات المحفوظة محلياً على الجهاز لفتح الشاشة في 0.1 ثانية
    await LocalStorageService.loadLocally();

    // ⚡ ثانياً: تحديث السحابة في الخلفية دون تعطيل الواجهة أو انتظار الاستجابة
    unawaited(_fetchRemoteDataSilently());

    return true;
  }

  /// دالة جلب البيانات من السحابة في الخلفية
  static Future<void> _fetchRemoteDataSilently() async {
    try {
      String syncKey = await _getDualSyncKey();
      Map? rawData;

      if (kIsWeb) {
        final url = Uri.parse("$_dbUrl/companies_storage/$syncKey/1_master_database.json");
        final response = await http.get(url).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200 && response.body != 'null') {
          rawData = jsonDecode(response.body) as Map?;
        }
      } else {
        FirebaseDatabase db = FirebaseDatabase.instance;
        db.goOnline();
        DatabaseReference ref = db.ref("companies_storage/$syncKey/1_master_database");
        DataSnapshot snapshot = await ref.get().timeout(const Duration(seconds: 8));
        if (snapshot.exists && snapshot.value != null) {
          rawData = Map.from(snapshot.value as Map);
        }
      }

      if (rawData != null && rawData.containsKey('data')) {
        _updateLocalMemory(rawData['data'].toString());
        await LocalStorageService.saveLocally();
        debugPrint('✅ تم تحديث البيانات السحابية في الخلفية بنجاح.');
      }
    } catch (e) {
      debugPrint('⚠️ المزامنة السحابية تعمل أوفلاين أو تعذرت في الخلفية: $e');
    }
  }

  static void _updateLocalMemory(String rawJson) {
    try {
      Map decodedData = jsonDecode(rawJson);
      AppData.storage.clear();
      decodedData.forEach((key, value) {
        if (value is List) {
          AppData.storage[key] = (value).map((item) {
            if (item is Map) {
              return Map<String, String>.from(
                item.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
              );
            }
            return <String, String>{};
          }).toList();
        }
      });
    } catch (e) {
      debugPrint('خطأ تحديث الذاكرة المحلية: $e');
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
}