import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../app_data.dart';
import 'local_storage_service.dart';
import 'security_manager.dart';
import 'google_drive_service.dart';

class CloudSyncService {
  static const String _dbUrl = "https://aqarat-captain-default-rtdb.firebaseio.com";
  
  // رقم إصدار التطبيق الحالي المثبت
  static const String currentAppVersion = "1.0.0"; 

  static StreamSubscription? _realtimeSubscription;
  static Timer? _restPollingTimer;
  
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

  /// 🚀 🔔 نظام فحص التحديثات الذكي (مع مهلة سماح قابلة للتخطي قبل القفل الإجباري)
  static Future<void> checkForMandatoryUpdate(BuildContext context) async {
    try {
      String? minRequiredVersion;
      bool forceUpdate = false;
      String playStoreUrl = "";
      String releaseDateStr = "";
      int graceDays = 7; // المهلة الافتراضية (7 أيام)

      if (_useRestApi) {
        final url = Uri.parse("$_dbUrl/system_config/app_update.json");
        final response = await http.get(url).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200 && response.body != 'null') {
          Map data = jsonDecode(response.body);
          minRequiredVersion = data['min_required_version']?.toString();
          forceUpdate = data['force_update'] == true;
          playStoreUrl = data['store_url']?.toString() ?? "";
          releaseDateStr = data['release_date']?.toString() ?? "";
          graceDays = int.tryParse(data['grace_days']?.toString() ?? '7') ?? 7;
        }
      } else {
        DatabaseReference ref = FirebaseDatabase.instance.ref("system_config/app_update");
        DataSnapshot snapshot = await ref.get().timeout(const Duration(seconds: 4));
        if (snapshot.exists && snapshot.value != null) {
          Map data = Map.from(snapshot.value as Map);
          minRequiredVersion = data['min_required_version']?.toString();
          forceUpdate = data['force_update'] == true;
          playStoreUrl = data['store_url']?.toString() ?? "";
          releaseDateStr = data['release_date']?.toString() ?? "";
          graceDays = int.tryParse(data['grace_days']?.toString() ?? '7') ?? 7;
        }
      }

      // إذا وجد إصدار جديد على السيرفر
      if (minRequiredVersion != null && _isVersionLower(currentAppVersion, minRequiredVersion)) {
        DateTime releaseDate = DateTime.tryParse(releaseDateStr) ?? DateTime.now();
        int daysPassed = DateTime.now().difference(releaseDate).inDays;
        
        // حساب الأيام المتبقية في مهلة السماح
        int remainingGraceDays = graceDays - daysPassed;

        if (context.mounted) {
          if (forceUpdate && remainingGraceDays <= 0) {
            // انتهت مهلة السماح -> قفل إجباري
            _showUpdateDialog(context, storeUrl: playStoreUrl, isMandatory: true, remainingDays: 0);
          } else {
            // ما زال في مهلة السماح -> تنبيه اختياري مع إمكانية التخطي
            _showUpdateDialog(context, storeUrl: playStoreUrl, isMandatory: false, remainingDays: remainingGraceDays > 0 ? remainingGraceDays : 0);
          }
        }
      }
    } catch (e) {
      debugPrint('تنبيه فحص التحديثات: $e');
    }
  }

  /// مقارنة إصدار النسخة الحالية بالإصدار المطلوبة
  static bool _isVersionLower(String current, String required) {
    try {
      List<int> currParts = current.split('.').map((e) => int.parse(e)).toList();
      List<int> reqParts = required.split('.').map((e) => int.parse(e)).toList();

      for (int i = 0; i < reqParts.length; i++) {
        int currVal = i < currParts.length ? currParts[i] : 0;
        if (currVal < reqParts[i]) return true;
        if (currVal > reqParts[i]) return false;
      }
    } catch (_) {}
    return false;
  }

  /// شاشة التحديث (مرنة: اختيارية أثناء المهلة، وإجبارية بعد انتهائها)
  static void _showUpdateDialog(BuildContext context, {required String storeUrl, required bool isMandatory, required int remainingDays}) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory, // لا يمكن إغلاقه إذا انتهت المهلة
      builder: (ctx) {
        return PopScope(
          canPop: !isMandatory,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: isMandatory ? Colors.redAccent : Colors.amber, width: 2),
            ),
            title: Row(
              children: [
                Icon(isMandatory ? Icons.warning_amber_rounded : Icons.system_update, color: isMandatory ? Colors.redAccent : Colors.amber),
                const SizedBox(width: 10),
                Text(
                  isMandatory ? 'تحديث إجباري مطلوب!' : 'تحديث جديد متوفر',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              isMandatory
                  ? 'انتهت مهلة السماح للتحديث.\nيرجى تحديث التطبيق الآن من جوجل بلاي لمتابعة الاستخدام.'
                  : 'يتوفر إصدار جديد من منظومة العقارات.\nمتبقي لديك ($remainingDays يوم) للتحديث قبل إغلاق النسخة القديمة.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              if (!isMandatory)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('تخطي الآن', style: TextStyle(color: Colors.grey)),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('تحديث الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  if (storeUrl.isNotEmpty) {
                    final Uri url = Uri.parse(storeUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
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

  /// 1️⃣ الاستماع اللحظي على الداتا المركزية المعتمدة
  static Future<void> startAutoSyncListener(Function() onDataUpdated) async {
    try {
      _realtimeSubscription?.cancel();
      _restPollingTimer?.cancel();

      String syncKey = await _getDualSyncKey();

      if (!_useRestApi) {
        DatabaseReference ref = FirebaseDatabase.instance.ref("companies_storage/$syncKey/3_master_database/data");
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

  /// 2️⃣ بث إشارة الحركة الحية
  static Future<void> broadcastUserAction({
    required BuildContext context,
    required String actionType,
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

  /// 3️⃣ طابور الدور المرتّب للعمليات (Queue Engine)
  static Future<void> enqueueSaveAndSync(BuildContext context, String actionType) async {
    broadcastUserAction(context: context, actionType: actionType);

    _writeQueue.add(() async {
      await LocalStorageService.saveLocally();
      await syncToCloud(isAuto: true, actionDescription: actionType);
    });

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

  /// 4️⃣ رفع البيانات وتنظيم الشجرة السحابية الثلاثية الدقيقة
  static Future<String?> syncToCloudWithError({bool isAuto = false, String actionDescription = 'تعديل بيانات'}) async {
    try {
      String syncKey = await _getDualSyncKey();
      String jsonData = jsonEncode(AppData.storage);
      String nowIso = DateTime.now().toIso8601String();
      String currentPhone = SecurityManager.currentUsername.isNotEmpty ? SecurityManager.currentUsername : 'مدير';
      String currentRole = SecurityManager.currentUserRole;

      Map<String, dynamic> masterPayload = {
        'data': jsonData,
        'last_updated': nowIso,
        'updated_by_phone': currentPhone,
        'updated_by_role': currentRole,
        'company_admin_email': SecurityManager.currentCompanyAdminEmail,
      };

      Map<String, dynamic> logPayload = {
        'action': actionDescription,
        'user': currentPhone,
        'role': currentRole,
        'timestamp': nowIso,
      };

      if (SecurityManager.isAdmin) {
        GoogleDriveService.checkAndExecuteScheduledBackup();
      }

      if (_useRestApi) {
        final masterUrl = Uri.parse("$_dbUrl/companies_storage/$syncKey/3_master_database.json");
        await http.put(masterUrl, headers: {'Content-Type': 'application/json'}, body: jsonEncode(masterPayload));

        final logUrl = Uri.parse("$_dbUrl/companies_storage/$syncKey/2_activity_log.json");
        await http.post(logUrl, headers: {'Content-Type': 'application/json'}, body: jsonEncode(logPayload));

        return null;
      } else {
        FirebaseDatabase db = FirebaseDatabase.instance;
        db.goOnline();
        DatabaseReference companyRef = db.ref("companies_storage/$syncKey");
        
        await companyRef.child("3_master_database").set(masterPayload).timeout(const Duration(seconds: 8));
        await companyRef.child("2_activity_log").push().set(logPayload).timeout(const Duration(seconds: 8));

        return null;
      }
    } catch (e) {
      return e.toString();
    }
  }

  static Future<bool> syncToCloud({bool isAuto = false, String actionDescription = 'تعديل'}) async {
    String? err = await syncToCloudWithError(isAuto: isAuto, actionDescription: actionDescription);
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
        final url = Uri.parse("$_dbUrl/companies_storage/$syncKey/3_master_database.json");
        final response = await http.get(url).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200 && response.body != 'null') {
          rawData = jsonDecode(response.body) as Map?;
        }
      } else {
        FirebaseDatabase db = FirebaseDatabase.instance;
        db.goOnline();
        DatabaseReference ref = db.ref("companies_storage/$syncKey/3_master_database");
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

  /// 🔄 التحديث الذكي: استبدال القوائم محلياً بالكامل لضمان اختفاء العناصر الممسوحة فوراً عند الجميع
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
    String? errorDetails = await syncToCloudWithError(isAuto: isAuto, actionDescription: 'مزامنة يدوية');
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
    await syncToCloud(isAuto: true, actionDescription: 'حفظ وتحديث فوري');
  }

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