import '../app_imports.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List _searchResults = [];
  bool _isSearching = false;
  String _selectedBackupFrequency = 'يومياً';
  String _personalGmail = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    NotificationService.refreshUnreadCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadSettings() async {
    try {
      await LicensingService.loadLicenseStatus();
      String freq = await LocalStorageService.getBackupFrequency();
      String pGmail = await LocalStorageService.getPersonalGmail();

      List validFrequencies = ['يومياً', 'أسبوعياً', 'شهرياً', 'يدوياً'];
      if (!validFrequencies.contains(freq)) {
        freq = 'يومياً';
      }

      if (mounted) {
        setState(() {
          _selectedBackupFrequency = freq;
          _personalGmail = pGmail;
        });
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    if (SecurityManager.currentUserRole == 'ضيف') return;

    String cleanQuery = query.trim().toLowerCase();

    if (cleanQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    List results = [];

    AppData.storage.forEach((sectionKey, listData) {
      for (var item in listData) {
        if (item is Map) {
          bool isMatch = item.values.any((val) {
            if (val == null) return false;
            return val.toString().toLowerCase().contains(cleanQuery);
          });

          if (isMatch) {
            results.add({
              'section': sectionKey,
              'data': Map<String, dynamic>.from(item),
            });
          }
        }
      }
    });

    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentRole = SecurityManager.currentUserRole;
    bool isGuest = SecurityManager.isGuest;
    bool isMasterUser = SecurityManager.isAdmin;

    final List allMenuItems = [
      {
        'title': 'بيانات العملاء',
        'icon': Icons.people,
        'color': Colors.blue.shade700,
        'screen': const ClientsScreen(),
        'allowedRoles': ['مدير']
      },
      {
        'title': 'بيانات السماسرة',
        'icon': Icons.badge,
        'color': Colors.teal.shade700,
        'screen': const BrokersScreen(),
        'allowedRoles': ['مدير']
      },
      {
        'title': 'طلبات العملاء',
        'icon': Icons.assignment,
        'color': Colors.orange.shade700,
        'screen': const CustomerRequestsScreen(),
        'allowedRoles': ['مدير', 'نائب مدير', 'مدير مكتب', 'مدير فرع', 'موظف مبيعات', 'مدخل بيانات']
      },
      {
        'title': 'المعروض للبيع',
        'icon': Icons.sell,
        'color': Colors.green.shade700,
        'screen': const ForSaleScreen(),
        'allowedRoles': ['مدير', 'نائب مدير', 'مدير مكتب', 'مدير فرع', 'موظف مبيعات', 'مدخل بيانات']
      },
      {
        'title': 'المعروض للإيجار',
        'icon': Icons.house,
        'color': Colors.red.shade700,
        'screen': const ForRentScreen(),
        'allowedRoles': ['مدير', 'نائب مدير', 'مدير مكتب', 'مدير فرع', 'موظف مبيعات', 'مدخل بيانات']
      },
      {
        'title': 'المعاينات',
        'icon': Icons.remove_red_eye,
        'color': Colors.purple.shade700,
        'screen': const InspectionsScreen(),
        'allowedRoles': ['مدير', 'نائب مدير', 'مدير مكتب', 'مدير فرع', 'موظف مبيعات', 'مدخل بيانات']
      },
      {
        'title': 'العمليات المكتملة',
        'icon': Icons.task_alt,
        'color': Colors.indigo.shade700,
        'screen': const CompletedOperationsScreen(),
        'allowedRoles': ['مدير', 'نائب مدير', 'مدير مكتب', 'مدير فرع']
      },
      {
        'title': 'الحسابات والمالية',
        'icon': Icons.account_balance_wallet,
        'color': Colors.brown.shade700,
        'screen': const AccountsScreen(),
        'allowedRoles': ['مدير']
      },
      {
        'title': 'التقرير العام',
        'icon': Icons.bar_chart,
        'color': Colors.blueGrey.shade700,
        'screen': const GeneralReportScreen(),
        'allowedRoles': ['مدير']
      },
      {
        'title': 'الأرشيف',
        'icon': Icons.archive,
        'color': Colors.blueGrey.shade900,
        'screen': const ArchiveScreen(),
        'allowedRoles': ['مدير']
      },
    ];

    final List menuItems = allMenuItems.where((item) {
      if (isMasterUser || isGuest) return true;
      List allowed = item['allowedRoles'] as List;
      return allowed.contains(currentRole);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFD54F),
          foregroundColor: Colors.black87,
          elevation: 4,
          title: Text(
            isGuest
                ? 'منظومة العقارات | وضع التصفح (للقراءة فقط)'
                : 'منظومة العقارات',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          actions: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (LicensingService.isMasterAdmin || LicensingService.isActivated)
                          ? const Color(0xFF1B5E20)
                          : const Color(0xFF4E342E),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: (LicensingService.isMasterAdmin || LicensingService.isActivated)
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (LicensingService.isMasterAdmin || LicensingService.isActivated)
                              ? Icons.verified
                              : Icons.timer,
                          color: (LicensingService.isMasterAdmin || LicensingService.isActivated)
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (LicensingService.isMasterAdmin || LicensingService.isActivated)
                              ? 'مفعل: مدى الحياة'
                              : 'فترة تجريبية: ${LicensingService.getRemainingDays()} يوم',
                          style: TextStyle(
                            color: (LicensingService.isMasterAdmin || LicensingService.isActivated)
                                ? Colors.greenAccent
                                : Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  ValueListenableBuilder<int>(
                    valueListenable: NotificationService.unreadCountNotifier,
                    builder: (context, notifCount, _) {
                      return Stack(
                        alignment: Alignment.topRight,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_active, color: Color(0xFF3E2723), size: 24),
                            tooltip: 'الإشعارات والتنبيهات',
                            onPressed: () {
                              NotificationService.showNotificationMenu(context);
                            },
                          ),
                          if (notifCount > 0)
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade800,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                child: Text(
                                  notifCount > 99 ? '+99' : '$notifCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  if (!isGuest && isMasterUser) ...[
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF1B5E20), size: 24),
                      tooltip: 'إدارة فريق العمل والموظفين',
                      onPressed: () => HomeEmployeesDialog.show(context),
                    ),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Color(0xFF01579B), size: 24),
                    tooltip: 'حول البرنامج والدعم الفني',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Color(0xFF212121), size: 24),
                    tooltip: 'إعدادات السيستم والنسخ',
                    onPressed: () => HomeSettingsDialog.show(
                      context: context,
                      initialBackupFrequency: _selectedBackupFrequency,
                      initialPersonalGmail: _personalGmail,
                      onBackupFrequencyChanged: (val) => setState(() => _selectedBackupFrequency = val),
                      onPersonalGmailChanged: (val) => setState(() => _personalGmail = val),
                      onDataRestored: () => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Color(0xFFB71C1C), size: 24),
                    tooltip: 'تسجيل الخروج',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: AlertDialog(
                            backgroundColor: const Color(0xFF2C2C2C),
                            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.amberAccent)),
                            content: const Text('هل تريد تسجيل الخروج والعودة لشاشة الدخول؟',
                                style: TextStyle(color: Colors.white)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                      context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                                },
                                child: const Text('خروج', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: isGuest
            ? null
            : Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BCD4), Color(0xFF7C4DFF), Color(0xFFFFB300)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiChatScreen()),
                    );
                  },
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  icon: const Icon(Icons.auto_awesome, size: 24, color: Colors.white),
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'المساعد الذكي',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.mic, size: 18, color: Colors.amberAccent),
                    ],
                  ),
                ),
              ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 5),
              Text(
                isGuest
                    ? 'مرحباً بك في وضع التصفح (للقراءة فقط)'
                    : 'مرحباً بك في منظومة الكابتن لإدارة العقارات',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: isGuest ? Colors.cyanAccent : Colors.amber),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  enabled: !isGuest,
                  style: const TextStyle(color: Colors.white),
                  onChanged: _onSearchChanged,
                  onSubmitted: _onSearchChanged,
                  decoration: InputDecoration(
                    labelText: isGuest
                        ? 'البحث غير متاح في وضع التصفح'
                        : 'بحث شامل بالاسم، الهاتف، أو كود الوحدة... (اضغط Enter للبحث)',
                    labelStyle: TextStyle(color: isGuest ? Colors.grey : Colors.white70, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: isGuest ? Colors.grey : Colors.cyanAccent),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.redAccent),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: _isSearching
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF181818),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Text(
                                    'نتائج البحث الشامل (${_searchResults.length})',
                                    style: const TextStyle(
                                        color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                const Divider(color: Colors.grey, height: 1),
                                Expanded(
                                  child: _searchResults.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'لا توجد نتائج مطابقة لكلمة البحث',
                                            style: TextStyle(color: Colors.white70, fontSize: 14),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: _searchResults.length,
                                          itemBuilder: (context, index) {
                                            final result = _searchResults[index];
                                            final section = result['section'];
                                            final data = Map<String, dynamic>.from(result['data'] as Map);

                                            return Card(
                                              color: const Color(0xFF252525),
                                              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          'القسم: $section',
                                                          style: const TextStyle(
                                                              color: Colors.cyanAccent,
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 13),
                                                        ),
                                                        if (data.containsKey('كود الوحدة'))
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                                color: Colors.blue.shade800,
                                                                borderRadius: BorderRadius.circular(4)),
                                                            child: Text('الكود: ${data['كود الوحدة']}',
                                                                style: const TextStyle(
                                                                    color: Colors.white, fontSize: 11)),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    ...data.entries.take(4).map((entry) => Padding(
                                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                                          child: Text(
                                                            '${entry.key}: ${entry.value}',
                                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                          ),
                                                        )),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Stack(
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  int crossAxisCount = constraints.maxWidth > 550 ? 3 : 2;

                                  return GridView.builder(
                                    padding: const EdgeInsets.only(bottom: 70),
                                    itemCount: menuItems.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: 1.5,
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = menuItems[index];
                                      return ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: item['color'],
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 4,
                                        ),
                                        onPressed: isGuest
                                            ? null
                                            : () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => item['screen']),
                                                ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(item['icon'], size: 32, color: Colors.white),
                                            const SizedBox(height: 8),
                                            Text(
                                              item['title'],
                                              style: const TextStyle(
                                                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              if (isGuest)
                                Positioned.fill(
                                  child: GestureDetector(
                                    onTap: () {
                                      SecurityManager.showPermissionDeniedSnackBar(
                                        context,
                                        'تنبيه هام: هذه الأقسام للقراءة فقط. لتفعيل كافة الصلاحيات يرجى تسجيل الدخول بحساب الشركة.',
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.55),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          margin: const EdgeInsets.symmetric(horizontal: 20),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF2C2C2C),
                                            borderRadius: BorderRadius.all(Radius.circular(12)),
                                            border: Border.fromBorderSide(
                                                BorderSide(color: Colors.cyanAccent, width: 1.5)),
                                          ),
                                          child: const Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.lock_outline, color: Colors.cyanAccent, size: 40),
                                              SizedBox(height: 10),
                                              Text(
                                                'وضع التصفح (للقراءة فقط)',
                                                style: TextStyle(
                                                    color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                'أنت تتصفح السيستم حالياً كضيف بدون صلاحيات تعديل.\nاضغط على زر (حول البرنامج ؟) في الأعلى لطلب اشتراكك الخاص.',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(color: Colors.white70, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}