import '../app_imports.dart';

class HomeNotificationsDialog {
  static void show(BuildContext context) {
    final storedNotifications = AppData.storage['الإشعارات'] ?? [];
    final storedInspections = AppData.storage['المعاينات'] ?? [];
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr =
        "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

    List<String> todayAlerts = [];
    List<String> tomorrowAlerts = [];
    List<String> upcomingAlerts = [];

    final weekDaysNames = {
      1: 'الإثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };

    for (var item in storedInspections) {
      String dateStr = (item['التاريخ'] ?? '').toString().trim();
      String clientName = (item['اسم العميل'] ?? item['اسم المشتري'] ?? 'عميل').toString();
      String unitCode = (item['كود الوحدة'] ?? '').toString();
      String status = (item['حالة المعاينة'] ?? 'قيد الانتظار').toString();

      if (status == 'تمت' || status == 'ملغاة') continue;

      if (dateStr == todayStr) {
        todayAlerts.add('• وحدة ($unitCode) مع العميل ($clientName) - اليوم!');
      } else if (dateStr == tomorrowStr) {
        tomorrowAlerts.add('• وحدة ($unitCode) مع العميل ($clientName) - غداً!');
      } else {
        try {
          DateTime parsedDate = DateTime.parse(dateStr);
          String dayName = weekDaysNames[parsedDate.weekday] ?? dateStr;
          if (parsedDate.isAfter(now) && parsedDate.difference(now).inDays <= 7) {
            upcomingAlerts.add('• يوم $dayName القادم ($dateStr): وحدة ($unitCode) مع ($clientName)');
          }
        } catch (_) {}
      }
    }

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.amberAccent, size: 24),
              SizedBox(width: 8),
              Text(
                'إشعارات وتنبيهات السيستم',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (todayAlerts.isNotEmpty || tomorrowAlerts.isNotEmpty || upcomingAlerts.isNotEmpty) ...[
                    const Text(
                      '📅 تنبيهات المعاينات القادمة:',
                      style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    if (todayAlerts.isNotEmpty) ...[
                      const Text(
                        'معاينات اليوم:',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      ...todayAlerts.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 2),
                          child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 12)))),
                      const SizedBox(height: 6),
                    ],
                    if (tomorrowAlerts.isNotEmpty) ...[
                      const Text(
                        'معاينات الغد (خلال 24 ساعة):',
                        style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      ...tomorrowAlerts.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 2),
                          child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 12)))),
                      const SizedBox(height: 6),
                    ],
                    if (upcomingAlerts.isNotEmpty) ...[
                      const Text(
                        'معاينات الأسبوع القادم:',
                        style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      ...upcomingAlerts.map((e) => Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 2),
                          child: Text(e, style: const TextStyle(color: Colors.white70, fontSize: 12)))),
                    ],
                    const Divider(color: Colors.grey, height: 20),
                  ],
                  const Text(
                    '🔔 إشعارات الإدارة والسيستم:',
                    style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  storedNotifications.isEmpty
                      ? const Text('لا توجد إشعارات عامة حالياً',
                          style: TextStyle(color: Colors.white70, fontSize: 12))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: storedNotifications.length,
                          itemBuilder: (context, index) {
                            final notif = Map<String, dynamic>.from(storedNotifications[index] as Map);
                            return Card(
                              color: const Color(0xFF1E1E1E),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.notifications, color: Colors.cyanAccent, size: 20),
                                title: Text(notif['العنوان'] ?? notif['title'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                subtitle: Text(notif['التفاصيل'] ?? notif['body'] ?? '',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                trailing: Text(notif['التاريخ'] ?? notif['time'] ?? '',
                                    style: const TextStyle(color: Colors.grey, fontSize: 9)),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}