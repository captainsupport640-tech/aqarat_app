import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../app_data.dart';
import '../app_storage_manager.dart';
import '../services/local_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/security_manager.dart';
import '02_brokers_screen.dart';
import '03_customer_requests_screen.dart';
import '04_for_sale_screen.dart';
import '05_for_rent_screen.dart';
import '06_inspections_screen.dart';
import '07_completed_operations_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  bool _isLoading = false;

  final nameController = TextEditingController();
  final phone1Controller = TextEditingController();
  final phone2Controller = TextEditingController();
  final currentAddressController = TextEditingController();
  final mainRequestController = TextEditingController();
  final professionController = TextEditingController();
  final notesController = TextEditingController();

  final focusName = FocusNode();
  final focusPhone1 = FocusNode();
  final focusPhone2 = FocusNode();
  final focusAddress = FocusNode();
  final focusRequest = FocusNode();
  final focusProfession = FocusNode();
  final focusNotes = FocusNode();

  @override
  void initState() {
    super.initState();
    _startRealtimeListener();
  }

  void _startRealtimeListener() async {
    String currentEmail = AppStorageManager.currentEmail;
    if (currentEmail.isEmpty) {
      currentEmail = await LocalStorageService.getPersonalGmail();
    }
    
    if (currentEmail.isNotEmpty) {
      AppStorageManager.listenToMasterDatabase(
        companyAdminEmail: currentEmail,
        onDataUpdated: (updatedData) {
          if (mounted) {
            setState(() {
              updatedData.forEach((key, value) {
                if (value != null) {
                  AppData.storage[key] = value;
                }
              });
              _isLoading = false;
            });
          }
        },
      );
    }
  }

  @override
  void dispose() {
    AppStorageManager.stopMasterDatabaseListener();
    nameController.dispose();
    phone1Controller.dispose();
    phone2Controller.dispose();
    currentAddressController.dispose();
    mainRequestController.dispose();
    professionController.dispose();
    notesController.dispose();

    focusName.dispose();
    focusPhone1.dispose();
    focusPhone2.dispose();
    focusAddress.dispose();
    focusRequest.dispose();
    focusProfession.dispose();
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

  void _syncDataToCloud() async {
    String currentEmail = AppStorageManager.currentEmail;
    if (currentEmail.isEmpty) {
      currentEmail = await LocalStorageService.getPersonalGmail();
    }
    if (currentEmail.isNotEmpty) {
      await AppStorageManager.syncMasterDatabase(
        companyAdminEmail: currentEmail,
        currentPhone: AppStorageManager.currentUsername,
        appData: AppData.storage,
      );
    }
  }

  void _saveClient(BuildContext dialogContext) async {
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
      if (!AppData.storage.containsKey('بيانات العملاء') || AppData.storage['بيانات العملاء'] == null) {
        AppData.storage['بيانات العملاء'] = [];
      }
      (AppData.storage['بيانات العملاء'] as List).add({
        'إسم العميل': nameController.text.trim().isEmpty ? '-' : nameController.text.trim(),
        'رقم التليفون 1': p1.isEmpty ? '-' : p1,
        'رقم التليفون 2': p2.isEmpty ? '-' : p2,
        'العنوان الحالي': currentAddressController.text.trim().isEmpty ? '-' : currentAddressController.text.trim(),
        'المطلب الأساسي': mainRequestController.text.trim().isEmpty ? '-' : mainRequestController.text.trim(),
        'تاريخ التسجيل': dateStr,
        'المهنة': professionController.text.trim().isEmpty ? '-' : professionController.text.trim(),
        'ملاحظات عامة': notesController.text.trim().isEmpty ? '-' : notesController.text.trim(),
      });
    });

    await LocalStorageService.saveLocally();
    CloudSyncService.syncToCloud(isAuto: true);
    _syncDataToCloud();

    Navigator.pop(dialogContext);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ العميل ومزامنة البيانات بنجاح'), backgroundColor: Colors.green),
    );
  }

  void _showAddClientDialog() {
    if (!SecurityManager.checkActionPermission(context, actionName: 'إضافة عميل')) return;

    nameController.clear();
    phone1Controller.clear();
    phone2Controller.clear();
    currentAddressController.clear();
    mainRequestController.clear();
    professionController.clear();
    notesController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('إضافة عميل جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
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
                    labelText: 'إسم العميل',
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
                  controller: currentAddressController,
                  focusNode: focusAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(focusRequest),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'العنوان الحالي', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF252525)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mainRequestController,
                  focusNode: focusRequest,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(focusProfession),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'المطلب الأساسي', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF252525)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: professionController,
                  focusNode: focusProfession,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => FocusScope.of(dialogContext).requestFocus(focusNotes),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'المهنة', labelStyle: TextStyle(color: Colors.white70), border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF252525)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  focusNode: focusNotes,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveClient(dialogContext),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
            onPressed: () => _saveClient(dialogContext),
            child: const Text('حفظ العميل'),
          ),
        ],
      ),
    );
  }

  // دالة الحذف الجذرية المؤبدة لجدول العملاء
  Future<void> _deleteClientRecord(int index) async {
    if (!SecurityManager.checkActionPermission(context, actionName: 'حذف عميل')) return;

    final rawList = AppData.storage['بيانات العملاء'];
    if (rawList is! List || index >= rawList.length) return;

    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: const Text('هل تريد حقاً نقل هذا العميل إلى سلة المهملات؟', style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف ونقل للسلة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() {
      if (!AppData.storage.containsKey('trash_bin') || AppData.storage['trash_bin'] == null) {
        AppData.storage['trash_bin'] = [];
      }

      final itemToDelete = rawList[index];
      Map<String, dynamic> deletedItem = itemToDelete is Map ? Map<String, dynamic>.from(itemToDelete) : {};
      final now = DateTime.now();
      deletedItem['source_screen'] = 'بيانات العملاء';
      deletedItem['deleted_date'] = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      (AppData.storage['trash_bin'] as List).add(deletedItem);
      rawList.removeAt(index);
    });

    await LocalStorageService.saveLocally();
    CloudSyncService.syncToCloud(isAuto: true);
    _syncDataToCloud();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نقل العميل إلى سلة المهملات وتحديث السحابة بنجاح'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawList = AppData.storage['بيانات العملاء'];
    final List clientsList = (rawList is List) ? rawList : [];
    final totalRows = clientsList.length < 15 ? 15 : clientsList.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بيانات العملاء | منظومة الكابتن لإدارة العقارات', style: TextStyle(fontSize: 16)),
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
                          const SnackBar(content: Text('جاري إعداد تقرير العملاء للطباعة...')),
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
                      onPressed: () {},
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
                          MaterialPageRoute(builder: (context) => const BrokersScreen()),
                        );
                      },
                      icon: const Icon(Icons.arrow_left_rounded, color: Colors.amberAccent, size: 24),
                      label: const Text('الصفحة التالية', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _showAddClientDialog,
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                      onPressed: () {},
                      child: const Text('العملاء', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BrokersScreen())),
                      child: const Text('السماسرة', style: TextStyle(color: Colors.white, fontSize: 11)),
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
                  const Text('إحصائيات العملاء:', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blueAccent, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('إجمالي العملاء المسجلين: ', style: TextStyle(color: Colors.white, fontSize: 12)),
                        Text('${clientsList.length}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
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
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.amberAccent),
                        )
                      : LayoutBuilder(
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
                                      DataColumn(label: Text('م', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent))),
                                      DataColumn(label: Text('إسم العميل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                      DataColumn(label: Text('رقم التليفون 1', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                      DataColumn(label: Text('رقم التليفون 2', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                      DataColumn(label: Text('العنوان الحالي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                      DataColumn(label: Text('المطلب الأساسي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                      DataColumn(label: Text('تاريخ التسجيل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                      DataColumn(label: Text('المهنة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                      DataColumn(label: Text('ملاحظات عامة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                      DataColumn(label: Text('حذف', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                                    ],
                                    rows: List.generate(totalRows, (index) {
                                      if (index < clientsList.length) {
                                        final rawItem = clientsList[index];
                                        final Map<String, dynamic> item = rawItem is Map ? Map<String, dynamic>.from(rawItem) : {};

                                        return DataRow(
                                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                                            return index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525);
                                          }),
                                          cells: [
                                            DataCell(Text('${index + 1}', style: const TextStyle(color: Colors.cyanAccent))),
                                            DataCell(Text(item['إسم العميل']?.toString() ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                            DataCell(Text(item['رقم التليفون 1']?.toString() ?? '-', style: const TextStyle(color: Colors.white))),
                                            DataCell(Text(item['رقم التليفون 2']?.toString() ?? '-', style: const TextStyle(color: Colors.white))),
                                            DataCell(Text(item['العنوان الحالي']?.toString() ?? '-', style: const TextStyle(color: Colors.white))),
                                            DataCell(Text(item['المطلب الأساسي']?.toString() ?? '-', style: const TextStyle(color: Colors.white))),
                                            DataCell(Text(item['تاريخ التسجيل']?.toString() ?? '-', style: const TextStyle(color: Colors.white))),
                                            DataCell(Text(item['المهنة']?.toString() ?? '-', style: const TextStyle(color: Colors.white))),
                                            DataCell(Text(item['ملاحظات عامة']?.toString() ?? '-', style: const TextStyle(color: Colors.white70))),
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                                                tooltip: 'حذف العميل',
                                                onPressed: () => _deleteClientRecord(index),
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