import 'package:shared_preferences/shared_preferences.dart';
import 'security_manager.dart';

class LicensingService {
  static const int _baseFormulaValue = 24 + 9 - 1983;

  static bool isMasterAdmin = false;
  static DateTime? trialStartDate;
  static bool isActivated = false;
  static String activationType = 'فترة تجريبية (7 أيام)';

  /// استخراج الرقم التعريفي البصمي للجهاز الحالي (10 أرقام)
  static String getDeviceHardwareId(String rawDeviceId) {
    String combined = "$rawDeviceId-$_baseFormulaValue";
    int hash = 0;
    for (int i = 0; i < combined.length; i++) {
      hash = 31 * hash + combined.codeUnitAt(i);
      hash = hash & hash;
    }
    String numericOnly = hash.abs().toString();
    if (numericOnly.length < 10) {
      numericOnly = numericOnly.padRight(10, '5');
    }
    return numericOnly.substring(0, 10);
  }

  /// تحميل حالة التفعيل المربوطة ببصمة الجهاز
  static Future<void> loadLicenseStatus() async {
    final prefs = await SharedPreferences.getInstance();

    String currentUsername = SecurityManager.currentUsername.trim();
    
    // فحص صلاحيات المبرمج الرئيسي برقمي الموبايل المعتمدين فقط
    bool isRootAdmin = (currentUsername == '01200626469' || currentUsername == '01004026247');

    if (isRootAdmin) {
      isMasterAdmin = true;
      isActivated = true;
      activationType = 'مدى الحياة';
      return;
    }

    isMasterAdmin = false;

    // قراءة التفعيل المسجل الخاص بهذا الجهاز محلياً
    isActivated = prefs.getBool('device_is_activated') ?? false;
    activationType = prefs.getString('device_activation_type') ?? 'فترة تجريبية (7 أيام)';

    if (activationType == 'مدى الحياة' || activationType == 'سنة' || activationType == 'شهر') {
      isActivated = true;
    } else {
      String? storedDate = prefs.getString('device_trial_start_date');
      if (storedDate != null) {
        trialStartDate = DateTime.tryParse(storedDate);
      } else {
        trialStartDate = DateTime.now();
        await prefs.setString('device_trial_start_date', trialStartDate!.toIso8601String());
      }
    }
  }

  /// فحص صلاحية الدخول برقمي الموبايل والباسورد
  static bool checkMasterAdmin(String username, String password) {
    String cleanUser = username.trim();
    if ((cleanUser == "01200626469" || cleanUser == "01004026247") && password.trim() == "1983") {
      isMasterAdmin = true;
      isActivated = true;
      activationType = 'مدى الحياة';
      return true;
    }
    return false;
  }

  /// تطبيق معادلة التفعيل المبنية على بصمة الجهاز:
  /// 1. إدخال (1983): إعادة ضبط التجريبي (7 أيام)
  /// 2. بصمة الجهاز المباشرة -> تفعيل شهري
  /// 3. (بصمة الجهاز + المعادلة) -> تفعيل سنوي
  /// 4. حرف A + (بصمة الجهاز + المعادلة) -> تفعيل مدى الحياة
  static Future<bool> processActivationCode({
    required String inputCode,
    required String deviceId,
  }) async {
    String cleanCode = inputCode.trim().toUpperCase();
    String hardwareKey = getDeviceHardwareId(deviceId);
    int deviceNum = int.tryParse(hardwareKey) ?? 12345678;

    // 1. الناتج الرقمي للـ (بصمة + المعادلة) = التفعيل السنوي
    int calculatedAnnual = 24 + 9 - 1983 + deviceNum;
    String annualCode = calculatedAnnual.abs().toString();

    // 2. النواتج المقبولة للتفعيل مدى الحياة (وجود حرف A قبل المعادلة أو البصمة)
    String lifetimeCode = "A$annualCode";
    String lifetimeCodeAlt = "A-$annualCode";
    String lifetimeCodeHardware = "A$hardwareKey";
    String lifetimeCodeHardwareAlt = "A-$hardwareKey";

    // إعادة ضبط الفترة التجريبية (كود المبرمج 1983)
    if (cleanCode == "1983" || cleanCode == "A1983") {
      trialStartDate = DateTime.now();
      isActivated = false;
      isMasterAdmin = false;
      activationType = 'فترة تجريبية (7 أيام)';
      await _saveDevicePrefs();
      return true;
    }

    // تفعيل مدى الحياة (حرف A + بصمة الجهاز والمعادلة)
    if (cleanCode == lifetimeCode || 
        cleanCode == lifetimeCodeAlt || 
        cleanCode == lifetimeCodeHardware || 
        cleanCode == lifetimeCodeHardwareAlt) {
      isActivated = true;
      isMasterAdmin = false;
      activationType = 'مدى الحياة';
      await _saveDevicePrefs();
      return true;
    }

    // تفعيل سنوي (ناتج بصمة الجهاز + المعادلة بدون A)
    if (cleanCode == annualCode) {
      isActivated = true;
      isMasterAdmin = false;
      activationType = 'سنة';
      await _saveDevicePrefs();
      return true;
    }

    // تفعيل شهري (بصمة الجهاز المباشرة)
    if (cleanCode == hardwareKey) {
      isActivated = true;
      isMasterAdmin = false;
      activationType = 'شهر';
      await _saveDevicePrefs();
      return true;
    }

    return false;
  }

  /// احتساب الأيام المتبقية للتفعيل على الجهاز
  static int getRemainingDays() {
    if (isMasterAdmin || isActivated || activationType == 'مدى الحياة') {
      return 9999;
    }

    if (activationType == 'سنة') return 365;
    if (activationType == 'شهر') return 30;

    DateTime today = DateTime.now();
    trialStartDate ??= today;

    if (today.isBefore(trialStartDate!)) {
      return 7;
    }

    int daysPassed = today.difference(trialStartDate!).inDays;
    int remaining = 7 - daysPassed;

    return remaining > 0 ? remaining : 0;
  }

  /// حفظ حالة تفعيل الجهاز في ذاكرة الموبايل
  static Future<void> _saveDevicePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('device_is_activated', isActivated);
    await prefs.setString('device_activation_type', activationType);
    if (trialStartDate != null) {
      await prefs.setString('device_trial_start_date', trialStartDate!.toIso8601String());
    }
  }
}