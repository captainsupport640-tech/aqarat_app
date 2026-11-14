import '../app_data.dart';

class AiAssistantService {
  static Future<String> sendMessageToAI(String prompt) async {
    try {
      String raw = prompt.trim();
      if (raw.isEmpty) {
        return 'أهلاً بك يا كابتن عبد الجواد. أنا جاهز لمساعدتك في أي استفسار عن العقارات، العملاء، الحسابات، أو أي حسبة مالية.';
      }

      String q = _normalizeArabic(raw);

      // 1. الحاسبة العقارية والمالية الذكية (عمولات - نسب مئوية - أقساط - عمليات حسابية)
      String? mathReply = _tryFinancialCalculation(q);
      if (mathReply != null) return mathReply;

      // 2. ملخص شامل للمنظومة بالكامل
      if (q.contains('ملخص') || q.contains('احصائيات') || q.contains('تقرير') || q.contains('وضع الشركة') || q.contains('كل البيانات')) {
        return _buildFullSystemSummary();
      }

      // 3. البحث عن كود وحدة محدد (مثال: كود 105 أو وحدة A12)
      RegExp codeRegex = RegExp(r'(?:كود|وحده|وحدة|رقم)\s*([a-zA-Z0-9\-]+)');
      Match? codeMatch = codeRegex.firstMatch(q);
      if (codeMatch != null) {
        String code = codeMatch.group(1)!.trim();
        String codeResult = _searchByUnitCodeOrKeyword(code);
        if (codeResult.isNotEmpty) return codeResult;
      }

      // 4. استفسارات المعروض للبيع
      if (q.contains('بيع') || q.contains('شقق') || q.contains('شقه') || q.contains('فيلا') || q.contains('ارض') || q.contains('محل') || q.contains('معروض')) {
        if (q.contains('ايجار') || q.contains('للايجار')) {
          return _formatSectionList('المعروض للإيجار', 'الوحدات المعروضة للإيجار', q);
        }
        return _formatSectionList('المعروض للبيع', 'العقارات المعروضة للبيع', q);
      }

      // 5. استفسارات المعروض للإيجار
      if (q.contains('ايجار') || q.contains('مؤجر') || q.contains('للايجار')) {
        return _formatSectionList('المعروض للإيجار', 'الوحدات المعروضة للإيجار', q);
      }

      // 6. استفسارات طلبات العملاء
      if (q.contains('طلب') || q.contains('طلبات') || q.contains('مشتري') || q.contains('بيدور')) {
        return _formatSectionList('طلبات العملاء', 'طلبات العملاء المسجلة', q);
      }

      // 7. استفسارات العملاء
      if (q.contains('عميل') || q.contains('عملاء') || q.contains('تليفون') || q.contains('رقم')) {
        String deepSearch = _searchByUnitCodeOrKeyword(_extractSearchKeyword(q));
        if (deepSearch.isNotEmpty) return deepSearch;
        return _formatSectionList('بيانات العملاء', 'العملاء المسجلين', q);
      }

      // 8. استفسارات السماسرة
      if (q.contains('سمسار') || q.contains('سماسره') || q.contains('وسيط') || q.contains('وسطاء')) {
        return _formatSectionList('بيانات السماسرة', 'السماسرة والوسطاء', q);
      }

      // 9. استفسارات المعاينات
      if (q.contains('معاينه') || q.contains('معاينات') || q.contains('ميعاد') || q.contains('مواعيد')) {
        return _formatSectionList('المعاينات', 'جدول المعاينات', q);
      }

      // 10. استفسارات العمليات المكتملة
      if (q.contains('خلص') || q.contains('تمت') || q.contains('تامه') || q.contains('مكتمله') || q.contains('عقود') || q.contains('مبيعات')) {
        return _formatSectionList('العمليات التامة', 'العمليات والعقود المكتملة', q);
      }

      // 11. استفسارات الحسابات والمالية
      if (q.contains('حساب') || q.contains('حسابات') || q.contains('ماليه') || q.contains('فلوس') || q.contains('مصروف') || q.contains('ايراد') || q.contains('خزنه')) {
        return _buildAccountsReport();
      }

      // 12. البحث الذكي الشامل في كل الجداول عن أي كلمة (اسم شخص، منطقة، سعر، إلخ)
      String generalSearch = _searchByUnitCodeOrKeyword(_extractSearchKeyword(q));
      if (generalSearch.isNotEmpty) {
        return generalSearch;
      }

      return 'لم أجد سجلاً مطابقاً تماماً لـ "$raw"، لكن يمكنك سؤالي عن:\n'
          '• "ملخص شامل للمنظومة"\n'
          '• "الشقق المعروضة للبيع" أو "المعروض للإيجار"\n'
          '• "طلبات العملاء" أو "المعاينات" أو "الحسابات"\n'
          '• اسم أي عميل أو كود أي وحدة\n'
          '• أو أي حسبة مالية مثل: "احسب عمولة 2.5% على 2500000" أو "قسط 1500000 على 5 سنين".';
    } catch (e) {
      return 'حدث خطأ أثناء معالجة الطلب: $e';
    }
  }

