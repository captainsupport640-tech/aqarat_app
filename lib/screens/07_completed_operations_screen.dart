import '../app_imports.dart';

class CompletedOperationsScreen extends StatefulWidget {
  const CompletedOperationsScreen({super.key});

  @override
  State<CompletedOperationsScreen> createState() => _CompletedOperationsScreenState();
}

class _CompletedOperationsScreenState extends State<CompletedOperationsScreen> {
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

  @override
  Widget build(BuildContext context) {
    if (!AppData.storage.containsKey('العمليات التامة') || AppData.storage['العمليات التامة'] == null) {
      AppData.storage['العمليات التامة'] = [];
    }
    if (!AppData.storage.containsKey('أرشيف العمليات') || AppData.storage['أرشيف العمليات'] == null) {
      AppData.storage['أرشيف العمليات'] = [];
    }

    List operationsList = [];
    var stored = AppData.storage['العمليات التامة'];
    if (stored != null) {
      for (dynamic e in stored) {
        if (e != null) {
          Map<String, String> mappedItem = {};
          e.forEach((key, value) {
            mappedItem[key.toString()] = value.toString();
          });
          operationsList.add(mappedItem);
        }
      }
    }

    final totalRows = operationsList.length < 15 ? 15 : operationsList.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: const CustomScreenAppBar(
          title: 'العمليات المكتملة',
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
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
                              label: Text('تاريخ العقد',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          DataColumn(
                              label: Text('إسم العميل',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          DataColumn(
                              label: Text('نوع العملية',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          DataColumn(
                              label: Text('سعر التعاقد',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                          DataColumn(
                              label: Text('المبلغ المدفوع',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                          DataColumn(
                              label: Text('المتبقي',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent))),
                          DataColumn(
                              label: Text('نسبة العمولة',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          DataColumn(
                              label: Text('قيمة العمولة',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent))),
                          DataColumn(
                              label: Text('حسابات وأرشفة',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                        ],
                        rows: List.generate(totalRows, (index) {
                          if (index < operationsList.length) {
                            Map<String, String> item = operationsList[index];

                            double price = double.tryParse(item['سعر التعاقد النهائي'] ?? '0') ?? 0;
                            double paid = double.tryParse(item['المبلغ المدفوع'] ?? '0') ?? 0;
                            double commRate =
                                double.tryParse((item['نسبة العمولة'] ?? '2.5').replaceAll('%', '').trim()) ?? 2.5;

                            double remaining = price - paid;
                            double commission = price * (commRate / 100.0);

                            bool isAccountOnly = (item['isAccountOnly'] ?? 'true') == 'true';
                            bool isArchived = (item['isArchived'] ?? 'false') == 'true';

                            return DataRow(
                              color: WidgetStateProperty.resolveWith<Color?>((states) {
                                return index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525);
                              }),
                              cells: [
                                DataCell(Text('${index + 1}', style: const TextStyle(color: Colors.cyanAccent))),
                                DataCell(Text(item['كود الوحدة'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                DataCell(Text(item['تاريخ العقد'] ?? '', style: const TextStyle(color: Colors.white))),
                                DataCell(Text(item['إسم العميل'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                DataCell(Text(item['نوع العملية (بيع / إيجار)'] ?? 'بيع / إيجار',
                                    style: const TextStyle(color: Colors.white))),
                                DataCell(
                                  TextFormField(
                                    initialValue: item['سعر التعاقد النهائي'] ?? '0',
                                    style: const TextStyle(
                                        color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) async {
                                      setState(() {
                                        item['سعر التعاقد النهائي'] = val;
                                        AppData.storage['العمليات التامة'] = operationsList;
                                      });
                                      await LocalStorageService.saveLocally();
                                      CloudSyncService.syncToCloud(isAuto: true);
                                    },
                                  ),
                                ),
                                DataCell(
                                  TextFormField(
                                    initialValue: item['المبلغ المدفوع'] ?? '0',
                                    style: const TextStyle(
                                        color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) async {
                                      setState(() {
                                        item['المبلغ المدفوع'] = val;
                                        AppData.storage['العمليات التامة'] = operationsList;
                                      });
                                      await LocalStorageService.saveLocally();
                                      CloudSyncService.syncToCloud(isAuto: true);
                                    },
                                  ),
                                ),
                                DataCell(
                                  Text(remaining.toStringAsFixed(0),
                                      style: const TextStyle(
                                          color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                                ),
                                DataCell(
                                  TextFormField(
                                    initialValue: item['نسبة العمولة'] ?? '2.5',
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: const InputDecoration(border: InputBorder.none),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) async {
                                      setState(() {
                                        item['نسبة العمولة'] = val;
                                        AppData.storage['العمليات التامة'] = operationsList;
                                      });
                                      await LocalStorageService.saveLocally();
                                      CloudSyncService.syncToCloud(isAuto: true);
                                    },
                                  ),
                                ),
                                DataCell(
                                  Text(commission.toStringAsFixed(0),
                                      style: const TextStyle(
                                          color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: isAccountOnly,
                                            activeColor: Colors.amber,
                                            onChanged: (val) async {
                                              setState(() {
                                                item['isAccountOnly'] = (val ?? true).toString();
                                                AppData.storage['العمليات التامة'] = operationsList;
                                              });
                                              await LocalStorageService.saveLocally();
                                              CloudSyncService.syncToCloud(isAuto: true);
                                            },
                                          ),
                                          const Text('حسابات', style: TextStyle(color: Colors.white, fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: isArchived,
                                            activeColor: Colors.redAccent,
                                            onChanged: (val) async {
                                              setState(() {
                                                bool newArchived = val ?? false;
                                                item['isArchived'] = newArchived.toString();

                                                if (newArchived) {
                                                  Map<String, String> removedItem = operationsList.removeAt(index);
                                                  AppData.storage['العمليات التامة'] = operationsList;

                                                  String unitCode = (removedItem['كود الوحدة'] ?? '').trim();
                                                  String rawClientName =
                                                      (removedItem['إسم العميل'] ?? removedItem['اسم العميل'] ?? '')
                                                          .trim();

                                                  List<String> phoneNumbers = [];
                                                  var clientsList = AppData.storage['العملاء'];
                                                  if (clientsList != null) {
                                                    for (var c in clientsList) {
                                                      String cName = (c['إسم العميل'] ??
                                                              c['اسم العميل'] ??
                                                              c['الاسم'] ??
                                                              '')
                                                          .toString()
                                                          .trim();

                                                      if (cName.isNotEmpty && rawClientName.isNotEmpty) {
                                                        if (cName == rawClientName ||
                                                            cName.contains(rawClientName) ||
                                                            rawClientName.contains(cName)) {
                                                          String p1 = (c['رقم التليفون 1'] ??
                                                                  c['رقم التليفون1'] ??
                                                                  c['رقم الهاتف'] ??
                                                                  c['التليفون'] ??
                                                                  '')
                                                              .toString()
                                                              .trim();
                                                          String p2 = (c['رقم التليفون 2'] ??
                                                                  c['رقم التليفون2'] ??
                                                                  c['الموبايل'] ??
                                                                  '')
                                                              .toString()
                                                              .trim();

                                                          if (p1.isNotEmpty && p1 != '-' && p1 != 'null') {
                                                            phoneNumbers.add(p1);
                                                          }
                                                          if (p2.isNotEmpty && p2 != '-' && p2 != 'null') {
                                                            phoneNumbers.add(p2);
                                                          }
                                                          break;
                                                        }
                                                      }
                                                    }

                                                    if (phoneNumbers.isEmpty && clientsList.isNotEmpty) {
                                                      var firstClient = clientsList.first;
                                                      String p1 = (firstClient['رقم التليفون 1'] ??
                                                              firstClient['رقم التليفون1'] ??
                                                              firstClient['رقم الهاتف'] ??
                                                              '')
                                                          .toString()
                                                          .trim();
                                                      String p2 = (firstClient['رقم التليفون 2'] ??
                                                              firstClient['رقم التليفون2'] ??
                                                              firstClient['الموبايل'] ??
                                                              '')
                                                          .toString()
                                                          .trim();
                                                      if (p1.isNotEmpty && p1 != '-' && p1 != 'null') {
                                                        phoneNumbers.add(p1);
                                                      }
                                                      if (p2.isNotEmpty && p2 != '-' && p2 != 'null') {
                                                        phoneNumbers.add(p2);
                                                      }
                                                    }
                                                  }

                                                  String combinedPhones =
                                                      phoneNumbers.isNotEmpty ? phoneNumbers.join('\n') : '-';

                                                  String propertyType = '-';
                                                  for (String key in [
                                                    'المعروض للبيع',
                                                    'العقارات المعروضة للبيع',
                                                    'بيانات البيع',
                                                    'المعروض للإيجار',
                                                    'العقارات المعروضة للإيجار',
                                                    'بيانات الإيجار',
                                                    'المعاينات'
                                                  ]) {
                                                    if (AppData.storage.containsKey(key) &&
                                                        AppData.storage[key] is Iterable) {
                                                      List list = AppData.storage[key] as List;
                                                      for (var prop in list) {
                                                        if (prop is Map &&
                                                            ((prop['كود الوحدة'] ?? prop['كود']) == unitCode)) {
                                                          if (prop['نوع العقار'] != null &&
                                                              prop['نوع العقار'].toString().trim().isNotEmpty) {
                                                            propertyType = prop['نوع العقار'].toString().trim();
                                                            break;
                                                          }
                                                        }
                                                      }
                                                    }
                                                    if (propertyType != '-') break;
                                                  }

                                                  removedItem['رقم الموبايل'] = combinedPhones;
                                                  removedItem['نوع العقار'] = propertyType;
                                                  removedItem['سعر التعاقد النهائي'] = price.toStringAsFixed(0);
                                                  removedItem['المبلغ المدفوع'] = paid.toStringAsFixed(0);
                                                  removedItem['المتبقي'] = remaining.toStringAsFixed(0);
                                                  removedItem['قيمة العمولة'] = commission.toStringAsFixed(0);

                                                  var archiveList = AppData.storage['أرشيف العمليات'];
                                                  if (archiveList != null) {
                                                    archiveList.add(removedItem);
                                                    AppData.storage['أرشيف العمليات'] = archiveList;
                                                  }

                                                  for (String saleKey in [
                                                    'المعروض للبيع',
                                                    'العقارات المعروضة للبيع',
                                                    'بيانات البيع'
                                                  ]) {
                                                    if (AppData.storage.containsKey(saleKey) &&
                                                        AppData.storage[saleKey] is List) {
                                                      List list = AppData.storage[saleKey] as List;
                                                      list.removeWhere((prop) {
                                                        if (prop is Map) {
                                                          return (prop['كود الوحدة'] == unitCode ||
                                                              prop['كود'] == unitCode);
                                                        }
                                                        return false;
                                                      });
                                                    }
                                                  }

                                                  for (String rentKey in [
                                                    'المعروض للإيجار',
                                                    'العقارات المعروضة للإيجار',
                                                    'بيانات الإيجار'
                                                  ]) {
                                                    if (AppData.storage.containsKey(rentKey) &&
                                                        AppData.storage[rentKey] is List) {
                                                      List list = AppData.storage[rentKey] as List;
                                                      list.removeWhere((prop) {
                                                        if (prop is Map) {
                                                          return (prop['كود الوحدة'] == unitCode ||
                                                              prop['كود'] == unitCode);
                                                        }
                                                        return false;
                                                      });
                                                    }
                                                  }
                                                } else {
                                                  AppData.storage['العمليات التامة'] = operationsList;
                                                }
                                              });

                                              await LocalStorageService.saveLocally();
                                              CloudSyncService.syncToCloud(isAuto: true);

                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'تم أرشفة العملية وجلب رقم الموبايل وحذفها من المعروضات بنجاح'),
                                                      backgroundColor: Colors.blue),
                                                );
                                              }
                                            },
                                          ),
                                          const Text('أرشيف', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return DataRow(
                              color: WidgetStateProperty.resolveWith<Color?>((states) {
                                return index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525);
                              }),
                              cells: List.generate(11, (cellIndex) => const DataCell(SizedBox.shrink())),
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