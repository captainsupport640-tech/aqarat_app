import 'package:flutter/material.dart';
import '../app_data.dart';
import '01_clients_screen.dart';
import '02_brokers_screen.dart';
import '03_customer_requests_screen.dart';
import '04_for_sale_screen.dart';
import '05_for_rent_screen.dart';
import '06_inspections_screen.dart';
import '07_completed_operations_screen.dart';
import '08_accounts_screen.dart';
import '09_general_report_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _selectedMonth = 'الكل';
  String _selectedYear = 'الكل';

  final List<String> _months = [
    'الكل', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'
  ];

  final List<String> _years = [
    'الكل', '2026', '2027', '2028', '2029', '2030'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var rawArchived = AppData.storage['أرشيف العمليات'];
    List<Map<String, String>> archiveRows = [];

    if (rawArchived != null) {
      for (var item in rawArchived) {
        Map<String, String> cleanedMap = {};
        Map mapItem = Map.from(item);
        mapItem.forEach((key, value) {
          cleanedMap[key.toString()] = value.toString();
        });
        archiveRows.add(cleanedMap);
      }
    }

    List<Map<String, String>> filteredRows = archiveRows.where((row) {
      bool matchesSearch = true;
      if (_searchQuery.trim().isNotEmpty) {
        String q = _searchQuery.trim().toLowerCase();
        String clientName = (row['إسم العميل'] ?? row['اسم العميل'] ?? row['اسم المشتري'] ?? '').toLowerCase();
        String unitCode = (row['كود الوحدة'] ?? '').toLowerCase();
        String opType = (row['نوع العملية (بيع / إيجار)'] ?? row['نوع العملية'] ?? '').toLowerCase();
        String propType = (row['نوع العقار'] ?? '').toLowerCase();

        matchesSearch = clientName.contains(q) ||
            unitCode.contains(q) ||
            opType.contains(q) ||
            propType.contains(q);
      }

      bool matchesYear = true;
      if (_selectedYear != 'الكل') {
        String contractDate = row['تاريخ العقد'] ?? '';
        if (!contractDate.contains(_selectedYear)) {
          matchesYear = false;
        }
      }

      bool matchesMonth = true;
      if (_selectedMonth != 'الكل') {
        String contractDate = row['تاريخ العقد'] ?? '';
        if (!contractDate.contains('-$_selectedMonth-') && !contractDate.contains('/$_selectedMonth/')) {
          matchesMonth = false;
        }
      }

      return matchesSearch && matchesYear && matchesMonth;
    }).toList();

    final totalRows = filteredRows.length < 15 ? 15 : filteredRows.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('أرشيف العمليات والبيانات الشامل | منظومة الكابتن', style: TextStyle(fontSize: 16)),
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
                      tooltip: 'طباعة الأرشيف',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري إعداد تقرير الأرشيف للطباعة...')),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C2C2C), foregroundColor: Colors.white),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GeneralReportScreen())),
                      icon: const Icon(Icons.arrow_right_rounded, color: Colors.amberAccent, size: 24),
                      label: const Text('الصفحة السابقة', style: TextStyle(fontSize: 12)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AccountsScreen())),
                      child: const Text('الحسابات', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF333333)),
                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GeneralReportScreen())),
                      child: const Text('التقرير', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
                      onPressed: () {},
                      child: const Text('الأرشيف', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF181818),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'بحث شامل: (اسم العميل، كود الوحدة...).',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        prefixIcon: const Icon(Icons.search, color: Colors.amberAccent),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF252525),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _years.contains(_selectedYear) ? _selectedYear : 'الكل',
                        dropdownColor: const Color(0xFF252525),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y == 'الكل' ? 'سنة: الكل' : 'سنة: $y'))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedYear = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _months.contains(_selectedMonth) ? _selectedMonth : 'الكل',
                        dropdownColor: const Color(0xFF252525),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m == 'الكل' ? 'شهر: الكل' : 'شهر: $m'))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedMonth = val;
                            });
                          }
                        },
                      ),
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
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
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
                                DataColumn(label: Text('كود الوحدة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                                DataColumn(label: Text('تاريخ العقد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('إسم العميل', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('نوع العقار', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent))),
                                DataColumn(label: Text('نوع العملية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('سعر التعاقد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent))),
                                DataColumn(label: Text('المبلغ المدفوع', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                                DataColumn(label: Text('المتبقي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent))),
                                DataColumn(label: Text('نسبة العمولة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                DataColumn(label: Text('قيمة العمولة', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent))),
                                DataColumn(label: Text('حذف', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))),
                              ],
                              rows: List.generate(totalRows, (index) {
                                if (index < filteredRows.length) {
                                  Map<String, String> row = filteredRows[index];
                                  final rowColor = index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525);

                                  String cName = row['إسم العميل'] ?? row['اسم العميل'] ?? row['اسم المشتري'] ?? '';
                                  String propType = row['نوع العقار'] ?? '';

                                  return DataRow(
                                    color: WidgetStateProperty.all(rowColor),
                                    cells: [
                                      DataCell(Text('${index + 1}', style: const TextStyle(color: Colors.cyanAccent))),
                                      DataCell(Text(row['كود الوحدة'] ?? '', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))),
                                      DataCell(Text(row['تاريخ العقد'] ?? '', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(cName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                      DataCell(Text(propType.trim().isNotEmpty ? propType : '-', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataCell(Text(row['نوع العملية (بيع / إيجار)'] ?? row['نوع العملية'] ?? 'بيع', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(row['سعر التعاقد النهائي'] ?? '0', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))),
                                      DataCell(Text(row['المبلغ المدفوع'] ?? '0', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                                      DataCell(Text(row['المتبقي'] ?? '0', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))),
                                      DataCell(Text(row['نسبة العمولة'] ?? '2.5', style: const TextStyle(color: Colors.white))),
                                      DataCell(Text(row['قيمة العمولة'] ?? '0', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                          tooltip: 'حذف السجل من الأرشيف',
                                          onPressed: () {
                                            setState(() {
                                              var originalArchive = AppData.storage['أرشيف العمليات'];
                                              if (originalArchive != null) {
                                                originalArchive.removeWhere((item) {
                                                  return (item['كود الوحدة'] == row['كود الوحدة']) &&
                                                      ((item['إسم العميل'] ?? item['اسم العميل'] ?? '') == cName);
                                                });
                                                AppData.storage['أرشيف العمليات'] = originalArchive;
                                              }
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('تم حذف السجل من الأرشيف بنجاح'), backgroundColor: Colors.red),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((states) => index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525)),
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
          ],
        ),
      ),
    );
  }
}