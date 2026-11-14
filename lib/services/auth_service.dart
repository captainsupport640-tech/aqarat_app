import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_imports.dart';
import 'server_config.dart';

class AuthService {
  static bool isValidEgyptianPhone(String phone) {
    if (phone.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      return false;
    }
    List validPrefixes = ['010', '011', '012', '015', '040'];
    return validPrefixes.any((prefix) => phone.startsWith(prefix));
  }

  static Future authenticateUser({
    required String username,
    required String password,
  }) async {
    String unifiedEmail = "$username@aqarat.com";
    bool isValidUser = false;
    bool isMasterOrProgrammer = false;
    String userRole = 'مدير';
    String firstName = 'المدير';
    String adminGmail = 'captain.support640@gmail.com';

    // 1. حساب المدير الرئيسي أو المبرمج
    if ((username == '01200626469' || username == '01004026247') && password == '1983') {
      isValidUser = true;
      isMasterOrProgrammer = true;
      userRole = username == '01004026247' ? 'مبرمج' : 'مدير';
      firstName = username == '01200626469' ? 'الكابتن عبد الجواد' : 'المبرمج الرئيسي';
      adminGmail = 'captain.support640@gmail.com';
    } else {
      // 2. البحث اللحظي المباشر في السيرفر (عبر REST API ليعمل على الويندوز والأندرويد)
      try {
        final url = Uri.parse(ServerConfig.getRootCompaniesUrl());
        final response = await http.get(url).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200 && response.body != 'null') {
          Map companies = jsonDecode(response.body) as Map;

          for (var companyKey in companies.keys) {
            var companyData = companies[companyKey];
            if (companyData is Map) {
              var usersTree = companyData[ServerConfig.usersNode] ??
                  companyData['2_employees_tree'] ??
                  companyData['2_users_tree'];

              if (usersTree is Map && usersTree[username] is Map) {
                var userData = usersTree[username] as Map;
                String storedPass = (userData['كلمة السر'] ?? userData['password'] ?? '').toString().trim();

                if (storedPass == password) {
                  isValidUser = true;
                  userRole = (userData['الوظيفة'] ?? userData['role'] ?? 'موظف مبيعات').toString().trim();
                  firstName = (userData['الاسم'] ?? userData['name'] ?? userData['firstName'] ?? 'موظف').toString().trim();
                  adminGmail = companyKey.toString().replaceAll('_at_', '@').replaceAll('_', '.');

                  LoginScreen.appUsers[username] = {
                    'company': LoginScreen.mainCompanyName,
                    'firstName': firstName,
                    'password': password,
                    'role': userRole,
                    'license': 'ساري',
                    'question': '',
                    'answer': '',
                    'email': unifiedEmail,
                    'personalGmail': adminGmail,
                  };
                  await LocalStorageService.saveAppUsers(LoginScreen.appUsers);
                  break;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint("تنبيه الاتصال بالسيرفر أثناء الدخول: $e");
      }

      // 3. في حال انقطاع الإنترنت، الرجوع للكاش المحلي
      if (!isValidUser && LoginScreen.appUsers.containsKey(username)) {
        final userData = LoginScreen.appUsers[username]!;
        if ((userData['password'] ?? '').toString().trim() == password) {
          isValidUser = true;
          userRole = userData['role'] ?? 'موظف مبيعات';
          firstName = userData['firstName'] ?? 'موظف';
          adminGmail = userData['personalGmail'] ?? adminGmail;
        }
      }
    }

    if (isValidUser) {
      List<String> permissions = SecurityManager.rolePermissions[userRole] ??
          SecurityManager.rolePermissions['موظف مبيعات'] ??
          ['view'];

      await SecurityManager.saveSession(
        phone: username,
        email: unifiedEmail,
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
    }

    return {
      'isValid': isValidUser,
      'isMaster': isMasterOrProgrammer,
      'role': userRole,
      'firstName': firstName,
      'adminGmail': adminGmail,
    };
  }
}