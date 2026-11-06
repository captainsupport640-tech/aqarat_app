import 'dart:async';
import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';
import 'cloud_sync_service.dart';

class AutoSaveService {
  static Timer? _timer;

  /// بدء تشغيل التايمر في الخلفية عند فتح البرنامج
  static void startAutoSave({int intervalInSeconds = 30}) {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: intervalInSeconds), (timer) async {
      try {
        // حفظ البيانات محلياً في الخلفية
        await LocalStorageService.saveLocally();
        
        // مزامنة التغييرات سحابياً في الخلفية
        await CloudSyncService.syncToCloud(isAuto: true);
        
        debugPrint('🔄 تم الحفظ والمزامنة التلقائية في الخلفية بنجاح.');
      } catch (e) {
        debugPrint('⚠️ خطأ في الحفظ التلقائي: $e');
      }
    });
  }

  /// إيقاف التايمر عند الحاجة
  static void stopAutoSave() {
    _timer?.cancel();
    _timer = null;
  }
}