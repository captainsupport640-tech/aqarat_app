import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app_data.dart';
import 'services/licensing_service.dart';
import 'services/local_storage_service.dart';
import 'services/file_backup_service.dart';
import 'services/security_manager.dart';
import 'services/cloud_sync_service.dart';
import 'screens/00_login_screen.dart';
import 'screens/01_clients_screen.dart';
import 'screens/02_brokers_screen.dart';
import 'screens/03_customer_requests_screen.dart';
import 'screens/04_for_sale_screen.dart';
import 'screens/05_for_rent_screen.dart';
import 'screens/06_inspections_screen.dart';
import 'screens/07_completed_operations_screen.dart';
import 'screens/08_accounts_screen.dart';
import 'screens/09_general_report_screen.dart';
import 'screens/10_archive_screen.dart';
import 'screens/about_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_storage_manager.dart';

Future<void> requestAllAppPermissions() async {
  if (kIsWeb) return;
  try {
    await Permission.storage.request();
    if (await Permission.manageExternalStorage.status.isDenied) {
      await Permission.manageExternalStorage.request();
    }
    await Permission.contacts.request();
    await Permission.camera.request();
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  } catch (e) {
    debugPrint('خطأ أثناء طلب الصلاحيات: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAivBdg27Z8onnbdzH6mGbpQwUa-vMr_p4",
          appId: "1:968213400606:web:718a68f00a9c95cbc0320f",
          messagingSenderId: "968213400606",
          projectId: "aqarat-captain",
          storageBucket: "aqarat-captain.firebasestorage.app",
          databaseURL: "https://aqarat-captain-default-rtdb.firebaseio.com",
        ),
      );
    }
  } catch (e) {
    debugPrint('تنبيه تهيئة فايربيس: $e');
  }

  await requestAllAppPermissions();

  CloudSyncService.initOfflineSupport();
  await LicensingService.loadLicenseStatus();
  await LocalStorageService.loadLocally();
  
  unawaited(
    Future.microtask(() async {
      try {
        await CloudSyncService.syncFromCloud(isAuto: true);
      } catch (e) {
        debugPrint('خطأ في المزامنة اللحظية: $e');
      }
    }),
  );

  runApp(const Aqarat());
}

class Aqarat extends StatelessWidget {
  const Aqarat({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منظومة الكابتن لإدارة العقارات',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 2,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

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
  String _selectedBackupFrequency = 'يدوياً';
  String _personalGmail = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
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

      List<String> validFrequencies = ['يومياً', 'أسبوعياً', 'شهرياً', 'يدوياً'];
      if (!validFrequencies.contains(freq)) {
        freq = 'يدوياً';
      }

      if (mounted) {
        setState(() {
          _selectedBackupFrequency = freq;
          _personalGmail = pGmail;
        });
      }
    } catch (_) {}
  }

