import 'package:shared_preferences/shared_preferences.dart';
import 'security_manager.dart';

class LicensingService {
  // قيمة المعادلة الحسابية المعتمدة
  static const int _baseFormulaValue = 24 + 9 - 1983;

  static bool isMasterAdmin = false;
  static DateTime? trialStartDate;
  static bool isActivated = false;
  static bool used2030Reset = false; // فحص استخدام كود 2030 لمرة واحدة
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
      activationType = 'مدى الحياة (مبرمج)';
      return;
    }

    isMasterAdmin = false;

    // قراءة حالة التفعيل السابقة وحالة كود 2030
    isActivated = prefs.getBool('device_is_activated') ?? false;
    activationType = prefs.getString('device_activation_type') ?? 'فترة تجريبية (7 أيام)';
    used2030Reset = prefs.getBool('used_2030_reset') ?? false;

    if (activationType == 'مدى الحياة' || activationType == 'سنة' || activationType == 'شهر تجريبي') {
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

  /// فحص صلاحية الدخول برقمي الموبايل والباسورد للمبرمج
  static bool checkMasterAdmin(String username, String password) {
    String cleanUser = username.trim();
    if ((cleanUser == "01200626469" || cleanUser == "01004026247") && password.trim() == "1983") {
      isMasterAdmin = true;
      isActivated = true;
      activationType = 'مدى الحياة (مبرمج)';
      return true;
    }
    return false;
  }

  /// ومعالجة أنواع التفعيل الـ 4:
  /// 1. كود 2030: تجديد التجريبي أسبوع لمرة واحدة فقط!
  /// 2. سيريال الجهاز المباشر: شهر تجريبي
  /// 3. ناتج (السيريال + المعادلة): تفعيل سنوي
  /// 4. حرف A + ناتج (السيريال + المعادلة): تفعيل مدى الحياة
  static Future<bool> processActivationCode({
    required String inputCode,
    required String deviceId,
  }) async {
    String cleanCode = inputCode.trim().toUpperCase();
    String hardwareKey = getDeviceHardwareId(deviceId);
    int deviceNum = int.tryParse(hardwareKey) ?? 12345678;

    // الناتج الرقمي لـ (بصمة الجهاز + المعادلة الحسابية) = التفعيل السنوي
    int calculatedAnnual = (deviceNum + _baseFormulaValue).abs();
    String annualCode = calculatedAnnual.toString();

    // 1️⃣ تجديد الفترة التجريبية بكود 2030 (مرة واحدة فقط على الجهاز)
    if (cleanCode == "2030") {
      if (used2030Reset) {
        return false; // تم استخدامه من قبل على هذا الجهاز
      }
      trialStartDate = DateTime.now();
      isActivated = false;
      isMasterAdmin = false;
      used2030Reset = true;
      activationType = 'فترة تجريبية (7 أيام)';
      await _saveDevicePrefs();
      return true;
    }

    // 2️⃣ تفعيل مدى الحياة (وجود حرف A مع كود المعادلة السنوية)
    if (cleanCode == "A$annualCode" || cleanCode == "${annualCode}A" || cleanCode == "A-$annualCode") {
      isActivated = true;
      isMasterAdmin = false;
      activationType = 'مدى الحياة';
      await _saveDevicePrefs();
      return true;
    }

    // 3️⃣ تفعيل سنوي (ناتج بصمة الجهاز + المعادلة)
    if (cleanCode == annualCode) {
      isActivated = true;
      isMasterAdmin = false;
      activationType = 'سنة';
      await _saveDevicePrefs();
      return true;
    }

    // 4️⃣ شهر تجريبي (إدخال سيريال الجهاز المباشر)
    if (cleanCode == hardwareKey || cleanCode == deviceId.trim()) {
      isActivated = true;
      isMasterAdmin = false;
      activationType = 'شهر تجريبي';
      await _saveDevicePrefs();
      return true;
    }

    return false;
  }

  /// احتساب الأيام المتبقية للتفعيل
  static int getRemainingDays() {
    if (isMasterAdmin || activationType == 'مدى الحياة') {
      return 9999;
    }

    if (activationType == 'سنة') return 365;
    if (activationType == 'شهر تجريبي') return 30;

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
    await prefs.setBool('used_2030_reset', used2030Reset);
    if (trialStartDate != null) {
      await prefs.setString('device_trial_start_date', trialStartDate!.toIso8601String());
    }
  }
}