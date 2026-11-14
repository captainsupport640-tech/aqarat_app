import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SecurityManager {
  // إيميل المبرمج الماستر الرئيسي للدعم الفني
  static const String programmerSupportEmail = 'captain.support640@gmail.com';

  // متغيرات الجلسة الحالية
  static String currentUserRole = 'مدير';
  static String currentUsername = '';
  static String currentUserPhone = '';
  static String currentUserEmail = '';
  static String currentCompanyAdminEmail = '';
  static List<String> currentPermissions = ['delete', 'delete_all', 'add', 'edit', 'view'];

  /// 🔔 طلب كافة صلاحيات المنظومة الشاملة (بما فيها الميكروفون) فور فتح التطبيق
  static Future<void> requestInitialSystemPermissions() async {
    try {
      await [
        Permission.storage,
        Permission.notification,
        Permission.contacts,
        Permission.camera,
        Permission.microphone,
      ].request();

      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }

      if (await Permission.systemAlertWindow.isDenied) {
        await Permission.systemAlertWindow.request();
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في طلب الأذونات: $e');
    }
  }

  /// مصفوفة الصلاحيات والأدوار المعتمدة
  static final Map<String, List<String>> rolePermissions = {
    'مبرمج': [
      'all_access',
      'system_config',
      'manage_companies',
      'master_database_admin',
      'delete_all',
      'delete',
      'add',
      'edit',
      'view'
    ],
    'مدير': [
      'manage_users',
      'view_all',
      'edit_all',
      'delete_all',
      'sync_master',
      'financial_reports',
      'delete',
      'add',
      'edit',
      'view'
    ],
    'نائب مدير': [
      'view_allowed',
      'edit_allowed',
      'sync_master',
      'add',
      'edit',
      'view'
    ],
    'مدير مكتب': [
      'view_allowed',
      'edit_allowed',
      'sync_master',
      'add',
      'edit',
      'view'
    ],
    'مدير فرع': [
      'view_allowed',
      'edit_allowed',
      'sync_master',
      'add',
      'edit',
      'view'
    ],
    'موظف مبيعات': [
      'add_data',
      'edit_own_data',
      'sync_master',
      'add',
      'edit',
      'view'
    ],
    'مدخل بيانات': [
      'add_data',
      'edit_own_data',
      'sync_master',
      'add',
      'edit',
      'view'
    ],
  };

  /// حفظ بيانات الجلسة عند تسجيل الدخول
  static Future<void> saveSession({
    required String phone,
    required String email,
    required String role,
    required List<String> permissions,
    required String adminGmail,
  }) async {
    currentUserPhone = phone.trim();
    currentUsername = phone.trim();
    currentUserEmail = email.trim();
    currentUserRole = role.trim();
    currentPermissions = List<String>.from(permissions);

    // إضافة صلاحيات الحذف فقط إذا كان مبرمجاً أو مديراً
    if (canDelete) {
      if (!currentPermissions.contains('delete')) currentPermissions.add('delete');
      if (!currentPermissions.contains('delete_all')) currentPermissions.add('delete_all');
    } else {
      currentPermissions.removeWhere((p) => p == 'delete' || p == 'delete_all');
    }

    currentCompanyAdminEmail = adminGmail.trim();
  }

  /// إعادة ضبط البيانات عند تسجيل الخروج
  static void clearUserData() {
    currentUserRole = 'مدير';
    currentUsername = '';
    currentUserPhone = '';
    currentUserEmail = '';
    currentCompanyAdminEmail = '';
    currentPermissions = ['delete', 'delete_all', 'add', 'edit', 'view'];
  }

  /// فحص هل المستخدم هو المبرمج الرئيسي (صلاحيات مطلقة كاملة)
  static bool get isProgrammer {
    String cleanEmail = currentUserEmail.trim().toLowerCase();
    String cleanAdminEmail = currentCompanyAdminEmail.trim().toLowerCase();

    return currentUserRole == 'مبرمج' ||
        cleanEmail == programmerSupportEmail ||
        cleanAdminEmail == programmerSupportEmail ||
        currentUsername == 'programmer' ||
        currentUsername == '01200626469' ||
        currentUsername == '01004026247';
  }

  /// فحص هل المستخدم هو المدير الرئيسي للشركة أو المبرمج
  static bool get isAdmin {
    return currentUserRole == 'مبرمج' || currentUserRole == 'مدير';
  }

  /// فحص هل المستخدم ضيف
  static bool get isGuest => currentUserRole == 'ضيف';

  /// ⛔ صلاحية الحذف والمسح (مقتصرة حصرياً على المدير والمبرمج)
  static bool get canDelete {
    if (isProgrammer) return true;
    if (isAdmin) return true;
    return false;
  }

  /// فحص صلاحية الإضافة والتعديل
  static bool get canAddOrEdit {
    if (isGuest) return false;
    return true;
  }

  /// معرّف الشركة
  static String get tenantCompanyId {
    if (isProgrammer) {
      return 'master_programmer_server';
    }

    String email = currentCompanyAdminEmail.trim().toLowerCase();
    if (email.isEmpty) return 'unassigned_company';

    return email
        .replaceAll('.', '_')
        .replaceAll('@', '_at_')
        .replaceAll('#', '')
        .replaceAll('\$', '')
        .replaceAll('[', '')
        .replaceAll(']', '');
  }

  /// فحص صلاحية الوصول إلى الشاشات حسب المصفوفة المعتمدة
  static bool canAccessScreen(String screenTitle) {
    if (isProgrammer) return true;
    if (currentUserRole == 'مدير') return true;

    // نائب المدير / مدير مكتب / مدير فرع (5 شاشات فقط)
    if (currentUserRole == 'نائب مدير' ||
        currentUserRole == 'مدير مكتب' ||
        currentUserRole == 'مدير فرع') {
      List<String> allowedForManagers = [
        'طلبات العملاء',
        'الطلبات',
        'المعروض للبيع',
        'البيع',
        'العقارات المعروضة للبيع',
        'المعروض للإيجار',
        'الإيجار',
        'العقارات المعروضة للإيجار',
        'المعاينات',
        'المعاينة',
        'العمليات المكتملة',
        'العمليات',
      ];
      return allowedForManagers.contains(screenTitle);
    }

    // موظف مبيعات / مدخل بيانات (4 شاشات فقط)
    if (currentUserRole == 'موظف مبيعات' || currentUserRole == 'مدخل بيانات') {
      List<String> allowedForStaff = [
        'طلبات العملاء',
        'الطلبات',
        'المعروض للبيع',
        'البيع',
        'العقارات المعروضة للبيع',
        'المعروض للإيجار',
        'الإيجار',
        'العقارات المعروضة للإيجار',
        'المعاينات',
        'المعاينة',
      ];
      return allowedForStaff.contains(screenTitle);
    }

    return false;
  }

  /// فحص الصلاحيات قبل الإجراءات
  static bool checkActionPermission(BuildContext context, {required String actionName}) {
    if (isProgrammer) return true;

    if (isGuest) {
      showPermissionDeniedSnackBar(context, 'عفواً، حساب الضيف للتصفح فقط!');
      return false;
    }

    if (actionName.contains('حذف') || actionName.contains('مسح')) {
      if (!canDelete) {
        showPermissionDeniedSnackBar(
          context,
          'عفواً، صلاحية المسح والحذف مقتصرة على مدير المنظومة فقط!',
        );
        return false;
      }
      return true;
    }

    if (actionName.contains('موظف') || actionName.contains('مستخدم')) {
      if (!isAdmin) {
        showPermissionDeniedSnackBar(context, 'عفواً، إضافة الموظفين وإدارة الحسابات من صلاحية المدير فقط!');
        return false;
      }
    }

    return true;
  }

  static void showPermissionDeniedSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.block, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// أداة الحماية العازلة لتقييد العناصر حسب الصلاحيات
class PermissionReadOnlyWrapper extends StatelessWidget {
  final Widget child;
  final bool hasPermission;

  const PermissionReadOnlyWrapper({
    super.key,
    required this.child,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    if (hasPermission) {
      return child;
    }

    return GestureDetector(
      onTap: () {
        SecurityManager.showPermissionDeniedSnackBar(
          context,
          'عفواً، ليس لديك صلاحية للقيام بهذا الإجراء',
        );
      },
      child: AbsorbPointer(
        absorbing: true,
        child: Opacity(
          opacity: 0.5,
          child: child,
        ),
      ),
    );
  }
}