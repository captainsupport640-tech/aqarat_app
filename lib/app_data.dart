import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/local_storage_service.dart';

class AppData {
  static final Map<String, List> storage = {
    'بيانات العملاء': [],
    'بيانات السماسرة': [],
    'طلبات العملاء': [],
    'المعروض للبيع': [],
    'المعروض للإيجار': [],
    'المعاينات': [],
    'العمليات التامة': [],
    'الحسابات': [],
    'التذكيرات المالية': [],
    'الإشعارات': [],
    'التقرير العام': [],
    'trash_bin': [],
  };
}

// دالة بناء الجدول الديناميكي الموحدة (مربوطة بسلة المهملات والحفظ التلقائي)
Widget buildDynamicTable({
  required List<String> headers,
  required List data,
  String? screenName,
  VoidCallback? onRefresh,
}) {
  final List<String> fullHeaders = [...headers, 'حذف'];

  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                  border: TableBorder.all(color: Colors.grey.shade400),
                  columns: fullHeaders
                      .map((title) => DataColumn(
                            label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ))
                      .toList(),
                  rows: data.asMap().entries.map((entry) {
                    int index = entry.key;
                    Map<String, String> rowData = entry.value;
                    List<String> keys = headers.sublist(1); // تخطي عمود 'م'
                    
                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        ...keys.map((key) => DataCell(Text(rowData[key] ?? ''))),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            tooltip: 'حذف السجل لنقله إلى سلة المهملات',
                            onPressed: () async {
                              if (screenName != null && AppData.storage.containsKey(screenName)) {
                                final itemToDelete = AppData.storage[screenName]![index];
                                TrashBinManager.moveToTrash(screenName, itemToDelete);

                                AppData.storage[screenName]?.removeAt(index);
                                await LocalStorageService.saveLocally();

                                onRefresh?.call();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('تم نقل السجل من ($screenName) إلى سلة المهملات بنجاح!'),
                                      backgroundColor: Colors.orange.shade800,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

// دالة نافذة الإضافة مع فحص 11 رقم للتليفون وتاريخ اليوم
void showFormDialog(BuildContext context, String screenTitle, List<String> fields, VoidCallback onRefresh) {
  final String todayDate = '10/04/2026';

  final Map<String, TextEditingController> controllers = {
    for (var field in fields)
      field: TextEditingController(
        text: field.contains('تاريخ') ? todayDate : '',
      )
  };

  final List<FocusNode> focusNodes = List.generate(fields.length, (index) => FocusNode());

  void saveData() async {
    for (var entry in controllers.entries) {
      if (entry.key.contains('تليفون') || entry.key.contains('هاتف')) {
        String val = entry.value.text.trim();
        if (val.isNotEmpty && val.length != 11) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطأ: رقم التليفون يجب أن يكون 11 رقماً بالضبط!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    final Map<String, String> newRow = {};
    controllers.forEach((key, controller) {
      newRow[key] = controller.text;
    });

    if (AppData.storage.containsKey(screenTitle)) {
      AppData.storage[screenTitle]!.add(newRow);
    }

    await LocalStorageService.saveLocally();

    if (context.mounted) {
      Navigator.pop(context);
      onRefresh();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة السجل بنجاح إلى ($screenTitle) وحفظه'),
          backgroundColor: Colors.green.shade800,
        ),
      );
    }
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text(
              'إضافة سجل جديد - $screenTitle',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.45 > 450 ? 480 : MediaQuery.of(context).size.width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(fields.length, (index) {
              final fieldName = fields[index];
              bool isPhone = fieldName.contains('تليفون') || fieldName.contains('هاتف');

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextField(
                  controller: controllers[fieldName],
                  focusNode: focusNodes[index],
                  keyboardType: isPhone ? TextInputType.number : TextInputType.text,
                  inputFormatters: isPhone
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ]
                      : [],
                  textInputAction: index < fields.length - 1 ? TextInputAction.next : TextInputAction.done,
                  onSubmitted: (_) {
                    if (index < fields.length - 1) {
                      FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                    } else {
                      saveData();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: fieldName,
                    alignLabelWithHint: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: saveData,
          icon: const Icon(Icons.check),
          label: const Text('حفظ البيانات', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

// --- دالة سلة المهملات الآمنة ومجمد الإشعارات ---
class TrashBinManager {
  static void moveToTrash(String screenName, Map<String, String> itemData) {
    if (!AppData.storage.containsKey('trash_bin') || AppData.storage['trash_bin'] == null) {
        AppData.storage['trash_bin'] = [];    }
    
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    Map<String, String> trashItem = {
      ...itemData,
      'source_screen': screenName,
      'deleted_date': dateStr,
    };
    
    AppData.storage['trash_bin']!.add(trashItem);
  }

  static void addRealNotification(String title, String body) {
    if (!AppData.storage.containsKey('الإشعارات') || AppData.storage['الإشعارات'] == null) {
      AppData.storage['الإشعارات'] = [];
    }
    
    final now = DateTime.now();
    final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')} - ${now.year}/${now.month}/${now.day}";
    
    // إضافة الإشعار الجديد في أول القائمة (فوق خالص)
    (AppData.storage['الإشعارات'] as List).insert(0, {
      'العنوان': title,
      'التفاصيل': body,
      'التاريخ': timeStr,
    });

    // وضع حد أقصى للإشعارات (آخر 25 إشعار فقط) ولو زادوا يتم مسح القديم تلقائياً
    const int maxNotifications = 25;
    if ((AppData.storage['الإشعارات'] as List).length > maxNotifications) {
      (AppData.storage['الإشعارات'] as List).removeRange(
        maxNotifications, 
        (AppData.storage['الإشعارات'] as List).length
      );
    }
  }
}