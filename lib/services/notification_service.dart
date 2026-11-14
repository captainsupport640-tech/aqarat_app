import '../app_imports.dart';

class NotificationItem {
  final String id;
  final String title;
  final String details;
  final String date;
  final String category;
  final Color color;
  final IconData icon;
  final String targetScreen;
  final String highlightKey;
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
    this.highlightKey = '',
    this.isRead = false,
  });
}

class NotificationService {
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static String? highlightedRecordKeyword;

  static void refreshUnreadCount() {
    try {
      int count = unreadCount;
      if (unreadCountNotifier.value != count) {
        unreadCountNotifier.value = count;
      }
    } catch (_) {}
  }

  static Future<void> addRealNotification(String title, String details) async {
    try {
      if (!AppData.storage.containsKey('الإشعارات') || AppData.storage['الإشعارات'] == null) {
        AppData.storage['الإشعارات'] = [];
      }
      final now = DateTime.now();
      final timeStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

      String notifId = 'sys_${now.millisecondsSinceEpoch}';

      (AppData.storage['الإشعارات'] as List).insert(0, {
        'id': notifId,
        'العنوان': title,
        'التفاصيل': details,
        'التاريخ': timeStr,
      });

      refreshUnreadCount();
      await LocalStorageService.saveLocally();
    } catch (e) {
      debugPrint('خطأ أثناء إضافة إشعار: $e');
    }
  }

  static List _getReadIds() {
    try {
      if (!AppData.storage.containsKey('read_notifications') || AppData.storage['read_notifications'] == null) {
        AppData.storage['read_notifications'] = [];
      }
      final rawList = AppData.storage['read_notifications'];
      if (rawList is List) {
        return rawList.map((e) => e.toString().trim()).toList();
      }
    } catch (_) {}
    return [];
  }

  static int get unreadCount {
    try {
      return getAllActiveNotifications(unreadOnly: true).length;
    } catch (_) {
      return 0;
    }
  }

  static List getAllActiveNotifications({bool unreadOnly = false}) {
    List notifications = [];
    List readIds = _getReadIds();

    // 1. تنبيهات طلبات العملاء
    try {
      var requests = AppData.storage['طلبات العملاء'] ?? AppData.storage['الطلبات'];
      if (requests is List) {
        for (int i = 0; i < requests.length; i++) {
          var req = requests[i];
          if (req is Map) {
            String clientName = (req['اسم العميل'] ?? req['إسم العميل'] ?? 'عميل').toString().trim();
            if (clientName.isEmpty || clientName == '-') clientName = 'عميل عام';
            String propType = (req['نوع العقار'] ?? 'عقار').toString().trim();
            String opType = (req['نوع العملية'] ?? 'طلب').toString().trim();
            String date = (req['التاريخ'] ?? '').toString().trim();

            String notifId = 'req_${i}_${clientName}_${propType}_$date';
            notifications.add(NotificationItem(
              id: notifId,
              title: 'طلب عميل: $clientName',
              details: 'مطلوب: $propType ($opType)',
              date: date,
              category: 'طلب',
              color: Colors.blueAccent,
              icon: Icons.person_search,
              targetScreen: 'طلبات العملاء',
              highlightKey: clientName,
              isRead: readIds.contains(notifId),
            ));
          }
        }
      }
    } catch (_) {}

    // 2. تنبيهات المعاينات
    try {
      var inspections = AppData.storage['المعاينات'];
      if (inspections is List) {
        for (int i = 0; i < inspections.length; i++) {
          var insp = inspections[i];
          if (insp is Map) {
            String status = (insp['حالة المعاينة'] ?? 'تحت المعاينة').toString().trim();
            if (status == 'تمت' || status == 'ملغاة') continue;

            String buyer = (insp['اسم المشتري'] ?? insp['إسم المشتري'] ?? insp['اسم العميل'] ?? 'عميل').toString().trim();
            String unitCode = (insp['كود الوحدة'] ?? '').toString().trim();
            String propType = (insp['نوع العقار'] ?? 'عقار').toString().trim();
            String date = (insp['تاريخ المعاينة'] ?? insp['التاريخ'] ?? '').toString().trim();

            String notifId = 'insp_${i}_${unitCode}_${buyer}_$date';
            notifications.add(NotificationItem(
              id: notifId,
              title: 'معاينة: $propType ${unitCode.isNotEmpty && unitCode != '-' ? "($unitCode)" : ""}',
              details: 'العميل: $buyer | الحالة: $status',
              date: date,
              category: 'معاينة',
              color: Colors.amberAccent,
              icon: Icons.visibility,
              targetScreen: 'المعاينات',
              highlightKey: unitCode.isNotEmpty && unitCode != '-' ? unitCode : buyer,
              isRead: readIds.contains(notifId),
            ));
          }
        }
      }
    } catch (_) {}

    // 3. تنبيهات الحسابات والتذكيرات المالية
    try {
      var reminders = AppData.storage['التذكيرات المالية'];
      if (reminders is List) {
        for (int i = 0; i < reminders.length; i++) {
          var rem = reminders[i];
          if (rem is Map) {
            String title = (rem['العنوان'] ?? rem['البيان'] ?? 'تذكير مالي').toString().trim();
            String amount = (rem['المبلغ'] ?? '-').toString().trim();
            String date = (rem['التاريخ'] ?? '').toString().trim();

            String notifId = 'rem_${i}_${title}_$date';
            notifications.add(NotificationItem(
              id: notifId,
              title: 'تذكير مالي: $title',
              details: 'المبلغ: $amount | الاستحقاق: $date',
              date: date,
              category: 'حسابات',
              color: Colors.greenAccent,
              icon: Icons.account_balance_wallet,
              targetScreen: 'الحسابات',
              highlightKey: title,
              isRead: readIds.contains(notifId),
            ));
          }
        }
      }
    } catch (_) {}

    // 4. إشعارات النظام
    try {
      var sysNotifs = AppData.storage['الإشعارات'];
      if (sysNotifs is List) {
        for (var notif in sysNotifs) {
          if (notif is Map) {
            String title = (notif['العنوان'] ?? notif['title'] ?? 'إشعار نظام').toString();
            String details = (notif['التفاصيل'] ?? notif['body'] ?? '').toString();
            String date = (notif['التاريخ'] ?? notif['time'] ?? '').toString();
            String notifId = (notif['id'] ?? 'sys_${title}_$date').toString();

            notifications.add(NotificationItem(
              id: notifId,
              title: title,
              details: details,
              date: date,
              category: 'نظام',
              color: Colors.cyanAccent,
              icon: Icons.notifications,
              targetScreen: '',
              isRead: readIds.contains(notifId),
            ));
          }
        }
      }
    } catch (_) {}

    if (unreadOnly) {
      return notifications.where((n) => n is NotificationItem && !n.isRead).toList();
    }

    return notifications;
  }

