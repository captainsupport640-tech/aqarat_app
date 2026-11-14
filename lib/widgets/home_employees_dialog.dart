import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_imports.dart';
import '../services/server_config.dart';

class HomeEmployeesDialog {
  static String _sanitizeEmailKey(String email) {
    return email.trim().toLowerCase().replaceAll('.', '_').replaceAll('@', '_at_');
  }

  static Future<List> _fetchEmployeesFromServer(String companyKey) async {
    final url = Uri.parse(ServerConfig.getCompanyDatabaseUrl(companyKey, ServerConfig.usersNode));
    final response = await http.get(url).timeout(const Duration(seconds: 6));

    if (response.statusCode != 200 || response.body == 'null' || response.body.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(response.body);
    final List list = [];

    if (decoded is Map) {
      decoded.forEach((key, value) {
        if (value is Map) {
          final mapItem = Map<String, dynamic>.from(value);
          mapItem['_nodeKey'] = key.toString();
          list.add(mapItem);
        }
      });
    } else if (decoded is List) {
      for (int i = 0; i < decoded.length; i++) {
        if (decoded[i] is Map) {
          final mapItem = Map<String, dynamic>.from(decoded[i]);
          mapItem['_nodeKey'] = i.toString();
          list.add(mapItem);
        }
      }
    }
    return list;
  }

  static void show(BuildContext context) {
    final TextEditingController empNameController = TextEditingController();
    final TextEditingController empUserController = TextEditingController();
    final TextEditingController empPassController = TextEditingController();
    String empRole = 'موظف مبيعات';

    String adminEmail = SecurityManager.currentCompanyAdminEmail.trim();
    if (adminEmail.isEmpty || !adminEmail.contains('@')) {
      adminEmail = 'captain.support640@gmail.com';
    }

    final String companyKey = _sanitizeEmailKey(adminEmail);

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
                    'سيرفر الشركة: $adminEmail',
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
              height: 340,
              child: TabBarView(
                children: [
                  // تبويب 1: إضافة موظف بالحقول العربية الأربعة تحت users
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: empNameController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                              labelText: 'الاسم', labelStyle: TextStyle(color: Colors.grey, fontSize: 12)),
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
                            labelText: 'رقم التليفون (11 رقم)',
                            labelStyle: TextStyle(color: Colors.amber, fontSize: 12),
                            prefixIcon: Icon(Icons.phone_android, color: Colors.amber, size: 18),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: empPassController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                              labelText: 'كلمة السر', labelStyle: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        const SizedBox(height: 8),
                        StatefulBuilder(
                          builder: (context, setRoleState) {
                            return DropdownButtonFormField<String>(
                              initialValue: empRole,
                              dropdownColor: const Color(0xFF1E1E1E),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                  labelText: 'الوظيفة',
                                  labelStyle: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                              items: ['نائب مدير', 'مدير مكتب', 'مدير فرع', 'موظف مبيعات', 'مدخل بيانات']
                                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                  .toList(),
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
                          label: const Text('حفظ بيانات الموظف على السيرفر',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            String name = empNameController.text.trim();
                            String userPhone = empUserController.text.trim();
                            String pass = empPassController.text.trim();

                            if (name.isEmpty || userPhone.isEmpty || pass.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('برجاء إدخال جميع البيانات!'), backgroundColor: Colors.orange),
                              );
                              return;
                            }

                            if (userPhone.length != 11) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('رقم التليفون يجب أن يكون 11 رقماً!'),
                                    backgroundColor: Colors.orange),
                              );
                              return;
                            }

                            try {
                              final url = Uri.parse(
                                  ServerConfig.getCompanyDatabaseUrl(companyKey, "${ServerConfig.usersNode}/$userPhone"));
                              final payload = {
                                'الاسم': name,
                                'رقم التليفون': userPhone,
                                'كلمة السر': pass,
                                'الوظيفة': empRole,
                              };

                              final res = await http
                                  .put(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
                                  .timeout(const Duration(seconds: 6));

                              if (res.statusCode == 200) {
                                LoginScreen.appUsers[userPhone] = {
                                  'company': LoginScreen.mainCompanyName,
                                  'firstName': name,
                                  'password': pass,
                                  'role': empRole,
                                  'license': 'ساري',
                                  'question': '',
                                  'answer': '',
                                  'email': '$userPhone@aqarat.com',
                                  'personalGmail': adminEmail,
                                };
                                await LocalStorageService.saveAppUsers(LoginScreen.appUsers);

                                empNameController.clear();
                                empUserController.clear();
                                empPassController.clear();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('تم تسجيل الموظف ($name) في الشجرة بنجاح!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                throw Exception('HTTP ${res.statusCode}');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تعذر الاتصال بالسيرفر: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // تبويب 2: عرض وحذف الموظفين مباشرة عبر HTTP REST API
                  StatefulBuilder(
                    builder: (context, setListState) {
                      return FutureBuilder<List>(
                        future: _fetchEmployeesFromServer(companyKey),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.amberAccent),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'تعذر تحميل الموظفين:\n${snapshot.error}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => setListState(() {}),
                                    child: const Text('إعادة المحاولة'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final List serverEmployees = snapshot.data ?? [];

                          if (serverEmployees.isEmpty) {
                            return const Center(
                              child: Text(
                                'لا يوجد موظفين مسجلين على سيرفر الشركة حالياً.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: serverEmployees.length,
                            itemBuilder: (context, index) {
                              final emp = Map<String, dynamic>.from(serverEmployees[index] as Map);
                              String nodeKey = (emp['_nodeKey'] ?? '').toString();
                              String empPhone =
                                  (emp['رقم التليفون'] ?? emp['phone'] ?? nodeKey).toString();
                              String empName =
                                  (emp['الاسم'] ?? emp['name'] ?? 'موظف ($empPhone)').toString();
                              String role = (emp['الوظيفة'] ?? emp['role'] ?? 'موظف').toString();

                              return Card(
                                color: const Color(0xFF1E1E1E),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: const Icon(Icons.person, color: Colors.cyanAccent, size: 22),
                                  title: Text(empName,
                                      style: const TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text('الموبايل: $empPhone  |  الوظيفة: $role',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 22),
                                    tooltip: 'حذف الموظف نهائياً من السيرفر',
                                    onPressed: () async {
                                      bool? confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: AlertDialog(
                                            backgroundColor: const Color(0xFF252525),
                                            title: const Text('تأكيد حذف الموظف',
                                                style: TextStyle(color: Colors.amberAccent, fontSize: 15)),
                                            content: Text(
                                                'هل أنت متأكد من حذف الموظف ($empName - $empPhone) من سيرفر الشركة؟',
                                                style: const TextStyle(color: Colors.white, fontSize: 13)),
                                            actions: [
                                              TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
                                              ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('حذف نهائي', style: TextStyle(color: Colors.white))),
                                            ],
                                          ),
                                        ),
                                      );

                                      if (confirm == true) {
                                        final delUrl = Uri.parse(ServerConfig.getCompanyDatabaseUrl(
                                            companyKey, "${ServerConfig.usersNode}/$nodeKey"));
                                        await http.delete(delUrl).timeout(const Duration(seconds: 6));

                                        LoginScreen.appUsers.remove(empPhone);
                                        await LocalStorageService.saveAppUsers(LoginScreen.appUsers);

                                        setListState(() {});

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('تم حذف الموظف ($empName) من سيرفر الشركة بنجاح!'),
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
}