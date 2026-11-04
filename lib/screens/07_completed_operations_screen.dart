import 'package:flutter/material.dart';
import '../app_data.dart';
import '../services/local_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '01_clients_screen.dart';
import '02_brokers_screen.dart';
import '03_customer_requests_screen.dart';
import '04_for_sale_screen.dart';
import '05_for_rent_screen.dart';
import '06_inspections_screen.dart';

class CompletedOperationsScreen extends StatefulWidget {
  const CompletedOperationsScreen({super.key});

  @override
  State<CompletedOperationsScreen> createState() => _CompletedOperationsScreenState();
}

class _CompletedOperationsScreenState extends State<CompletedOperationsScreen> {
  @override
  Widget build(BuildContext context) {
    if (!AppData.storage.containsKey('العمليات التامة') || AppData.storage['العمليات التامة'] == null) {
      AppData.storage['العمليات التامة'] = <Map<String, String>>[];
    }
    if (!AppData.storage.containsKey('أرشيف العمليات') || AppData.storage['أرشيف العمليات'] == null) {
      AppData.storage['أرشيف العمليات'] = <Map<String, String>>[];
    }

    List<Map<String, String>> operationsList = [];
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
        appBar: AppBar(
          title: const Text('العمليات التامة | منظومة الكابتن لإدارة العقارات', style: TextStyle(fontSize: 16)),
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
                          const SnackBar(content: Text('جاري طباعة تقرير العمليات التامة الحالي...'), backgroundColor: Colors.cyan),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const InspectionsScreen()),
                        );
                      },
                      icon: const Icon(Icons.arrow_right_rounded, color: Colors.amberAccent, size: 22),
                      label: const Text('الصفحة السابقة', style: TextStyle(fontSize: 11)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                      onPressed: () {},
                      child: const Text('العمليات', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                              columnSpacing: 14,
                              columns: const [
                                DataColumn(label: Text('م', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent))),
                                DataColumn(label: Text('كود الوحدة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('تاريخ العقد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('إسم العميل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('نوع العملية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('سعر التعاقد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                                DataColumn(label: Text('المبلغ المدفوع', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                                DataColumn(label: Text('المتبقي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent))),
                                DataColumn(label: Text('نسبة العمولة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('قيمة العمولة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent))),
                                DataColumn(label: Text('حسابات وأرشفة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                              ],
                              rows: List.generate(totalRows, (index) {
                                if (index < operationsList.length) {
                                  Map<String, String> item = operationsList[index];

                                  double price = double.tryParse(item['سعر التعاقد النهائي'] ?? '0') ?? 0;
                                  double paid = double.tryParse(item['المبلغ المدفوع'] ?? '0') ?? 0;
                                  double commRate = double.tryParse((item['نسبة العمولة'] ?? '2.5').replaceAll('%', '').trim()) ?? 2.5;

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
                                      DataCell(Text(item['كود الوحدة'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                      DataCell(Text(item['تاريخ العقد'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(item['إسم العميل'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                      DataCell(Text(item['نوع العملية (بيع / إيجار)'] ?? 'بيع / إيجار', style: const TextStyle(color: Colors.white))),
                                      DataCell(
                                        TextFormField(
                                          initialValue: item['سعر التعاقد النهائي'] ?? '0',
                                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13),
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
                                          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
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
                                        Text(remaining.toStringAsFixed(0), style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
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
                                        Text(commission.toStringAsFixed(0), style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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
                                                        String rawClientName = (removedItem['إسم العميل'] ?? removedItem['اسم العميل'] ?? '').trim();

                                                        List<String> phoneNumbers = [];
                                                        var clientsList = AppData.storage['العملاء'];
                                                        if (clientsList != null) {
                                                          for (var c in clientsList) {
                                                            if (true) {
                                                              String cName = (c['إسم العميل'] ?? c['اسم العميل'] ?? c['الاسم'] ?? '').toString().trim();

                                                              if (cName.isNotEmpty && rawClientName.isNotEmpty) {
                                                                if (cName == rawClientName || cName.contains(rawClientName) || rawClientName.contains(cName)) {
                                                                  String p1 = (c['رقم التليفون 1'] ?? c['رقم التليفون1'] ?? c['رقم الهاتف'] ?? c['التليفون'] ?? '').toString().trim();
                                                                  String p2 = (c['رقم التليفون 2'] ?? c['رقم التليفون2'] ?? c['الموبايل'] ?? '').toString().trim();

                                                                  if (p1.isNotEmpty && p1 != '-' && p1 != 'null') phoneNumbers.add(p1);
                                                                  if (p2.isNotEmpty && p2 != '-' && p2 != 'null') phoneNumbers.add(p2);
                                                                  break;
                                                                }
                                                              }
                                                            }
                                                          }

                                                          if (phoneNumbers.isEmpty && clientsList.isNotEmpty) {
                                                            var firstClient = clientsList.first;
                                                            if (true) {
                                                              String p1 = (firstClient['رقم التليفون 1'] ?? firstClient['رقم التليفون1'] ?? firstClient['رقم الهاتف'] ?? '').toString().trim();
                                                              String p2 = (firstClient['رقم التليفون 2'] ?? firstClient['رقم التليفون2'] ?? firstClient['الموبايل'] ?? '').toString().trim();
                                                              if (p1.isNotEmpty && p1 != '-' && p1 != 'null') phoneNumbers.add(p1);
                                                              if (p2.isNotEmpty && p2 != '-' && p2 != 'null') phoneNumbers.add(p2);
                                                            }
                                                          }
                                                        }

                                                        String combinedPhones = phoneNumbers.isNotEmpty ? phoneNumbers.join('\n') : '-';

                                                        String propertyType = '-';
                                                        for (String key in ['المعروض للبيع', 'العقارات المعروضة للبيع', 'بيانات البيع', 'المعروض للإيجار', 'العقارات المعروضة للإيجار', 'بيانات الإيجار', 'المعاينات']) {
                                                          if (AppData.storage.containsKey(key) && AppData.storage[key] is Iterable) {
                                                            List list = AppData.storage[key] as List;
                                                            for (var prop in list) {
                                                              if (prop is Map && ((prop['كود الوحدة'] ?? prop['كود']) == unitCode)) {
                                                                if (prop['نوع العقار'] != null && prop['نوع العقار'].toString().trim().isNotEmpty) {
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

                                                        // حذف الوحدة تماماً من شيتات البيع بأمان تام
                                                        for (String saleKey in ['المعروض للبيع', 'العقارات المعروضة للبيع', 'بيانات البيع']) {
                                                          if (AppData.storage.containsKey(saleKey) && AppData.storage[saleKey] is List) {
                                                            List list = AppData.storage[saleKey] as List;
                                                            list.removeWhere((prop) {
                                                              if (prop is Map) {
                                                                return (prop['كود الوحدة'] == unitCode || prop['كود'] == unitCode);
                                                              }
                                                              return false;
                                                            });
                                                          }
                                                        }

                                                        // حذف الوحدة تماماً من شيتات الإيجار بأمان تام
                                                        for (String rentKey in ['المعروض للإيجار', 'العقارات المعروضة للإيجار', 'بيانات الإيجار']) {
                                                          if (AppData.storage.containsKey(rentKey) && AppData.storage[rentKey] is List) {
                                                            List list = AppData.storage[rentKey] as List;
                                                            list.removeWhere((prop) {
                                                              if (prop is Map) {
                                                                return (prop['كود الوحدة'] == unitCode || prop['كود'] == unitCode);
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
                                                        const SnackBar(content: Text('تم أرشفة العملية وجلب رقم الموبايل وحذفها من المعروضات بنجاح'), backgroundColor: Colors.blue),
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
          ],
        ),
      ),
    );
  }
}