import '../app_imports.dart';

/// ملف إعدادات السيرفر المستقل لربط المنظومة بالسحابة
/// لتغيير السيرفر مستقبلاً: عدّل الرابط في هذا الملف فقط
class ServerConfig {
  // 1. نوع مزود الخدمة ('firebase' أو 'custom_api')
  static const String activeProvider = 'firebase';

  // 2. عنوان السيرفر الأساسي (Realtime Database URL)
  static const String databaseUrl = "https://aqarat-captain-default-rtdb.firebaseio.com";

  // 3. إعدادات الربط السحابي
  static const FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyAivBdg27Z8onnbdzH6mGbpQwUa-vMr_p4",
    appId: "1:968213400606:web:718a68f00a9c95cbc0320f",
    messagingSenderId: "968213400606",
    projectId: "aqarat-captain",
    storageBucket: "aqarat-captain.firebasestorage.app",
    databaseURL: databaseUrl,
  );

  // 4. عنوان السيرفر البديل (في حال النقل مستقبلاً إلى سيرفر خاص)
  static const String customApiBaseUrl = "https://your-future-server.com/api";

  // 5. أسماء العقد الرئيسية الواضحة في الشجرة
  static const String companiesRootNode = "companies_storage";
  static const String databaseNode = "database";       // قاعدة بيانات الشركة
  static const String usersNode = "users";             // المستخدمين والموظفين
  static const String activityLogNode = "activity_log";// سجل النشاط والتعديلات
  static const String systemConfigNode = "system_config/app_update";

  // 6. دوال بناء الروابط تلقائياً لجميع المنصات (ويندوز وأندرويد)
  static String getRootCompaniesUrl() {
    if (activeProvider == 'custom_api') {
      return "$customApiBaseUrl/$companiesRootNode";
    }
    return "$databaseUrl/$companiesRootNode.json";
  }

  static String getCompanyDatabaseUrl(String companyKey, String subPath) {
    if (activeProvider == 'custom_api') {
      return "$customApiBaseUrl/$companiesRootNode/$companyKey/$subPath";
    }
    return "$databaseUrl/$companiesRootNode/$companyKey/$subPath.json";
  }

  static String getUsersUrl(String companyKey) {
    return getCompanyDatabaseUrl(companyKey, usersNode);
  }

  static String getSingleUserUrl(String companyKey, String phone) {
    return getCompanyDatabaseUrl(companyKey, "$usersNode/$phone");
  }

  static String getSystemUpdateUrl() {
    if (activeProvider == 'custom_api') {
      return "$customApiBaseUrl/$systemConfigNode";
    }
    return "$databaseUrl/$systemConfigNode.json";
  }
}