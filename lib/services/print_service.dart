import 'package:flutter/material.dart';
import 'local_storage_service.dart';
import 'cloud_sync_service.dart';

class PrintService {
  static Future<void> printReport(BuildContext context, String screenName) async {
    // 1. حفظ البيانات محلياً وسحابياً لضمان دقة أحدث السجلات والتقارير
    await LocalStorageService.saveLocally();
    CloudSyncService.syncToCloud(isAuto: true);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث البيانات وجاري تجهيز تقرير ($screenName) للطباعة...'),
          backgroundColor: Colors.cyan,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}