  static Future<void> markAsRead(String notifId) async {
    try {
      if (!AppData.storage.containsKey('read_notifications') || AppData.storage['read_notifications'] == null) {
        AppData.storage['read_notifications'] = [];
      }
      List readList = AppData.storage['read_notifications']!;
      if (!readList.contains(notifId)) {
        readList.add(notifId);
      }
      refreshUnreadCount();
      await LocalStorageService.saveLocally();
    } catch (_) {}
  }

  static Future<void> markAllAsRead() async {
    try {
      List items = getAllActiveNotifications();
      if (!AppData.storage.containsKey('read_notifications') || AppData.storage['read_notifications'] == null) {
        AppData.storage['read_notifications'] = [];
      }
      List readList = AppData.storage['read_notifications']!;
      for (var item in items) {
        if (item is NotificationItem && !readList.contains(item.id)) {
          readList.add(item.id);
        }
      }
      unreadCountNotifier.value = 0;
      await LocalStorageService.saveLocally();
    } catch (_) {}
  }

  static void _navigateToTargetScreen(BuildContext context, NotificationItem item) {
    if (item.targetScreen.isEmpty) return;

    highlightedRecordKeyword = item.highlightKey;

    if (SecurityManager.canAccessScreen(item.targetScreen)) {
      Widget destinationWidget;
      if (item.targetScreen == 'طلبات العملاء') {
        destinationWidget = const CustomerRequestsScreen();
      } else if (item.targetScreen == 'المعاينات') {
        destinationWidget = const InspectionsScreen();
      } else if (item.targetScreen == 'الحسابات') {
        destinationWidget = const AccountsScreen();
      } else {
        return;
      }

      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (context) => destinationWidget),
      );

      if (item.highlightKey.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.amber.shade800,
                duration: const Duration(seconds: 4),
                content: Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.black),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'السجل المستهدف: ${item.highlightKey} (${item.details})',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        });
      }
    } else {
      SecurityManager.showPermissionDeniedSnackBar(
        context,
        'عفواً، لا تملك صلاحية الوصول إلى قسم ${item.targetScreen}',
      );
    }
  }

  static void showNotificationMenu(BuildContext context) {
    List allActiveItems = getAllActiveNotifications(unreadOnly: false);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            int currentUnread = allActiveItems.where((e) => e is NotificationItem && !e.isRead).length;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active, color: Colors.amber, size: 22),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'التنبيهات ($currentUnread غير مقروء)',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.amber.withValues(alpha: 0.15),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          icon: const Icon(Icons.done_all, color: Colors.amberAccent, size: 16),
                          label: const Text('تمييز الكل كمقروء',
                              style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                          onPressed: () async {
                            await markAllAsRead();
                            setStateDialog(() {
                              for (var item in allActiveItems) {
                                if (item is NotificationItem) item.isRead = true;
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                          tooltip: 'إغلاق',
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ],
                ),
                content: SizedBox(
                  width: 520,
                  height: 400,
                  child: allActiveItems.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد تنبيهات نشطة حالياً',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: allActiveItems.length,
                          itemBuilder: (context, index) {
                            final NotificationItem item = allActiveItems[index] as NotificationItem;
                            return Card(
                              color: item.isRead ? const Color(0xFF202020) : const Color(0xFF2D2D2D),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: item.isRead
                                      ? Colors.grey.withValues(alpha: 0.2)
                                      : item.color.withValues(alpha: 0.6),
                                  width: item.isRead ? 1 : 1.5,
                                ),
                              ),
                              child: ListTile(
                                onTap: () async {
                                  if (!item.isRead) {
                                    await markAsRead(item.id);
                                    setStateDialog(() => item.isRead = true);
                                  }
                                  if (item.targetScreen.isNotEmpty && dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                    _navigateToTargetScreen(context, item);
                                  }
                                },
                                leading: CircleAvatar(
                                  backgroundColor: item.color.withValues(alpha: 0.2),
                                  child: Icon(item.icon, color: item.color, size: 20),
                                ),
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: item.isRead ? Colors.white70 : item.color,
                                    fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  item.details,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(item.date, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                        if (item.targetScreen.isNotEmpty)
                                          const Text('فتح السجل ◀',
                                              style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                                      ],
                                    ),
                                    if (!item.isRead)
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline,
                                            color: Colors.greenAccent, size: 20),
                                        tooltip: 'تمييز كمقروء',
                                        onPressed: () async {
                                          await markAsRead(item.id);
                                          setStateDialog(() => item.isRead = true);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('إغلاق', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}