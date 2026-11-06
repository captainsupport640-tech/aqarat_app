import 'dart:convert';
import 'dart:io' show File, Directory, Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../app_data.dart';
import 'local_storage_service.dart';
import 'google_drive_service.dart';
import 'cloud_sync_service.dart';

class FileBackupService {

  /// الحصول على المسار الحقيقي لمجلد المستندات (Documents/Aqarat_Backups)
  static Future<Directory?> getDocumentsDirectory() async {
    if (kIsWeb) return null;
    try {
      Directory? targetDir;
      if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          targetDir = Directory('$userProfile\\Documents\\Aqarat_Backups');
        }
      }
      targetDir ??= await getApplicationDocumentsDirectory();

      final Directory backupFolder = Directory('${targetDir.path}/Aqarat_Backups');
      if (!await backupFolder.exists()) {
        await backupFolder.create(recursive: true);
      }
      return backupFolder;
    } catch (e) {
      debugPrint('خطأ في تحديد مسار المستندات: $e');
      return null;
    }
  }

  static Future<File?> _getBackupFile() async {
    final folder = await getDocumentsDirectory();
    if (folder == null) return null;
    return File('${folder.path}/aqarat_backup.json');
  }

  static void _mergeDataIntoAppData(Map<String, dynamic> sourceData) {
    sourceData.forEach((sectionKey, newItemsList) {
      if (newItemsList is List) {
        if (!AppData.storage.containsKey(sectionKey) || AppData.storage[sectionKey] == null) {
          AppData.storage[sectionKey] = [];
        }

        List currentList = AppData.storage[sectionKey]!;

        for (var newItemRaw in newItemsList) {
          if (newItemRaw is Map) {
            Map<String, String> newItem = Map<String, String>.from(
              newItemRaw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
            );

            bool exists = currentList.any((existingItem) {
              if (existingItem is Map) {
                if (newItem.containsKey('كود الوحدة') && existingItem.containsKey('كود الوحدة')) {
                  return newItem['كود الوحدة'] == existingItem['كود الوحدة'] && (newItem['كود الوحدة'] ?? '').isNotEmpty;
                }
                if (newItem.containsKey('رقم التليفون 1') && existingItem.containsKey('رقم التليفون 1')) {
                  return newItem['رقم التليفون 1'] == existingItem['رقم التليفون 1'] && (newItem['رقم التليفون 1'] ?? '').isNotEmpty;
                }
              }
              return existingItem.toString() == newItem.toString();
            });

            if (!exists) {
              currentList.add(newItem);
            }
          }
        }
      }
    });
  }

  /// 📄 دالة إنشاء وتوليد ملف PDF حقيقي وحفظه في مجلد Documents
  static Future<bool> exportPdfToDocuments(BuildContext context) async {
    try {
      final pdf = pw.Document();

      // تحميل خط يدعم اللغة العربية للـ PDF
      final fontData = await PdfGoogleFonts.cairoRegular();
      final fontBoldData = await PdfGoogleFonts.cairoBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: fontData,
            bold: fontBoldData,
          ),
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            List<pw.Widget> widgets = [];

            // ترويسة التقرير
            widgets.add(
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'تقرير منظومة الكابتن الشامل لإدارة العقارات',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                    ),
                    pw.Text(
                      'التاريخ: ${DateTime.now().toString().split(' ')[0]}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
            );

            widgets.add(pw.SizedBox(height: 10));

            // تجميع وتنسيق البيانات من كافة أقسام المنظومة
            AppData.storage.forEach((sectionTitle, items) {
              if (items.isNotEmpty) {
                widgets.add(
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 8),
                    padding: const pw.EdgeInsets.all(6),
                    color: PdfColors.grey200,
                    child: pw.Text(
                      'قسم: $sectionTitle (إجمالي البيانات: ${items.length})',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                    ),
                  ),
                );

                for (var item in items) {
                  if (item is Map) {
                    List<String> details = [];
                    item.forEach((k, v) {
                      if (v != null && v.toString().trim().isNotEmpty) {
                        details.add('$k: $v');
                      }
                    });

                    widgets.add(
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        margin: const pw.EdgeInsets.only(bottom: 4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                        ),
                        child: pw.Text(
                          details.join(' | '),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    );
                  }
                }
              }
            });

            return widgets;
          },
        ),
      );

      // حفظ الملف الحقيقي داخل مجلد Documents/Aqarat_Backups
      final docsFolder = await getDocumentsDirectory();
      if (docsFolder == null) return false;

      final pdfFile = File('${docsFolder.path}/تقرير_المنظومة_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await pdfFile.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم حفظ ملف الـ PDF بنجاح في:\n${pdfFile.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('خطأ إنشاء وتصدير الـ PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل تصدير الـ PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// تنفيذ النسخ الاحتياطي التلقائي للأرشيف والبيانات
  static Future<bool> backupToFile(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ جاري النسخ المحلي للبيانات والرفع على السحابة...'),
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      await LocalStorageService.saveLocally();

      String? localSavedPath;
      if (!kIsWeb) {
        await LocalStorageService.exportBackupToDocumentsAuto();
        File? file = await _getBackupFile();
        if (file != null) {
          String jsonData = jsonEncode(AppData.storage);
          await file.writeAsString(jsonData);
          localSavedPath = file.path;
        }
      }

      bool driveSuccess = await GoogleDriveService.uploadBackupToDrive();
      await CloudSyncService.syncToCloud(isAuto: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              driveSuccess
                  ? '✅ تم النسخ الاحتياطي وحفظه في Documents وتحديث Google Drive بنجاح!'
                  : '⚠️ تم حفظ البيانات في ($localSavedPath)، وتعذر اتصال السحابة.',
            ),
            backgroundColor: driveSuccess ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return true;
    } catch (e) {
      debugPrint('خطأ في النسخ الاحتياطي: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ فشل النسخ الاحتياطي: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return false;
    }
  }

  static Future<bool> restoreFromFile(BuildContext context) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ جاري فحص واستعادة البيانات وتجميع أحدث نسخة...'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 3),
        ),
      );
    }

    try {
      bool restoredFromAny = false;

      await LocalStorageService.loadLocally();

      if (!kIsWeb) {
        bool imported = await LocalStorageService.importBackupFromFile();
        if (imported) {
          restoredFromAny = true;
        } else {
          File? file = await _getBackupFile();
          if (file != null && await file.exists()) {
            try {
              String jsonString = await file.readAsString();
              Map<String, dynamic> localFileData = jsonDecode(jsonString);
              _mergeDataIntoAppData(localFileData);
              restoredFromAny = true;
            } catch (_) {}
          }
        }
      }

      try {
        bool driveRestored = await GoogleDriveService.restoreBackupFromDrive();
        if (driveRestored) {
          restoredFromAny = true;
        }
      } catch (e) {
        debugPrint('خطأ Google Drive: $e');
      }

      try {
        await CloudSyncService.syncFromCloud(isAuto: false);
        restoredFromAny = true;
      } catch (e) {
        debugPrint('خطأ الفايربيس: $e');
      }

      await LocalStorageService.saveLocally();
      await CloudSyncService.syncToCloud(isAuto: true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restoredFromAny
                  ? '✅ تمت الاستعادة بنجاح وتجميع أحدث نسخة مكتملة!'
                  : '⚠️ لم يتم العثور على بيانات سابقة.',
            ),
            backgroundColor: restoredFromAny ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return restoredFromAny;
    } catch (e) {
      debugPrint('خطأ الاستعادة الشاملة: $e');
      return false;
    }
  }
}