class ParsedPropertyData {
  String? propertyType;
  String? location;
  String? area;
  String? price;
  String? phone;
  String? ownerName;
  String? details;

  ParsedPropertyData({
    this.propertyType,
    this.location,
    this.area,
    this.price,
    this.phone,
    this.ownerName,
    this.details,
  });
}

class SmartTextParser {
  static ParsedPropertyData parseMessage(String rawText) {
    String text = rawText.trim();
    
    // 1. استخراج رقم الهاتف (11 رقم يبدأ بـ 01)
    RegExp phoneRegex = RegExp(r'(01[0125]\d{8})');
    Match? phoneMatch = phoneRegex.firstMatch(text);
    String? phone = phoneMatch?.group(0);

    // 2. استخراج المساحة (أرقام يتبعها متر أو م2)
    RegExp areaRegex = RegExp(r'(\d+)\s*(متر|م2|م)');
    Match? areaMatch = areaRegex.firstMatch(text);
    String? area = areaMatch?.group(1);

    // 3. استخراج السعر
    RegExp priceRegex = RegExp(r'(\d+[\d,.]*)\s*(مليون|ألف|الف|جنيه|ج)');
    Match? priceMatch = priceRegex.firstMatch(text);
    String? price = priceMatch?.group(0);

    // 4. استخراج نوع العقار
    String propertyType = 'شقة'; // افتراضي
    if (text.contains('فيلا')) propertyType = 'فيلا';
    else if (text.contains('روف')) propertyType = 'روف';
    else if (text.contains('محل')) propertyType = 'محل';
    else if (text.contains('أرض') || text.contains('ارض')) propertyType = 'أرض';
    else if (text.contains('عمارة')) propertyType = 'عمارة';
    else if (text.contains('مكتب')) propertyType = 'مكتب';

    // 5. استخراج اسم العميل/المالك (الكلمات بعد للتواصل أو أ/ أو كابتن)
    RegExp nameRegex = RegExp(r'(للتواصل|المالك|أ\/|كابتن|أستاذ|م\/)\s+([\u0600-\u06FF]+(?:\s+[\u0600-\u06FF]+)?)');
    Match? nameMatch = nameRegex.firstMatch(text);
    String? ownerName = nameMatch?.group(2);

    // 6. استخراج الموقع التقديري من الكلمات المفتاحية
    String location = '';
    List<String> commonLocations = [
      'التجمع', 'زايد', 'أكتوبر', 'المعادي', 'الشروق', 'بدر', 'العبور',
      'مدينتي', 'الرحاب', 'نصر', 'مصر الجديدة', 'المهندسين', 'الزمالك'
    ];
    for (var loc in commonLocations) {
      if (text.contains(loc)) {
        location = loc;
        break;
      }
    }

    return ParsedPropertyData(
      propertyType: propertyType,
      location: location,
      area: area != null ? '$area متر' : '',
      price: price ?? '',
      phone: phone ?? '',
      ownerName: ownerName ?? '',
      details: text,
    );
  }
}