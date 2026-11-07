import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app_data.dart';
import 'local_storage_service.dart';
import 'cloud_sync_service.dart';
import 'security_manager.dart';
import '../screens/03_customer_requests_screen.dart';
import '../screens/06_inspections_screen.dart';

class NotificationItem {
  final String id;
  final String title;
  final String details;
  final String date;
  final String category; // 'طلب' | 'معاينة' | 'تذكير مالي' | 'نظام'
  final Color color;
  final IconData icon;
  final String targetScreen; // الشاشة المستهدفة للتوجيه المباشر
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.details,
    required this.date,
    required this.category,
    required this.color,
    required this.icon,
    this.targetScreen = '',
    this.isRead = false,
  });
}

class NotificationService {
  
  /// طلب كافة الصلاحيات المطلوبة فور بدء تشغيل الإشعارات
  static Future<void> requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      try {
        await [
          Permission.notification,
          Permission.storage,
        ].request();
      } catch (e) {
        debugPrint('⚠️ خطأ صلاحيات الإشعارات: $e');
      }
    }
  }

  /// جلب قائمة المعرّفات المقروءة بشكل آمن
  static List<String> _getReadIds() {
    try {
      if (!AppData.storage.containsKey('read_notifications') || AppData.storage['read_notifications'] == null) {
        AppData.storage['read_notifications'] = <String>[];
      }
      final rawList = AppData.storage['read_notifications'];
      if (rawList is List) {
        return rawList.map((e) => e.toString().trim()).toList();
      }
    } catch (_) {}
    return [];
  }

  /// جلب عدد الإشعارات غير المقروءة بدقة
  static int get unreadCount {
    try {
      return getAllActiveNotifications(unreadOnly: true).length;
    } catch (_) {
      return 0;
    }
  }

  /// جلب جميع التنبيهات النشطة
  static List<NotificationItem> getAllActiveNotifications({bool unreadOnly = false}) {
    List<NotificationItem> notifications = [];
    List<String> readIds = _getReadIds();

    try {
      _extractCustomerRequestNotifications(notifications, readIds);
    } catch (_) {}

    try {
      _extractInspectionNotifications(notifications, readIds);
    } catch (_) {}

    try {
      _extractAccountReminderNotifications(notifications, readIds);
    } catch (_) {}

    if (unreadOnly) {
      return notifications.where((n) => !n.isRead).toList();
    }

    return notifications;
  }

  /// استخراج تنبيهات طلبات العملاء
  static void _extractCustomerRequestNotifications(List<NotificationItem> list, List<String> readIds) {
    var requests = AppData.storage['طلبات العملاء'];
    if (requests is! List) return;

    for (var req in requests) {
      if (req is Map) {
        String clientName = req['اسم العميل']?.toString() ?? 'عميل';
        String propType = req['نوع العقار']?.toString() ?? 'عقار';
        String opType = req['نوع العملية']?.toString() ?? 'طلب';
        String date = req['التاريخ']?.toString() ?? '';

        bool isRent = opType.contains('إيجار') || opType.contains('ايجار');
        String targetKey = isRent ? 'العقارات المعروضة للإيجار' : 'العقارات المعروضة للبيع';
        var properties = AppData.storage[targetKey] ?? 
                         AppData.storage[isRent ? 'بيانات الإيجار' : 'بيانات البيع'];

        int matchCount = 0;
        if (properties is List) {
          for (var prop in properties) {
            if (prop is Map && (prop['نوع العقار']?.toString() ?? '').contains(propType)) {
              matchCount++;
            }
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
            targetScreen: 'طلبات العملاء',
            isRead: readIds.contains(notifId),
          ));
        }
      }
    }
  }

  /// استخراج تنبيهات المعاينات
  static void _extractInspectionNotifications(List<NotificationItem> list, List<String> readIds) {
    var inspections = AppData.storage['المعاينات'];
    if (inspections is! List) return;

    for (var insp in inspections) {
      if (insp is Map) {
        String status = insp['حالة المعاينة']?.toString() ?? 'تحت المعاينة';
        String buyer = insp['إسم المشتري']?.toString() ?? 'مشتري';
        String propType = insp['نوع العقار']?.toString() ?? 'عقار';
        String date = insp['التاريخ']?.toString() ?? '';

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
            targetScreen: 'المعاينات',
            isRead: readIds.contains(notifId),
          ));
        }
      }
    }
  }

  /// استخراج تنبيهات الحسابات والتذكيرات المالية
  static void _extractAccountReminderNotifications(List<NotificationItem> list, List<String> readIds) {
    var reminders = AppData.storage['التذكيرات المالية'];
    if (reminders is! List) return;

    for (var rem in reminders) {
      if (rem is Map) {
        String title = rem['العنوان']?.toString() ?? 'تذكير مالي';
        String type = rem['النوع']?.toString() ?? 'التزام';
        String amount = rem['المبلغ']?.toString() ?? '-';
        String date = rem['التاريخ']?.toString() ?? '';
        String status = rem['الحالة']?.toString() ?? 'نشط';

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
            targetScreen: 'طلبات العملاء',
            isRead: readIds.contains(notifId),
          ));
        }
      }
    }
  }

  /// تعيين إشعار كمقروء
  static Future<void> markAsRead(String id) async {
    try {
      if (!AppData.storage.containsKey('read_notifications') || AppData.storage['read_notifications'] == null) {
        AppData.storage['read_notifications'] = <String>[];
      }
      List readList = AppData.storage['read_notifications']!;
      if (!readList.contains(id)) {
        readList.add(id);
        await LocalStorageService.saveLocally();
        CloudSyncService.syncToCloud(isAuto: true);
      }
    } catch (_) {}
  }

  /// تعيين كافة الإشعارات كمقروءة
  static Future<void> markAllAsRead() async {
    try {
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
      CloudSyncService.syncToCloud(isAuto: true);
    } catch (_) {}
  }

  /// التوجيه المباشر والآمن للشاشة المستهدفة
  static void _navigateToTargetScreen(BuildContext context, String targetScreen) {
    if (targetScreen.isEmpty) return;
    
    if (SecurityManager.canAccessScreen(targetScreen)) {
      Widget destinationWidget;
      if (targetScreen == 'طلبات العملاء') {
        destinationWidget = const CustomerRequestsScreen();
      } else if (targetScreen == 'المعاينات') {
        destinationWidget = const InspectionsScreen();
      } else {
        return;
      }

      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (context) => destinationWidget),
      );
    } else {
      SecurityManager.showPermissionDeniedSnackBar(
        context, 
        'عفواً، لا تملك صلاحية الوصول إلى قسم $targetScreen'
      );
    }
  }

  /// عرض قائمة الإشعارات
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
                                      if (context.mounted) {
                                        Navigator.pop(bottomSheetContext);
                                        _navigateToTargetScreen(context, item.targetScreen);
                                      }
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor: item.color.withValues(alpha: 0.2),
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