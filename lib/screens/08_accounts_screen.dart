import 'package:flutter/material.dart';
import '../app_data.dart';
import '../app_dropdowns.dart';
import '../services/local_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../app_storage_manager.dart';
import '01_clients_screen.dart';
import '02_brokers_screen.dart';
import '03_customer_requests_screen.dart';
import '04_for_sale_screen.dart';
import '05_for_rent_screen.dart';
import '06_inspections_screen.dart';
import '07_completed_operations_screen.dart';
import '09_general_report_screen.dart';
import '10_archive_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
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
            });
          }
        },
      );
    }
  }

  @override
  void dispose() {
    AppStorageManager.stopMasterDatabaseListener();
    super.dispose();
  }  
  void _showAddExpenseDialog() {
    String selectedExpenseCategory = AppDropdowns.expenseCategories.first;
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    void saveExpense(BuildContext dialogContext) async {
      if (amountController.text.trim().isNotEmpty) {
        final now = DateTime.now();
        final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        setState(() {
          if (!AppData.storage.containsKey('المصروفات') || AppData.storage['المصروفات'] == null) {
            AppData.storage['المصروفات'] = [];
          }
          (AppData.storage['المصروفات'] as List).add({
            'التاريخ': dateStr,
            'البيان': selectedExpenseCategory,
            'المصروفات': amountController.text.trim(),
            'ملاحظات': notesController.text.trim(),
          });
        });

        await LocalStorageService.saveLocally();
        CloudSyncService.syncToCloud(isAuto: true);

        Navigator.pop(dialogContext);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ ومزامنة المصروف سحابياً بنجاح'), backgroundColor: Colors.green),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('إضافة مصروف جديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppDropdowns.buildDropdownField(
                  label: 'بيان المصروف / البند',
                  value: selectedExpenseCategory,
                  items: AppDropdowns.expenseCategories,
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedExpenseCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'قيمة المصروف',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF252525),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => saveExpense(context),
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF252525),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.redAccent))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
              onPressed: () => saveExpense(context),
              child: const Text('حفظ المصروف'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    String reminderCategory = 'إيجار شهري';
    
    final now = DateTime.now();
    String reminderDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final List<String> reminderTypes = [
      'إيجار شهري',
      'فواتير كهرباء',
      'فواتير مياه',
      'أجور ومرتبات الموظفين',
      'صيانة دورية',
      'أخرى'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.notification_add, color: Colors.amberAccent, size: 24),
                SizedBox(width: 8),
                Text('إضافة تذكير مالي جديد', style: TextStyle(color: Colors.white, fontSize: 15)),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: reminderCategory,
                      dropdownColor: const Color(0xFF2C2C2C),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'نوع التذكير / الالتزام',
                        labelStyle: TextStyle(color: Colors.amberAccent),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFF252525),
                      ),
                      items: reminderTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => reminderCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'عنوان التذكير (مثال: إيجار المقر الرئيسي)',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFF252525),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المتوقع (اختياري)',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFF252525),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('تاريخ الاستحقاق: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reminderDate,
                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2025),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                reminderDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                          child: const Text('تغيير التاريخ', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
                onPressed: () async {
                  String title = titleController.text.trim();
                  if (title.isEmpty) title = reminderCategory;

                  setState(() {
                    if (!AppData.storage.containsKey('التذكيرات المالية') || AppData.storage['التذكيرات المالية'] == null) {
                      AppData.storage['التذكيرات المالية'] = [];
                    }

                    List reminders = AppData.storage['التذكيرات المالية'] as List;
                    reminders.add({
                      'العنوان': title,
                      'النوع': reminderCategory,
                      'المبلغ': amountController.text.trim().isEmpty ? '-' : amountController.text.trim(),
                      'التاريخ': reminderDate,
                      'الحالة': 'نشط',
                    });
                  });

                  await LocalStorageService.saveLocally();
                  CloudSyncService.syncToCloud(isAuto: true);

                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إضافة التذكير المالي بنجاح وسيدخل ضمن تنبيهات النظام'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text('حفظ التذكير', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List accountsRows = [];

    List rawCompleted = AppData.storage['العمليات التامة'] ?? [];
    for (var op in rawCompleted) {
      if (op is Map) {
        Map<String, String> item = Map<String, String>.from(op);
        bool isAccountOnly = (item['isAccountOnly'] ?? 'true') == 'true';
        if (isAccountOnly) {
          double price = double.tryParse(item['سعر التعاقد النهائي'] ?? '0') ?? 0;
          double commRate = double.tryParse((item['نسبة العمولة'] ?? '2.5').replaceAll('%', '').trim()) ?? 2.5;
          double commission = price * (commRate / 100.0);

          accountsRows.add({
            'التاريخ': item['تاريخ العقد'] ?? '',
            'البيان': 'عمولة (${item['كود الوحدة'] ?? ''}) - ${item['إسم المشتري'] ?? ''}',
            'نوع العملية': item['نوع العملية (بيع / إيجار)'] ?? 'بيع',
            'الدخل': commission.toStringAsFixed(0),
            'المصروفات': '0',
            'ملاحظات': 'ترحيل تلقائي من العمليات المكتملة',
          });
        }
      }
    }

    List rawArchived = AppData.storage['أرشيف العمليات'] ?? [];
    for (var op in rawArchived) {
      if (op is Map) {
        Map<String, String> item = Map<String, String>.from(op);
        bool isAccountOnly = (item['isAccountOnly'] ?? 'true') == 'true';
        if (isAccountOnly) {
          double price = double.tryParse(item['سعر التعاقد النهائي'] ?? '0') ?? 0;
          double commRate = double.tryParse((item['نسبة العمولة'] ?? '2.5').replaceAll('%', '').trim()) ?? 2.5;
          double commission = price * (commRate / 100.0);

          accountsRows.add({
            'التاريخ': item['تاريخ العقد'] ?? '',
            'البيان': 'عمولة أرشيف (${item['كود الوحدة'] ?? ''}) - ${item['إسم المشتري'] ?? ''}',
            'نوع العملية': item['نوع العملية (بيع / إيجار)'] ?? 'بيع',
            'الدخل': commission.toStringAsFixed(0),
            'المصروفات': '0',
            'ملاحظات': 'من الأرشيف والعمليات',
          });
        }
      }
    }

    List rawExpenses = AppData.storage['المصروفات'] ?? [];
    for (var exp in rawExpenses) {
      if (exp is Map) {
        Map<String, String> item = Map<String, String>.from(exp);
        accountsRows.add({
          'التاريخ': item['التاريخ'] ?? '',
          'البيان': item['البيان'] ?? '',
          'نوع العملية': 'مصروفات',
          'الدخل': '0',
          'المصروفات': item['المصروفات'] ?? '0',
          'ملاحظات': item['ملاحظات'] ?? '',
        });
      }
    }

    List rawReminders = AppData.storage['التذكيرات المالية'] ?? [];
    for (var rem in rawReminders) {
      if (rem is Map) {
        Map<String, String> item = Map<String, String>.from(rem);
        String status = item['الحالة'] ?? 'نشط';
        if (status == 'نشط') {
          accountsRows.add({
            'التاريخ': item['التاريخ'] ?? '',
            'البيان': 'تذكير: ${item['العنوان'] ?? ''} (${item['النوع'] ?? ''})',
            'نوع العملية': 'تذكير مالي',
            'الدخل': '0',
            'المصروفات': item['المبلغ'] ?? '0',
            'ملاحظات': 'مستحق الدفع - تذكير مالي',
          });
        }
      }
    }

    final totalRows = accountsRows.length < 15 ? 15 : accountsRows.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الحسابات والخزينة | منظومة الكابتن لإدارة العقارات', style: TextStyle(fontSize: 16)),
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
                      tooltip: 'طباعة التقرير الفعلي',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري طباعة تقرير الحسابات الحالي...'), backgroundColor: Colors.cyan),
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
                          MaterialPageRoute(builder: (context) => const CompletedOperationsScreen()),
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
                          MaterialPageRoute(builder: (context) => const GeneralReportScreen()),
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
                      onPressed: _showAddExpenseDialog,
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: const Text('إضافة مصروف جديد', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade900,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _showAddReminderDialog,
                      icon: const Icon(Icons.notification_add, color: Colors.white, size: 18),
                      label: const Text('إضافة تذكير', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ArchiveScreen()),
                        );
                      },
                      icon: const Icon(Icons.archive, color: Colors.white, size: 14),
                      label: const Text('الأرشيف', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                      onPressed: () {},
                      child: const Text('الحسابات', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GeneralReportScreen())),
                      child: const Text('التقرير', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
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
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
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
                              columnSpacing: 20,
                              columns: const [
                                DataColumn(label: Text('م', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent))),
                                DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('البيان / بند المصروف', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                                DataColumn(label: Text('نوع العملية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('الدخل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                                DataColumn(label: Text('المصروفات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                                DataColumn(label: Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70))),
                              ],
                              rows: List.generate(totalRows, (index) {
                                if (index < accountsRows.length) {
                                  Map<String, String> row = accountsRows[index];
                                  double income = double.tryParse(row['الدخل'] ?? '0') ?? 0;
                                  double expense = double.tryParse(row['المصروفات'] ?? '0') ?? 0;

                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                                      return index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525);
                                    }),
                                    cells: [
                                      DataCell(Text('${index + 1}', style: const TextStyle(color: Colors.cyanAccent))),
                                      DataCell(Text(row['التاريخ'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(row['البيان'] ?? '', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))),
                                      DataCell(Text(row['نوع العملية'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(income > 0 ? income.toStringAsFixed(0) : '-', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                                      DataCell(Text(expense > 0 ? expense.toStringAsFixed(0) : '-', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                                      DataCell(Text(row['ملاحظات'] ?? '', style: const TextStyle(color: Colors.white70))),
                                    ],
                                  );
                                } else {
                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                                      return index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525);
                                    }),
                                    cells: List.generate(7, (cellIndex) => const DataCell(SizedBox.shrink())),
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