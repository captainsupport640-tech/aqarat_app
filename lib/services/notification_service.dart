import 'package:flutter/material.dart';
import '../app_data.dart';
import 'local_storage_service.dart';
import 'cloud_sync_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String details;
  final String date;
  final String category; // 'طلب' | 'معاينة' | 'تذكير مالي' | 'نظام'
  final Color color;
  final IconData icon;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.details,
    required this.date,
    required this.category,
    required this.color,
    required this.icon,
    this.isRead = false,
  });
}

class NotificationService {
  
  /// جلب قائمة المعرّفات المقروءة بشكل مضمون وموحّد
  static List<String> _getReadIds() {
    if (!AppData.storage.containsKey('read_notifications') || AppData.storage['read_notifications'] == null) {
      AppData.storage['read_notifications'] = <String>[];
    }
    final rawList = AppData.storage['read_notifications']!;
    return rawList.map((e) => e.toString()).toList();
  }

  /// جلب عدد الإشعارات غير المقروءة فقط للعداد الخارجي (الجرس) بدقة تامة
  static int get unreadCount {
    List<NotificationItem> activeUnread = getAllActiveNotifications(unreadOnly: true);
    return activeUnread.length;
  }

  /// جلب جميع التنبيهات النشطة وربطها بالملفات الداخلية بشكل مباشر
  static List<NotificationItem> getAllActiveNotifications({bool unreadOnly = false}) {
    List<NotificationItem> notifications = [];
    List<String> readIds = _getReadIds();

    // 1️⃣ تنبيهات شاشة طلبات العملاء من البيانات الداخلية الفعلية
    _extractCustomerRequestNotifications(notifications, readIds);

    // 2️⃣ تنبيهات شاشة المعاينات من الملفات الداخلية الفعلية
    _extractInspectionNotifications(notifications, readIds);

    // 3️⃣ تنبيهات شاشة الحسابات والتذكيرات المالية الفعلية
    _extractAccountReminderNotifications(notifications, readIds);

    if (unreadOnly) {
      return notifications.where((n) => !n.isRead).toList();
    }

    return notifications;
  }

