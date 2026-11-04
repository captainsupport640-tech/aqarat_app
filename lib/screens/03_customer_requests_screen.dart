import '../services/notification_service.dart';
import 'package:flutter/material.dart';
import '../app_data.dart';
import '../app_dropdowns.dart';
import '../services/local_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/smart_text_parser.dart';
import '01_clients_screen.dart';
import '02_brokers_screen.dart';
import '04_for_sale_screen.dart';
import '05_for_rent_screen.dart';
import '06_inspections_screen.dart';
import '07_completed_operations_screen.dart';

class CustomerRequestsScreen extends StatefulWidget {
  const CustomerRequestsScreen({super.key});

  @override
  State<CustomerRequestsScreen> createState() => _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState extends State<CustomerRequestsScreen> {
  int selectedRequestIndex = 0;
  String _searchPropertyFilter = 'الكل';

  void _showAddRequestDialog({ParsedPropertyData? initialData}) {
    final clientNames = AppDropdowns.getClientNames();
    List<String> validClients = (clientNames.isEmpty || clientNames.first == 'لا توجد عملاء مسجلة')
        ? ['عميل عام']
        : clientNames;

    String selectedClient = validClients.first;
    if (initialData?.ownerName != null && initialData!.ownerName!.isNotEmpty) {
      for (var c in validClients) {
        if (c.contains(initialData.ownerName!)) {
          selectedClient = c;
          break;
        }
      }
    }

    String selectedOperation = AppDropdowns.operationTypes.first;
    String selectedProperty = AppDropdowns.propertyTypes.first;
    if (initialData?.propertyType != null && initialData!.propertyType!.isNotEmpty) {
      for (var p in AppDropdowns.propertyTypes) {
        if (p.contains(initialData.propertyType!)) {
          selectedProperty = p;
          break;
        }
      }
    }

    String selectedUnit = AppDropdowns.measurementUnits.first;
    String selectedBudget = AppDropdowns.budgetOptions.first;

    final List<String> areaOptions = [
      '50 متر', '75 متر', '100 متر', '120 متر', '150 متر',
      '200 متر', '250 متر', '300 متر', '500 متر', 'قيراط واحد', 'فدان واحد'
    ];

    String selectedArea = areaOptions.first;
    if (initialData?.area != null && initialData!.area!.isNotEmpty) {
      for (var a in areaOptions) {
        if (a.contains(initialData.area!)) {
          selectedArea = a;
          break;
        }
      }
    }

    String defaultNotes = initialData?.details ?? '';
    if (initialData?.phone != null && initialData!.phone!.isNotEmpty) {
      defaultNotes = 'رقم الهاتف: ${initialData.phone}\n' + defaultNotes;
    }
    final notesController = TextEditingController(text: defaultNotes);
    final fNotes = FocusNode();

    void saveRequest(BuildContext dialogContext) async {
      if (selectedClient.isEmpty || selectedClient == 'لا توجد عملاء مسجلة') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('برجاء إضافة عملاء أولاً لتسجيل الطلبات'), backgroundColor: Colors.red),
        );
        return;
      }

      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      setState(() {
        if (!AppData.storage.containsKey('طلبات العملاء') || AppData.storage['طلبات العملاء'] == null) {
          AppData.storage['طلبات العملاء'] = <Map<String, String>>[];
        }

        List requests = AppData.storage['طلبات العملاء'] as List;
        requests.add({
          'التاريخ': dateStr,
          'اسم العميل': selectedClient,
          'نوع العملية': selectedOperation,
          'نوع العقار': selectedProperty,
          'وحدة القياس': selectedUnit,
          'الميزانية': selectedBudget,
          'المساحة المطلوبة': selectedArea,
          'ملاحظات': notesController.text.trim().isEmpty ? '-' : notesController.text.trim(),
        });
      });

      await LocalStorageService.saveLocally();
      CloudSyncService.syncToCloud(isAuto: true);

