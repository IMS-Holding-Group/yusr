import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/voice_service.dart';
import '../../services/voice_navigation_service.dart';
import '../../services/voice_command_parser.dart';
import '../../services/db_service.dart';
import '../../services/recommendation_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/product_image_card.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';
import 'recommendations_screen.dart';

class ProductsScreen extends StatefulWidget {
  final int userId;

  const ProductsScreen({super.key, required this.userId});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

enum _ShoppingInputMode { unset, voice, manual }

class _ProductsScreenState extends State<ProductsScreen> {
  final VoiceService _voiceService = VoiceService();
  final VoiceNavigationService _voiceNav = VoiceNavigationService();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _featuredProducts = [];
  List<Map<String, dynamic>> _recommendedProducts = [];
  List<String> _categories = ['الكل', 'إلكترونيات', 'ملابس', 'أجهزة', 'أطعمة', 'أثاث', 'كتب', 'ألعاب'];
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isVoiceSearchActive = false;
  bool _isVoiceModeActive = false;
  bool _welcomeInProgress = false;
  _ShoppingInputMode _shoppingInputMode = _ShoppingInputMode.unset;
  int _currentIndex = 4; // الرئيسية

  @override
  void initState() {
    super.initState();
    _ensureDataExists();
    _loadProducts();
    _loadFeaturedProducts();
    _loadRecommendations();
    _initializeAndWelcome();
  }

  Future<void> _initializeAndWelcome() async {
    await _initializeVoice();
    await _setupVoiceNavigation();
    if (mounted) _startWelcomeFlow();
  }

  Future<void> _ensureDataExists() async {
    await DBService.ensureProductsExist();
  }
  
