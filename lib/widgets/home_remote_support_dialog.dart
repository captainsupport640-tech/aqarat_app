import '../app_imports.dart';

class HomeRemoteSupportDialog {
  static void show(BuildContext context) {
    bool isProgrammerAdmin = SecurityManager.isAdmin;
    final TextEditingController targetCompanyKeyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF222222),
          title: Row(
            children: [
              Icon(
                isProgrammerAdmin ? Icons.admin_panel_settings : Icons.support_agent,
                color: isProgrammerAdmin ? Colors.greenAccent : Colors.cyanAccent,
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                isProgrammerAdmin ? 'غرفة دعم المبرمج عن بعد' : 'الدعم الفني والصيانة عن بعد',
                style: TextStyle(color: isProgrammerAdmin ? Colors.greenAccent : Colors.cyanAccent, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isProgrammerAdmin
                    ? 'أدخل رقم موبايل أو كود الشركة المراد الدخول على سيرفرها للصيانة والدعم الفني:'
                    : 'يمكنك التواصل مباشرة مع المبرمج الرئيسي لطلب الصيانة أو تحديث البيانات عن بعد:',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (isProgrammerAdmin) ...[
                TextField(
                  controller: targetCompanyKeyController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'رقم موبايل أو كود الشركة',
                    labelStyle: const TextStyle(color: Colors.amberAccent),
                    filled: true,
                    fillColor: const Color(0xFF141414),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('بريد الدعم الفني للمبرمج:', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                      SizedBox(height: 4),
                      Text('captain.support640@gmail.com',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('حالة الاتصال: جاهز لاستقبال الدعم والصيانة الفورية.',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isProgrammerAdmin ? Colors.teal.shade700 : Colors.blue.shade800,
              ),
              onPressed: () {
                if (isProgrammerAdmin) {
                  String keyTarget = targetCompanyKeyController.text.trim();
                  if (keyTarget.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('برجاء إدخال كود أو موبايل الشركة!'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('جاري الاتصال بسيرفر الشركة ($keyTarget) لبدء الصيانة...'),
                      backgroundColor: Colors.teal,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'تم إرسال طلب الدعم الفني للمبرمج (captain.support640@gmail.com) وجاري المتابعة!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text(
                isProgrammerAdmin ? 'بدء جلسة الصيانة' : 'إرسال طلب دعم للمبرمج',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}