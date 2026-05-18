import 'package:flutter/material.dart';
import '../../services/voice_service.dart';
import '../../services/api_client.dart';
import '../../services/db_service.dart';
import '../../services/voice_command_parser.dart';
import '../widgets/voice_button.dart';
import '../widgets/voice_mic_button.dart';
import 'products_screen.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final int userId;
  final String userName;
  
  const HomeScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  final ApiClient _apiClient = ApiClient();
  bool _isListening = false;
  late AnimationController _animationController;
  late List<Animation<double>> _buttonAnimations;
  
  @override
  void initState() {
    super.initState();
    _initializeVoice();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _buttonAnimations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            index * 0.15,
            0.6 + (index * 0.15),
            curve: Curves.easeOut,
          ),
        ),
      );
    });
    
    _animationController.forward();
  }
  
  Future<void> _initializeVoice() async {
    await _voiceService.initialize();
    _voiceService.onSpeechResult = _handleSpeechResult;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _voiceService.speak('مرحباً ${widget.userName}. كيف يمكنني مساعدتك اليوم؟');
    });
  }
  
  void _handleSpeechResult(String text) {
    setState(() => _isListening = false);
    _voiceService.stopListening();
    _processVoiceCommand(text);
  }
  
  Future<void> _processVoiceCommand(String text) async {
    // التعامل مع timeout أو نص فارغ
    if (text.isEmpty || text == '__TIMEOUT__') {
      await _voiceService.speak('لم أسمع أي شيء. يرجى المحاولة مرة أخرى');
      return;
    }
    
    final cleanedText = text.trim();
    if (cleanedText.isEmpty) {
      await _voiceService.speak('لم أسمع أي شيء. يرجى المحاولة مرة أخرى');
      return;
    }
    
    print('Processing voice command: $cleanedText');
    
    // استخدام المحلل المحلي أولاً (يعمل بدون خادم - للمكفوفين)
    var result = VoiceCommandParser.parse(cleanedText);
    var intent = result['intent'] ?? 'unknown';
    
    // إن فشل المحلل المحلي، جرب الخادم
    if (intent == 'unknown' && result['speak_text'] == null) {
      try {
        final apiResult = await _apiClient.processNLU(cleanedText);
        intent = apiResult['intent'] ?? 'unknown';
        result = {...result, ...apiResult};
      } catch (_) {}
    }
    
    print('Intent: $intent');
    
    switch (intent) {
      case 'search':
      case 'search_product':
        await _handleVoiceSearch(result['query'] ?? cleanedText);
        break;
      case 'add_to_cart':
      case 'checkout':
        _navigateToCart();
        break;
      case 'view_cart':
        _navigateToCart();
        break;
      case 'view_products':
        _navigateToProducts();
        break;
      case 'navigate_profile':
      case 'order_status':
        _navigateToProfile();
        break;
      case 'navigate_settings':
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => SettingsScreen(userId: widget.userId),
        ));
        break;
      default:
        await _voiceService.speak(result['speak_text'] ?? 'لم أفهم. جرّب: بحث عن كتب، السلة، أو تصفح المتجر');
    }
  }
  
  Future<void> _handleVoiceSearch(String query) async {
    await _voiceService.speak('جاري البحث عن $query');
    
    // البحث في قاعدة البيانات المحلية
    final products = await DBService.searchProducts(query);
    
    if (products.isEmpty) {
      await _voiceService.speak('لم أجد منتجات مطابقة للبحث عن $query');
      return;
    }
    
    // إذا وجد منتج واحد فقط → انتقل تلقائياً لصفحته
    if (products.length == 1) {
      final product = products[0];
      final name = product['name_ar'] ?? product['name'] ?? '';
      final price = product['price'] ?? 0;
      await _voiceService.speak('وجدت $name بسعر $price ريال. جاري فتح صفحة المنتج');
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            productId: product['id'],
            userId: widget.userId,
          ),
        ),
      );
      return;
    }
    
    // إذا وجد أكثر من منتج → انتقل لصفحة المنتجات مع النتيجة
    await _voiceService.speak('وجدت ${products.length} منتج. جاري فتح صفحة المنتجات');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsScreen(userId: widget.userId),
      ),
    );
  }
  
  void _navigateToProducts() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProductsScreen(userId: widget.userId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  
  void _navigateToCart() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CartScreen(userId: widget.userId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  
  void _navigateToProfile() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ProfileScreen(userId: widget.userId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
  
  Future<void> _startVoiceSearch() async {
    if (_isListening) return;
    
    setState(() => _isListening = true);
    
    // إيقاف أي استماع سابق
    await _voiceService.stopListening();
    await _voiceService.stopSpeaking();
    await Future.delayed(const Duration(milliseconds: 300));
    
    await _voiceService.speak('ما الذي تريد البحث عنه؟');
    
    // انتظار انتهاء الكلام قبل بدء الاستماع
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // ربط callback للنتيجة
    _voiceService.onSpeechResult = _handleSpeechResult;
    
    final success = await _voiceService.startListening();
    if (!success) {
      setState(() => _isListening = false);
      await _voiceService.speak('فشل بدء الاستماع. يرجى المحاولة مرة أخرى');
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _voiceService.stopSpeaking();
    _voiceService.stopListening();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              'يُسر',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => SettingsScreen(userId: widget.userId),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeTransition(
                    opacity: _buttonAnimations[0],
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.3),
                        end: Offset.zero,
                      ).animate(_buttonAnimations[0]),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'مرحباً',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'IBMPlexSansArabic',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.userName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.primary,
                                fontFamily: 'IBMPlexSansArabic',
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_isListening)
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 500),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: 0.9 + (value * 0.1),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                            blurRadius: 12,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.mic,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'جاري الاستماع...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'IBMPlexSansArabic',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _buttonAnimations[1],
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_buttonAnimations[1]),
                      child: VoiceButton(
                        icon: Icons.search_rounded,
                        label: 'استمع وابحث',
                        onPressed: _startVoiceSearch,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _buttonAnimations[2],
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_buttonAnimations[2]),
                      child: VoiceButton(
                        icon: Icons.shopping_cart_rounded,
                        label: 'السلة',
                        onPressed: _navigateToCart,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _buttonAnimations[3],
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_buttonAnimations[3]),
                      child: VoiceButton(
                        icon: Icons.person_rounded,
                        label: 'حسابي',
                        onPressed: _navigateToProfile,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _buttonAnimations[3],
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_buttonAnimations[3]),
                      child: VoiceButton(
                        icon: Icons.store_rounded,
                        label: 'تصفح المتجر',
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        onPressed: _navigateToProducts,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        VoiceMicButton(userId: widget.userId, parentContext: context),
      ],
    );
  }
}
