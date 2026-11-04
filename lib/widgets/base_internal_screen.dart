import 'package:flutter/material.dart';
import '../screens/01_clients_screen.dart';
import '../screens/02_brokers_screen.dart';
import '../screens/03_customer_requests_screen.dart';
import '../screens/04_for_sale_screen.dart';
import '../screens/05_for_rent_screen.dart';
import '../screens/06_inspections_screen.dart';
import '../screens/07_completed_operations_screen.dart';
import '../screens/08_accounts_screen.dart';
import '../screens/09_general_report_screen.dart';

class BaseInternalScreen extends StatelessWidget {
  final String screenTitle;
  final Widget childContent;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onAdd;

  const BaseInternalScreen({
    super.key,
    required this.screenTitle,
    required this.childContent,
    required this.onAdd,
    this.onPrevious,
    this.onNext,
  });

  void _navigateTo(BuildContext context, String title) {
    String cleanTitle = title.replaceAll('\n', ' ').trim();

    if (cleanTitle.contains('العملاء') && !cleanTitle.contains('طلبات') && !cleanTitle.contains('المعاينات')) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientsScreen()));
    } else if (cleanTitle.contains('السماسرة')) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BrokersScreen()));
    } else if (cleanTitle.contains('طلبات')) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomerRequestsScreen()));
    } else if (cleanTitle.contains('المعروض للبيع')) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ForSaleScreen()));
    } else if (cleanTitle.contains('المعروض للإيجار')) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ForRentScreen()));
    } else if (cleanTitle.contains('المعاينات')) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const InspectionsScreen()));
    } else if (cleanTitle.contains('العمليات التامة')) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CompletedOperationsScreen()));
    } else if (cleanTitle.contains('الحسابات')) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AccountsScreen()));
    } else if (cleanTitle.contains('التقرير العام')) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GeneralReportScreen()));
    }
  }

  Widget _buildHeaderButton(String title, Color defaultColor, VoidCallback onTap) {
    String cleanTitle = title.replaceAll('\n', ' ');
    bool isActive = screenTitle == cleanTitle;
    return SizedBox(
      width: 70,
      height: 42,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.red.shade700 : defaultColor,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: isActive ? Colors.yellow : Colors.white, width: isActive ? 2 : 1),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: isActive ? 11 : 10,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text('$screenTitle | منظومة الكابتن لإدارة العقارات', style: const TextStyle(color: Colors.white, fontSize: 14)),
          backgroundColor: const Color(0xFF1E293B),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildHeaderButton('الصفحة\nالرئيسية', Colors.orange.shade800, () => Navigator.pop(context)),
                          const SizedBox(width: 6),
                          _buildHeaderButton('طلبات\nالعملاء', Colors.orange.shade700, () => _navigateTo(context, 'طلبات\nالعملاء')),
                          const SizedBox(width: 6),
                          _buildHeaderButton('المعروض\nللبيع', Colors.blue.shade700, () => _navigateTo(context, 'المعروض\nللبيع')),
                          const SizedBox(width: 6),
                          _buildHeaderButton('المعروض\nللإيجار', Colors.orange.shade600, () => _navigateTo(context, 'المعروض\nللإيجار')),
                          const SizedBox(width: 6),
                          _buildHeaderButton('المعاينات\nوالعملاء', Colors.green.shade600, () => _navigateTo(context, 'المعاينات\nوالعملاء')),
                          const SizedBox(width: 6),
                          _buildHeaderButton('بيانات\nالسماسرة', Colors.grey.shade800, () => _navigateTo(context, 'بيانات\nالسماسرة')),
                          const SizedBox(width: 6),
                          _buildHeaderButton('بيانات\nالعملاء', Colors.blue.shade800, () => _navigateTo(context, 'بيانات\nالعملاء')),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: onAdd,
                            icon: const Icon(Icons.add_circle, color: Colors.white, size: 20),
                            label: const Text('إضافة سجل جديد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: onPrevious ?? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا هو الشيت الأول'))),
                            icon: const Icon(Icons.arrow_back, size: 26, color: Colors.cyanAccent),
                            tooltip: 'السابق',
                          ),
                          IconButton(
                            onPressed: onNext ?? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هذا هو الشيت الأخير'))),
                            icon: const Icon(Icons.arrow_forward, size: 26, color: Colors.cyanAccent),
                            tooltip: 'التالي',
                          ),
                          const SizedBox(width: 5),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('طباعة'),
                                  content: Text('جاري تجهيز وثيقة الطباعة لشيت ($screenTitle)...'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.print, size: 30, color: Colors.white),
                            tooltip: 'طباعة',
                          ),
                          const SizedBox(width: 5),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.home, color: Colors.amber, size: 32),
                            tooltip: 'الرئيسية',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(child: childContent),
            ],
          ),
        ),
      ),
    );
  }
}

