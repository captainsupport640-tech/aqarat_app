import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/auto_save_service.dart';
import 'services/notification_service.dart';
import 'app_data.dart';
import 'services/local_network_scanner.dart';
import 'services/licensing_service.dart';
import 'services/local_storage_service.dart';
import 'services/file_backup_service.dart';
import 'services/security_manager.dart';
import 'services/cloud_sync_service.dart';
import 'services/support_service.dart';
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
  AutoSaveService.startAutoSave(intervalInSeconds: 30);
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
    _startRealtimeSyncListener();
  }

  void _startRealtimeSyncListener() {
    String currentEmail = SecurityManager.currentCompanyAdminEmail.trim();
    if (currentEmail.isEmpty) {
      currentEmail = 'captain.support640@gmail.com';
    }
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

          CloudSyncService.notifyDeviceSyncing(
            context: context,
            actionUser: SecurityManager.currentUsername.isEmpty ? 'جهاز مرتبط' : SecurityManager.currentUsername,
            actionRole: SecurityManager.currentUserRole,
            actionType: 'تحديث لحظي',
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    AppStorageManager.stopMasterDatabaseListener();
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

    // التفتيش المباشر بدون فحص النوع الزائد لإلغاء التحذير
    AppData.storage.forEach((sectionKey, listData) {
      for (var item in listData) {
        if (item is Map) {
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
      }
    });

    setState(() {
      _searchResults = results;
      _isSearching = true;
    });
  }  
  void _showAddEmployeeDialog(BuildContext context) {
    final TextEditingController empNameController = TextEditingController();
    final TextEditingController empUserController = TextEditingController();
    final TextEditingController empPassController = TextEditingController();
    String empRole = 'مدخل بيانات';

    String currentPhone = SecurityManager.currentUsername.trim();
    String adminEmail = SecurityManager.currentCompanyAdminEmail.trim();
    
    if (adminEmail.isEmpty) {
      if (SecurityManager.isAdmin) {
        adminEmail = currentPhone.isNotEmpty ? '$currentPhone@aqarat.com' : 'admin@aqarat.com';
      } else {
        adminEmail = 'captain.support640@gmail.com';
      }
    }

    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF2C2C2C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge, color: Colors.amberAccent, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'إدارة فريق العمل والموظفين',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'شركة المدير: $adminEmail',
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                const TabBar(
                  indicatorColor: Colors.amberAccent,
                  labelColor: Colors.amberAccent,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(icon: Icon(Icons.person_add, size: 18), text: 'إضافة موظف'),
                    Tab(icon: Icon(Icons.person_remove, size: 18), text: 'حذف موظف'),
                  ],
                ),
              ],
            ),
            content: SizedBox(
              width: 460,
              height: 320,
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: empNameController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(labelText: 'اسم الموظف', labelStyle: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: empUserController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'رقم التليفون (اسم المستخدم - 11 رقم)',
                            labelStyle: TextStyle(color: Colors.amber, fontSize: 12),
                            prefixIcon: Icon(Icons.phone_android, color: Colors.amber, size: 18),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: empPassController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(labelText: 'كلمة السر', labelStyle: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        const SizedBox(height: 8),
                        StatefulBuilder(
                          builder: (context, setRoleState) {
                            return DropdownButtonFormField<String>(
                              value: empRole,
                              dropdownColor: const Color(0xFF1E1E1E),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(labelText: 'الصلاحية', labelStyle: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                              items: ['نائب مدير', 'مدخل بيانات'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                              onChanged: (val) {
                                if (val != null) setRoleState(() => empRole = val);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          icon: const Icon(Icons.check_circle, color: Colors.white, size: 18),
                          label: const Text('حفظ وإضافة الموظف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            String name = empNameController.text.trim();
                            String userPhone = empUserController.text.trim();
                            String pass = empPassController.text.trim();

                            if (name.isEmpty || userPhone.isEmpty || pass.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('الرجاء إكمال كافة البيانات!'), backgroundColor: Colors.orange),
                              );
                              return;
                            }

                            if (userPhone.length != 11) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('رقم التليفون يجب أن يكون 11 رقماً!'), backgroundColor: Colors.orange),
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

                            if (!AppData.storage.containsKey('الحسابات') || AppData.storage['الحسابات'] == null) {
                              AppData.storage['الحسابات'] = [];
                            }
                            (AppData.storage['الحسابات'] as List).add({
                              'اسم الموظف': name,
                              'رقم التليفون': userPhone,
                              'الصلاحية': empRole,
                            });

                            await LocalStorageService.saveLocally();

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تم تسجيل الموظف ($name) وإعطائه الصلاحية بنجاح!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  StatefulBuilder(
                    builder: (context, setListState) {
                      List appUsers = AppData.storage['الحسابات'] ?? [];

                      if (appUsers.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا يوجد موظفون مسجلون حالياً تحت هذه الشركة.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: appUsers.length,
                        itemBuilder: (context, index) {
                          final emp = Map<String, dynamic>.from(appUsers[index]);
                          String empName = emp['اسم الموظف'] ?? emp['إسم الموظف'] ?? emp['الاسم'] ?? 'موظف';
                          String empPhone = emp['رقم التليفون'] ?? emp['الهاتف'] ?? '';

                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.person, color: Colors.cyanAccent, size: 22),
                              title: Text(empName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('تليفون: $empPhone', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 22),
                                tooltip: 'حذف الموظف نهائياً وإلغاء دخوله',
                                onPressed: () async {
                                  bool deleted = await AppStorageManager.deleteEmployeeFromTree(
                                    companyAdminEmail: adminEmail,
                                    employeePhone: empPhone,
                                  );

                                  if (deleted) {
                                    setListState(() {
                                      appUsers.removeAt(index);
                                    });
                                    await LocalStorageService.saveLocally();

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('تم حذف الموظف ($empName) وإلغاء صلاحية دخوله تماماً!'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق', style: TextStyle(color: Colors.cyanAccent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
           
  void _showSettingsDialog(BuildContext context) async {
    if (SecurityManager.isGuest) {
      SecurityManager.showPermissionDeniedSnackBar(context, 'حساب ضيف: غير مسموح لك بالدخول إلى إعدادات المنظومة والضبط.');
      return;
    }

    bool canAccess = await AppStorageManager.checkSettingsAccessAllowed(context);
    if (!canAccess) return;

    final TextEditingController activationController = TextEditingController();
    final TextEditingController googleDriveEmailController = TextEditingController(text: _personalGmail);

    String myDeviceId = "CAPTAIN-PC-2026";
    String hardwareId = LicensingService.getDeviceHardwareId(myDeviceId);

    if (context.mounted) {
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
                          icon: const Icon(Icons.folder_open, color: Colors.white),
                          label: const Text('نسخ احتياطي محلي + اختيار مجلد التنسيق', style: TextStyle(color: Colors.white, fontSize: 13)),
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
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade800,
                            minimumSize: const Size(double.infinity, 42),
                            alignment: Alignment.centerRight,
                          ),
                          icon: const Icon(Icons.wifi_find, color: Colors.white),
                          label: const Text('بحث يدوي عن أجهزة الشبكة (Wi-Fi)', style: TextStyle(color: Colors.white, fontSize: 13)),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NetworkScannerScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade800,
                            minimumSize: const Size(double.infinity, 42),
                            alignment: Alignment.centerRight,
                          ),
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                          label: const Text('تصدير المنظومة بالكامل إلى ملف PDF', style: TextStyle(color: Colors.white, fontSize: 13)),
                          onPressed: () async {
                            await FileBackupService.exportPdfToDocuments(context);
                          },
                        ),
                        const SizedBox(height: 10),
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
      {'title': 'العمليات المكتملة', 'icon': Icons.task_alt, 'color': Colors.indigo.shade700, 'screen': const CompletedOperationsScreen(), 'allowedRoles': ['مدير', 'مدير النظام', 'نائب مدير']},
      {'title': 'حسابات المنظومة', 'icon': Icons.account_balance_wallet, 'color': Colors.brown.shade700, 'screen': const AccountsScreen(), 'allowedRoles': ['مدير', 'مدير النظام']},
      {'title': 'التقرير العام', 'icon': Icons.bar_chart, 'color': Colors.blueGrey.shade700, 'screen': const GeneralReportScreen(), 'allowedRoles': ['مدير', 'مدير النظام']},
      {'title': 'الأرشيف', 'icon': Icons.archive, 'color': Colors.blueGrey.shade900, 'screen': const ArchiveScreen(), 'allowedRoles': ['مدير', 'مدير النظام', 'نائب مدير']},
    ];

    final List menuItems = allMenuItems.where((item) {
      if (isMasterUser || isGuest) return true;
      List<String> allowed = item['allowedRoles'];
      return allowed.contains(currentRole);
    }).toList();

    int unreadNotifCount = NotificationService.unreadCount;

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
                  onPressed: () => NotificationService.showNotificationMenu(context),
                ),
                if (unreadNotifCount > 0)
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
                        '$unreadNotifCount',
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
                tooltip: 'إدارة فريق العمل والموظفين',
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
                            SecurityManager.clearUserData();
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
                          child: LayoutBuilder(
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
    SupportService.requestRemoteSupport(context);
  }
}