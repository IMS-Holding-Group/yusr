import 'nlu_svm_classifier.dart';

/// محلل الأوامر الصوتية العربية محلياً - يعمل بدون خادم
/// يدعم المكفوفين بالتحكم الكامل في التطبيق بالصوت
class VoiceCommandParser {
  /// تحليل النص وإرجاع النية والمعلومة المستخرجة
  /// [text] النص من التعرف على الصوت
  /// يرجع Map يحتوي: intent, query (لل بحث), productNumber (لاختيار منتج), speakText
  static Map<String, dynamic> parse(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      return {'intent': 'unknown', 'speak_text': 'لم أسمع أي شيء'};
    }

    // طبقة تصنيف مستوحاة من SVM + أوزان TF (انظر nlu_svm_classifier.dart)
    final svm = NluSvmClassifier.classify(cleaned);
    if (svm['intent'] == 'view_recommendations' &&
        (svm['confidence'] as double) > 0.38) {
      return {'intent': 'view_recommendations'};
    }

    // التوصيات (كلمات مباشرة)
    if (_containsAny(cleaned, [
          'توصيات',
          'توصية',
          'اقتراحات',
          'اقتراح',
          'موصى',
          'موصي',
          'شوف لي',
          'اقترح',
        ]) &&
        !_containsAny(cleaned, ['بحث', 'ابحث'])) {
      return {'intent': 'view_recommendations'};
    }

    // البحث: بحث عن كتب، ابحث عن هاتف، ابحث كتب، ابحث هاتف
    final searchPrefixes = ['بحث عن ', 'ابحث عن ', 'ابحث ', 'بحث ', 'دور عن ', 'دور على ', 'اطلب '];
    for (final prefix in searchPrefixes) {
      if (cleaned.contains(prefix)) {
        final idx = cleaned.indexOf(prefix);
        final rest = cleaned.substring(idx + prefix.length).trim();
        if (rest.length >= 2) {
          return {'intent': 'search', 'query': rest};
        }
      }
    }
    // كلمات بحث قصيرة
    if (_containsAny(cleaned, ['بحث', 'ابحث']) && cleaned.length > 3) {
      final without = cleaned
          .replaceAll('بحث', '').replaceAll('ابحث', '')
          .replaceAll('عن', '').replaceAll('على', '')
          .replaceAll('هاتف', '').replaceAll('موبايل', '').replaceAll('جوال', '')
          .replaceAll('لابتوب', '').replaceAll('كمبيوتر', '').replaceAll('حاسوب', '')
          .replaceAll('ذكي', '').trim();
      if (without.length >= 2) return {'intent': 'search', 'query': without};
      return {'intent': 'search', 'query': cleaned};
    }

    // إضافة للسلة / شراء المنتج الحالي (في صفحة المنتج)
    final addPatterns = ['أضف', 'ضيف', 'إضافة', 'أضيف', 'حط', 'ضع', 'أضف للسلة', 'ضيف للسلة', 
        'أضف إلى السلة', 'ضيف إلى السلة', 'أضف للعربة', 'ضيف للعربة', 'أضف لسلة', 'اضافه', 'ضيفه', 'اشتر'];
    if (_containsAny(cleaned, addPatterns) || 
        (_containsAny(cleaned, ['سلة', 'عربة', 'السلة', 'العربة']) && 
         _containsAny(cleaned, ['أضف', 'ضيف', 'حط', 'ضع', 'اشتر', 'اشتري']))) {
      return {'intent': 'add_to_cart'};
    }

    // شراء / إتمام الطلب (في السلة أو صفحة المنتج أو صفحة الدفع)
    final buyPatterns = ['شراء', 'شرا', 'اشتري', 'اشتر', 'شراء الآن', 'اكمل الشراء', 
        'إتمام الشراء', 'تمم الشراء', 'ادفع', 'دفع', 'تأكيد', 'أكيد', 'اكمل', 'تأكيد الشراء', 
        'نعم', 'تمام', 'أكمل الطلب', 'اكمل الطلب', 'تأكيد الطلب'];
    if (_containsAny(cleaned, buyPatterns)) {
      return {'intent': 'checkout'};
    }

    // عرض السلة
    final cartPatterns = ['السلة', 'سلة', 'عربة', 'العربة', 'عرض السلة', 'افتح السلة', 'افتح سلة'];
    if (_containsAny(cleaned, cartPatterns) && !_containsAny(cleaned, addPatterns)) {
      return {'intent': 'view_cart'};
    }

