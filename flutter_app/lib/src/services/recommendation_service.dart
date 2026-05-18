import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';
import 'db_service.dart';

/// تصفية تعاونية قائمة على العناصر (Item-Based Collaborative Filtering)
/// كما في تقرير المشروع: تقدير تشابه المنتجات من تعايشها في سلوك المستخدمين،
/// ثم اقتراح منتجات مشابهة لما تفاعل معه المستخدم الحالي.
class RecommendationService {
  RecommendationService._();

  static const _viewW = 1.0;
  static const _cartW = 2.5;
  static const _purchaseW = 5.0;

  static double _weightForType(String type) {
    switch (type) {
      case 'view':
        return _viewW;
      case 'cart':
        return _cartW;
      case 'purchase':
        return _purchaseW;
      default:
        return 0.5;
    }
  }

  /// تسجيل تفاعل: مشاهدة، إضافة للسلة، أو شراء
  static Future<void> recordInteraction(
    int userId,
    int productId,
    String interactionType,
  ) async {
    if (userId <= 0 || productId <= 0) return;
    final db = await DBService.database;
    final w = _weightForType(interactionType);
    await db.insert('user_product_interactions', {
      'user_id': userId,
      'product_id': productId,
      'weight': w,
      'interaction_type': interactionType,
    });
  }

  /// مصفوفة تعايش المنتجات: لكل مستخدم نجمع أزواج (i,j) بثقل أدنى
  static Future<Map<String, double>> _cooccurrenceMatrix(Database db) async {
    final rows = await db.rawQuery('''
      SELECT user_id, product_id, SUM(weight) as s
      FROM user_product_interactions
      GROUP BY user_id, product_id
    ''');

    final byUser = <int, List<Map<String, dynamic>>>{};
    for (final r in rows) {
      final uid = r['user_id'] as int;
      byUser.putIfAbsent(uid, () => []).add(r);
    }

    final co = <String, double>{};
    for (final list in byUser.values) {
      if (list.length < 2) continue;
      for (var a = 0; a < list.length; a++) {
        for (var b = a + 1; b < list.length; b++) {
          final ia = list[a]['product_id'] as int;
          final ib = list[b]['product_id'] as int;
          if (ia == ib) continue;
          final i = ia < ib ? ia : ib;
          final j = ia < ib ? ib : ia;
          final wa = (list[a]['s'] as num).toDouble();
          final wb = (list[b]['s'] as num).toDouble();
          final key = '$i,$j';
          co[key] = (co[key] ?? 0) + math.min(wa, wb);
        }
      }
    }
    return co;
  }

  static Future<Map<int, double>> _productPopularity(Database db) async {
    final rows = await db.rawQuery('''
      SELECT product_id, SUM(weight) as pop
      FROM user_product_interactions
      GROUP BY product_id
    ''');
    final m = <int, double>{};
    for (final r in rows) {
      m[r['product_id'] as int] = (r['pop'] as num).toDouble();
    }
    return m;
  }

  static Future<Map<int, double>> _userProductScores(
    Database db,
    int userId,
  ) async {
    final rows = await db.rawQuery('''
      SELECT product_id, SUM(weight) as s
      FROM user_product_interactions
      WHERE user_id = ?
      GROUP BY product_id
    ''', [userId]);
    final m = <int, double>{};
    for (final r in rows) {
      m[r['product_id'] as int] = (r['s'] as num).toDouble();
    }
    return m;
  }

  /// تنبؤ بالمنتجات: نقاط(j) = Σ_i sim(i,j) * score(u,i) ، sim تشبه جيب التمام على مستخدمين
  static Future<List<Map<String, dynamic>>> getRecommendations(
    int userId, {
    int limit = 8,
  }) async {
    final db = await DBService.database;
    final userScores = await _userProductScores(db, userId);
    final co = await _cooccurrenceMatrix(db);
    final pop = await _productPopularity(db);

    if (userScores.isEmpty) {
      return _popularFallback(db, pop, limit: limit);
    }

    final itemDegrees = <int, double>{};
    for (final e in co.entries) {
      final parts = e.key.split(',');
      final i = int.parse(parts[0]);
      final j = int.parse(parts[1]);
      itemDegrees[i] = (itemDegrees[i] ?? 0) + e.value;
      itemDegrees[j] = (itemDegrees[j] ?? 0) + e.value;
    }

    final scores = <int, double>{};

    for (final seed in userScores.entries) {
      final i = seed.key;
      final ui = seed.value;
      final di = math.sqrt((itemDegrees[i] ?? 1) + 1e-6);

      for (final e in co.entries) {
        final parts = e.key.split(',');
        final a = int.parse(parts[0]);
        final b = int.parse(parts[1]);
        int? other;
        if (a == i) {
          other = b;
        } else if (b == i) {
          other = a;
        }
        if (other == null) continue;

        final dj = math.sqrt((itemDegrees[other] ?? 1) + 1e-6);
        final sim = e.value / (di * dj);
        scores[other] = (scores[other] ?? 0) + sim * ui;
      }
    }

    for (final pid in userScores.keys) {
      scores.remove(pid);
    }

    if (scores.isEmpty) {
      return _popularFallback(db, pop,
          limit: limit, exclude: userScores.keys.toSet());
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final ids = sorted.take(limit * 2).map((e) => e.key).toList();
    if (ids.isEmpty) return [];

    final placeholders = List.filled(ids.length, '?').join(',');
    final products = await db.rawQuery(
      'SELECT * FROM products WHERE id IN ($placeholders)',
      ids,
    );

    final byId = {for (final p in products) p['id'] as int: p};
    final out = <Map<String, dynamic>>[];
    for (final id in ids) {
      final p = byId[id];
      if (p != null) out.add(p);
      if (out.length >= limit) break;
    }
    return out;
  }

  static Future<List<Map<String, dynamic>>> _popularFallback(
    Database db,
    Map<int, double> pop, {
    required int limit,
    Set<int> exclude = const {},
  }) async {
    if (pop.isEmpty) {
      final all = await DBService.getAllProducts();
      return all.take(limit).toList();
    }
    final sorted = pop.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final ids = sorted
        .where((e) => !exclude.contains(e.key))
        .take(limit * 2)
        .map((e) => e.key)
        .toList();
    if (ids.isEmpty) return [];
    final placeholders = List.filled(ids.length, '?').join(',');
    final products = await db.rawQuery(
      'SELECT * FROM products WHERE id IN ($placeholders)',
      ids,
    );
    final byId = {for (final p in products) p['id'] as int: p};
    final out = <Map<String, dynamic>>[];
    for (final id in ids) {
      final p = byId[id];
      if (p != null) out.add(p);
      if (out.length >= limit) break;
    }
    return out;
  }
}
