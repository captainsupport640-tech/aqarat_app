import 'package:flutter/material.dart';

class SecurityManager {
  // إيميل المبرمج الماستر الرئيسي للدعم الفني
  static const String programmerSupportEmail = 'captain.support640@gmail.com';

  // متغيرات الجلسة الحالية (ديناميكية بالكامل وقابلة للتغيير على الواقع)
  static String currentUserRole = 'مدخل بيانات';
  static String currentUsername = ''; // رقم الهاتف/اسم المستخدم
  static String currentUserPhone = ''; // رقم الهاتف المباشر
  static String currentUserEmail = ''; // الإيميل التلقائي ([phone]@aqarat.com)
  static String currentCompanyAdminEmail = ''; // إيميل الجيميل الخاص بمدير الشركة الرئيسي
  static List<String> currentPermissions = []; // مصفوفة الصلاحيات الممنوحة

  /// مصفوفة الصلاحيات والأدوار المعتمدة
  static final Map<String, List<String>> rolePermissions = {
    'مبرمج': [
      'all_access',
      'system_config',
      'manage_companies',
      'master_database_admin',
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
      'view_all',
      'edit_all',
      'sync_master',
      'view_reports',
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

  /// حفظ بيانات الجلسة الواقعية عند تسجيل الدخول
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
    currentPermissions = permissions;
    currentCompanyAdminEmail = adminGmail.trim();
  }

  /// إعادة ضبط بيانات المستخدم الحالي عند تسجيل الخروج
  static void clearUserData() {
    currentUserRole = 'مدخل بيانات';
    currentUsername = '';
    currentUserPhone = '';
    currentUserEmail = '';
    currentCompanyAdminEmail = '';
    currentPermissions.clear();
  }

  /// فحص هل المستخدم الحالي هو المبرمج الرئيسي
  static bool get isProgrammer {
    String cleanEmail = currentUserEmail.trim().toLowerCase();
    String cleanAdminEmail = currentCompanyAdminEmail.trim().toLowerCase();
    
    return currentUserRole == 'مبرمج' ||
           cleanEmail == programmerSupportEmail ||
           cleanAdminEmail == programmerSupportEmail;
  }

  /// فحص هل المستخدم هو المدير الرئيسي للشركة
  static bool get isAdmin {
    return isProgrammer || currentUserRole == 'مدير';
  }

  /// فحص هل المستخدم الحالي ضيف
  static bool get isGuest => currentUserRole == 'ضيف';

  /// فحص هل يملك المستخدم صلاحية الحذف؟
  static bool get canDelete {
    return isProgrammer || 
           currentUserRole == 'مدير' || 
           currentPermissions.contains('delete_all') ||
           currentPermissions.contains('delete');
  }

  /// فحص هل يملك المستخدم صلاحية الإضافة والتعديل؟
  static bool get canAddOrEdit {
    return isProgrammer || 
           currentUserRole == 'مدير' || 
           currentUserRole == 'نائب مدير' || 
           currentUserRole == 'مدخل بيانات' ||
           currentPermissions.contains('add') ||
           currentPermissions.contains('edit');
  }

  /// إرجاع المعرّف الديناميكي للشركة بناءً على إيميل الجيميل للمدير الرئيسي
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

  /// فحص صلاحية الوصول إلى الشاشات حسب الدور والواقع
  static bool canAccessScreen(String screenTitle) {
    if (isProgrammer || isAdmin) {
      return true;
    }

    if (currentUserRole == 'نائب مدير') {
      List<String> allowedForViceManager = [
        'بيانات العملاء',
        'العملاء',
        'طلبات العملاء',
        'الطلبات',
        'المعروض للبيع',
        'البيع',
        'المعروض للإيجار',
        'الإيجار',
        'المعاينات',
        'المعاينة',
        'العمليات المكتملة',
        'العمليات',
        'تقارير',
      ];
      return allowedForViceManager.contains(screenTitle);
    }

    if (currentUserRole == 'مدخل بيانات') {
      List<String> allowedForDataEntry = [
        'بيانات العملاء',
        'العملاء',
        'طلبات العملاء',
        'الطلبات',
        'المعروض للبيع',
        'البيع',
        'المعروض للإيجار',
        'الإيجار',
        'المعاينات',
        'المعاينة',
      ];
      return allowedForDataEntry.contains(screenTitle);
    }

    return false;
  }

  /// فحص الصلاحيات قبل أي عملية (إضافة/تعديل/حذف)
  static bool checkActionPermission(BuildContext context, {required String actionName}) {
    if (isProgrammer) return true;

    // منع الحذف لغير المدير والمبرمج
    if (actionName.contains('حذف') || actionName.contains('مسح')) {
      if (!canDelete) {
        showPermissionDeniedSnackBar(context, 'عفواً، صلاحية الحذف مقتصرة على المدير والمبرمج فقط!');
        return false;
      }
    }

    // منع إضافة الموظفين لغير المدير والمبرمج
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