    // عرض المنتجات / المتجر
    final productsPatterns = ['تصفح', 'المنتجات', 'المتجر', 'المتاجر', 'منتجات', 'عرض المنتجات', 
        'عرض المتجر', 'تصفح المتجر', 'الكل', 'جميع المنتجات'];
    if (_containsAny(cleaned, productsPatterns)) {
      return {'intent': 'view_products'};
    }

    // الرئيسية
    final homePatterns = ['الرئيسية', 'البيت', 'الصفحة الرئيسية', 'رجع للرئيسية', 'ارجع', 'رجع'];
    if (_containsAny(cleaned, homePatterns)) {
      return {'intent': 'navigate_home'};
    }

    // الحساب / الملف الشخصي
    final profilePatterns = ['الحساب', 'حسابي', 'الملف الشخصي', 'بروفايل', 'حساب'];
    if (_containsAny(cleaned, profilePatterns)) {
      return {'intent': 'navigate_profile'};
    }

    // الإعدادات
    final settingsPatterns = ['الإعدادات', 'إعدادات', 'الإعداد'];
    if (_containsAny(cleaned, settingsPatterns)) {
      return {'intent': 'navigate_settings'};
    }

    // الفئات
    final categoriesPatterns = ['الفئات', 'فئات', 'تصنيفات', 'التصنيفات'];
    if (_containsAny(cleaned, categoriesPatterns)) {
      return {'intent': 'navigate_categories'};
    }

    // اقرأ الوصف
    final descPatterns = ['وصف', 'اقرأ', 'اقرأ الوصف', 'الوصف', 'اعرض الوصف', 'شرح'];
    if (_containsAny(cleaned, descPatterns)) {
      return {'intent': 'read_description'};
    }

    // السعر
    final pricePatterns = ['السعر', 'كم السعر', 'كم', 'الثمن', 'كم ثمن'];
    if (_containsAny(cleaned, pricePatterns)) {
      return {'intent': 'read_price'};
    }

    // التالي / السابق
    if (_containsAny(cleaned, ['التالي', 'اللي بعد', 'اللي بعدة'])) {
      return {'intent': 'navigate_next'};
    }
    if (_containsAny(cleaned, ['السابق', 'اللي قبل', 'قبل', 'رجوع'])) {
      return {'intent': 'navigate_previous'};
    }

    // اختيار منتج برقم: رقم 1، واحد، اثنين، المنتج الأول
    final numMatch = RegExp(r'(\d+)|واحد|اثنين|اثنان|ثلاثة|اربعة|خمسة|ستة|سبعة|ثمانية|تسعة|عشرة').firstMatch(cleaned);
    if (numMatch != null) {
      final numStr = numMatch.group(1);
      int? num = int.tryParse(numStr ?? '');
      if (num == null) {
        const arabicNums = {'واحد': 1, 'اثنين': 2, 'اثنان': 2, 'ثلاثة': 3, 'اربعة': 4, 
            'خمسة': 5, 'ستة': 6, 'سبعة': 7, 'ثمانية': 8, 'تسعة': 9, 'عشرة': 10};
        num = arabicNums[numMatch.group(0) ?? ''];
      }
      if (num != null && num >= 1 && num <= 20) {
        if (_containsAny(cleaned, ['رقم', 'منتج', 'اختار', 'اختر', 'أول', 'ثاني', 'ثالث']) ||
            cleaned.length < 15) {
          return {'intent': 'select_product', 'productNumber': num};
        }
      }
    }

    // احذف من السلة
    final removePatterns = ['احذف', 'حذف', 'شيل', 'امسح', 'أزل', 'ازل'];
    if (_containsAny(cleaned, removePatterns)) {
      final numM = RegExp(r'(\d+)').firstMatch(cleaned);
      final productNumber = numM != null ? int.tryParse(numM.group(1) ?? '') : null;
      return {'intent': 'remove_from_cart', 'productNumber': productNumber};
    }

    // اقرأ السلة / اعرض محتويات
    if (_containsAny(cleaned, ['اقرأ السلة', 'اعرض السلة', 'محتويات', 'المحتويات'])) {
      return {'intent': 'read_cart'};
    }

    // إذا لم يتطابق شيء، اعتبره بحثاً إن كان النص طويلاً
    if (cleaned.length >= 3 && !_containsAny(cleaned, ['لا', 'ما', 'كيف', 'لماذا', 'لم'])) {
      return {'intent': 'search', 'query': cleaned};
    }

    return {
      'intent': 'unknown',
      'speak_text': 'لم أفهم. جرّب: بحث عن كتب، أضف للسلة، شراء، السلة، أو تصفح المنتجات'
    };
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final k in keywords) {
      if (text.contains(k)) return true;
    }
    return false;
  }
}