  static String _normalizeArabic(String input) {
    return input
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .trim();
  }

  static String _extractSearchKeyword(String q) {
    List<String> stopWords = [
      'هات', 'جيب', 'قولي', 'عايز', 'اعرف', 'تفاصيل', 'بيانات', 'عن', 'في', 'من', 'علي', 'على',
      'العميل', 'عميل', 'الوحدة', 'وحدة', 'كود', 'رقم', 'تليفون', 'فين', 'ايه', 'هي', 'هو', 'بكام', 'سعر'
    ];
    List<String> words = q.split(RegExp(r'\s+'));
    List<String> filtered = words.where((w) => w.length > 1 && !stopWords.contains(w)).toList();
    return filtered.join(' ').trim();
  }

  // حاسبة العمولات والأقساط والنسب المئوية والعمليات الحسابية
  static String? _tryFinancialCalculation(String q) {
    List<double> numbers = RegExp(r'\d+(?:\.\d+)?')
        .allMatches(q)
        .map((m) => double.tryParse(m.group(0)!) ?? 0)
        .toList();

    // حساب العمولة أو النسبة المئوية
    if ((q.contains('عموله') || q.contains('نسبه') || q.contains('%') || q.contains('في الميه')) && numbers.length >= 2) {
      double percent = numbers[0] < numbers[1] ? numbers[0] : numbers[1];
      double amount = numbers[0] >= numbers[1] ? numbers[0] : numbers[1];
      double result = amount * (percent / 100.0);
      return '🧮 **حاسبة العمولات والنسب:**\n'
          '• المبلغ الإجمالي: ${_formatNum(amount)} جنيه\n'
          '• النسبة: $percent%\n'
          '• قيمة العمولة / النسبة: **${_formatNum(result)} جنيه**\n'
          '• الصافي بعد الخصم: ${_formatNum(amount - result)} جنيه';
    }

    // حساب الأقساط
    if ((q.contains('قسط') || q.contains('اقساط') || q.contains('تقسيط')) && numbers.length >= 2) {
      double total = numbers[0] >= numbers[1] ? numbers[0] : numbers[1];
      double period = numbers[0] < numbers[1] ? numbers[0] : numbers[1];
      bool isYears = q.contains('سنه') || q.contains('سنين') || q.contains('اعوام') || period <= 15;
      double months = isYears ? period * 12 : period;
      double monthly = total / months;
      double quarterly = monthly * 3;
      return '📅 **حاسبة الأقساط العقارية:**\n'
          '• المبلغ المقسط: ${_formatNum(total)} جنيه\n'
          '• المدة: ${months.toInt()} شهر (${(months / 12).toStringAsFixed(1)} سنة)\n'
          '• القسط الشهري: **${_formatNum(monthly)} جنيه**\n'
          '• القسط الربع سنوي (كل 3 شهور): **${_formatNum(quarterly)} جنيه**';
    }

    // حساب سعر المتر
    if ((q.contains('سعر المتر') || q.contains('المتر بكام')) && numbers.length >= 2) {
      double price = numbers[0] >= numbers[1] ? numbers[0] : numbers[1];
      double area = numbers[0] < numbers[1] ? numbers[0] : numbers[1];
      if (area > 0) {
        double meterPrice = price / area;
        return '📐 **حساب سعر المتر:**\n'
            '• إجمالي السعر: ${_formatNum(price)} جنيه\n'
            '• المساحة: $area متر\n'
            '• سعر المتر الواحد: **${_formatNum(meterPrice)} جنيه/م²**';
      }
    }

    // عمليات حسابية مباشرة (+ - * /)
    RegExp basicMath = RegExp(r'(\d+(?:\.\d+)?)\s*([\+\-\*\/×÷])\s*(\d+(?:\.\d+)?)');
    Match? mathMatch = basicMath.firstMatch(q);
    if (mathMatch != null) {
      double a = double.parse(mathMatch.group(1)!);
      String op = mathMatch.group(2)!;
      double b = double.parse(mathMatch.group(3)!);
      double res = 0;
      if (op == '+') res = a + b;
      if (op == '-') res = a - b;
      if (op == '*' || op == '×') res = a * b;
      if (op == '/' || op == '÷') res = b != 0 ? a / b : 0;
      return '🔢 ناتج العملية الحسابية ($a $op $b) = **${_formatNum(res)}**';
    }

    return null;
  }