  Future<void> _setupVoiceNavigation() async {
    await _voiceNav.initialize(context, widget.userId);
    _voiceNav.onProductSelected = (product) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            productId: product['id'],
            userId: widget.userId,
          ),
        ),
      );
    };
    _voiceNav.onCartUpdate = () {
      // تحديث السلة
    };
    _voiceNav.onNavigateToProduct = (productId) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            productId: productId,
            userId: widget.userId,
          ),
        ),
      );
    };
  }

  Future<void> _initializeVoice() async {
    await _voiceService.initialize();
  }

  /// ترحيب صوتي تلقائي عند فتح المتجر وسؤال طريقة التسوق
  Future<void> _startWelcomeFlow() async {
    if (_welcomeInProgress || _isVoiceSearchActive) return;
    _welcomeInProgress = true;

    await _voiceService.speak(
      'أهلاً بك في متجر يُسر. هل تفضّل التسوق بالوضع الصوتي أم يدوياً؟ قل: بالصوت، أو: باليد.',
    );
    await Future.delayed(const Duration(milliseconds: 800));

    var attempts = 0;
    while (attempts < 2 && mounted) {
      final choice = await _listenForShoppingModeChoice();
      if (choice == _ShoppingInputMode.voice) {
        _welcomeInProgress = false;
        await _activateVoiceShoppingMode();
        return;
      }
      if (choice == _ShoppingInputMode.manual) {
        _welcomeInProgress = false;
        await _activateManualShoppingMode();
        return;
      }
      attempts++;
      if (attempts < 2 && mounted) {
        await _voiceService.speak(
          'لم أفهم إجابتك. قل بالصوت للتسوق صوتياً، أو باليد للتصفح اليدوي.',
        );
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    _welcomeInProgress = false;
    if (mounted && _shoppingInputMode == _ShoppingInputMode.unset) {
      await _activateManualShoppingMode();
    }
  }

  Future<_ShoppingInputMode?> _listenForShoppingModeChoice() async {
    final completer = Completer<_ShoppingInputMode?>();
    var settled = false;

    void finish(_ShoppingInputMode? mode) {
      if (settled) return;
      settled = true;
      if (!completer.isCompleted) completer.complete(mode);
    }

    _voiceService.onSpeechResult = (text) async {
      await _voiceService.stopListening();
      if (text.isEmpty || text == '__TIMEOUT__') {
        finish(null);
        return;
      }
      finish(_parseShoppingModeChoice(text));
    };

    final ok = await _voiceService.startListening();
    if (!ok) {
      finish(null);
      return null;
    }

    Future.delayed(const Duration(seconds: 12), () {
      if (!settled) {
        _voiceService.stopListening();
        finish(null);
      }
    });

    return completer.future;
  }

  _ShoppingInputMode? _parseShoppingModeChoice(String text) {
    final t = text.trim().toLowerCase();
    final normalized = t
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');

    if (normalized.contains('صوت') ||
        normalized.contains('صوتيا') ||
        normalized.contains('ميكروفون') ||
        normalized.contains('مايك')) {
      return _ShoppingInputMode.voice;
    }
    if (normalized.contains('يد') ||
        normalized.contains('يدوي') ||
        normalized.contains('يدويا') ||
        normalized.contains('كتابه') ||
        normalized.contains('كتابة') ||
        normalized.contains('يدين')) {
      return _ShoppingInputMode.manual;
    }
    return null;
  }

  Future<void> _activateVoiceShoppingMode() async {
    if (!mounted) return;
    setState(() {
      _shoppingInputMode = _ShoppingInputMode.voice;
      _isVoiceModeActive = true;
    });
    await _setupVoiceNavigation();
    await _voiceService.speak(
      'تم اختيار التسوق بالصوت. يمكنك الآن قول ما تبحث عنه، أو اسم منتج، أو قول السلة لعرض السلة.',
    );
    await _voiceNav.enableVoiceMode(announce: false);
  }

  Future<void> _activateManualShoppingMode() async {
    if (!mounted) return;
    setState(() => _shoppingInputMode = _ShoppingInputMode.manual);
    await _voiceService.speak(
      'تم اختيار التسوق اليدوي. يمكنك التصفح باللمس. اضغط زر الميكروفون في أي وقت لتفعيل الوضع الصوتي.',
    );
    await _setupVoiceNavigation();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> products;
      if (_searchQuery.isNotEmpty) {
        products = await DBService.searchProducts(_searchQuery);
      } else if (_selectedCategory != 'الكل') {
        products = await DBService.getProductsByCategory(_selectedCategory);
      } else {
        products = await DBService.getAllProducts();
      }

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
        // تحديث المنتجات في خدمة التنقل الصوتي
        _voiceNav.updateProducts(products);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _toggleVoiceMode() async {
    if (_welcomeInProgress) return;
    if (_isVoiceModeActive) {
      await _voiceNav.disableVoiceMode();
      setState(() {
        _isVoiceModeActive = false;
        _shoppingInputMode = _ShoppingInputMode.manual;
      });
    } else {
      await _voiceNav.enableVoiceMode();
      setState(() {
        _isVoiceModeActive = true;
        _shoppingInputMode = _ShoppingInputMode.voice;
      });
    }
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      final allProducts = await DBService.getAllProducts();
      if (mounted) {
        setState(() {
          _featuredProducts = allProducts.take(4).toList();
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      final recs =
          await RecommendationService.getRecommendations(widget.userId, limit: 10);
      if (mounted) {
        setState(() => _recommendedProducts = recs);
      }
    } catch (_) {}
  }

  Future<void> _startVoiceSearch() async {
    if (_isVoiceSearchActive || _welcomeInProgress) return;
    
    print('=== Starting voice search ===');
    setState(() => _isVoiceSearchActive = true);
    
    await _voiceService.stopListening();
    await _voiceService.stopSpeaking();
    await Future.delayed(const Duration(milliseconds: 500));
    
    await _voiceService.speak('قل ما تريد البحث عنه');
    
    await Future.delayed(const Duration(milliseconds: 3500));
    
    final previousCallback = _voiceService.onSpeechResult;
    bool callbackExecuted = false;
    
    print('Setting up onSpeechResult callback');
    _voiceService.onSpeechResult = (text) async {
      print('=== onSpeechResult called with: $text ===');
      
      if (callbackExecuted) {
        print('Callback already executed, ignoring');
        return;
      }
      callbackExecuted = true;
      
      await _voiceService.stopListening();
      
      if (text.isEmpty || text.trim().isEmpty || text == '__TIMEOUT__') {
        print('Empty text or timeout received - no speech detected');
        setState(() => _isVoiceSearchActive = false);
        
        if (previousCallback != null) {
          _voiceService.onSpeechResult = previousCallback;
        } else {
          await _voiceNav.initialize(context, widget.userId);
        }
        
        await _voiceService.speak('لم أسمع أي شيء. يرجى المحاولة مرة أخرى واضغط على زر الميكروفون');
        return;
      }
      
      setState(() => _isVoiceSearchActive = false);
      
      if (previousCallback != null) {
        _voiceService.onSpeechResult = previousCallback;
      } else {
        await _voiceNav.initialize(context, widget.userId);
      }
      
      try {
        print('Processing voice search text: $text');
        
        final cleanedText = text.trim();
        if (cleanedText.isEmpty) {
          await _voiceService.speak('لم أسمع أي شيء. يرجى المحاولة مرة أخرى');
          return;
        }
        
        // استخدام المحلل المحلي أولاً (يعمل بدون خادم)
        var result = VoiceCommandParser.parse(cleanedText);
        String query = '';
        
        if (result['intent'] == 'search' && result['query'] != null) {
          query = result['query'].toString().trim();
          print('Using local parser query: $query');
        } else {
          try {
            final apiResult = await ApiClient().processNLU(cleanedText);
            if (apiResult['intent'] == 'search' && apiResult['query'] != null) {
              query = apiResult['query'].toString().trim();
              print('Using NLU query: $query');
            }
          } catch (_) {}
        }
        
        if (query.isEmpty) {
          query = cleanedText
              .replaceAll('ابحث', '').replaceAll('بحث', '')
              .replaceAll('عن', '').replaceAll('على', '').trim();
          if (query.isEmpty) query = cleanedText;
          print('Using cleaned text as query: $query');
        }
        
        print('Final search query: $query');
        
        if (query.isNotEmpty) {
          setState(() => _searchQuery = query);
          await _loadProducts();
          
          print('Products found: ${_products.length}');
          
          if (_products.isNotEmpty) {
            // إذا وجد منتج واحد فقط → انتقل تلقائياً لصفحته
            if (_products.length == 1) {
              final product = _products[0];
              final name = product['name_ar'] ?? product['name'] ?? '';
              final price = product['price'] ?? 0;
              await _voiceService.speak('وجدت $name بسعر $price ريال. جاري فتح صفحة المنتج');
              
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      productId: product['id'],
                      userId: widget.userId,
                    ),
                  ),
                );
              }
            } else {
              // إذا وجد أكثر من منتج → أعلن وابقى في الصفحة
              await _voiceService.speak('وجدت ${_products.length} منتج. يمكنك اختيار المنتج الذي تريده');
            }
          } else {
            await _voiceService.speak('لم أجد منتجات مطابقة للبحث عن $query');
          }
        } else {
          await _voiceService.speak('لم أفهم طلبك. يرجى المحاولة مرة أخرى');
        }
      } catch (e, stackTrace) {
        print('Error in voice search: $e');
        print('Stack trace: $stackTrace');
        await _voiceService.speak('حدث خطأ أثناء البحث. يرجى المحاولة مرة أخرى');
      }
    };
    
    print('Starting listening...');
    final success = await _voiceService.startListening();
    print('Listening started: $success');
    
    if (!success) {
      setState(() => _isVoiceSearchActive = false);
      if (previousCallback != null) {
        _voiceService.onSpeechResult = previousCallback;
      } else {
        await _voiceNav.initialize(context, widget.userId);
      }
      await _voiceService.speak('فشل بدء الاستماع');
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // الحساب
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: widget.userId),
          ),
        );
        break;
      case 1: // الفئات
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CategoriesScreen(userId: widget.userId),
          ),
        );
        break;
      case 2: // مايكروفون - تفعيل/إيقاف الصوت تلقائياً
        _toggleVoiceMode();
        break;
      case 3: // السلة
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CartScreen(userId: widget.userId),
          ),
        );
        break;
      case 4: // الرئيسية
        // Already on home screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: const Text(
          'يُسر',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.support_agent,
              color: AppTheme.iconGray,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(userId: widget.userId),
                ),
              );
            },
            tooltip: 'الدعم الفني',
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar with Voice Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.searchBarBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                            _loadProducts();
                          },
                          decoration: InputDecoration(
                            hintText: 'ابحث عن منتج...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontFamily: 'IBMPlexSansArabic',
                            ),
                            prefixIcon: IconButton(
                              icon: Icon(
                                _isVoiceSearchActive ? Icons.mic : Icons.mic_none,
                                color: _isVoiceSearchActive ? AppTheme.secondaryBlue : AppTheme.iconGray,
                                size: 20,
                              ),
                              onPressed: _startVoiceSearch,
                            ),
                            suffixIcon: Icon(
                              Icons.search,
                              color: AppTheme.iconGray,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Discount Banner with Image
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.searchBarBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Text on the left
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Text(
                            'تخفيض 50% على اللابتوبات',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              fontFamily: 'IBMPlexSansArabic',
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                      // Image on the right
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/laptops.jpg',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 100,
                            height: 100,
                            color: AppTheme.searchBarBackground,
                            child: Icon(
                              Icons.laptop,
                              color: AppTheme.iconGray,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_recommendedProducts.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'موصى لك',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecommendationsScreen(
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'عرض الكل',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryBlue,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _recommendedProducts.length,
                    itemBuilder: (context, index) {
                      final product = _recommendedProducts[index];
                      return Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: SizedBox(
                          width: 150,
                          child: ProductImageCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    productId: product['id'],
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Categories Horizontal Scroll (RTL) with Images
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  reverse: false, // RTL: start from right
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    
                    // Get image for category
                    String? categoryImage;
                    if (category != 'الكل') {
                      switch (category) {
                        case 'إلكترونيات':
                          categoryImage = 'IPhone-16.jpg';
                          break;
                        case 'ملابس':
                          categoryImage = 'Clothing.webp';
                          break;
                        case 'أجهزة':
                          categoryImage = 'Coffee-machine.webp';
                          break;
                        case 'أطعمة':
                          categoryImage = 'foods.jpg';
                          break;
                        case 'أثاث':
                          categoryImage = 'Sofa.jpg';
                          break;
                        case 'كتب':
                          categoryImage = 'Book.png';
                          break;
                        case 'ألعاب':
                          categoryImage = 'games.jpg';
                          break;
                      }
                    }
                    
                    return Padding(
                      padding: EdgeInsets.only(left: index == 0 ? 0 : 8, right: index == _categories.length - 1 ? 0 : 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = category);
                          _loadProducts();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.secondaryBlue : AppTheme.searchBarBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.secondaryBlue : AppTheme.divider,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Image on the left (if exists)
                              if (categoryImage != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assets/images/$categoryImage',
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.white.withOpacity(0.2) : AppTheme.iconGray.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.category,
                                        size: 16,
                                        color: isSelected ? AppTheme.white : AppTheme.iconGray,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              // Text on the right
                              Text(
                                category,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? AppTheme.white : AppTheme.textPrimary,
                                  fontFamily: 'IBMPlexSansArabic',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Featured Categories Section
              // "الأكثر مبيعاً" section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الأكثر مبيعاً',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoriesScreen(userId: widget.userId),
                          ),
                        );
                      },
                      child: const Text(
                        'عرض الكل',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryBlue,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Featured Products Grid (2 products) - Images only
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 250,
                  child: Row(
                    children: [
                      Expanded(
                        child: _featuredProducts.isNotEmpty
                            ? ProductImageCard(
                                product: _featuredProducts[0],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(
                                        productId: _featuredProducts[0]['id'],
                                        userId: widget.userId,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const SizedBox(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _featuredProducts.length > 1
                            ? ProductImageCard(
                                product: _featuredProducts[1],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(
                                        productId: _featuredProducts[1]['id'],
                                        userId: widget.userId,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Category Sections (2 categories with 2 products each)
              if (_featuredProducts.length > 2) ...[
                // Category 1
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'إلكترونيات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoriesScreen(userId: widget.userId),
                            ),
                          );
                        },
                        child: const Text(
                          'عرض الكل',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryBlue,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 250,
                    child: Row(
                      children: [
                        Expanded(
                          child: _featuredProducts.length > 2
                              ? ProductImageCard(
                                  product: _featuredProducts[2],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailScreen(
                                          productId: _featuredProducts[2]['id'],
                                          userId: widget.userId,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : const SizedBox(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _featuredProducts.length > 3
                              ? ProductImageCard(
                                  product: _featuredProducts[3],
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailScreen(
                                          productId: _featuredProducts[3]['id'],
                                          userId: widget.userId,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // All Products Section
              if (_products.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Text(
                    'جميع المنتجات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              productId: product['id'],
                              userId: widget.userId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
              if (_products.isEmpty && !_isLoading)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'لا توجد منتجات',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
            bottomNavigationBar: _buildBottomNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(
          top: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // الحساب (index 0)
            _buildNavItem(Icons.person_outline, Icons.person, 'الحساب', 0),
            // الفئات (index 1)
            _buildNavItem(Icons.category_outlined, Icons.category, 'الفئات', 1),
            // مايكروفون (index 2) - أيقونة أزرق كبيرة في المنتصف
            _buildMicrophoneButton(),
            // السلة (index 3)
            _buildNavItem(Icons.shopping_cart_outlined, Icons.shopping_cart, 'السلة', 3),
            // الرئيسية (index 4)
            _buildNavItem(Icons.home_outlined, Icons.home, 'الرئيسية', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton() {
    return GestureDetector(
      onTap: () => _onNavItemTapped(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _isVoiceModeActive ? AppTheme.success : AppTheme.secondaryBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isVoiceModeActive ? AppTheme.success : AppTheme.secondaryBlue).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _isVoiceModeActive ? Icons.mic : Icons.mic_none,
          color: AppTheme.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppTheme.secondaryBlue : AppTheme.iconGray,
            size: isActive ? 26 : 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppTheme.secondaryBlue : AppTheme.textSecondary,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}
