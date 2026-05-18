import 'package:flutter/material.dart';
import '../../services/recommendation_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

/// منتجات موصى بها (تصفية تعاونية) — صفحة كاملة يمكن فتحها من الأوامر الصوتية
class RecommendationsScreen extends StatefulWidget {
  final int userId;

  const RecommendationsScreen({super.key, required this.userId});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list =
        await RecommendationService.getRecommendations(widget.userId, limit: 20);
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: const Text(
          'موصى لك',
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'لا توجد توصيات بعد. تصفّح المنتجات أو أضف للسلة لنبني اقتراحات تناسبك.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'IBMPlexSansArabic',
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final product = _items[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              productId: product['id'] as int,
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
