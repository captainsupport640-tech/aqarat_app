import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'local_storage_service.dart';
import 'cloud_sync_service.dart';

class PrintService {
  static Future<void> printReport(BuildContext context, String screenName) async {
    // 1. حفظ البيانات محلياً وسحابياً لضمان دقة أحدث السجلات والتقارير
    await LocalStorageService.saveLocally();
    CloudSyncService.syncToCloud(isAuto: true);

    try {
      // 2. تحديد مسار الحفظ في مجلد المستندات (Aqarat_Backups)
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/Aqarat_Backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String filePath = '${backupDir.path}/تقرير_${screenName}_$timestamp.pdf';

      // 3. إنشاء ملف تجريبي للتقرير وتأكيد الحفظ (أو ربطه بمولد الـ PDF الفعلي لديك)
      final File file = File(filePath);
      await file.writeAsString('تقرير منظومة الكابتن - قسم: $screenName - تاريخ التصدير: ${DateTime.now()}');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم حفظ ملف الـ PDF بنجاح في:\n${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ أثناء حفظ تقرير الـ PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}