  static String _formatNum(double val) {
    String str = val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 2);
    return str.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  static String _buildFullSystemSummary() {
    int clients = (AppData.storage['بيانات العملاء'] ?? []).length;
    int brokers = (AppData.storage['بيانات السماسرة'] ?? []).length;
    int requests = (AppData.storage['طلبات العملاء'] ?? []).length;
    int forSale = (AppData.storage['المعروض للبيع'] ?? []).length;
    int forRent = (AppData.storage['المعروض للإيجار'] ?? []).length;
    int inspections = (AppData.storage['المعاينات'] ?? []).length;
    int completed = (AppData.storage['العمليات التامة'] ?? []).length;
    int accounts = (AppData.storage['الحسابات'] ?? []).length;

    return '📊 **الملخص الشامل لمنظومة الكابتن العقارية:**\n'
        '• إجمالي العملاء المسجلين: $clients عميل\n'
        '• السماسرة والوسطاء: $brokers سمسار\n'
        '• طلبات العملاء النشطة: $requests طلب\n'
        '• المعروض للبيع: $forSale وحدة\n'
        '• المعروض للإيجار: $forRent وحدة\n'
        '• المعاينات المسجلة: $inspections معاينة\n'
        '• العمليات المكتملة: $completed عملية\n'
        '• قيود الحسابات والمالية: $accounts حركة مالية';
  }

  static String _formatSectionList(String sectionKey, String title, String query) {
    List items = AppData.storage[sectionKey] ?? [];
    if (items.isEmpty) {
      return 'لا توجد أي سجلات مسجلة حالياً في قسم ($title).';
    }

    String keyword = _extractSearchKeyword(query);
    List filtered = items;
    if (keyword.isNotEmpty &&
        !['بيع', 'ايجار', 'طلبات', 'معاينات', 'عملاء', 'سماسره', 'عمليات', 'شقق'].contains(keyword)) {
      var matched = items.where((item) {
        if (item is! Map) return false;
        return item.values.any((v) => _normalizeArabic(v.toString()).contains(keyword));
      }).toList();
      if (matched.isNotEmpty) filtered = matched;
    }

    StringBuffer sb = StringBuffer('📋 **$title (العدد: ${filtered.length}):**\n');
    int limit = filtered.length > 8 ? 8 : filtered.length;
    for (int i = 0; i < limit; i++) {
      var item = filtered[i];
      if (item is Map) {
        List<String> parts = [];
        item.forEach((k, v) {
          if (v != null && v.toString().trim().isNotEmpty && v.toString() != '-') {
            parts.add('$k: $v');
          }
        });
        sb.writeln('${i + 1}. ${parts.take(5).join(' | ')}');
      }
    }
    if (filtered.length > 8) {
      sb.writeln('... ويوجد ${filtered.length - 8} سجل آخر في القسم.');
    }
    return sb.toString().trim();
  }

  static String _buildAccountsReport() {
    List accounts = AppData.storage['الحسابات'] ?? [];
    if (accounts.isEmpty) {
      return 'لا توجد حركات مالية مسجلة في قسم الحسابات حالياً.';
    }

    double totalIncome = 0;
    double totalExpense = 0;

    for (var acc in accounts) {
      if (acc is Map) {
        double amount = double.tryParse((acc['المبلغ'] ?? acc['القيمة'] ?? '0').toString().replaceAll(',', '')) ?? 0;
        String type = _normalizeArabic((acc['النوع'] ?? acc['نوع الحركة'] ?? '').toString());
        if (type.contains('مصروف') || type.contains('صرف') || type.contains('خصم')) {
          totalExpense += amount;
        } else {
          totalIncome += amount;
        }
      }
    }

    StringBuffer sb = StringBuffer('💰 **ملخص الحسابات والمالية (${accounts.length} حركة):**\n'
        '• إجمالي الإيرادات / المقبوضات: ${_formatNum(totalIncome)} جنيه\n'
        '• إجمالي المصروفات: ${_formatNum(totalExpense)} جنيه\n'
        '• صافي الرصيد: **${_formatNum(totalIncome - totalExpense)} جنيه**\n\n'
        'آخر الحركات المسجلة:\n');

    int limit = accounts.length > 5 ? 5 : accounts.length;
    for (int i = 0; i < limit; i++) {
      var acc = accounts[i];
      if (acc is Map) {
        sb.writeln('• ${acc['البيان'] ?? '-'} | المبلغ: ${acc['المبلغ'] ?? '-'} | النوع: ${acc['النوع'] ?? '-'}');
      }
    }
    return sb.toString().trim();
  }

  static String _searchByUnitCodeOrKeyword(String keyword) {
    if (keyword.isEmpty) return '';
    String normKey = _normalizeArabic(keyword);
    List<String> foundLines = [];

    AppData.storage.forEach((section, list) {
      if (section == 'trash_bin' || section == 'الإشعارات' || section == 'read_notifications') return;
      for (var item in list) {
        if (item is Map) {
          bool match = item.values.any((val) => val != null && _normalizeArabic(val.toString()).contains(normKey));
          if (match) {
            List<String> details = [];
            item.forEach((k, v) {
              if (v != null && v.toString().trim().isNotEmpty && v.toString() != '-') {
                details.add('$k: $v');
              }
            });
            foundLines.add('📌 [$section]: ${details.take(5).join(' | ')}');
          }
        }
      }
    });

    if (foundLines.isEmpty) return '';
    return '🔍 **نتائج البحث في بيانات المنظومة عن "$keyword":**\n${foundLines.take(8).join('\n')}';
  }
}