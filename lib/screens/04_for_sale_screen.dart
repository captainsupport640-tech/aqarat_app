import '../app_imports.dart';

class ForSaleScreen extends StatefulWidget {
  const ForSaleScreen({super.key});

  @override
  State<ForSaleScreen> createState() => _ForSaleScreenState();
}

class _ForSaleScreenState extends State<ForSaleScreen> {
  final List categoryOptions = ['بيع', 'تنازل', 'بدل'];

  final List statusOptions = [
    'متاح',
    'تحت المعاينة',
    'محجوز',
    'تم البيع',
    'تم الإيجار',
    'موقوف',
    'ملغي'
  ];

  String selectedSearchFilter = 'الكل';

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

  String _getNextCode() {
    final propertiesList = AppData.storage['العقارات المعروضة للبيع'] ?? [];
    int maxId = 0;
    for (var item in propertiesList) {
      String code = item['كود الوحدة'] ?? '';
      int? num = int.tryParse(code.replaceAll(RegExp(r'[^0-9]'), ''));
      if (num != null && num > maxId) {
        maxId = num;
      }
    }
    return 'S${maxId + 1}';
  }

  void _showAddPropertyDialog({ParsedPropertyData? initialData}) {
    final clientNames = AppDropdowns.getClientNames();
    List validClients = (clientNames.isEmpty || clientNames.first == 'لا توجد عملاء مسجلة')
        ? ['عميل عام']
        : clientNames;

    String selectedClient = validClients.first.toString();
    if (initialData?.ownerName != null && initialData!.ownerName!.isNotEmpty) {
      for (var c in validClients) {
        if (c.toString().contains(initialData.ownerName!)) {
          selectedClient = c.toString();
          break;
        }
      }
    }

    String selectedCategory = categoryOptions.first.toString();

    String selectedPropertyType =
        AppDropdowns.propertyTypes.isNotEmpty ? AppDropdowns.propertyTypes.first : 'شقة سكنية';
    if (initialData?.propertyType != null && initialData!.propertyType!.isNotEmpty) {
      for (var t in AppDropdowns.propertyTypes) {
        if (t.contains(initialData.propertyType!)) {
          selectedPropertyType = t;
          break;
        }
      }
    }

    String selectedUnit = AppDropdowns.measurementUnits.isNotEmpty ? AppDropdowns.measurementUnits.first : 'متر';
    String selectedLocation = AppDropdowns.locations.isNotEmpty ? AppDropdowns.locations.first : 'القاهرة';

    final List viewOptions = ['بحري', 'قبلي', 'على الشارع الرئيسي', 'حدائق', 'ناصية', 'خلفي'];
    String selectedView = viewOptions.first.toString();
    String selectedStatus = statusOptions.first.toString();

    String newCode = _getNextCode();
    final codeController = TextEditingController(text: newCode);

    final areaController = TextEditingController(text: initialData?.area ?? '');
    final priceController = TextEditingController();

    String defaultNotes = initialData?.details ?? '';
    if (initialData?.phone != null && initialData!.phone!.isNotEmpty) {
      defaultNotes = 'رقم الهاتف: ${initialData.phone}\n$defaultNotes';
    }
    final notesController = TextEditingController(text: defaultNotes);

    void saveProperty() async {
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      setState(() {
        if (!AppData.storage.containsKey('العقارات المعروضة للبيع')) {
          AppData.storage['العقارات المعروضة للبيع'] = [];
        }
        AppData.storage['العقارات المعروضة للبيع']!.add({
          'الفئة': selectedCategory,
          'كود الوحدة': codeController.text.trim(),
          'التاريخ': dateStr,
          'إسم المالك': selectedClient,
          'نوع العقار': selectedPropertyType,
          'الموقع أو المنطقة': selectedLocation,
          'المساحة': areaController.text.trim().isEmpty ? '-' : areaController.text.trim(),
          'وحدة القياس': selectedUnit,
          'الفيو': selectedView,
          'السعر المطلوب': priceController.text.trim().isEmpty ? '-' : priceController.text.trim(),
          'الحالة': selectedStatus,
          'محجوز للعميل': (selectedStatus == 'محجوز' || selectedStatus == 'تحت المعاينة') ? selectedClient : '',
          'ملاحظات': notesController.text.trim().isEmpty ? '-' : notesController.text.trim(),
        });
      });

      await LocalStorageService.saveLocally();
      CloudSyncService.syncToCloud(isAuto: true);

      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ ومزامنة العقار سحابياً بنجاح في المنظومة!'), backgroundColor: Colors.green),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'إضافة عقار جديد للبيع ($newCode)',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: const Color(0xFF2C2C2C),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'الفئة',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFF252525),
                    ),
                    items: categoryOptions
                        .map((cat) => DropdownMenuItem<String>(value: cat.toString(), child: Text(cat.toString())))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeController,
                    readOnly: true,
                    style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'كود الوحدة (تلقائي)',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFF252525),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppDropdowns.buildDropdownField(
                    label: 'إسم المالك',
                    value: selectedClient,
                    items: List<String>.from(validClients),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedClient = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppDropdowns.buildDropdownField(
                    label: 'نوع العقار',
                    value: selectedPropertyType,
                    items: AppDropdowns.propertyTypes,
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedPropertyType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedLocation,
                    dropdownColor: const Color(0xFF2C2C2C),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'الموقع أو المنطقة',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFF252525),
                    ),
                    items: AppDropdowns.locations
                        .map((loc) => DropdownMenuItem<String>(value: loc, child: Text(loc)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedLocation = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areaController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'المساحة',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFF252525),
                    ),
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
                  DropdownButtonFormField<String>(
                    value: selectedView,
                    dropdownColor: const Color(0xFF2C2C2C),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'الفيو',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFF252525),
                    ),
                    items: viewOptions
                        .map((v) => DropdownMenuItem<String>(value: v.toString(), child: Text(v.toString())))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedView = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.text,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'السعر المطلوب (كتابة يدوية)',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFF252525),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    dropdownColor: const Color(0xFF2C2C2C),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'الحالة',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFF252525),
                    ),
                    items: statusOptions
                        .map((s) => DropdownMenuItem<String>(value: s.toString(), child: Text(s.toString())))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedStatus = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
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
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Colors.redAccent))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
              onPressed: saveProperty,
              child: const Text('حفظ العقار'),
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
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 26),
              SizedBox(width: 8),
              Text('تحليل نص رسالة (واتساب / ماسنجر)',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('قم بـ (نسخ ولصق) نص الرسالة غير المرتب هنا وسيقوم النظام بتوزيع البيانات تلقائياً:',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 10),
                TextField(
                  controller: rawTextController,
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'مثال: شقة للبيع في الشروق 150 متر مطلوب مليون و800 ألف للتواصل كابتن أحمد 01012345678...',
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
              label: const Text('تحليل واستخراج البيانات',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                if (rawTextController.text.trim().isEmpty) return;
                ParsedPropertyData parsedData = SmartTextParser.parseMessage(rawTextController.text);
                Navigator.pop(context);
                _showAddPropertyDialog(initialData: parsedData);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getRowColorByStatus(String status) {
    switch (status) {
      case 'متاح':
        return Colors.green.shade900.withOpacity(0.6);
      case 'تحت المعاينة':
        return Colors.amber.shade900.withOpacity(0.6);
      case 'محجوز':
      case 'تم البيع':
      case 'تم الإيجار':
      case 'موقوف':
      case 'ملغي':
        return Colors.red.shade900.withOpacity(0.6);
      default:
        return Colors.red.shade900.withOpacity(0.6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allProperties = AppData.storage['العقارات المعروضة للبيع'] ?? [];

    final propertiesList = allProperties.where((item) {
      if (selectedSearchFilter == 'الكل') return true;
      return (item['نوع العقار'] ?? '').toString().trim() == selectedSearchFilter;
    }).toList();

    final totalRows = propertiesList.length < 15 ? 15 : propertiesList.length;

    final Map propertyTypeCounts = {};
    for (var prop in allProperties) {
      final type = (prop['نوع العقار'] ?? 'أخرى').toString().trim();
      propertyTypeCounts[type] = (propertyTypeCounts[type] ?? 0) + 1;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المعروض للبيع | منظومة الكابتن لإدارة العقارات', style: TextStyle(fontSize: 16)),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.amber, size: 24),
              tooltip: 'الصفحة الرئيسية',
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
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
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade800,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onPressed: _showSmartParserDialog,
                      icon: const Icon(Icons.paste, color: Colors.white, size: 18),
                      label: const Text('تحليل رسالة واتساب',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onPressed: () => _showAddPropertyDialog(),
                      icon: const Icon(Icons.add_circle, color: Colors.white, size: 18),
                      label: const Text('إضافة عقار للبيع',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    PropertyFilterBar(
                      selectedFilter: selectedSearchFilter,
                      onFilterChanged: (newVal) {
                        setState(() => selectedSearchFilter = newVal);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF181818),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إحصائيات المعروضات (حسب نوع العقار):',
                      style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade900.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueAccent, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('إجمالي المعروضات',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration:
                                  BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(4)),
                              child: Text('${allProperties.length}',
                                  style:
                                      const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      ...propertyTypeCounts.entries.where((entry) => entry.value > 0).map((entry) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF252525),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  entry.key.toString(),
                                  style:
                                      const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.cyan.shade900,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${entry.value}',
                                    style: const TextStyle(
                                        color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
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
                                11: IntrinsicColumnWidth(),
                                12: IntrinsicColumnWidth(),
                                13: IntrinsicColumnWidth(),
                                14: IntrinsicColumnWidth(),
                              },
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(color: Color(0xFF2C2C2C)),
                                  children: [
                                    _buildHeaderCell('م', Colors.cyanAccent),
                                    _buildHeaderCell('الفئة', Colors.white),
                                    _buildHeaderCell('كود الوحدة', Colors.white),
                                    _buildHeaderCell('التاريخ', Colors.white),
                                    _buildHeaderCell('إسم المالك', Colors.white),
                                    _buildHeaderCell('نوع العقار', Colors.white),
                                    _buildHeaderCell('الموقع أو المنطقة', Colors.white),
                                    _buildHeaderCell('المساحة', Colors.white),
                                    _buildHeaderCell('وحدة القياس', Colors.white),
                                    _buildHeaderCell('الفيو', Colors.white),
                                    _buildHeaderCell('السعر المطلوب', Colors.white),
                                    _buildHeaderCell('الحالة', Colors.white),
                                    _buildHeaderCell('اسم العميل (الحاجز)', Colors.amberAccent),
                                    _buildHeaderCell('ملاحظات', Colors.white),
                                    _buildHeaderCell('حذف', Colors.redAccent),
                                  ],
                                ),
                                ...List.generate(totalRows, (index) {
                                  if (index < propertiesList.length) {
                                    Map item = propertiesList[index];
                                    String currentStatus = item['الحالة'] ?? 'متاح';
                                    if (!statusOptions.contains(currentStatus)) {
                                      currentStatus = 'متاح';
                                      item['الحالة'] = 'متاح';
                                    }

                                    final rowColor = _getRowColorByStatus(currentStatus);

                                    return TableRow(
                                      decoration: BoxDecoration(color: rowColor),
                                      children: [
                                        _buildDataCell(
                                            Text('${index + 1}',
                                                style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                                            alignment: Alignment.center),
                                        _buildDataCell(Text(item['الفئة'] ?? '',
                                            style: const TextStyle(
                                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                                        _buildDataCell(Text(item['كود الوحدة'] ?? '',
                                            style: const TextStyle(
                                                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                                        _buildDataCell(Text(item['التاريخ'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(Text(item['إسم المالك'] ?? '',
                                            style: const TextStyle(
                                                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11))),
                                        _buildDataCell(Text(item['نوع العقار'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(Text(item['الموقع أو المنطقة'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(Text(item['المساحة'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(Text(item['وحدة القياس'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(Text(item['الفيو'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(Text(item['السعر المطلوب'] ?? '',
                                            style: const TextStyle(color: Colors.white, fontSize: 11))),
                                        _buildDataCell(
                                          DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: currentStatus,
                                              dropdownColor: const Color(0xFF2C2C2C),
                                              style: TextStyle(
                                                color: currentStatus == 'متاح'
                                                    ? Colors.greenAccent
                                                    : currentStatus == 'تحت المعاينة'
                                                        ? Colors.amberAccent
                                                        : Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                              items: statusOptions.map((status) {
                                                Color c = Colors.white;
                                                if (status == 'متاح') {
                                                  c = Colors.greenAccent;
                                                } else if (status == 'تحت المعاينة') {
                                                  c = Colors.amberAccent;
                                                } else {
                                                  c = Colors.redAccent;
                                                }

                                                return DropdownMenuItem<String>(
                                                  value: status.toString(),
                                                  child: Text(status.toString(),
                                                      style: TextStyle(
                                                          color: c, fontWeight: FontWeight.bold, fontSize: 11)),
                                                );
                                              }).toList(),
                                              onChanged: (newVal) async {
                                                if (newVal != null) {
                                                  setState(() {
                                                    item['الحالة'] = newVal;
                                                    if (newVal != 'محجوز' && newVal != 'تحت المعاينة') {
                                                      item['محجوز للعميل'] = '';
                                                    }
                                                  });
                                                  await LocalStorageService.saveLocally();
                                                  CloudSyncService.syncToCloud(isAuto: true);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        _buildDataCell(
                                          Text(
                                            item['محجوز للعميل'] ?? '-',
                                            style: const TextStyle(
                                                color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 11),
                                          ),
                                        ),
                                        _buildDataCell(Text(item['ملاحظات'] ?? '',
                                            style: const TextStyle(color: Colors.white70, fontSize: 11))),
                                        _buildDataCell(
                                          IconButton(
                                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 18),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () async {
                                              setState(() {
                                                if (!AppData.storage.containsKey('trash_bin') ||
                                                    AppData.storage['trash_bin'] == null) {
                                                  AppData.storage['trash_bin'] = [];
                                                }

                                                Map<String, String> deletedItem =
                                                    Map<String, String>.from(propertiesList[index]);
                                                final now = DateTime.now();
                                                deletedItem['source_screen'] = 'العقارات المعروضة للبيع';
                                                deletedItem['deleted_date'] =
                                                    "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                                                (AppData.storage['trash_bin'] as List).add(deletedItem);
                                                allProperties.remove(propertiesList[index]);
                                              });

                                              await LocalStorageService.saveLocally();
                                              CloudSyncService.syncToCloud(isAuto: true);

                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                      content:
                                                          Text('تم نقل العقار إلى سلة المهملات وتحديث السحابة بنجاح'),
                                                      backgroundColor: Colors.orange),
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
                                      decoration: BoxDecoration(
                                          color: index.isEven ? const Color(0xFF1E1E1E) : const Color(0xFF252525)),
                                      children: List.generate(15, (_) => const SizedBox(height: 30)),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(Widget child, {Alignment alignment = Alignment.centerRight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Align(
        alignment: alignment,
        child: child,
      ),
    );
  }
}