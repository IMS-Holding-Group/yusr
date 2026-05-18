import 'dart:math' as math;

/// تصنيف نوايا مبسّط مستوحى من SVM + TF-IDF من التقرير:
/// تمثيل النص كمتجه كلمات (وزن TF بسيط) ثم فصل خطي بضرب في أوزان فئات ثابتة
/// (تقريب لـ hyperplane عندما تكون الأوزان معرفة مسبقاً).
class NluSvmClassifier {
  NluSvmClassifier._();

  static const _intents = <String>[
    'search',
    'add_to_cart',
    'checkout',
    'view_cart',
    'view_products',
    'navigate_home',
    'read_description',
    'view_recommendations',
  ];

  static const _prototypes = <String, Map<String, double>>{
    'search': {
      'بحث': 1.2,
      'ابحث': 1.2,
      'دور': 0.8,
      'هاتف': 0.4,
      'لابتوب': 0.4,
      'منتج': 0.3,
    },
    'add_to_cart': {
      'أضف': 1.1,
      'ضيف': 1.1,
      'سلة': 0.9,
      'عربة': 0.7,
      'شراء': 0.4,
    },
    'checkout': {
      'شراء': 1.0,
      'ادفع': 0.9,
      'تأكيد': 0.8,
      'اكمل': 0.7,
      'طلب': 0.5,
    },
    'view_cart': {
      'سلة': 1.0,
      'عربة': 0.9,
      'عرض': 0.4,
    },
    'view_products': {
      'منتجات': 1.1,
      'متجر': 0.9,
      'تصفح': 0.8,
    },
    'navigate_home': {
      'رئيسية': 1.0,
      'البيت': 0.9,
      'رجع': 0.5,
    },
    'read_description': {
      'وصف': 1.0,
      'اقرأ': 0.9,
      'شرح': 0.6,
    },
    'view_recommendations': {
      'توصيات': 1.2,
      'اقتراح': 1.0,
      'موصى': 0.9,
      'مقترحات': 0.8,
    },
  };

  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toList();
  }

  /// يعيد النية ذات أعلى درجة هامش (تقريب دالة قرار SVM خطية)
  static Map<String, dynamic> classify(String rawText) {
    final tokens = _tokenize(rawText);
    if (tokens.isEmpty) {
      return {'intent': 'unknown', 'confidence': 0.0};
    }

    final tf = <String, double>{};
    for (final t in tokens) {
      tf[t] = (tf[t] ?? 0) + 1;
    }
    final n = tokens.length.toDouble();
    for (final k in tf.keys.toList()) {
      tf[k] = (tf[k]! / n) * (1 + math.log(n / (tf[k]! + 1))); // tf مُعدّل خفيف
    }

    var bestIntent = 'unknown';
    var bestScore = -1.0;

    for (final intent in _intents) {
      final w = _prototypes[intent];
      if (w == null) continue;
      var s = 0.0;
      var norm = 0.0;
      for (final e in w.entries) {
        norm += e.value * e.value;
        s += (tf[e.key] ?? 0) * e.value;
      }
      norm = math.sqrt(norm);
      final double score = norm > 0 ? s / norm : 0.0;
      if (score > bestScore) {
        bestScore = score;
        bestIntent = intent;
      }
    }

    if (bestScore < 0.15) {
      return {'intent': 'unknown', 'confidence': bestScore};
    }
    return {'intent': bestIntent, 'confidence': bestScore};
  }
}
