import '../app_imports.dart';
import '08_accounts_screen.dart';
import '10_archive_screen.dart';

class GeneralReportScreen extends StatefulWidget {
  const GeneralReportScreen({super.key});

  @override
  State<GeneralReportScreen> createState() => _GeneralReportScreenState();
}

class _GeneralReportScreenState extends State<GeneralReportScreen> {
  late String selectedMonth;
  late String selectedYear;

  final List monthsList = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];

  final List yearsList = ['2025', '2026', '2027', '2028', '2029', '2030'];

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    int currentMonthIndex = now.month - 1;
    if (currentMonthIndex >= 0 && currentMonthIndex < monthsList.length) {
      selectedMonth = monthsList[currentMonthIndex].toString();
    } else {
      selectedMonth = 'نوفمبر';
    }
    selectedYear = yearsList.contains(now.year.toString()) ? now.year.toString() : '2026';
    _startRealtimeListener();
  }

  void _startRealtimeListener() async {
    try {
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
    } catch (_) {}
  }

  @override
  void dispose() {
    try {
      AppStorageManager.stopMasterDatabaseListener();
    } catch (_) {}
    super.dispose();
  }

  int _getMonthNumber(String monthName) {
    int idx = monthsList.indexOf(monthName);
    return idx != -1 ? idx + 1 : 11;
  }

  @override
  Widget build(BuildContext context) {
    final List categories = AppDropdowns.expenseCategories.isNotEmpty
        ? AppDropdowns.expenseCategories
        : ['إيجار', 'كهرباء ومياه', 'مرتبات', 'دعاية وإعلان', 'انتقالات', 'منوع'];

    List accountsRows = [];

    try {
      List rawCompleted = AppData.storage['العمليات التامة'] ?? [];
      for (var item in rawCompleted) {
        if (item is Map) {
          Map opMap = Map.from(item);
          bool isAccountOnly = (opMap['isAccountOnly'] ?? 'true').toString() == 'true';
          if (isAccountOnly) {
            double price = double.tryParse((opMap['سعر التعاقد النهائي'] ?? '0').toString()) ?? 0;
            double commRate =
                double.tryParse((opMap['نسبة العمولة'] ?? '2.5').toString().replaceAll('%', '').trim()) ?? 2.5;
            double commission = price * (commRate / 100.0);

            accountsRows.add({
              'التاريخ': (opMap['تاريخ العقد'] ?? '').toString(),
              'البيان': 'عمولة (${opMap['كود الوحدة'] ?? ''}) - ${opMap['إسم المشتري'] ?? ''}',
              'الدخل': commission.toStringAsFixed(0),
              'المصروفات': '0',
            });
          }
        }
      }

      List rawArchived = AppData.storage['أرشيف العمليات'] ?? [];
      for (var item in rawArchived) {
        if (item is Map) {
          Map opMap = Map.from(item);
          bool isAccountOnly = (opMap['isAccountOnly'] ?? 'true').toString() == 'true';
          if (isAccountOnly) {
            double price = double.tryParse((opMap['سعر التعاقد النهائي'] ?? '0').toString()) ?? 0;
            double commRate =
                double.tryParse((opMap['نسبة العمولة'] ?? '2.5').toString().replaceAll('%', '').trim()) ?? 2.5;
            double commission = price * (commRate / 100.0);

            accountsRows.add({
              'التاريخ': (opMap['تاريخ العقد'] ?? '').toString(),
              'البيان': 'عمولة أرشيف (${opMap['كود الوحدة'] ?? ''}) - ${opMap['إسم المشتري'] ?? ''}',
              'الدخل': commission.toStringAsFixed(0),
              'المصروفات': '0',
            });
          }
        }
      }

      List rawExpenses = AppData.storage['المصروفات'] ?? [];
      for (var item in rawExpenses) {
        if (item is Map) {
          Map expMap = Map.from(item);
          accountsRows.add({
            'التاريخ': (expMap['التاريخ'] ?? '').toString(),
            'البيان': (expMap['البيان'] ?? '').toString(),
            'الدخل': '0',
            'المصروفات': (expMap['المصروفات'] ?? '0').toString(),
          });
        }
      }
    } catch (_) {}

    double totalIncomeMonth = 0;
    double totalExpensesMonth = 0;
    double totalIncomeYear = 0;
    double totalExpensesYear = 0;

    Map expenseBreakdown = {};
    for (var cat in categories) {
      expenseBreakdown[cat.toString()] = 0.0;
    }

    int targetMonthNum = _getMonthNumber(selectedMonth);

    for (var item in accountsRows) {
      String dateStr = (item['التاريخ'] ?? '').toString();
      double income = double.tryParse((item['الدخل'] ?? '0').toString()) ?? 0;
      double expense = double.tryParse((item['المصروفات'] ?? '0').toString()) ?? 0;
      String statement = (item['البيان'] ?? '').toString();

      bool matchesYear = false;
      bool matchesMonth = false;

      if (dateStr.isNotEmpty) {
        try {
          DateTime parsedDate = DateTime.parse(dateStr);
          if (parsedDate.year.toString() == selectedYear) {
            matchesYear = true;
            if (parsedDate.month == targetMonthNum) {
              matchesMonth = true;
            }
          }
        } catch (_) {
          if (dateStr.contains(selectedYear)) {
            matchesYear = true;
            matchesMonth = true;
          }
        }
      }

      if (matchesYear) {
        totalIncomeYear += income;
        totalExpensesYear += expense;
      }

      if (matchesMonth) {
        totalIncomeMonth += income;
        totalExpensesMonth += expense;

        if (expense > 0) {
          bool foundCat = false;
          for (var cat in categories) {
            String catStr = cat.toString();
            if (statement.contains(catStr)) {
              expenseBreakdown[catStr] = (expenseBreakdown[catStr] ?? 0.0) + expense;
              foundCat = true;
              break;
            }
          }
          if (!foundCat) {
            expenseBreakdown['منوع'] = (expenseBreakdown['منوع'] ?? 0.0) + expense;
          }
        }
      }
    }

    double netProfitMonth = totalIncomeMonth - totalExpensesMonth;
    double netProfitYear = totalIncomeYear - totalExpensesYear;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: const CustomScreenAppBar(title: 'التقرير العام والحسابات الختامية'),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
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
                        onPressed: () async {
                          await printFullGeneralReport();
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
                            MaterialPageRoute(builder: (context) => const AccountsScreen()),
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
                            MaterialPageRoute(builder: (context) => const ArchiveScreen()),
                          );
                        },
                        icon: const Icon(Icons.arrow_left_rounded, color: Colors.amberAccent, size: 24),
                        label: const Text('الصفحة التالية', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ArchiveScreen()),
                          );
                        },
                        icon: const Icon(Icons.archive, color: Colors.white, size: 18),
                        label: const Text('الأرشيف', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('حساب الشهر: ',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            DropdownButton<String>(
                              value: selectedMonth,
                              dropdownColor: const Color(0xFF2C2C2C),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                              underline: const SizedBox.shrink(),
                              items: monthsList.map((month) {
                                return DropdownMenuItem<String>(
                                  value: month.toString(),
                                  child: Text(month.toString(), style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (val) async {
                                if (val != null) {
                                  setState(() => selectedMonth = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('حساب السنة: ',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            DropdownButton<String>(
                              value: selectedYear,
                              dropdownColor: const Color(0xFF2C2C2C),
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                              underline: const SizedBox.shrink(),
                              items: yearsList.map((year) {
                                return DropdownMenuItem<String>(
                                  value: year.toString(),
                                  child: Text(year.toString(), style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (val) async {
                                if (val != null) {
                                  setState(() => selectedYear = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.amber, width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Table(
                        border: TableBorder.all(color: Colors.grey.shade700),
                        columnWidths: const {
                          0: FixedColumnWidth(45),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFF2C2C2C)),
                            children: [
                              const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('م',
                                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('البيان',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('إجمالي الدخل ($selectedMonth $selectedYear)',
                                      style:
                                          const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('إجمالي حساب السنة ($selectedYear)',
                                      style:
                                          const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
                            children: [
                              const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('1',
                                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                              const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('إجمالي الدخل (العمولات)',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('${totalIncomeMonth.toStringAsFixed(0)} ج.م.',
                                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('إجمالي دخل السنة:\n${totalIncomeYear.toStringAsFixed(0)} ج.م.',
                                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFF252525)),
                            children: [
                              const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('2',
                                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                              const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('إجمالي المصروفات',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('${totalExpensesMonth.toStringAsFixed(0)} ج.م.',
                                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('إجمالي مصروفات السنة:\n${totalExpensesYear.toStringAsFixed(0)} ج.م.',
                                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
                            children: [
                              const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('3',
                                      textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                              const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('صافي الربح',
                                      style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('${netProfitMonth.toStringAsFixed(0)} ج.م.',
                                      style: TextStyle(
                                          color: netProfitMonth >= 0 ? Colors.cyanAccent : Colors.red,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('صافي ربح السنة:\n${netProfitYear.toStringAsFixed(0)} ج.م.',
                                      style: TextStyle(
                                          color: netProfitYear >= 0 ? Colors.cyanAccent : Colors.red,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('تفاصيل المصروفات وبنود الصرف:',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade700, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Table(
                        border: TableBorder.all(color: Colors.grey.shade800),
                        columnWidths: const {
                          0: FixedColumnWidth(45),
                          1: FlexColumnWidth(3),
                          2: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFF2C2C2C)),
                            children: [
                              const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('م',
                                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                              const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('بند المصروف',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                              Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('إجمالي المنصرف ($selectedMonth $selectedYear)',
                                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center)),
                            ],
                          ),
                          ...List.generate(categories.length, (index) {
                            String category = categories[index].toString();
                            double amount = (expenseBreakdown[category] ?? 0.0).toDouble();
                            return TableRow(
                              decoration:
                                  BoxDecoration(color: index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525)),
                              children: [
                                Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('${index + 1}',
                                        textAlign: TextAlign.center, style: const TextStyle(color: Colors.white))),
                                Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(category, style: const TextStyle(color: Colors.white))),
                                Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('${amount.toStringAsFixed(0)} ج.م.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: amount > 0 ? Colors.redAccent : Colors.grey,
                                            fontWeight: FontWeight.bold))),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}