      Navigator.pop(dialogContext);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ طلب العميل وتحديث السحابة بنجاح'), backgroundColor: Colors.green),
        );
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            initialData != null ? 'إضافة طلب عميل (من نص الرسالة)' : 'إضافة طلب عميل جديد',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppDropdowns.buildDropdownField(
                    label: 'إسم العميل',
                    value: selectedClient,
                    items: validClients,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedClient = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppDropdowns.buildDropdownField(
                    label: 'نوع العملية',
                    value: selectedOperation,
                    items: AppDropdowns.operationTypes,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedOperation = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppDropdowns.buildDropdownField(
                    label: 'نوع العقار',
                    value: selectedProperty,
                    items: AppDropdowns.propertyTypes,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedProperty = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppDropdowns.buildDropdownField(
                    label: 'وحدة القياس',
                    value: selectedUnit,
                    items: AppDropdowns.measurementUnits,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedUnit = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppDropdowns.buildDropdownField(
                    label: 'الميزانية / السعر المتوقع',
                    value: selectedBudget,
                    items: AppDropdowns.budgetOptions,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedBudget = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppDropdowns.buildDropdownField(
                    label: 'المساحة المطلوبة',
                    value: selectedArea,
                    items: areaOptions,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedArea = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    focusNode: fNotes,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => saveRequest(dialogContext),
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات وتفاصيل النص المستخرج',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFF252525),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء', style: TextStyle(color: Colors.redAccent))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
              onPressed: () => saveRequest(dialogContext),
              child: const Text('حفظ الطلب'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSmartParserDialog() {
    final TextEditingController rawTextController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF1E1E1E),
          title: Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 26),
              SizedBox(width: 8),
              Text('تحليل نص رسالة طلب (واتساب / ماسنجر)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('قم بنسخ نص رسالة الطلب هنا وسيقوم النظام بتوزيع البيانات تلقائياً:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 10),
                TextField(
                  controller: rawTextController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'مثال: مطلوب شقة للإيجار 150 متر في التجمع بحد أقصى 10 آلاف للتواصل كابتن محمد 01012345678...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF282828),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700),
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 18),
              label: const Text('تحليل واستخراج البيانات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                if (rawTextController.text.trim().isEmpty) return;
                ParsedPropertyData parsedData = SmartTextParser.parseMessage(rawTextController.text);
                Navigator.pop(context);
                _showAddRequestDialog(initialData: parsedData);
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _getMatchingResults(Map<String, String> request) {
    String clientName = (request['اسم العميل'] ?? '').trim();
    String operation = (request['نوع العملية'] ?? '').toString().trim();
    String category = (request['الفئة'] ?? '').toString().trim();
    String targetProperty = (request['نوع العقار'] ?? '').toString().trim();
    String targetArea = (request['المساحة المطلوبة'] ?? '').toString().replaceAll('متر', '').trim();

    bool isRentOperation = operation.contains('إيجار') || operation.contains('ايجار') ||
        category.contains('إيجار') || category.contains('ايجار');

    String storageKey = isRentOperation ? 'العقارات المعروضة للإيجار' : 'العقارات المعروضة للبيع';
    var rawList = AppData.storage[storageKey] ??
        AppData.storage[isRentOperation ? 'بيانات الإيجار' : 'بيانات البيع'] ?? [];

    List<Map<String, String>> sourceList = List<Map<String, String>>.from(
        rawList.map((e) => Map<String, String>.from(e))
    );

    return sourceList.where((item) {
      String itemStatus = (item['الحالة'] ?? '').toString().trim();
      String itemProperty = (item['نوع العقار'] ?? '').toString().trim();
      String itemArea = (item['المساحة'] ?? '').toString().replaceAll('متر', '').trim();
      String reservedForClient = (item['محجوز للعميل'] ?? '').toString().trim();

      if (_searchPropertyFilter != 'الكل' && targetProperty != _searchPropertyFilter) {
        if (!targetProperty.contains(_searchPropertyFilter) && !itemProperty.contains(_searchPropertyFilter)) {
          return false;
        }
      }

      if ((itemStatus == 'محجوز' || itemStatus == 'تحت المعاينة') && reservedForClient.isNotEmpty && reservedForClient != clientName) {
        return false;
      }

      bool isAvailable = (itemStatus == 'متاح' || itemStatus.isEmpty);
      bool isReservedOrInspectedForThisUser = ((itemStatus == 'محجوز' || itemStatus == 'تحت المعاينة') && reservedForClient == clientName);

      if (!isAvailable && !isReservedOrInspectedForThisUser) return false;

      bool matchProperty = targetProperty.isEmpty || itemProperty.contains(targetProperty) || targetProperty.contains(itemProperty);
      bool matchArea = targetArea.isEmpty || itemArea == '-' || itemArea.contains(targetArea) || targetArea.contains(itemArea);

      return matchProperty && matchArea;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    var rawList = AppData.storage['طلبات العملاء'] ?? [];
    var requestsList = List<Map<String, String>>.from(rawList.map((e) => Map<String, String>.from(e)));

    if (_searchPropertyFilter != 'الكل') {
      requestsList = requestsList.where((req) => (req['نوع العقار'] ?? '').trim() == _searchPropertyFilter).toList();
    }

    final totalRows = requestsList.length < 15 ? 15 : requestsList.length;
    List<String> propertyFilterOptions = ['الكل', ...AppDropdowns.propertyTypes];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلبات العملاء | منظومة الكابتن لإدارة العقارات', style: TextStyle(fontSize: 16)),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Badge(
                label: Text('${NotificationService.getAllActiveNotifications().length}'),
                child: const Icon(Icons.notifications_active, color: Colors.amber),
              ),
              tooltip: 'التنبيهات الحية',
              onPressed: () {
                NotificationService.showNotificationMenu(context);
              },
            ),
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
                          const SnackBar(content: Text('جاري طباعة تقرير طلبات العملاء الحالي...'), backgroundColor: Colors.cyan),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const BrokersScreen()),
                        );
                      },
                      icon: const Icon(Icons.arrow_right_rounded, color: Colors.amberAccent, size: 22),
                      label: const Text('الصفحة السابقة', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const ForSaleScreen()),
                        );
                      },
                      icon: const Icon(Icons.arrow_left_rounded, color: Colors.amberAccent, size: 22),
                      label: const Text('الصفحة التالية', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onPressed: _showSmartParserDialog,
                      icon: const Icon(Icons.paste, color: Colors.white, size: 18),
                      label: const Text('تحليل رسالة واتساب', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onPressed: () => _showAddRequestDialog(),
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 18),
                      label: const Text('إضافة طلب عميل', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amberAccent, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('بحث بنوع العقار: ', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                          const SizedBox(width: 6),
                          DropdownButton<String>(
                            value: propertyFilterOptions.contains(_searchPropertyFilter) ? _searchPropertyFilter : 'الكل',
                            dropdownColor: const Color(0xFF1E1E1E),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            underline: const SizedBox.shrink(),
                            items: propertyFilterOptions.map((prop) {
                              return DropdownMenuItem<String>(
                                value: prop,
                                child: Text(prop, style: const TextStyle(color: Colors.white)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _searchPropertyFilter = val);
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                      onPressed: () {},
                      child: const Text('الطلبات', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
                  const Text('إحصائيات الطلبات:', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
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
                        const Text('إجمالي الطلبات المعروضة: ', style: TextStyle(color: Colors.white, fontSize: 12)),
                        Text('${requestsList.length}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
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
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: constraints.maxWidth),
                            child: Table(
                              border: TableBorder.all(color: Colors.grey.shade800, width: 1),
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              columnWidths: const {
                                0: IntrinsicColumnWidth(),
                                1: IntrinsicColumnWidth(),
                                2: IntrinsicColumnWidth(),
                                3: IntrinsicColumnWidth(),
                                4: IntrinsicColumnWidth(),
                                5: IntrinsicColumnWidth(),
                                6: IntrinsicColumnWidth(),
                                7: IntrinsicColumnWidth(),
                                8: IntrinsicColumnWidth(),
                                9: IntrinsicColumnWidth(),
                                10: IntrinsicColumnWidth(),
                              },
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(color: Color(0xFF2C2C2C)),
                                  children: [
                                    _buildHeaderCell('م', Colors.amberAccent),
                                    _buildHeaderCell('التاريخ', Colors.white),
                                    _buildHeaderCell('اسم العميل', Colors.white),
                                    _buildHeaderCell('نوع العملية', Colors.white),
                                    _buildHeaderCell('نوع العقار', Colors.white),
                                    _buildHeaderCell('وحدة القياس', Colors.white),
                                    _buildHeaderCell('الميزانية', Colors.white),
                                    _buildHeaderCell('المساحة المطلوبة', Colors.white),
                                    _buildHeaderCell('حالة المعروض والعقارات المطابقة', Colors.greenAccent),
                                    _buildHeaderCell('ملاحظات', Colors.white),
                                    _buildHeaderCell('حذف', Colors.redAccent),
                                  ],
                                ),
                                ...List.generate(totalRows, (index) {
                                  if (index < requestsList.length) {
                                    Map<String, String> item = requestsList[index];
                                    String currentClient = (item['اسم العميل'] ?? '').trim();
                                    List<Map<String, String>> rowMatches = _getMatchingResults(item);
                                    Color rowColor = index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525);

                                    return TableRow(
                                      decoration: BoxDecoration(color: rowColor),
                                      children: [
                                        _buildDataCell(Text('${index + 1}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11)), alignment: Alignment.center),
                                        _buildDataCell(Text(item['التاريخ'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(Text(currentClient, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11))),
                                        _buildDataCell(Text(item['نوع العملية'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(Text(item['نوع العقار'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(Text(item['وحدة القياس'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(Text(item['الميزانية'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(Text(item['المساحة المطلوبة'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(
                                          rowMatches.isEmpty
                                              ? const Text('لا توجد عقارات مطابقة', style: TextStyle(color: Colors.redAccent, fontSize: 10))
                                              : Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: List.generate(rowMatches.length, (matchIdx) {
                                              var matchProp = rowMatches[matchIdx];
                                              String propName = matchProp['نوع العقار'] ?? 'عقار';
                                              String propArea = matchProp['المساحة'] ?? matchProp['المساحة المطلوبة'] ?? '-';
                                              String propPrice = matchProp['السعر المطلوب'] ?? matchProp['السعر'] ?? '-';
                                              String propStatus = matchProp['الحالة'] ?? 'متاح';
                                              String reservedFor = matchProp['محجوز للعميل'] ?? '';
                                              bool isReserved = (propStatus == 'محجوز' && reservedFor == currentClient);
                                              bool isUnderInspection = false;

                                              return Container(
                                                margin: const EdgeInsets.symmetric(vertical: 1),
                                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: isReserved ? Colors.orange.shade900.withOpacity(0.8) : const Color(0xFF1B4D2E),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: isReserved ? Colors.amberAccent : Colors.greenAccent),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Checkbox(
                                                      value: isReserved,
                                                      activeColor: Colors.amber,
                                                      checkColor: Colors.black,
                                                      visualDensity: VisualDensity.compact,
                                                      onChanged: (val) async {
                                                        setState(() {
                                                          String operation = (item['نوع العملية'] ?? '').toString().trim();
                                                          String category = (item['الفئة'] ?? '').toString().trim();
                                                          bool isRentOperation = operation.contains('إيجار') || operation.contains('ايجار') || category.contains('إيجار') || category.contains('ايجار');
                                                          String storageKey = isRentOperation ? 'العقارات المعروضة للإيجار' : 'العقارات المعروضة للبيع';
                                                          var storageTarget = AppData.storage.containsKey(storageKey) ? storageKey : (isRentOperation ? 'بيانات الإيجار' : 'بيانات البيع');
                                                          List masterList = AppData.storage[storageTarget] ?? [];
                                                          int actualMatchIndex = masterList.indexWhere((element) => element['نوع العقار'] == matchProp['نوع العقار']);
                                                          if (val == true) {
                                                            if (actualMatchIndex != -1) {
                                                              masterList[actualMatchIndex]['الحالة'] = 'محجوز';
                                                              masterList[actualMatchIndex]['محجوز للعميل'] = currentClient;
                                                            }
                                                          } else {
                                                            if (actualMatchIndex != -1 && masterList[actualMatchIndex]['محجوز للعميل'] == currentClient) {
                                                              masterList[actualMatchIndex]['الحالة'] = 'متاح';
                                                              masterList[actualMatchIndex]['محجوز للعميل'] = '';
                                                            }
                                                          }
                                                        });
                                                        await LocalStorageService.saveLocally();
                                                        CloudSyncService.syncToCloud(isAuto: true);
                                                      },
                                                    ),
                                                    const Text('محجوز', style: TextStyle(color: Colors.white, fontSize: 9)),
                                                    const SizedBox(width: 2),
                                                    Checkbox(
                                                      value: isUnderInspection,
                                                      activeColor: Colors.amberAccent,
                                                      checkColor: Colors.black,
                                                      visualDensity: VisualDensity.compact,
                                                      onChanged: (val) async {
                                                        if (val == true) {
                                                          setState(() {
                                                            String operation = (item['نوع العملية'] ?? '').toString().trim();
                                                            String category = (item['الفئة'] ?? '').toString().trim();
                                                            bool isRentOperation = operation.contains('إيجار') || operation.contains('ايجار') || category.contains('إيجار') || category.contains('ايجار');
                                                            String storageKey = isRentOperation ? 'العقارات المعروضة للإيجار' : 'العقارات المعروضة للبيع';
                                                            var storageTarget = AppData.storage.containsKey(storageKey) ? storageKey : (isRentOperation ? 'بيانات الإيجار' : 'بيانات البيع');
                                                            List masterList = AppData.storage[storageTarget] ?? [];
                                                            int actualMatchIndex = masterList.indexWhere((element) => element['نوع العقار'] == matchProp['نوع العقار']);
                                                            if (actualMatchIndex != -1) {
                                                              masterList[actualMatchIndex]['الحالة'] = 'تحت المعاينة';
                                                              masterList[actualMatchIndex]['محجوز للعميل'] = currentClient;
                                                            }
                                                            if (!AppData.storage.containsKey('المعاينات') || AppData.storage['المعاينات'] == null) {
                                                              AppData.storage['المعاينات'] = <Map<String, String>>[];
                                                            }
                                                            (AppData.storage['المعاينات'] as List).add({
                                                              'كود الوحدة': matchProp['كود الوحدة'] ?? '-',
                                                              'التاريخ': item['التاريخ'] ?? '',
                                                              'إسم المشتري': currentClient,
                                                              'نوع العملية': item['نوع العملية'] ?? 'شراء',
                                                              'نوع العقار': matchProp['نوع العقار'] ?? '',
                                                              'السعر المعروض': matchProp['السعر المطلوب'] ?? matchProp['السعر'] ?? '',
                                                              'رأى المشتري': '-',
                                                              'إسم المالك': matchProp['إسم المالك'] ?? '-',
                                                              'حالة المعاينة': 'تحت المعاينة',
                                                              'ملاحظات': item['ملاحظات'] ?? '',
                                                            });
                                                            requestsList.removeAt(index);
                                                            AppData.storage['طلبات العملاء'] = requestsList;
                                                          });
                                                          await LocalStorageService.saveLocally();
                                                          CloudSyncService.syncToCloud(isAuto: true);
                                                        }
                                                      },
                                                    ),
                                                    const Text('تحت المعاينة', style: TextStyle(color: Colors.white, fontSize: 9)),
                                                    const SizedBox(width: 4),
                                                    Text('$propName ($propArea - $propPrice)', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                        _buildDataCell(Text(item['ملاحظات'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11))),
                                        _buildDataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () async {
                                              setState(() {
                                                if (!AppData.storage.containsKey('trash_bin') || AppData.storage['trash_bin'] == null) {
                                                  AppData.storage['trash_bin'] = <Map<String, String>>[];
                                                }

                                                Map<String, String> deletedItem = Map<String, String>.from(requestsList[index]);
                                                final now = DateTime.now();
                                                deletedItem['source_screen'] = 'طلبات العملاء';
                                                deletedItem['deleted_date'] = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                                                (AppData.storage['trash_bin'] as List).add(deletedItem);
                                                requestsList.removeAt(index);
                                                AppData.storage['طلبات العملاء'] = requestsList;
                                              });

                                              await LocalStorageService.saveLocally();
                                              CloudSyncService.syncToCloud(isAuto: true);

                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('تم نقل طلب العميل إلى سلة المهملات بنجاح'), backgroundColor: Colors.orange),
                                                );
                                              }
                                            },
                                          ),
                                          alignment: Alignment.center,
                                        ),
                                      ],
                                    );
                                  } else {
                                    return TableRow(
                                      decoration: BoxDecoration(color: index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525)),
                                      children: List.generate(11, (_) => const SizedBox(height: 30)),
                                    );
                                  }
                                }),
                              ],
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

  Widget _buildHeaderCell(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(Widget child, {Alignment alignment = Alignment.centerRight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Align(
        alignment: alignment,
        child: child,
      ),
    );
  }
}