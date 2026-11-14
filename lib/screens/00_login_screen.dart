import '../app_imports.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static final Map<String, Map<String, String>> appUsers = {
    '01200626469': {
      'company': 'شركة ماهي البهوتي للتسويق العقاري',
      'firstName': 'الكابتن عبد الجواد',
      'password': '1983',
      'role': 'مدير',
      'license': 'مدى الحياة',
      'question': 'ما هي مدينة ميلادك؟',
      'answer': 'القاهرة',
      'email': '01200626469@aqarat.com',
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
      'email': '01004026247@aqarat.com',
      'personalGmail': 'captain.support640@gmail.com',
    },
  };

  static String mainCompanyName = 'شركة ماهي البهوتي للتسويق العقاري';
  static String subAppName = 'منظومة الكابتن للتسويق العقاري';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = true;
  bool _isLoading = false;

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await LocalStorageService.loadLocally();

    Map<String, Map<String, String>> savedUsers = await LocalStorageService.loadAppUsers();
    if (savedUsers.isNotEmpty) {
      LoginScreen.appUsers.addAll(savedUsers);
    }

    final prefs = await SharedPreferences.getInstance();
    bool remember = prefs.getBool('remember_me') ?? true;
    String savedUsername = prefs.getString('saved_username') ?? '';
    String savedPassword = prefs.getString('saved_password') ?? '';

    if (mounted) {
      setState(() {
        _rememberMe = remember;
        if (remember && savedUsername.isNotEmpty) {
          _usernameController.text = savedUsername;
          _passwordController.text = savedPassword;
        }
      });
    }
  }

  Future<void> _login() async {
    if (_isLoading) return;

    String username = _usernameController.text.trim().replaceAll(' ', '');
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال اسم المستخدم (رقم الموبايل) وكلمة السر بدقة!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!AuthService.isValidEgyptianPhone(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خطأ: يجب إدخال رقم تليفون مكون من 11 رقم يبدأ بـ (010, 011, 012, 015, 040)!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authResult = await AuthService.authenticateUser(
      username: username,
      password: password,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (authResult['isValid'] == true) {
      _executeSuccessfulLogin(
        username,
        authResult['adminGmail'],
        isMasterAdmin: authResult['isMaster'],
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ: رقم الموبايل أو كلمة السر غير صحيحة!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loginAsGuest() async {
    await SecurityManager.saveSession(
      phone: 'guest',
      email: 'guest@aqarat.com',
      role: 'ضيف',
      permissions: ['view'],
      adminGmail: 'guest_server',
    );
    _executeSuccessfulLogin('guest', 'guest@aqarat.com', isGuest: true);
  }

  Future<void> _executeSuccessfulLogin(String username, String gmail,
      {bool isGuest = false, bool isMasterAdmin = false}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('remember_me', _rememberMe);

    if (_rememberMe && !isGuest) {
      await prefs.setString('saved_gmail', gmail);
      await prefs.setString('saved_username', username);
      await prefs.setString('saved_password', _passwordController.text.trim());
    } else if (!_rememberMe) {
      await prefs.remove('saved_username');
      await prefs.remove('saved_password');
    }

    String fName = isGuest ? 'زائر (تصفح فقط)' : (LoginScreen.appUsers[username]?['firstName'] ?? 'المدير');

    // إرسال إشعار تسجيل الدخول الفوري للمدير والمبرمج عبر خدمة الإشعارات
    await NotificationService.addRealNotification(
      'تسجيل دخول جديد',
      'تم دخول $fName بصلاحية (${SecurityManager.currentUserRole}) بنجاح.',
    );

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
                          labelText: 'اسم المستخدم (رقم الموبايل - 11 رقم)',
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
                            onChanged: (bool? value) async {
                              bool newVal = value ?? true;
                              setState(() => _rememberMe = newVal);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('remember_me', newVal);
                            },
                          ),
                          const Text('حفظ حالة الدخول تلقائياً بالدومين الموحد',
                              style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              : const Text('دخول للسيستم',
                                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
                          child: const Text('دخول كضيف (تصفح فقط)',
                              style: TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => ForgotPasswordDialog.show(context),
                            child: const Text('نسيت كلمة السر؟',
                                style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () => RegisterCompanyDialog.show(
                              context,
                              onSuccess: (phone, pass) {
                                setState(() {
                                  _usernameController.text = phone;
                                  _passwordController.text = pass;
                                  _rememberMe = true;
                                });
                              },
                            ),
                            child: const Text('تسجيل شركة جديدة',
                                style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
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