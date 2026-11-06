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
  
  // طابور العمليات المنتظرة لمنع التعارض والتهنيج
  static final List<Function> _writeQueue = [];
  static bool _isProcessingQueue = false;

  static bool get _useRestApi => kIsWeb || defaultTargetPlatform == TargetPlatform.windows;

  static void initOfflineSupport() {
    try {
      if (!_useRestApi) {
        FirebaseDatabase.instance.setPersistenceEnabled(true);
      }
    } catch (e) {
      debugPrint('تنبيه دعم الأوفلاين: $e');
    }
  }

  static Future<String> _getDualSyncKey() async {
    String email = SecurityManager.currentCompanyAdminEmail.trim();
    if (email.isEmpty) {
      email = await LocalStorageService.getPersonalGmail();
    }
    if (email.isEmpty) {
      email = await LocalStorageService.getStoredEmail();
    }
    email = email.trim();

    if (email.isEmpty || !email.contains('@')) {
      email = 'captain.support640@gmail.com';
    }

    return email.toLowerCase().replaceAll('.', '_').replaceAll('@', '_at_');
  }

  /// 1️⃣ الاستماع اللحظي وتفعيل وضع الاستقبال الفوري
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
        _restPollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
          await _fetchRemoteDataSilently(onUpdated: onDataUpdated);
        });
      }
    } catch (e) {
      debugPrint('خطأ في الاستماع اللحظي: $e');
    }
  }

  /// 2️⃣ بث إشارة الكتابة الحية (إشعار: فلان يكتب/يعدل الآن)
  static Future<void> broadcastUserAction({
    required BuildContext context,
    required String actionType, // "إضافة" أو "تعديل" أو "حذف"
  }) async {
    String username = SecurityManager.currentUsername.isEmpty ? 'المستخدم' : SecurityManager.currentUsername;
    String role = SecurityManager.currentUserRole;

    if (context.mounted) {
      notifyDeviceSyncing(
        context: context,
        actionUser: username,
        actionRole: role,
        actionType: actionType,
      );
    }
  }

  /// 3️⃣ إضافة عملية الحفظ والتعديل في طابور الدور (Queue Process)
  static Future<void> enqueueSaveAndSync(BuildContext context, String actionType) async {
    // 1. إظهار الإشعار الحي للمستخدم الحاضر والبث
    broadcastUserAction(context: context, actionType: actionType);

    // 2. إدخال العملية في طابور الانتظار
    _writeQueue.add(() async {
      await LocalStorageService.saveLocally();
      await syncToCloud(isAuto: true);
    });

    // 3. معالجة الطابور بالتسلسل وبدون تهنيج الشاشة
    _processWriteQueue();
  }

  static Future<void> _processWriteQueue() async {
    if (_isProcessingQueue || _writeQueue.isEmpty) return;
    _isProcessingQueue = true;

    while (_writeQueue.isNotEmpty) {
      final task = _writeQueue.removeAt(0);
      try {
        await task();
      } catch (e) {
        debugPrint('خطأ في تنفيذ طابور التعديلات: $e');
      }
    }

    _isProcessingQueue = false;
  }

  /// 4️⃣ رفع البيانات الموحدة لـ Firebase
  static Future<String?> syncToCloudWithError({bool isAuto = false}) async {
    try {
      String syncKey = await _getDualSyncKey();
      String jsonData = jsonEncode(AppData.storage);
      String nowIso = DateTime.now().toIso8601String();
      String currentPhone = SecurityManager.currentUsername;

      Map<String, dynamic> masterPayload = {
        'data': jsonData,
        'last_updated': nowIso,
        'updated_by_phone': currentPhone,
        'email': SecurityManager.currentCompanyAdminEmail,
      };

      if (SecurityManager.isAdmin) {
        GoogleDriveService.checkAndExecuteScheduledBackup();
      }

      if (_useRestApi) {
        final masterUrl = Uri.parse("$_dbUrl/companies_storage/$syncKey/1_master_database.json");
        final response = await http.put(
          masterUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(masterPayload),
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 || response.statusCode == 204) {
          return null;
        } else {
          return 'خطأ سيرفر (كود ${response.statusCode})';
        }
      } else {
        FirebaseDatabase db = FirebaseDatabase.instance;
        db.goOnline();
        DatabaseReference companyRef = db.ref("companies_storage/$syncKey");
        await companyRef.child("1_master_database").set(masterPayload).timeout(const Duration(seconds: 8));
        return null;
      }
    } catch (e) {
      return e.toString();
    }
  }

  static Future<bool> syncToCloud({bool isAuto = false}) async {
    String? err = await syncToCloudWithError(isAuto: isAuto);
    return err == null;
  }

  static Future<bool> syncFromCloud({bool isAuto = false}) async {
    await LocalStorageService.loadLocally();
    _fetchRemoteDataSilently();
    return true;
  }

  static Future<void> _fetchRemoteDataSilently({Function()? onUpdated}) async {
    try {
      String syncKey = await _getDualSyncKey();
      Map? rawData;

      if (_useRestApi) {
        final url = Uri.parse("$_dbUrl/companies_storage/$syncKey/1_master_database.json");
        final response = await http.get(url).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200 && response.body != 'null') {
          rawData = jsonDecode(response.body) as Map?;
        }
      } else {
        FirebaseDatabase db = FirebaseDatabase.instance;
        db.goOnline();
        DatabaseReference ref = db.ref("companies_storage/$syncKey/1_master_database");
        DataSnapshot snapshot = await ref.get().timeout(const Duration(seconds: 5));
        if (snapshot.exists && snapshot.value != null) {
          rawData = Map.from(snapshot.value as Map);
        }
      }

      if (rawData != null && rawData.containsKey('data')) {
        bool changed = _updateLocalMemorySmart(rawData['data'].toString());
        if (changed) {
          await LocalStorageService.saveLocally();
          if (onUpdated != null) onUpdated();
        }
      }
    } catch (_) {}
  }

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
    } catch (_) {
      return false;
    }
  }

  static Future<void> performCloudSync(BuildContext context, {bool isAuto = false}) async {
    String? errorDetails = await syncToCloudWithError(isAuto: isAuto);
    if (!isAuto && context.mounted) {
      bool success = errorDetails == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✅ تمت المزامنة السحابية بنجاح!' : '❌ فشل الاتصال بالسحابة'),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  static Future<void> saveAndSyncInstant() async {
    await LocalStorageService.saveLocally();
    await syncToCloud(isAuto: true);
  }

  /// 5️⃣ الشريط السفلي لإظهار اسم وتخصص من يقوم بالتعديل حالياً
  static void notifyDeviceSyncing({
    required BuildContext context,
    required String actionUser,
    required String actionRole,
    String actionType = 'تعديل',
  }) {
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
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '✍️ جاري إجراء ($actionType) بواسطة: $actionUser ($actionRole)...',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}