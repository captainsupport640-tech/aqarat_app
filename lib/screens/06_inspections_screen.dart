import '../app_imports.dart';

class InspectionsScreen extends StatefulWidget {
  const InspectionsScreen({super.key});

  @override
  State<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends State<InspectionsScreen> {
  final List inspectionStatusOptions = [
    'تحت المعاينة',
    'تمت',
    'تأجلت',
    'مرفوضة',
  ];

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

  Color _getRowColorByStatus(String status) {
    switch (status) {
      case 'تحت المعاينة':
        return Colors.amber.shade900.withOpacity(0.6);
      case 'تمت':
        return Colors.green.shade900.withOpacity(0.6);
      case 'تأجلت':
      case 'مرفوضة':
        return Colors.red.shade900.withOpacity(0.6);
      default:
        return Colors.grey.shade900.withOpacity(0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AppData.storage.containsKey('المعاينات') || AppData.storage['المعاينات'] == null) {
      AppData.storage['المعاينات'] = [];
    }

    List storedInspections = AppData.storage['المعاينات'] as List;
    List masterInspections = [];
    for (var item in storedInspections) {
      if (item is Map) {
        masterInspections.add(Map<String, String>.from(item));
      }
    }

    final totalRows = masterInspections.length < 15 ? 15 : masterInspections.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const CustomScreenAppBar(title: 'المعاينات'),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
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
                        columnSpacing: 14,
                        columns: const [
                          DataColumn(
                              label:
                                  Text('م', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent))),
                          DataColumn(
                              label: Text('كود الوحدة',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          DataColumn(
                              label: Text('تاريخ المعاينة',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                          DataColumn(
                              label: Text('إسم المشتري',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          DataColumn(
                              label: Text('نوع العملية',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                          DataColumn(
                              label: Text('نوع العقار',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          DataColumn(
                              label: Text('السعر المعروض للبيع أو الإيجار',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          DataColumn(
                              label: Text('رأى المشتري (يدوى)',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                          DataColumn(
                              label: Text('إسم المالك',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          DataColumn(
                              label: Text('حالة المعاينة (قرار العميل)',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent))),
                          DataColumn(
                              label:
                                  Text('ملاحظات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          DataColumn(
                              label:
                                  Text('حذف', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                        ],
                        rows: List.generate(totalRows, (index) {
                          if (index < masterInspections.length) {
                            Map item = masterInspections[index];

                            String currentStatus = item['حالة المعاينة'] ?? 'تحت المعاينة';
                            if (!inspectionStatusOptions.contains(currentStatus)) {
                              currentStatus = 'تحت المعاينة';
                            }

                            final rowColor = _getRowColorByStatus(currentStatus);

                            return DataRow(
                              color: WidgetStateProperty.all(rowColor),
                              cells: [
                                DataCell(Text('${index + 1}', style: const TextStyle(color: Colors.cyanAccent))),
                                DataCell(Text(item['كود الوحدة'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                DataCell(
                                  TextFormField(
                                    initialValue: item['التاريخ'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'اكتب التاريخ...',
                                      hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                    onChanged: (val) async {
                                      item['التاريخ'] = val;
                                      await LocalStorageService.saveLocally();
                                      CloudSyncService.syncToCloud(isAuto: true);
                                    },
                                  ),
                                ),
                                DataCell(Text(item['إسم المشتري'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                DataCell(Text(item['نوع العملية'] ?? 'شراء',
                                    style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))),
                                DataCell(
                                    Text(item['نوع العقار'] ?? '', style: const TextStyle(color: Colors.white))),
                                DataCell(
                                    Text(item['السعر المعروض'] ?? '', style: const TextStyle(color: Colors.white))),
                                DataCell(
                                  TextFormField(
                                    initialValue: item['رأى المشتري'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'اكتب رأي المشتري...',
                                      hintStyle: TextStyle(color: Colors.white38),
                                    ),
                                    onChanged: (val) async {
                                      item['رأى المشتري'] = val;
                                      await LocalStorageService.saveLocally();
                                      CloudSyncService.syncToCloud(isAuto: true);
                                    },
                                  ),
                                ),
                                DataCell(Text(item['إسم المالك'] ?? '', style: const TextStyle(color: Colors.white))),
                                DataCell(
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: currentStatus,
                                      dropdownColor: const Color(0xFF2C2C2C),
                                      style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      items: inspectionStatusOptions.map((status) {
                                        return DropdownMenuItem<String>(
                                          value: status.toString(),
                                          child: Text(status.toString(),
                                              style:
                                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        );
                                      }).toList(),
                                      onChanged: (newVal) async {
                                        if (newVal != null) {
                                          setState(() {
                                            item['حالة المعاينة'] = newVal;
                                            String unitCode = (item['كود الوحدة'] ?? '').toString().trim();
                                            String opType = (item['نوع العملية'] ?? '').toString().trim();

                                            if (newVal == 'تمت') {
                                              if (opType.contains('إيجار') || opType.contains('ايجار')) {
                                                for (String rentKey in [
                                                  'المعروض للإيجار',
                                                  'العقارات المعروضة للإيجار',
                                                  'بيانات الإيجار'
                                                ]) {
                                                  if (AppData.storage.containsKey(rentKey) &&
                                                      AppData.storage[rentKey] is List) {
                                                    List list = AppData.storage[rentKey] as List;
                                                    for (var prop in list) {
                                                      if (prop is Map &&
                                                          (prop['كود الوحدة'] == unitCode || prop['كود'] == unitCode)) {
                                                        prop['الحالة'] = 'تم الإيجار';
                                                        prop['حالة العقار'] = 'تم الإيجار';
                                                        prop['محجوز للعميل'] = item['إسم المشتري'] ?? '';
                                                      }
                                                    }
                                                  }
                                                }
                                              } else {
                                                for (String saleKey in [
                                                  'المعروض للبيع',
                                                  'العقارات المعروضة للبيع',
                                                  'بيانات البيع'
                                                ]) {
                                                  if (AppData.storage.containsKey(saleKey) &&
                                                      AppData.storage[saleKey] is List) {
                                                    List list = AppData.storage[saleKey] as List;
                                                    for (var prop in list) {
                                                      if (prop is Map &&
                                                          (prop['كود الوحدة'] == unitCode || prop['كود'] == unitCode)) {
                                                        prop['الحالة'] = 'تم البيع';
                                                        prop['حالة العقار'] = 'تم البيع';
                                                        prop['محجوز للعميل'] = item['إسم المشتري'] ?? '';
                                                      }
                                                    }
                                                  }
                                                }
                                              }

                                              if (!AppData.storage.containsKey('العمليات التامة') ||
                                                  AppData.storage['العمليات التامة'] == null) {
                                                AppData.storage['العمليات التامة'] = [];
                                              }

                                              final now = DateTime.now();
                                              final dateStr =
                                                  "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                                              (AppData.storage['العمليات التامة'] as List).add({
                                                'كود الوحدة': unitCode,
                                                'تاريخ العقد': dateStr,
                                                'إسم العميل': item['إسم المشتري'] ?? '',
                                                'نوع العملية (بيع / إيجار)': opType.contains('إيجار') ? 'إيجار' : 'بيع',
                                                'سعر التعاقد النهائي': item['السعر المعروض'] ?? '0',
                                                'المبلغ المدفوع': '0',
                                                'المتبقي': item['السعر المعروض'] ?? '0',
                                                'نسبة العمولة': '2.5',
                                                'قيمة العمولة': '',
                                                'isAccountOnly': 'true',
                                                'isArchived': 'false',
                                              });

                                              masterInspections.removeAt(index);
                                              AppData.storage['المعاينات'] =
                                                  masterInspections.map((e) => Map<String, String>.from(e)).toList();
                                            } else if (newVal == 'مرفوضة' || newVal == 'تأجلت') {
                                              for (String saleKey in [
                                                'المعروض للبيع',
                                                'العقارات المعروضة للبيع',
                                                'بيانات البيع',
                                                'المعروض للإيجار',
                                                'العقارات المعروضة للإيجار',
                                                'بيانات الإيجار'
                                              ]) {
                                                if (AppData.storage.containsKey(saleKey) &&
                                                    AppData.storage[saleKey] is List) {
                                                  List list = AppData.storage[saleKey] as List;
                                                  for (var prop in list) {
                                                    if (prop is Map &&
                                                        (prop['كود الوحدة'] == unitCode || prop['كود'] == unitCode)) {
                                                      prop['الحالة'] = 'متاح';
                                                      prop['حالة العقار'] = 'متاح';
                                                      prop['محجوز للعميل'] = '';
                                                    }
                                                  }
                                                }
                                              }

                                              String exactOriginalOpType = item['نوع العملية'] ?? 'شراء';

                                              if (!AppData.storage.containsKey('طلبات العملاء') ||
                                                  AppData.storage['طلبات العملاء'] == null) {
                                                AppData.storage['طلبات العملاء'] = [];
                                              }
                                              (AppData.storage['طلبات العملاء'] as List).add({
                                                'التاريخ': item['التاريخ'] ?? '',
                                                'اسم العميل': item['إسم المشتري'] ?? 'عميل عام',
                                                'نوع العملية': exactOriginalOpType,
                                                'نوع العقار': item['نوع العقار'] ?? '',
                                                'وحدة القياس': 'متر',
                                                'الميزانية': item['السعر المعروض'] ?? '',
                                                'المساحة المطلوبة': '-',
                                                'ملاحظات': item['ملاحظات'] ?? '-',
                                              });

                                              masterInspections.removeAt(index);
                                              AppData.storage['المعاينات'] =
                                                  masterInspections.map((e) => Map<String, String>.from(e)).toList();
                                            } else {
                                              AppData.storage['المعاينات'] =
                                                  masterInspections.map((e) => Map<String, String>.from(e)).toList();
                                            }
                                          });

                                          await LocalStorageService.saveLocally();
                                          CloudSyncService.syncToCloud(isAuto: true);

                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                  content: Text('تم تحديث الحالة ونقلها بنجاح ($newVal)'),
                                                  backgroundColor: Colors.green),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                DataCell(Text(item['ملاحظات'] ?? '', style: const TextStyle(color: Colors.white70))),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                                    onPressed: () async {
                                      setState(() {
                                        masterInspections.removeAt(index);
                                        AppData.storage['المعاينات'] =
                                            masterInspections.map((e) => Map<String, String>.from(e)).toList();
                                      });
                                      await LocalStorageService.saveLocally();
                                      CloudSyncService.syncToCloud(isAuto: true);

                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('تم حذف المعاينة وتحديث السحابة بنجاح'),
                                              backgroundColor: Colors.orange),
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
                              cells: List.generate(12, (cellIndex) => const DataCell(SizedBox.shrink())),
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
    );
  }
}