  /// استخراج تنبيهات طلبات العملاء والعقارات المطابقة
  static void _extractCustomerRequestNotifications(List<NotificationItem> list, List<String> readIds) {
    try {
      List requests = AppData.storage['طلبات العملاء'] ?? [];
      for (var req in requests) {
        if (req is Map) {
          String clientName = req['اسم العميل'] ?? 'عميل';
          String propType = req['نوع العقار'] ?? 'عقار';
          String opType = req['نوع العملية'] ?? 'طلب';
          String date = req['التاريخ'] ?? '';

          bool isRent = opType.contains('إيجار') || opType.contains('ايجار');
          String targetKey = isRent ? 'العقارات المعروضة للإيجار' : 'العقارات المعروضة للبيع';
          List properties = AppData.storage[targetKey] ?? 
                           AppData.storage[isRent ? 'بيانات الإيجار' : 'بيانات البيع'] ?? [];

          int matchCount = 0;
          for (var prop in properties) {
            if (prop is Map && (prop['نوع العقار'] ?? '').contains(propType)) {
              matchCount++;
            }
          }

          if (matchCount > 0) {
            String notifId = 'req_${clientName}_${propType}_$date';
            list.add(NotificationItem(
              id: notifId,
              title: 'مطابقة طلب عميل: $clientName',
              details: 'يوجد $matchCount عقار مطابقة لطلب ($propType - $opType)',
              date: date,
              category: 'طلب',
              color: Colors.blueAccent,
              icon: Icons.person_search,
              isRead: readIds.contains(notifId),
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ جلب تنبيهات الطلبات: $e');
    }
  }

  /// استخراج تنبيهات المعاينات
  static void _extractInspectionNotifications(List<NotificationItem> list, List<String> readIds) {
    try {
      List inspections = AppData.storage['المعاينات'] ?? [];
      for (var insp in inspections) {
        if (insp is Map) {
          String status = insp['حالة المعاينة'] ?? 'تحت المعاينة';
          String buyer = insp['إسم المشتري'] ?? 'مشتري';
          String propType = insp['نوع العقار'] ?? 'عقار';
          String date = insp['التاريخ'] ?? '';

          if (status == 'تحت المعاينة') {
            String notifId = 'insp_${buyer}_${propType}_$date';
            list.add(NotificationItem(
              id: notifId,
              title: 'معاينة معلقة: $buyer',
              details: 'عقار: $propType - لم يتم تسجيل قرار العميل النهائي بعد',
              date: date,
              category: 'معاينة',
              color: Colors.amberAccent,
              icon: Icons.visibility,
              isRead: readIds.contains(notifId),
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ جلب تنبيهات المعاينات: $e');
    }
  }

  /// استخراج تنبيهات الحسابات والتذكيرات المالية الإيجارية
  static void _extractAccountReminderNotifications(List<NotificationItem> list, List<String> readIds) {
    try {
      List reminders = AppData.storage['التذكيرات المالية'] ?? [];
      for (var rem in reminders) {
        if (rem is Map) {
          String title = rem['العنوان'] ?? 'تذكير مالي';
          String type = rem['النوع'] ?? 'التزام';
          String amount = rem['المبلغ'] ?? '-';
          String date = rem['التاريخ'] ?? '';
          String status = rem['الحالة'] ?? 'نشط';

          if (status == 'نشط') {
            String notifId = 'rem_${title}_$date';
            list.add(NotificationItem(
              id: notifId,
              title: 'تذكير مالي: $title',
              details: 'النوع: $type | القيمة: $amount ج.م | استحقاق: $date',
              date: date,
              category: 'تذكير مالي',
              color: Colors.greenAccent,
              icon: Icons.notifications_active,
              isRead: readIds.contains(notifId),
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ جلب تنبيهات الحسابات: $e');
    }
  }

  /// تعيين إشعار كمقروء وحفظه محلياً والسحابية بشكل دائم
  static Future<void> markAsRead(String id) async {
    if (!AppData.storage.containsKey('read_notifications') || AppData.storage['read_notifications'] == null) {
      AppData.storage['read_notifications'] = <String>[];
    }
    List readList = AppData.storage['read_notifications']!;
    if (!readList.contains(id)) {
      readList.add(id);
      await LocalStorageService.saveLocally();
      await CloudSyncService.syncToCloud(isAuto: true);
    }
  }

  /// تعيين كافة الإشعارات الظاهرة كمقروءة وربطها بالشاشات والملفات بشكل جذري
  static Future<void> markAllAsRead() async {
    List<NotificationItem> items = getAllActiveNotifications();
    if (!AppData.storage.containsKey('read_notifications') || AppData.storage['read_notifications'] == null) {
      AppData.storage['read_notifications'] = <String>[];
    }
    List readList = AppData.storage['read_notifications']!;
    for (var item in items) {
      if (!readList.contains(item.id)) {
        readList.add(item.id);
      }
    }
    await LocalStorageService.saveLocally();
    await CloudSyncService.syncToCloud(isAuto: true);
  }

  /// عرض قائمة الإشعارات غير المقروءة فقط وتحديث القائمة فوراً عند الضغط
  static void showNotificationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            List<NotificationItem> activeUnreadItems = getAllActiveNotifications(unreadOnly: true);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications, color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'التنبيهات الإشعارية الحية (${activeUnreadItems.length})',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (activeUnreadItems.isNotEmpty)
                              TextButton(
                                onPressed: () async {
                                  await markAllAsRead();
                                  setSheetState(() {});
                                },
                                child: const Text('تحديد الكل كمقروء', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () => Navigator.pop(bottomSheetContext),
                            ),
                          ],
                        )
                      ],
                    ),
                    const Divider(color: Colors.grey),
                    Expanded(
                      child: activeUnreadItems.isEmpty
                          ? const Center(
                              child: Text(
                                'لا توجد تنبيهات جديدة غير مقروءة حالياً',
                                style: TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            )
                          : ListView.builder(
                              itemCount: activeUnreadItems.length,
                              itemBuilder: (context, index) {
                                final item = activeUnreadItems[index];
                                return Card(
                                  color: const Color(0xFF2D2D2D),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    onTap: () async {
                                      await markAsRead(item.id);
                                      setSheetState(() {});
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: item.color.withOpacity(0.2),
                                      child: Icon(item.icon, color: item.color, size: 20),
                                    ),
                                    title: Text(
                                      item.title,
                                      style: TextStyle(
                                        color: item.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: Text(
                                      item.details,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(item.date, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                        const SizedBox(height: 4),
                                        const Icon(Icons.circle, color: Colors.amber, size: 8),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}