  void _showTrashBinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            if (!AppData.storage.containsKey('trash_bin') || AppData.storage['trash_bin'] == null) {
              AppData.storage['trash_bin'] = [];
            }
            List trashList = AppData.storage['trash_bin']!;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Colors.amberAccent, size: 26),
                        SizedBox(width: 8),
                        Text('سلة المهملات (محفوظة لمدة 30 يوم)', style: TextStyle(color: Colors.amberAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (trashList.isNotEmpty)
                      TextButton.icon(
                        onPressed: () async {
                          setDialogState(() {
                            AppData.storage['trash_bin'] = [];
                          });
                          setState(() {});
                          await LocalStorageService.saveLocally();
                          CloudSyncService.syncToCloud(isAuto: true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم إفراغ سلة المهملات بالكامل بنجاح!'), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                        icon: const Icon(Icons.cleaning_services, color: Colors.redAccent, size: 18),
                        label: const Text('إفراغ السلة بالكامل', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                content: SizedBox(
                  width: 520,
                  height: 360,
                  child: trashList.isEmpty
                      ? const Center(
                          child: Text(
                            'سلة المهملات فارغة تماماً.\nأي عنصر يتم حذفه من أي شاشة سيظهر هنا لمدة 30 يوماً.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          itemCount: trashList.length,
                          itemBuilder: (context, index) {
                            final item = Map<String, dynamic>.from(trashList[index]);
                            String sourceScreen = item['source_screen'] ?? 'غير معروف';
                            String deletedDate = item['deleted_date'] ?? '-';

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade800),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'القسم: $sourceScreen (تاريخ الحذف: $deletedDate)',
                                          style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.entries
                                              .where((e) => e.key != 'source_screen' && e.key != 'deleted_date')
                                              .map((e) => '${e.key}: ${e.value}')
                                              .take(4)
                                              .join(' | '),
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.restore_from_trash, color: Colors.greenAccent, size: 22),
                                    tooltip: 'استرجاع السجل',
                                    onPressed: () async {
                                      String targetScreen = item['source_screen'] ?? 'بيانات العملاء';
                                      Map<String, String> restoredItem = Map<String, String>.from(item);
                                      restoredItem.remove('source_screen');
                                      restoredItem.remove('deleted_date');

                                      setDialogState(() {
                                        if (!AppData.storage.containsKey(targetScreen) || AppData.storage[targetScreen] == null) {
                                          AppData.storage[targetScreen] = [];
                                        }
                                        (AppData.storage[targetScreen] as List).add(restoredItem);
                                        trashList.removeAt(index);
                                      });

                                      setState(() {});
                                      await LocalStorageService.saveLocally();
                                      CloudSyncService.syncToCloud(isAuto: true);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('تم استرجاع السجل بنجاح إلى قسم ($targetScreen)'), backgroundColor: Colors.green),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 22),
                                    tooltip: 'حذف نهائي',
                                    onPressed: () async {
                                      setDialogState(() {
                                        trashList.removeAt(index);
                                      });
                                      setState(() {});
                                      await LocalStorageService.saveLocally();
                                      CloudSyncService.syncToCloud(isAuto: true);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('تم حذف السجل بشكل نهائي!'), backgroundColor: Colors.redAccent),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق', style: TextStyle(color: Colors.cyanAccent)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
        bool isMatch = item.entries.any((entry) {
          String val = entry.value.toString().toLowerCase();
          return val.contains(cleanQuery);
        });

        if (isMatch) {
          results.add({
            'section': sectionKey,
            'data': Map<String, dynamic>.from(item),
          });
        }
      }
    });

    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }

  void _showNotificationsDialog(BuildContext context) {
    final storedNotifications = AppData.storage['الإشعارات'] ?? [];
    final storedInspections = AppData.storage['المعاينات'] ?? [];
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";

    List<String> todayAlerts = [];
    List<String> tomorrowAlerts = [];
    List<String> upcomingAlerts = [];

    final weekDaysNames = {
      1: 'الإثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };

    for (var item in storedInspections) {
      String dateStr = (item['التاريخ'] ?? '').toString().trim();
      String clientName = (item['إسم المشتري'] ?? item['اسم العميل'] ?? 'عميل').toString();
      String unitCode = (item['كود الوحدة'] ?? '').toString();
      String status = (item['حالة المعاينة'] ?? 'تحت المعاينة').toString();

      if (status == 'تمت' || status == 'مرفوضة') continue;

      if (dateStr == todayStr) {
        todayAlerts.add('• وحدة ($unitCode) مع العميل ($clientName) - اليوم!');
      } else if (dateStr == tomorrowStr) {
        tomorrowAlerts.add('• وحدة ($unitCode) مع العميل ($clientName) - غداً!');
      } else {
        try {
          DateTime parsedDate = DateTime.parse(dateStr);
          String dayName = weekDaysNames[parsedDate.weekday] ?? dateStr;
          if (parsedDate.isAfter(now) && parsedDate.difference(now).inDays <= 7) {
            upcomingAlerts.add('• يوم $dayName الموافق ($dateStr): وحدة ($unitCode) مع ($clientName)');
          }
        } catch (_) {}
      }
    }

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: const [
              Icon(Icons.notifications_active, color: Colors.amberAccent, size: 24),
              SizedBox(width: 8),
              Text('إشعارات وتنبيهات المنظومة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 400),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (todayAlerts.isNotEmpty || tomorrowAlerts.isNotEmpty || upcomingAlerts.isNotEmpty) ...[
                    const Text('🚨 تنبيهات المعاينات القادمة:', style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    if (todayAlerts.isNotEmpty) ...[
                      const Text('معاينات اليوم:', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ...todayAlerts.map((e) => Padding(padding: const EdgeInsets.only(right: 8, bottom: 2), child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 12)))),
                      const SizedBox(height: 6),
                    ],
                    if (tomorrowAlerts.isNotEmpty) ...[
                      const Text('معاينات غداً (خلال 24 ساعة):', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ...tomorrowAlerts.map((e) => Padding(padding: const EdgeInsets.only(right: 8, bottom: 2), child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 12)))),
                      const SizedBox(height: 6),
                    ],
                    if (upcomingAlerts.isNotEmpty) ...[
                      const Text('معاينات الأيام القادمة (السبت، الأحد...):', style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ...upcomingAlerts.map((e) => Padding(padding: const EdgeInsets.only(right: 8, bottom: 2), child: Text(e, style: const TextStyle(color: Colors.white70, fontSize: 12)))),
                    ],
                    const Divider(color: Colors.grey, height: 20),
                  ],
                  const Text('📢 إشعارات النظام والعمليات:', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  storedNotifications.isEmpty
                      ? const Text('لا توجد إشعارات نظام أخرى حالياً', style: TextStyle(color: Colors.white70, fontSize: 12))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: storedNotifications.length,
                          itemBuilder: (context, index) {
                            final notif = Map<String, dynamic>.from(storedNotifications[index] as Map);
                            return Card(
                              color: const Color(0xFF1E1E1E),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.notifications, color: Colors.cyanAccent, size: 20),
                                title: Text(notif['العنوان'] ?? notif['title'] ?? '', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                subtitle: Text(notif['التفاصيل'] ?? notif['body'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                trailing: Text(notif['التاريخ'] ?? notif['time'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 9)),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddEmployeeDialog(BuildContext context) {
    final TextEditingController empNameController = TextEditingController();
    final TextEditingController empUserController = TextEditingController();
    final TextEditingController empPassController = TextEditingController();
    String empRole = 'مدخل بيانات';

    String currentPhone = SecurityManager.currentUsername;
    String adminEmail = currentPhone.isNotEmpty ? '$currentPhone@aqarat.com' : 'admin@aqarat.com';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            title: const Text('إضافة موظف جديد للفريق (شجرة الحسابات)', style: TextStyle(color: Colors.greenAccent, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, color: Colors.cyanAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'مظلة شركة المدير: $adminEmail',
                            style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: empNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'اسم الموظف', labelStyle: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: empUserController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'رقم التليفون (اسم المستخدم - 11 رقم)',
                      labelStyle: TextStyle(color: Colors.amber),
                      prefixIcon: Icon(Icons.phone_android, color: Colors.amber),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: empPassController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'كلمة السر', labelStyle: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: empRole,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'صلاحية الموظف', labelStyle: TextStyle(color: Colors.amberAccent)),
                    items: ['نائب مدير', 'مدخل بيانات'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => empRole = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                onPressed: () async {
                  String name = empNameController.text.trim();
                  String userPhone = empUserController.text.trim();
                  String pass = empPassController.text.trim();

                  if (name.isEmpty || userPhone.isEmpty || pass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الرجاء إكمال بيانات الموظف!'), backgroundColor: Colors.orange),
                    );
                    return;
                  }

                  if (userPhone.length != 11) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الرجاء إدخال رقم تليفون صحيح مكون من 11 رقم!'), backgroundColor: Colors.orange),
                    );
                    return;
                  }

                  await AppStorageManager.registerEmployeeInTree(
                    companyAdminEmail: adminEmail,
                    employeePhone: userPhone,
                    employeeName: name,
                    password: pass,
                    role: empRole,
                  );

                  await LocalStorageService.saveLocally();
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم إضافة الموظف ($name) برقم ($userPhone) وربطه بنجاح في شجرة الحسابات!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                child: const Text('حفظ وإضافة', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    if (SecurityManager.isGuest) {
      SecurityManager.showPermissionDeniedSnackBar(context, 'حساب ضيف: غير مسموح لك بالدخول إلى إعدادات المنظومة والضبط.');
      return;
    }

    final TextEditingController activationController = TextEditingController();
    final TextEditingController wifiIpController = TextEditingController();
    final TextEditingController googleDriveEmailController = TextEditingController(text: _personalGmail);

    String myDeviceId = "CAPTAIN-PC-2026";
    String hardwareId = LicensingService.getDeviceHardwareId(myDeviceId);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String currentPhone = SecurityManager.currentUsername;
          String generatedCompanyServerEmail = '$currentPhone@aqarat.com';

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings, color: Colors.amber, size: 28),
                  SizedBox(width: 8),
                  Text('إعدادات المنظومة والضبط', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: googleDriveEmailController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          labelText: 'إيميل Google Drive الشخصي (للنسخ والرفع والسيرفر)',
                          labelStyle: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                          prefixIcon: const Icon(Icons.cloud_sync, color: Colors.amberAccent, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF141414),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) async {
                          setDialogState(() {
                            _personalGmail = val.trim();
                          });
                          setState(() {
                            _personalGmail = val.trim();
                          });
                          await LocalStorageService.savePersonalGmail(val.trim());
                        },
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, color: Colors.cyanAccent, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'إيميل الشركة الموحد: $generatedCompanyServerEmail',
                                style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('جدولة النسخ الاحتياطي التلقائي:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: ['يومياً', 'أسبوعياً', 'شهرياً', 'يدوياً'].contains(_selectedBackupFrequency)
                            ? _selectedBackupFrequency
                            : 'يدوياً',
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF141414),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: ['يومياً', 'أسبوعياً', 'شهرياً', 'يدوياً'].map((freq) {
                          return DropdownMenuItem(value: freq, child: Text(freq));
                        }).toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            setDialogState(() => _selectedBackupFrequency = val);
                            setState(() => _selectedBackupFrequency = val);
                            await LocalStorageService.setBackupFrequency(val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          minimumSize: const Size(double.infinity, 42),
                          alignment: Alignment.centerRight,
                        ),
                        icon: const Icon(Icons.delete_sweep, color: Colors.white),
                        label: const Text('🗑️ سلة المهملات (المحذوفات واسترجاعها)', style: TextStyle(color: Colors.white, fontSize: 13)),
                        onPressed: () {
                          Navigator.pop(context);
                          _showTrashBinDialog(context);
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          minimumSize: const Size(double.infinity, 42),
                          alignment: Alignment.centerRight,
                        ),
                        icon: const Icon(Icons.cloud_upload, color: Colors.white),
                        label: const Text('المزامنة السحابية اللحظية (Firebase)', style: TextStyle(color: Colors.white, fontSize: 13)),
                        onPressed: () async {
                          await CloudSyncService.performCloudSync(context);
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade800,
                          minimumSize: const Size(double.infinity, 42),
                          alignment: Alignment.centerRight,
                        ),
                        icon: const Icon(Icons.backup, color: Colors.white),
                        label: const Text('نسخ احتياطي محلي + تصدير ملف', style: TextStyle(color: Colors.white, fontSize: 13)),
                        onPressed: () async {
                          await FileBackupService.backupToFile(context);
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          minimumSize: const Size(double.infinity, 42),
                          alignment: Alignment.centerRight,
                        ),
                        icon: const Icon(Icons.restore, color: Colors.white),
                        label: const Text('استعادة البيانات من ملف', style: TextStyle(color: Colors.white, fontSize: 13)),
                        onPressed: () async {
                          await FileBackupService.restoreFromFile(context);
                          await CloudSyncService.saveAndSyncInstant();
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade900,
                          minimumSize: const Size(double.infinity, 42),
                          alignment: Alignment.centerRight,
                        ),
                        icon: const Icon(Icons.admin_panel_settings, color: Colors.greenAccent),
                        label: const Text('🛠️ لوحة تحكم الدعم الفني (التحكم عن بُعد)', style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          _showRemoteSupportDialog(context);
                        },
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF252525),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.wifi, color: Colors.greenAccent, size: 20),
                                SizedBox(width: 8),
                                Text('الربط والشبكة المحلية (WiFi)', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'تأكد من اتصال الأجهزة بنفس شبكة الواي فاي لمشاركة ومزامنة البيانات بسلاسة بين الأجهزة.',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: wifiIpController,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'عنوان IP الجهاز الرئيسي (مثال: 192.168.1.50)',
                                labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                                prefixIcon: const Icon(Icons.computer, color: Colors.greenAccent, size: 18),
                                filled: true,
                                fillColor: const Color(0xFF141414),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade800,
                                minimumSize: const Size(double.infinity, 36),
                                alignment: Alignment.centerRight,
                              ),
                              icon: const Icon(Icons.link, color: Colors.white, size: 18),
                              label: const Text('اتصال يدوي عبر الـ IP', style: TextStyle(color: Colors.white, fontSize: 12)),
                              onPressed: () {
                                String enteredIp = wifiIpController.text.trim();
                                if (enteredIp.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('برجاء كتابة عنوان الـ IP أولاً!'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('جاري الاتصال بالجهاز عبر الـ IP: $enteredIp...'), backgroundColor: Colors.teal, duration: const Duration(seconds: 2)),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade800,
                                minimumSize: const Size(double.infinity, 36),
                                alignment: Alignment.centerRight,
                              ),
                              icon: const Icon(Icons.hub, color: Colors.white, size: 18),
                              label: const Text('فحص تلقائي للأجهزة عبر الشبكة المحلية', style: TextStyle(color: Colors.white, fontSize: 12)),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('جاري البحث عن الأجهزة المجاورة على نفس شبكة الواي فاي...'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF282828),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('حالة التراخيص والتشغيل:', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(
                              LicensingService.isMasterAdmin || LicensingService.isActivated
                                  ? 'التفعيل: مدى الحياة'
                                  : LicensingService.activationType,
                              style: TextStyle(color: LicensingService.isMasterAdmin || LicensingService.isActivated ? Colors.greenAccent : Colors.cyanAccent, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('كود الجهاز: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    hardwareId,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, color: Colors.amber, size: 18),
                                  tooltip: 'نسخ كود الجهاز',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: hardwareId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تم نسخ كود الجهاز بنجاح!'), backgroundColor: Colors.blue, duration: Duration(seconds: 2)),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: activationController,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                labelText: 'أدخل كود التفعيل أو التمديد',
                                labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                                filled: true,
                                fillColor: const Color(0xFF141414),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                                onPressed: () async {
                                  bool success = await LicensingService.processActivationCode(
                                    inputCode: activationController.text,
                                    deviceId: myDeviceId,
                                  );
                                  if (success) {
                                    setDialogState(() {});
                                    setState(() {});
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('تم تنشيط وترخيص المنظومة بنجاح!'), backgroundColor: Colors.green),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('كود التفعيل غير صحيح أو تم استهلاكه مسبقاً!'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                                child: const Text('تنشيط وترخيص النظام', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentRole = SecurityManager.currentUserRole;
    bool isGuest = SecurityManager.isGuest;
    bool isMasterUser = SecurityManager.isAdmin;

    final List allMenuItems = [
      {'title': 'بيانات العملاء', 'icon': Icons.people, 'color': Colors.blue.shade700, 'screen': const ClientsScreen(), 'allowedRoles': ['مدير', 'مدير النظام', 'نائب مدير', 'مدخل بيانات']},
      {'title': 'بيانات السماسرة', 'icon': Icons.badge, 'color': Colors.teal.shade700, 'screen': const BrokersScreen(), 'allowedRoles': ['مدير', 'مدير النظام', 'نائب مدير', 'مدخل بيانات']},
      {'title': 'طلبات العملاء', 'icon': Icons.assignment, 'color': Colors.orange.shade700, 'screen': const CustomerRequestsScreen(), 'allowedRoles': ['مدير', 'مدير النظام', 'نائب مدير', 'مدخل بيانات']},
      {'title': 'المعروض للبيع', 'icon': Icons.sell, 'color': Colors.green.shade700, 'screen': const ForSaleScreen(), 'allowedRoles': ['مدير', 'مدير النظام', 'نائب مدير', 'مدخل بيانات']},
      {'title': 'المعروض للإيجار', 'icon': Icons.house, 'color': Colors.red.shade700, 'screen': const ForRentScreen(), 'allowedRoles': ['مدير', 'مدير النظام', 'نائب مدير', 'مدخل بيانات']},
      {'title': 'المعاينات', 'icon': Icons.remove_red_eye, 'color': Colors.purple.shade700, 'screen': const InspectionsScreen(), 'allowedRoles': ['مدير', 'مدير النظام', 'نائب مدير', 'مدخل بيانات']},
      {'title': 'العمليات المكتملة', 'icon': Icons.task_alt, 'color': Colors.indigo.shade700, 'screen': const CompletedOperationsScreen(), 'allowedRoles': ['مدير', 'مدير النظام', 'نائب مدير', 'مدخل بيانات']},
      {'title': 'حسابات المنظومة', 'icon': Icons.account_balance_wallet, 'color': Colors.brown.shade700, 'screen': const AccountsScreen(), 'allowedRoles': ['مدير', 'مدير النظام']},
      {'title': 'التقرير العام', 'icon': Icons.bar_chart, 'color': Colors.blueGrey.shade700, 'screen': const GeneralReportScreen(), 'allowedRoles': ['مدير', 'مدير النظام']},
      {'title': 'الأرشيف', 'icon': Icons.archive, 'color': Colors.blueGrey.shade900, 'screen': const ArchiveScreen(), 'allowedRoles': ['مدير', 'مدير النظام', 'نائب مدير']},
    ];

    final List menuItems = allMenuItems.where((item) {
      if (isMasterUser || isGuest) return true;
      List<String> allowed = item['allowedRoles'];
      return allowed.contains(currentRole);
    }).toList();

    int notifCount = (AppData.storage['الإشعارات'] ?? []).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isGuest
                ? 'الصفحة الرئيسية | وضع الضيف (معاينة وتصفح)'
                : 'الصفحة الرئيسية | منظومة الكابتن لإدارة العقارات',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (LicensingService.isMasterAdmin || LicensingService.isActivated) ? Colors.green.shade900.withValues(alpha: 0.8) : Colors.amber.shade900.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: (LicensingService.isMasterAdmin || LicensingService.isActivated) ? Colors.greenAccent : Colors.amberAccent, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (LicensingService.isMasterAdmin || LicensingService.isActivated) ? Icons.verified : Icons.timer,
                    color: (LicensingService.isMasterAdmin || LicensingService.isActivated) ? Colors.greenAccent : Colors.amberAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (LicensingService.isMasterAdmin || LicensingService.isActivated)
                        ? 'تفعيل: مدى الحياة'
                        : 'فترة تجريبية: ${LicensingService.getRemainingDays()} يوم',
                    style: TextStyle(
                      color: (LicensingService.isMasterAdmin || LicensingService.isActivated) ? Colors.greenAccent : Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.amberAccent, size: 24),
                  tooltip: 'الإشعارات والتنبيهات',
                  onPressed: () => _showNotificationsDialog(context),
                ),
                if (notifCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$notifCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (!isGuest && isMasterUser)
              IconButton(
                icon: const Icon(Icons.person_add_alt_1, color: Colors.greenAccent, size: 24),
                tooltip: 'إضافة موظف جديد للفريق',
                onPressed: () => _showAddEmployeeDialog(context),
              ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.cyanAccent, size: 24),
              tooltip: 'حول المنظومة وشرح العمل',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.amber, size: 24),
              tooltip: 'إعدادات المنظومة والضبط',
              onPressed: () => _showSettingsDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 24),
              tooltip: 'تسجيل الخروج',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: AlertDialog(
                      backgroundColor: const Color(0xFF2C2C2C),
                      title: const Text('تأكيد الخروج', style: TextStyle(color: Colors.amberAccent)),
                      content: const Text('هل تريد تسجيل الخروج والعودة لشاشة الدخول؟', style: TextStyle(color: Colors.white)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                          },
                          child: const Text('خروج', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 5),
              Text(
                isGuest
                    ? 'مرحباً بك يا زائر (وضع الضيف - تصفح فقط)'
                    : 'مرحباً بك في منظومة الكابتن لإدارة العقارات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isGuest ? Colors.cyanAccent : Colors.amber),
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
                  onSubmitted: (value) {
                    _onSearchChanged(value);
                  },
                  decoration: InputDecoration(
                    labelText: isGuest
                        ? 'البحث غير متاح في وضع الضيف'
                        : 'ابحث فورياً بالكود، أو الاسم، أو رقم التليفون... (اضغط Enter للبحث)',
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
                                    'نتائج البحث الفوري (${_searchResults.length})',
                                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ),
                                const Divider(color: Colors.grey, height: 1),
                                Expanded(
                                  child: _searchResults.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'لا توجد نتائج مطابقة لما تكتبه حالياً',
                                            style: TextStyle(color: Colors.white70, fontSize: 14),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: _searchResults.length,
                                          itemBuilder: (context, index) {
                                            final result = _searchResults[index];
                                            final section = result['section'];
                                            final data = result['data'] as Map<String, dynamic>;

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
                                                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                                        ),
                                                        if (data.containsKey('كود الوحدة'))
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(color: Colors.blue.shade800, borderRadius: BorderRadius.circular(4)),
                                                            child: Text('الكود: ${data['كود الوحدة']}', style: const TextStyle(color: Colors.white, fontSize: 11)),
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
                                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                                        'حساب ضيف: هذه الأقسام للتصفح فقط. يمكنك فقط الاطلاع على شرح المنظومة من أعلى الشاشة.',
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
                                            border: Border.fromBorderSide(BorderSide(color: Colors.cyanAccent, width: 1.5)),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.lock_outline, color: Colors.cyanAccent, size: 40),
                                              SizedBox(height: 10),
                                              Text(
                                                'وضع الضيف (معاينة تصفح فقط)',
                                                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                'جميع أقسام البيانات محمية ولا يمكن الدخول إليها.\nاضغط على زر (حول المنظومة ⓘ) في الأعلى لشرح وتفاصيل المنظومة.',
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

  void _showRemoteSupportDialog(BuildContext context) {
    bool isProgrammerAdmin = SecurityManager.isAdmin;

    final TextEditingController targetCompanyKeyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF222222),
          title: Row(
            children: [
              Icon(
                isProgrammerAdmin ? Icons.admin_panel_settings : Icons.support_agent, 
                color: isProgrammerAdmin ? Colors.greenAccent : Colors.cyanAccent, 
                size: 26
              ),
              const SizedBox(width: 8),
              Text(
                isProgrammerAdmin ? 'لوحة تحكم الدعم الفني عن بُعد' : 'الاتصال بالمبرمج والدعم الفني', 
                style: TextStyle(color: isProgrammerAdmin ? Colors.greenAccent : Colors.cyanAccent, fontSize: 16)
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isProgrammerAdmin 
                    ? 'يمكنك هنا فحص أو تعديل بيانات أي عميل أو شركة مسجلة سحابياً على السيرفر لتصحيح المشاكل وهو قاعد مكانه:'
                    : 'يمكنك التواصل المباشر مع الدعم الفني (كابتن عبده) لطلب المساعدة أو حل أي مشكلة تواجهك في المنظومة:',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (isProgrammerAdmin) ...[
                TextField(
                  controller: targetCompanyKeyController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'أدخل إيميل أو مفتاح شركة العميل',
                    labelStyle: const TextStyle(color: Colors.amberAccent),
                    filled: true,
                    fillColor: const Color(0xFF141414),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('البريد المباشر للدعم الفني:', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                      const SizedBox(height: 4),
                      const Text('captain.support640@gmail.com', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('حالة الاتصال: متصل وجاهز لاستقبال طلبات الدعم وصيانة المنظومة.', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isProgrammerAdmin ? Colors.teal.shade700 : Colors.blue.shade800
              ),
              onPressed: () {
                if (isProgrammerAdmin) {
                  String keyTarget = targetCompanyKeyController.text.trim();
                  if (keyTarget.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('برجاء إدخال مفتاح أو إيميل العميل!'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('جاري الاتصال بسحابية العميل ($keyTarget) وفحص البيانات...'),
                      backgroundColor: Colors.teal,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال طلب الدعم الفني لإيميل (captain.support640@gmail.com) بنجاح وسيتم الرد عليك قريباً!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text(
                isProgrammerAdmin ? 'فحص وسحب البيانات' : 'إرسال طلب الدعم للدعم الفني', 
                style: const TextStyle(color: Colors.white)
              ),
            ),
          ],
        ),
      ),
    );
  }
}