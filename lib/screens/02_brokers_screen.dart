import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../app_data.dart';
import '../services/local_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '01_clients_screen.dart';
import '03_customer_requests_screen.dart';
import '04_for_sale_screen.dart';
import '05_for_rent_screen.dart';
import '06_inspections_screen.dart';
import '07_completed_operations_screen.dart';

class BrokersScreen extends StatefulWidget {
  const BrokersScreen({super.key});

  @override
  State<BrokersScreen> createState() => _BrokersScreenState();
}

class _BrokersScreenState extends State<BrokersScreen> {
  final nameController = TextEditingController();
  final phone1Controller = TextEditingController();
  final phone2Controller = TextEditingController();
  final addressController = TextEditingController();
  final specializationController = TextEditingController();
  final officeNameController = TextEditingController();
  final notesController = TextEditingController();

  final focusName = FocusNode();
  final focusPhone1 = FocusNode();
  final focusPhone2 = FocusNode();
  final focusAddress = FocusNode();
  final focusSpecialization = FocusNode();
  final focusOfficeName = FocusNode();
  final focusNotes = FocusNode();

  @override
  void dispose() {
    nameController.dispose();
    phone1Controller.dispose();
    phone2Controller.dispose();
    addressController.dispose();
    specializationController.dispose();
    officeNameController.dispose();
    notesController.dispose();

    focusName.dispose();
    focusPhone1.dispose();
    focusPhone2.dispose();
    focusAddress.dispose();
    focusSpecialization.dispose();
    focusOfficeName.dispose();
    focusNotes.dispose();
    super.dispose();
  }

