import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// نموذج مشفّر–مفكّك مبسّط يعكس فكرة CNN-RNN من التقرير:
/// - المشفّر: استخراج متجه ميزات من الصورة (ألوان، سطوع، تباين، تدرج تقريبي).
/// - المفكّك: توليد جملة كلمة بكلمة من مفردات مرتبطة بالميزات (سلسلة تكرارية منطقية).
class EncoderDecoderCaptionService {
  EncoderDecoderCaptionService._();

  /// متجه ميزات مشفّر (بديل مضغوط لتمثيل CNN)
  static List<double> encodeImage(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return List<double>.filled(16, 0.5);

    final small = img.copyResize(decoded, width: 64, height: 64);
    double r = 0, g = 0, b = 0;
    final n = small.width * small.height;
    final rs = <int>[], gs = <int>[], bs = <int>[];

    for (var y = 0; y < small.height; y++) {
      for (var x = 0; x < small.width; x++) {
        final p = small.getPixel(x, y);
        final rr = p.r.toInt(), gg = p.g.toInt(), bb = p.b.toInt();
        r += rr;
        g += gg;
        b += bb;
        rs.add(rr);
        gs.add(gg);
        bs.add(bb);
      }
    }

    r /= n;
    g /= n;
    b /= n;

    double varChannel(List<int> ch) {
      if (ch.isEmpty) return 0;
      final m = ch.reduce((a, b) => a + b) / ch.length;
      var s = 0.0;
      for (final v in ch) {
        s += (v - m) * (v - m);
      }
      return math.sqrt(s / ch.length);
    }

    final sr = varChannel(rs) / 255.0;
    final sg = varChannel(gs) / 255.0;
    final sb = varChannel(bs) / 255.0;
    final contrast = (sr + sg + sb) / 3.0;

    final brightness = (r + g + b) / (3.0 * 255.0);
    final mx = math.max(r, math.max(g, b));
    final mn = math.min(r, math.min(g, b));
    final sat = mx < 1e-6 ? 0.0 : (mx - mn) / mx;

    // تدرج بسيط (تقريب كثافة الحواف)
    double grad = 0;
    var gc = 0;
    double lum(img.Pixel p) => 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
    for (var y = 1; y < small.height - 1; y++) {
      for (var x = 1; x < small.width - 1; x++) {
        final gx = (lum(small.getPixel(x + 1, y)) - lum(small.getPixel(x - 1, y))).abs();
        final gy = (lum(small.getPixel(x, y + 1)) - lum(small.getPixel(x, y - 1))).abs();
        grad += gx + gy;
        gc++;
      }
    }
    grad = gc > 0 ? (grad / gc) / 255.0 : 0;

    return [
      r / 255.0,
      g / 255.0,
      b / 255.0,
      sr,
      sg,
      sb,
      contrast,
      brightness,
      sat,
      grad,
    ];
  }

  /// توليد وصف عربي (المفكّك — تسلسل كلمات من الميزات + سياق اسم الملف/المنتج)
  static String decodeCaption(
    List<double> enc, {
    String? fileNameHint,
    String? productNameHint,
  }) {
    final r = enc[0], g = enc[1], b = enc[2];
    final contrast = enc[6];
    final brightness = enc[7];
    final saturation = enc[8];
    final edge = enc[9];

    final words = <String>[];

    words.add('صورة');
    words.add('منتج');

    final hint = (productNameHint ?? '').trim();
    if (hint.isNotEmpty) {
      words.add('تُظهر');
      words.add(hint);
    } else {
      words.add(_objectFromFileName(fileNameHint ?? ''));
    }

    words.add(_toneFromRgb(r, g, b));
    words.add(_brightnessPhrase(brightness));
    words.add(_saturationPhrase(saturation));
    if (contrast > 0.12) {
      words.add('بتباين');
      words.add('جيد');
      words.add('بين');
      words.add('المناطق');
    }
    if (edge > 0.08) {
      words.add('وملامح');
      words.add('واضحة');
      words.add('للشكل');
      words.add('العام');
    }

    return words.where((w) => w.isNotEmpty).join(' ');
  }

  static String generateCaptionFromBytes(
    Uint8List bytes, {
    String? assetFileName,
    String? productName,
  }) {
    final enc = encodeImage(bytes);
    return decodeCaption(
      enc,
      fileNameHint: assetFileName,
      productNameHint: productName,
    );
  }

  static String _objectFromFileName(String name) {
    final n = name.toLowerCase();
    if (n.contains('iphone') || n.contains('phone')) return 'لهاتف ذكي';
    if (n.contains('laptop') || n.contains('mac')) return 'لحاسوب محمول';
    if (n.contains('headphone') || n.contains('airpod')) return 'لسماعات';
    if (n.contains('sony') && n.contains('5')) return 'لجهاز ألعاب';
    if (n.contains('shoe')) return 'لحذاء';
    if (n.contains('coffee')) return 'لمشروب أو آلة قهوة';
    if (n.contains('sofa')) return 'لأثاث منزلي';
    if (n.contains('book') || n.contains('novel')) return 'لكتاب أو مطبوعة';
    return 'لمنتج معروض';
  }

  static String _toneFromRgb(double r, double g, double b) {
    if (r >= g && r >= b && r > 0.35) return 'بألوان دافئة مائلة للأحمر';
    if (b >= r && b >= g && b > 0.35) return 'بألوان باردة مائلة للأزرق';
    if (g >= r && g >= b && g > 0.35) return 'بألوان طبيعية مائلة للأخضر';
    return 'بألوان متوازنة';
  }

  static String _brightnessPhrase(double br) {
    if (br > 0.65) return 'ومظهر عام فاتح';
    if (br < 0.35) return 'ومظهر عام داكن نسبياً';
    return 'ومظهر عام متوسط السطوع';
  }

  static String _saturationPhrase(double sat) {
    if (sat > 0.45) return 'وألوان مشبعة';
    if (sat < 0.15) return 'وألوان قريبة من الرمادي';
    return 'وإشباع لوني معتدل';
  }
}
