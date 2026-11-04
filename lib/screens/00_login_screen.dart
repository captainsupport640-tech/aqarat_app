import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import '../main.dart';
import '../services/local_storage_service.dart';
import '../services/security_manager.dart';
import '../services/licensing_service.dart';
import '../app_storage_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static final Map<String, Map<String, String>> appUsers = {
    '01200626469': {
      'company': 'شركة ماهي البهوتي للاستثمار العقاري',
      'firstName': 'الكابتن عبد الجواد',
      'password': '1983',
      'role': 'مدير',
      'license': 'مدى الحياة',
      'question': 'ما هي مدينة ميلادك؟',
      'answer': 'القاهرة',
      'email': 'admin@aqarat.com',
      'personalGmail': 'captain.support640@gmail.com',
    },
    '01004026247': {
      'company': 'الدعم الفني المركزي',
      'firstName': 'المبرمج الرئيسي',
      'password': '1983',
      'role': 'مبرمج',
      'license': 'مدى الحياة',
      'question': 'ما هي مدينة ميلادك؟',
      'answer': 'القاهرة',
      'email': 'captain.support640@gmail.com',
      'personalGmail': 'captain.support640@gmail.com',
    },
  };

  static String mainCompanyName = 'شركة ماهي البهوتي للتسويق العقاري';
  static String subAppName = 'منظومة الكابتن للتسويق العقاري';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _gmailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = false;

  final FocusNode _gmailFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _newFirstNameController = TextEditingController();
  final TextEditingController _newUsernameController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _securityAnswerController = TextEditingController();

  String selectedSecurityQuestion = 'ما هي مدينة ميلادك؟';
  String selectedUserRole = 'مدخل بيانات';

  final List<String> securityQuestions = [
    'ما هي مدينة ميلادك؟',
    'ما هو اسمك الأفضل في الطفولة؟',
    'ما هو اسم حيوانك الأليف الأول؟'
  ];

  final List<String> availableRoles = [
    'مدير',
    'نائب مدير',
    'مدخل بيانات',
    'مبرمج',
  ];

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }

  // دالة التحقق من صحة رقم التليفون (11 رقم) وبدايته بالشبكات المتاحة
  bool _isValidEgyptianPhone(String phone) {
    if (phone.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return false;
    }
    List<String> validPrefixes = ['010', '011', '012', '015', '040'];
    return validPrefixes.any((prefix) => phone.startsWith(prefix));
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _gmailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _gmailFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _companyEmailController.dispose();
    _companyNameController.dispose();
    _newFirstNameController.dispose();
    _newUsernameController.dispose();
    _newPasswordController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  void _loadInitialData() async {
    await LocalStorageService.loadLocally();

    Map<String, Map<String, String>> savedUsers = await LocalStorageService.loadAppUsers();
    if (savedUsers.isNotEmpty) {
      LoginScreen.appUsers.addAll(savedUsers);
    }

    final prefs = await SharedPreferences.getInstance();
    bool remember = prefs.getBool('remember_me') ?? false;

    if (remember) {
      String savedGmail = prefs.getString('saved_gmail') ?? '';
      String savedUsername = prefs.getString('saved_username') ?? '';
      String savedPassword = prefs.getString('saved_password') ?? '';

      setState(() {
        _rememberMe = remember;
        _gmailController.text = savedGmail;
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
      });
    } else {
      setState(() {
        _rememberMe = false;
        _gmailController.clear();
        _usernameController.clear();
        _passwordController.clear();
      });
    }
  }

  void _login() async {
    String gmail = _gmailController.text.trim();
    String username = _usernameController.text.trim().replaceAll(' ', '');
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال اسم المستخدم وكلمة السر بدقة!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // التحقق من شرط 11 رقم للشبكات 010, 011, 012, 015, 040
    if (!_isValidEgyptianPhone(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: يجب إدخال رقم تليفون مكون من 11 رقم يبدأ بـ (010, 011, 012, 015, 040)!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    bool isValidUser = false;
    bool isMasterOrProgrammer = false;
    String userRole = 'مدير';
    String firstName = 'المدير';
    String adminGmail = gmail;

    // 1. التحقق الاستثنائي للأدمن والمبرمج الرئيسي
    if ((username == '01200626469' || username == '01004026247') && password == '1983') {
      isValidUser = true;
      isMasterOrProgrammer = true;
      userRole = username == '01004026247' ? 'مبرمج' : 'مدير';
      firstName = username == '01200626469' ? 'الكابتن عبد الجواد' : 'المبرمج الرئيسي';
    } else {
      // 2. فحص الخريطة المحلية أولاً للاستجابة السريعة
      if (LoginScreen.appUsers.containsKey(username)) {
        final userData = LoginScreen.appUsers[username]!;
        if ((userData['password'] ?? '').toString().trim() == password) {
          isValidUser = true;
          userRole = userData['role'] ?? 'مدخل بيانات';
          firstName = userData['firstName'] ?? 'موظف';
          adminGmail = userData['personalGmail'] ?? gmail;
        }
      }

      // 3. الفحص أونلاين في شجرة المستخدمين السحابية
      if (!isValidUser) {
        try {
          DatabaseEvent event = await FirebaseDatabase.instance.ref().child('companies_storage').once();
          if (event.snapshot.value != null) {
            Map<dynamic, dynamic> companies = event.snapshot.value as Map<dynamic, dynamic>;

            for (var companyKey in companies.keys) {
              var usersTree = companies[companyKey]['2_employees_tree'] ?? companies[companyKey]['2_users_tree'];
              
              if (usersTree != null && usersTree[username] != null) {
                var userData = usersTree[username];
                
                if (userData['password'].toString().trim() == password) {
                  isValidUser = true;
                  userRole = userData['role'] ?? 'مدخل بيانات';
                  firstName = userData['firstName'] ?? 'موظف';
                  adminGmail = companyKey.toString().replaceAll('_at_', '@').replaceAll('_', '.');
                  
                  // حفظ محلي لتسهيل الدخول القادم
                  LoginScreen.appUsers[username] = {
                    'company': LoginScreen.mainCompanyName,
                    'firstName': firstName,
                    'password': password,
                    'role': userRole,
                    'license': 'ساري',
                    'question': '',
                    'answer': '',
                    'email': "$username@aqarat.com",
                    'personalGmail': adminGmail,
                  };
                  await LocalStorageService.saveAppUsers(LoginScreen.appUsers);
                  break;
                }
              }
            }
          }
        } catch (e) {
          debugPrint("خطأ في الاتصال بقاعدة البيانات أونلاين: $e");
        }
      }
    }

    if (isValidUser) {
      if (adminGmail.isEmpty) {
        adminGmail = LoginScreen.appUsers[username]?['personalGmail'] ?? 
                await LocalStorageService.getPersonalGmail();
        if (adminGmail.isEmpty) adminGmail = 'admin@aqarat.com';
      }

      List<String> permissions = SecurityManager.rolePermissions[userRole] ?? 
          SecurityManager.rolePermissions['مدخل بيانات']!;

      await SecurityManager.saveSession(
        phone: username,
        email: "$username@aqarat.com",
        role: userRole,
        permissions: permissions,
        adminGmail: adminGmail,
      );

      if (isMasterOrProgrammer) {
        LicensingService.isActivated = true;
        LicensingService.isMasterAdmin = true;
        LicensingService.activationType = 'مدى الحياة';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_activated', true);
        await prefs.setBool('is_master_admin', true);
        await prefs.setString('activation_type', 'مدى الحياة');
      } else {
        await LicensingService.loadLicenseStatus();
      }

      if (adminGmail.isNotEmpty) {
        await LocalStorageService.savePersonalGmail(adminGmail);
        await LocalStorageService.loginWithEmail(adminGmail);
      }
      
      _executeSuccessfulLogin(username, adminGmail, isMasterAdmin: isMasterOrProgrammer);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: اسم المستخدم أو كلمة السر غير صحيحة!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _loginAsGuest() async {
    await SecurityManager.saveSession(
      phone: 'guest',
      email: 'guest@aqarat.com',
      role: 'ضيف',
      permissions: ['view'],
      adminGmail: 'guest_server',
    );
    _executeSuccessfulLogin('guest', 'guest@aqarat.com', isGuest: true);
  }

  void _executeSuccessfulLogin(String username, String gmail, {bool isGuest = false, bool isMasterAdmin = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!isGuest && gmail.isNotEmpty) {
      await LocalStorageService.loginWithEmail(gmail);
      await LocalStorageService.savePersonalGmail(gmail);
    }

    if (_rememberMe && !isGuest) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_gmail', gmail);
      await prefs.setString('saved_username', username);
      await prefs.setString('saved_password', _passwordController.text.trim());
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('saved_gmail');
      await prefs.remove('saved_username');
      await prefs.remove('saved_password');
    }

    String fName = isGuest ? 'زائر (تصفح فقط)' : (LoginScreen.appUsers[username]?['firstName'] ?? 'المدير');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('مرحباً بك يا $fName - تم الدخول بنجاح بصلاحية: ${SecurityManager.currentUserRole}'),
          backgroundColor: isGuest ? Colors.blue : Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _showRegisterDialog() {
    _companyEmailController.clear();
    _companyNameController.clear();
    _newFirstNameController.clear();
    _newUsernameController.clear();
    _newPasswordController.clear();
    _securityAnswerController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xFF2C2C2C),
                title: const Text(
                  'تسجيل حساب جديد وتنشيط المنظومة',
                  style: TextStyle(color: Colors.amberAccent, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _companyEmailController,
                        style: const TextStyle(color: Colors.cyanAccent),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (emailVal) {
                          if (emailVal.contains('@') && _newFirstNameController.text.isEmpty) {
                            String extractedName = emailVal.split('@').first;
                            extractedName = extractedName.replaceAll(RegExp(r'[0-9._-]'), ' ').trim();
                            if (extractedName.isNotEmpty) {
                              setDialogState(() {
                                _newFirstNameController.text = extractedName;
                              });
                            }
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'إدخال الجيميل لمدير الشركة الرئيسي',
                          labelStyle: TextStyle(color: Colors.cyanAccent),
                          prefixIcon: Icon(Icons.mark_email_read, color: Colors.cyanAccent),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _companyNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'اسم الشركة أو المكتب العقاري',
                          labelStyle: TextStyle(color: Colors.amberAccent),
                          prefixIcon: Icon(Icons.business, color: Colors.amberAccent),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newFirstNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم أو الموظف',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.person, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newUsernameController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'اسم المستخدم (رقم التليفون - 11 رقم)',
                          labelStyle: TextStyle(color: Colors.amber),
                          prefixIcon: Icon(Icons.phone_android, color: Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'كلمة السر',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.lock, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedUserRole,
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'الصلاحية والدور في المنظومة',
                          labelStyle: TextStyle(color: Colors.amberAccent),
                          prefixIcon: Icon(Icons.admin_panel_settings, color: Colors.amberAccent),
                        ),
                        items: availableRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedUserRole = val);
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: selectedSecurityQuestion,
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'سؤال الأمان للاستعادة',
                          labelStyle: TextStyle(color: Colors.amberAccent),
                          prefixIcon: Icon(Icons.security, color: Colors.amberAccent),
                        ),
                        items: securityQuestions.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedSecurityQuestion = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _securityAnswerController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'إجابة سؤال الأمان',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.question_answer, color: Colors.grey),
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                    onPressed: () async {
                      String rawEmail = _companyEmailController.text.trim();
                      String comp = _companyNameController.text.trim();
                      String fName = _newFirstNameController.text.trim();
                      String phoneUser = _newUsernameController.text.trim();
                      String pass = _newPasswordController.text.trim();
                      String ans = _securityAnswerController.text.trim();

                      if (rawEmail.isEmpty || comp.isEmpty || phoneUser.isEmpty || pass.isEmpty || fName.isEmpty || ans.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الرجاء إكمال جميع البيانات وسؤال الأمان!'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      if (!_isValidEgyptianPhone(phoneUser)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الرجاء إدخال رقم تليفون صحيح مكون من 11 رقم يبدأ بـ (010, 011, 012, 015, 040)!'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      if (!_isValidEmail(rawEmail)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('الرجاء إدخال إيميل صحيح بفرومات مكتملة!'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      // التسجيل السحابي الحقيقي في 2_employees_tree
                      await AppStorageManager.registerEmployeeInTree(
                              companyAdminEmail: rawEmail,
                              employeePhone: phoneUser,
                              employeeName: comp.isNotEmpty ? comp : 'مسؤول الشركة',
                              password: pass,
                              role: selectedUserRole,
                            );

                      await LocalStorageService.loginWithEmail(rawEmail);
                      await LocalStorageService.savePersonalGmail(rawEmail);

                      LoginScreen.mainCompanyName = comp;
                      LoginScreen.appUsers[phoneUser] = {
                        'company': comp,
                        'firstName': fName,
                        'password': pass,
                        'role': selectedUserRole,
                        'license': 'فترة تجريبية 30 يوم',
                        'question': selectedSecurityQuestion,
                        'answer': ans,
                        'email': "$phoneUser@aqarat.com",
                        'personalGmail': rawEmail,
                      };

                      await LocalStorageService.saveAppUsers(LoginScreen.appUsers);

                      setState(() {
                        _gmailController.text = rawEmail;
                        _usernameController.text = phoneUser;
                        _passwordController.text = pass;
                        _rememberMe = true;
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تسجيل حساب المستخدم وإضافته بنجاح!'), backgroundColor: Colors.green),
                      );
                    },
                    child: const Text('حفظ وتسجيل', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController recoverUserCtrl = TextEditingController();
    final TextEditingController recoverAnswerCtrl = TextEditingController();
    final TextEditingController newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: const Color(0xFF2C2C2C),
                title: const Text('استعادة وتغيير كلمة السر', style: TextStyle(color: Colors.amberAccent)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: recoverUserCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'اسم المستخدم (رقم التليفون - 11 رقم)',
                        labelStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.phone_android, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: recoverAnswerCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'إجابة سؤال الأمان', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'كلمة السر الجديدة', labelStyle: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
                    onPressed: () async {
                      String u = recoverUserCtrl.text.trim();
                      String a = recoverAnswerCtrl.text.trim();
                      String np = newPassCtrl.text.trim();

                      if (LoginScreen.appUsers.containsKey(u) && LoginScreen.appUsers[u]!['answer'] == a) {
                        LoginScreen.appUsers[u]!['password'] = np;
                        await LocalStorageService.saveAppUsers(LoginScreen.appUsers);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تغيير كلمة السر بنجاح!'), backgroundColor: Colors.green),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('اسم المستخدم أو إجابة سؤال الأمان غير صحيحة!'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: const Text('تحديث كلمة السر', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF141414),
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF141414)),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 85,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.domain,
                            size: 60,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        LoginScreen.mainCompanyName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.amber, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        LoginScreen.subAppName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _gmailController,
                        focusNode: _gmailFocus,
                        style: const TextStyle(color: Colors.cyanAccent),
                        keyboardType: TextInputType.emailAddress,
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_usernameFocus),
                        decoration: InputDecoration(
                          labelText: 'إدخال الجيميل الخاص بتسجيل الدخول',
                          labelStyle: const TextStyle(color: Colors.cyanAccent),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: const Icon(Icons.mark_email_read, color: Colors.cyanAccent),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _usernameController,
                        focusNode: _usernameFocus,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم (رقم التليفون - 11 رقم)',
                          labelStyle: const TextStyle(color: Colors.amber),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: const Icon(Icons.phone_android, color: Colors.amber),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: !_showPassword,
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'كلمة السر',
                          labelStyle: const TextStyle(color: Colors.amber),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2C),
                          prefixIcon: const Icon(Icons.lock, color: Colors.amber),
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: Colors.amber,
                            checkColor: Colors.black,
                            onChanged: (bool? value) => setState(() => _rememberMe = value ?? false),
                          ),
                          const Text('حفظ حالة الدخول والربط', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _login,
                          child: const Text('دخول للسيستم', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.cyanAccent),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _loginAsGuest,
                          child: const Text('دخول كضيف (تصفح فقط)', style: TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text('نسيت كلمة السر؟', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: _showRegisterDialog,
                            child: const Text('تسجيل حساب جديد', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
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