  // دالة اختيار جهة اتصال من الهاتف
  Future<void> _pickContact(TextEditingController targetPhoneController) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ميزة اختيار جهات الاتصال متاحة فقط عند تشغيل التطبيق على الهاتف المحمول.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (await FlutterContacts.requestPermission()) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null) {
            setState(() {
              if (nameController.text.trim().isEmpty && fullContact.displayName.isNotEmpty) {
                nameController.text = fullContact.displayName;
              }
              if (fullContact.phones.isNotEmpty) {
                String rawPhone = fullContact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
                if (rawPhone.startsWith('+20')) {
                  rawPhone = rawPhone.replaceFirst('+20', '0');
                } else if (rawPhone.startsWith('20')) {
                  rawPhone = rawPhone.replaceFirst('20', '0');
                }
                targetPhoneController.text = rawPhone;
              }
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم استيراد بيانات جهة الاتصال بنجاح'), backgroundColor: Colors.green),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض صلاحية الوصول إلى جهات الاتصال.'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في استيراد جهة الاتصال: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _saveBroker(BuildContext dialogContext) async {
    String p1 = phone1Controller.text.trim();
    String p2 = phone2Controller.text.trim();

    if (p1.isNotEmpty && p1 != '-' && p1.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: رقم التليفون الأول يجب أن يكون 11 رقماً بالضبط!', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (p2.isNotEmpty && p2 != '-' && p2.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: رقم التليفون الثاني يجب أن يكون 11 رقماً بالضبط!', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    setState(() {
      if (!AppData.storage.containsKey('بيانات السماسرة')) {
        AppData.storage['بيانات السماسرة'] = [];
      }
      AppData.storage['بيانات السماسرة']!.add({
        'إسم السمسار': nameController.text.trim().isEmpty ? '-' : nameController.text.trim(),
        'رقم التليفون 1': p1.isEmpty ? '-' : p1,
        'رقم التليفون 2': p2.isEmpty ? '-' : p2,
        'العنوان / المنطقة': addressController.text.trim().isEmpty ? '-' : addressController.text.trim(),
        'التخصص العقاري': specializationController.text.trim().isEmpty ? '-' : specializationController.text.trim(),
        'إسم المكتب': officeNameController.text.trim().isEmpty ? '-' : officeNameController.text.trim(),
        'تاريخ التسجيل': dateStr,
        'ملاحظات عامة': notesController.text.trim().isEmpty ? '-' : notesController.text.trim(),
      });
    });

    await LocalStorageService.saveLocally();
    CloudSyncService.syncToCloud(isAuto: true);

    Navigator.pop(dialogContext);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ بيانات السمسار ومزامنة البيانات بنجاح'), backgroundColor: Colors.green),
    );
  }

  void _showAddBrokerDialog() {
    nameController.clear();
    phone1Controller.clear();
    phone2Controller.clear();
    addressController.clear();
    specializationController.clear();
    officeNameController.clear();
    notesController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('إضافة سمسار جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  focusNode: focusName,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(focusPhone1),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'إسم السمسار',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF252525),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone1Controller,
                  focusNode: focusPhone1,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(focusPhone2),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'رقم التليفون 1 (11 رقماً)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF252525),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contacts, color: Colors.amberAccent),
                      tooltip: 'اختيار من دليل الهاتف',
                      onPressed: () => _pickContact(phone1Controller),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone2Controller,
                  focusNode: focusPhone2,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(focusAddress),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'رقم التليفون 2 (11 رقماً)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: const Color(0xFF252525),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.contacts, color: Colors.amberAccent),
                      tooltip: 'اختيار من دليل الهاتف',
                      onPressed: () => _pickContact(phone2Controller),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  focusNode: focusAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(focusSpecialization),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'العنوان / المنطقة', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF252525)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specializationController,
                  focusNode: focusSpecialization,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(focusOfficeName),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'التخصص العقاري (بيع / إيجار / أراضي)', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF252525)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: officeNameController,
                  focusNode: focusOfficeName,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(focusNotes),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'إسم المكتب العقاري', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF252525)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  focusNode: focusNotes,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveBroker(dialogContext),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'ملاحظات عامة (اضغط Enter للحفظ)', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF252525)),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء', style: TextStyle(color: Colors.redAccent))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800),
            onPressed: () => _saveBroker(dialogContext),
            child: const Text('حفظ السمسار'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brokersList = AppData.storage['بيانات السماسرة'] ?? [];
    final totalRows = brokersList.length < 15 ? 15 : brokersList.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بيانات السماسرة | منظومة الكابتن لإدارة العقارات', style: TextStyle(fontSize: 16)),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close, size: 22),
              tooltip: 'إغلاق',
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF141414),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.home, color: Colors.amber, size: 26),
                      tooltip: 'الصفحة الرئيسية',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.print, color: Colors.cyanAccent, size: 24),
                      tooltip: 'طباعة التقرير',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري إعداد تقرير السماسرة للطباعة...')),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ClientsScreen()),
                        );
                      },
                      icon: const Icon(Icons.arrow_right_rounded, color: Colors.amberAccent, size: 24),
                      label: const Text('الصفحة السابقة', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const CustomerRequestsScreen()),
                        );
                      },
                      icon: const Icon(Icons.arrow_left_rounded, color: Colors.amberAccent, size: 24),
                      label: const Text('الصفحة التالية', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _showAddBrokerDialog,
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 18),
                      label: const Text('إضافة سجل جديد', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: const Color(0xFF1E1E1E),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientsScreen())),
                      child: const Text('العملاء', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                      onPressed: () {},
                      child: const Text('السماسرة', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomerRequestsScreen())),
                      child: const Text('الطلبات', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ForSaleScreen())),
                      child: const Text('البيع', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ForRentScreen())),
                      child: const Text('الإيجار', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const InspectionsScreen())),
                      child: const Text('المعاينة', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CompletedOperationsScreen())),
                      child: const Text('العمليات', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF181818),
              child: Row(
                children: [
                  const Text('إحصائيات السماسرة:', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade900.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.tealAccent, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('إجمالي السماسرة المسجلين: ', style: TextStyle(color: Colors.white, fontSize: 12)),
                        Text('${brokersList.length}', style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFF2C2C2C)),
                              border: TableBorder.all(color: Colors.grey.shade800, width: 1),
                              columnSpacing: 16,
                              columns: const [
                                DataColumn(label: Text('م', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.tealAccent))),
                                DataColumn(label: Text('إسم السمسار', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('رقم التليفون 1', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('رقم التليفون 2', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('العنوان / المنطقة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('التخصص العقاري', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('إسم المكتب', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('تاريخ التسجيل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('ملاحظات عامة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('حذف', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                              ],
                              rows: List.generate(totalRows, (index) {
                                if (index < brokersList.length) {
                                  Map<String, String> item = brokersList[index];
                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                                      return index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525);
                                    }),
                                    cells: [
                                      DataCell(Text('${index + 1}', style: const TextStyle(color: Colors.tealAccent))),
                                      DataCell(Text(item['إسم السمسار'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataCell(Text(item['رقم التليفون 1'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(item['رقم التليفون 2'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(item['العنوان / المنطقة'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(item['التخصص العقاري'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(item['إسم المكتب'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(item['تاريخ التسجيل'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(item['ملاحظات عامة'] ?? '', style: const TextStyle(color: Colors.white70))),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                                          onPressed: () async {
                                            setState(() {
                                              // 1. التأكد من وجود سلة المهملات
                                              if (!AppData.storage.containsKey('trash_bin') || AppData.storage['trash_bin'] == null) {
                                                AppData.storage['trash_bin'] = <Map<String, String>>[];
                                              }

                                              // 2. إعداد السجل وإضافة اسم الشاشة وتاريخ الحذف
                                              Map<String, String> deletedItem = Map<String, String>.from(brokersList[index]);
                                              final now = DateTime.now();
                                              deletedItem['source_screen'] = 'بيانات السماسرة';
                                              deletedItem['deleted_date'] = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                                              // 3. النقل لسلة المهملات ثم المسح
                                              (AppData.storage['trash_bin'] as List).add(deletedItem);
                                              brokersList.removeAt(index);
                                            });

                                            // 4. حفظ وتزامن تلقائي
                                            await LocalStorageService.saveLocally();
                                            CloudSyncService.syncToCloud(isAuto: true);

                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('تم نقل السمسار إلى سلة المهملات وتحديث السحابة بنجاح'), backgroundColor: Colors.orange),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                                      return index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525);
                                    }),
                                    cells: List.generate(10, (cellIndex) => const DataCell(SizedBox.shrink())),
                                  );
                                }
                              }),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}