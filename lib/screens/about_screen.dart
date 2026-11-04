import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // نافذة لعرض تفاصيل الشرح الخاصة بكل قسم
  void _showGuideDetails(BuildContext context, String title, List<String> steps) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: const Color(0xFF1E1E1E),
          title: Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: steps.map((step) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.cyanAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('حسناً، فهمت', style: TextStyle(color: Colors.cyanAccent, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حول المنظومة وشرح العمل'),
          centerTitle: true,
          backgroundColor: const Color(0xFF1E1E1E),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- بطاقة التعريف بالبرنامج والدعم الفني ---
              Card(
                elevation: 4,
                color: const Color(0xFF252525),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.blueAccent.withOpacity(0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_city,
                        size: 65,
                        color: Colors.cyanAccent,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'منظومة الكابتن للتسويق العقاري',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade800,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'الإصدار: 1.0.0 (السحابي المركزي)',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const Divider(height: 25, color: Colors.grey),
                      const Text(
                        'للتواصل والدعم الفني والترخيص:',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      // رقم التليفون
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.phone, color: Colors.greenAccent, size: 20),
                          SizedBox(width: 8),
                          SelectableText(
                            '01200626469',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // إيميل الدعم الفني الرئيسي
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.email, color: Colors.cyanAccent, size: 20),
                          SizedBox(width: 8),
                          SelectableText(
                            'captain.support640@gmail.com',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // --- عنوان قسم دليل الشرح ---
              Row(
                children: const [
                  Icon(Icons.help_outline, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'دليل طريقة العمل وشرح البرنامج تفصيلياً',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- 1. قسم إدارة العقارات والطلبات ---
              _buildInteractiveStepCard(
                context,
                stepNumber: '1',
                title: 'إدارة العقارات والطلبات والمعاينة',
                subtitle: 'اضغط لقراءة شرح إضافة العملاء، السماسرة، الطلبات، الواتساب والعمليات',
                icon: Icons.home_work_outlined,
                onTap: () {
                  _showGuideDetails(
                    context,
                    'دليل إدارة العقارات والطلبات',
                    [
                      'بيانات العملاء: الضغط على "إضافة سجل جديد"، إدخال اسم العميل، أرقام التليفونات، العنوان، المطلب، والمهنة ثم الضغط على "حفظ".',
                      'بيانات السماسرة: الضغط على "إضافة سمسار"، إدخال الاسم والأرقام والعنوان ثم الضغط على "حفظ". (يجب الحفظ بعد كل عملية).',
                      'طلبات العملاء: إدخال طلب جديد باختيار العميل من القائمة المنسدلة، تحديد نوع العملية، نوع العقار، وحدة القياس (متر/قيراط/فدان)، الميزانية، المساحة والملاحظات.',
                      'المطابقة الآلية: عند اختيار حالة المعروض والعقارات المطابقة، يتم عرض العقارات المطابقة تلقائياً من شيت البيع أو الإيجار.',
                      'تحليل رسائل الواتساب: نسخ نص رسالة الواتساب ووضعها في المربع المخصص ليتم تحليل واستخراج البيانات تلقائياً.',
                      'المعروض للبيع والإيجار: إضافة العقارات عبر زر "إضافة عقار جديد" بنفس الآلية ببيانات دقيقة.',
                      'المعاينة والعمليات: في شيت الطلبات يحدد مربع المعاينة لنقل الطلب مباشرة لشيت المعايانات، ثم تحديد قرار العميل بنقله للعمليات المكتملة والحسابات والأرشيف.',
                    ],
                  );
                },
              ),

              // --- 2. قسم المطابقة والبحث الذكي ---
              _buildInteractiveStepCard(
                context,
                stepNumber: '2',
                title: 'المطابقة والبحث الذكي والتصفية',
                subtitle: 'اضغط لقراءة شرح البحث الفوري بالتليفون أو الكود والتصفية بالتقرير',
                icon: Icons.search,
                onTap: () {
                  _showGuideDetails(
                    context,
                    'دليل المطابقة والبحث الذكي',
                    [
                      'البحث الفوري من الشاشة الرئيسية: اكتب أي معلومة (رقم الموبايل - كود الوحدة - اسم العميل أو السمسار) ليظهر الناتج فورياً.',
                      'التصفية في شاشات العرض: إمكانية تصفية العقارات والطلبات في شاشات البيع والإيجار والطلبات بحسب نوع العقار بسهولة.',
                      'التقرير العام والأرشيف: البحث والتصفية بحسب الشهر أو السنة، مع إمكانية البحث المباشر في سجلات الأرشيف بأي بيانات.',
                    ],
                  );
                },
              ),

              // --- 3. قسم النسخ الاحتياطي والترخيص ---
              _buildInteractiveStepCard(
                context,
                stepNumber: '3',
                title: 'النسخ الاحتياطي وتفعيل الترخيص المحلي',
                subtitle: 'اضغط لقراءة شرح أخذ النسخ الاحتياطية وتفعيل التجربة والتحديث',
                icon: Icons.security,
                onTap: () {
                  _showGuideDetails(
                    context,
                    'دليل النسخ الاحتياطي والتفعيل',
                    [
                      'النسخ الاحتياطي: الضغط على "نسخ محلي" أو عبر شبكة WiFi لعمل نسخة احتياطية لحماية البيانات.',
                      'استعادة البيانات: الضغط على زر "استعادة البيانات" واختيار الملف لاسترجاع بياناتك بكل سهولة.',
                      'تفعيل التجربة (30 يوماً): من قائمة الإعدادات أعلى اليسار يتم اختيار كود الجهاز لتفعيل الفترة التجريبية.',
                      'التفعيل السنوي أو مدى الحياة: نسخ كود الجهاز عبر زر النسخ المباشر، وإرساله للدعم الفني لتلقي كود التفعيل.',
                    ],
                  );
                },
              ),

              // --- 4. قسم كيفية تفعيل والعمل على السحابة (منفصل) ---
              _buildInteractiveStepCard(
                context,
                stepNumber: '4',
                title: 'كيفية التفعيل والتشغيل على السحابة المركزية',
                subtitle: 'اضغط لقراءة خطوات ربط شركتك بالمنظومة السحابية وعزل البيانات',
                icon: Icons.cloud_done,
                onTap: () {
                  _showGuideDetails(
                    context,
                    'دليل تفعيل والتشغيل على السحابة',
                    [
                      'رابط التشغيل السحابي: يمكنك الوصول للمنظومة وتشغيلها مباشرة عبر المتصفح من خلال الرابط: https://captain-real-estate-system.web.app',
                      'تسجيل إيميل الشركة (Tenant ID): عند فتح النظام سحابياً، قم بإدخال إيميل الشركة الرئيسي الخاص بك ليكون هو المعرّف الموحد.',
                      'عزل البيانات الفوري: يضمن النظام إنشاء مسار سحابي خاص ومستقل لبيانات شركتك وحدك تماماً وبشكل آمن بالكامل.',
                      'المزامنة وإدارة الدعم: يتم حفظ ومزامنة العمليات لحظياً (Realtime Cloud Sync)، وللتواصل والمتابعة الفنية يعتمد إيميل الماستر: captain.support640@gmail.com',
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت مخصصة للكروت التفاعلية
  Widget _buildInteractiveStepCard(
      BuildContext context, {
        required String stepNumber,
        required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: const Color(0xFF222222),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.cyanAccent.withOpacity(0.2)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent.withOpacity(0.2),
          child: Text(
            stepNumber,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ),
        trailing: Icon(icon, color: Colors.cyanAccent),
      ),
    );
  }
}