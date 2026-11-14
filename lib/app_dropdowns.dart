import 'package:flutter/material.dart';
import 'app_data.dart';

class AppDropdowns {
  static const List<String> interestStatuses = [
    'مهتم جداً',
    'متابعة',
    'عميل محتمل',
    'تم التنفيذ',
    'غير مهتم'
  ];

  static const List<String> propertyTypes = [
    'منزل كامل',
    'منزل جديد',
    'منزل قديم',
    'فيلا',
    'مكتب',
    'محل',
    'شقة سكنية',
    'شقة إداري',
    'شقة استثمارية',
    'مخزن',
    'جراج',
    'شاليه',
    'أرض فضاء',
    'أرض زراعية',
    'أرض مباني',
    'أرض مخللات',
    'أرض استثماري'
  ];

  // قائمة البلاد والمدن والأماكن بالترتيب المطلوب
  static const List<String> locations = [
    'مركز زفتي',
    'نهطاي',
    'ميت غمر',
    'كفر عنان',
    'الحاجبي',
    'كوبري العشرة',
    'ترعه الشرخ',
    'خلف السكة الحديد',
    'الجزيرة',
    'كفر الجنيدي',
    'الأسكندرية',
    'سنبو',
    'القاهرة',
    'أماكن مختلفة'
  ];

  static const List<String> operationTypes = [
    'شراء',
    'إيجار',
    'إيجار مفروش',
    'بيع',
    'تنازل',
    'بدل'
  ];

  static const List<String> measurementUnits = [
    'متر',
    'قيراط',
    'سهم',
    'فدان'
  ];

  static const List<String> budgetOptions = [
    'أقل من 100 ألف',
    '100 ألف',
    '200 ألف',
    '300 ألف',
    '400 ألف',
    '500 ألف (نص مليون)',
    '750 ألف',
    '1 مليون',
    '1.5 مليون',
    '2 مليون',
    '3 مليون',
    '4 مليون',
    '5 مليون',
    '10 مليون فأكثر'
  ];

  // قوائم المصروفات والحسابات الجديدة
  static const List<String> expenseCategories = [
    'إيجار مكتب',
    'فاتورة كهرباء',
    'فاتورة إنترنت',
    'فاتورة مياه',
    'أجور موظفين',
    'ضيافة وبوفيه',
    'مواصلات ونثريات',
    'صيانة وإصلاحات',
    'منوع'
  ];

  static const List<String> revenueCategories = [
    'عمولة بيع',
    'عمولة إيجار',
    'أخرى'
  ];

  static List<String> getClientNames() {
    final clients = AppData.storage['بيانات العملاء'] ?? AppData.storage['العملاء'] ?? [];
    if (clients.isEmpty) {
      return ['لا توجد عملاء مسجلة'];
    }
    return clients
        .map<String>((c) => c['إسم العميل'] ?? c['اسم العميل'] ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static Widget buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    String safeValue = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF252525),
      ),
      dropdownColor: const Color(0xFF2C2C2C),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}