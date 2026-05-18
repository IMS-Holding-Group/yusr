import 'package:flutter/material.dart';
import 'voice_service.dart';
import 'recommendation_service.dart';
import 'voice_command_parser.dart';
import 'api_client.dart';
import 'db_service.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/screens/product_detail_screen.dart';
import '../ui/screens/cart_screen.dart';
import '../ui/screens/checkout_screen.dart';
import '../ui/screens/products_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/orders_screen.dart';
import '../ui/screens/addresses_screen.dart';
import '../ui/screens/payment_methods_screen.dart';
import '../ui/screens/recommendations_screen.dart';

/// خدمة التنقل الصوتي المتكاملة
/// تتيح التحكم الكامل في التطبيق بالصوت بدون لمس الشاشة
class VoiceNavigationService {
  static final VoiceNavigationService _instance = VoiceNavigationService._internal();
  factory VoiceNavigationService() => _instance;
  VoiceNavigationService._internal();

  final VoiceService _voiceService = VoiceService();
  final ApiClient _apiClient = ApiClient();
  
  bool _isContinuousListening = false;
  bool _isVoiceModeActive = false;
  
  // حالة التصفح الصوتي
  List<Map<String, dynamic>> _currentProducts = [];
  int _currentProductIndex = 0;
  
  int _currentUserId = 0;
  BuildContext? _currentContext;
  String? _currentAddressTitle;
  String? _currentAddressStreet;
  String? _currentAddressCity;
  String? _currentAddressDistrict;
  String? _currentAddressBuilding;
  String? _currentAddressApartment;
  String? _currentAddressPostal;
  String? _currentPaymentType;
  String? _currentCardNumber;
  String? _currentCardHolder;
  int? _currentExpiryMonth;
  int? _currentExpiryYear;
  String? _currentCvv;
  String? _currentWalletProvider;
  String? _currentBankName;
  String _currentStep = '';
  
  Function(String)? onScreenChange;
  Function(Map<String, dynamic>)? onProductSelected;
  Function()? onCartUpdate;
  Function()? onAddressAdded;
  Function()? onPaymentMethodAdded;
  
  // Callbacks للتنقل التلقائي
  Function(int productId)? onNavigateToProduct;
  Function()? onNavigateToCart;
  Function()? onNavigateToCheckout;
  Function()? onNavigateToProducts;
  Function()? onNavigateToHome;
  Function()? onNavigateToProfile;
  
  Future<void> initialize(BuildContext context, int userId) async {
    _currentUserId = userId;
    _currentContext = context;
    await _voiceService.initialize();
    _setupVoiceCallbacks();
  }
  
  void _setupVoiceCallbacks() {
    _voiceService.onSpeechResult = (text) async {
      await _processVoiceCommand(text);
    };
  }
  
  /// تفعيل وضع الصوت المتكامل
  Future<void> enableVoiceMode({bool announce = true}) async {
    _isVoiceModeActive = true;
    _isContinuousListening = true;
    if (announce) {
      await _voiceService.speak(
        'تم تفعيل وضع الصوت. يمكنك الآن التحكم في التطبيق بالكامل بالصوت',
      );
    }
    await _startContinuousListening();
  }
  
  /// إيقاف وضع الصوت
  Future<void> disableVoiceMode() async {
    _isVoiceModeActive = false;
    _isContinuousListening = false;
    await _voiceService.stopListening();
    await _voiceService.speak('تم إيقاف وضع الصوت');
  }
  
  /// بدء الاستماع المستمر
  Future<void> _startContinuousListening() async {
    if (!_isContinuousListening) return;
    
    await Future.delayed(const Duration(milliseconds: 500));
    final success = await _voiceService.startListening();
    
    if (!success) {
      await _voiceService.speak('فشل بدء الاستماع');
      _isContinuousListening = false;
    }
  }
  
  /// معالجة الأوامر الصوتية
  Future<void> _processVoiceCommand(String text) async {
    if (!_isVoiceModeActive) return;
    
    // التعامل مع timeout أو نص فارغ
    if (text.isEmpty || text == '__TIMEOUT__') {
      await _voiceService.speak('لم أسمع أي شيء. يرجى المحاولة مرة أخرى');
      // إعادة بدء الاستماع المستمر
      if (_isContinuousListening) {
        await Future.delayed(const Duration(milliseconds: 1000));
        await _startContinuousListening();
      }
      return;
    }
    
    final cleanedText = text.trim();
    if (cleanedText.isEmpty) {
      await _voiceService.speak('لم أسمع أي شيء. يرجى المحاولة مرة أخرى');
      if (_isContinuousListening) {
        await Future.delayed(const Duration(milliseconds: 1000));
        await _startContinuousListening();
      }
      return;
    }
    
    print('Processing voice command: $cleanedText');
    
    // استخدام المحلل المحلي أولاً (يعمل بدون خادم)
    var result = VoiceCommandParser.parse(cleanedText);
    var intent = result['intent'] ?? 'unknown';
    
    if (intent == 'unknown') {
      try {
        final apiResult = await _apiClient.processNLU(cleanedText);
        intent = apiResult['intent'] ?? 'unknown';
        result = {...result, ...apiResult};
      } catch (_) {}
    }
    
    print('NLU Intent: $intent');
    
    try {
      switch (intent) {
        case 'search':
          await _handleSearch(result['query'] ?? cleanedText);
          break;
        case 'add_to_cart':
          await _handleAddToCart(cleanedText);
          break;
        case 'view_cart':
          await _handleViewCart();
          break;
        case 'checkout':
          await _handleCheckout();
          break;
        case 'view_products':
          await _handleViewProducts();
          break;
        case 'view_recommendations':
          await _handleViewRecommendations();
          break;
        case 'read_description':
          await _handleReadDescription();
          break;
        case 'remove_from_cart':
          await _handleRemoveFromCart(cleanedText);
          break;
        case 'navigate':
          await _handleNavigation(cleanedText);
          break;
        case 'select_product':
          await _handleSelectProduct(cleanedText);
          break;
        case 'navigate_to_account':
          await _handleNavigateToAccount();
          break;
        case 'add_address':
          await _handleAddAddress(cleanedText);
          break;
        case 'add_payment_method':
          await _handleAddPaymentMethod(cleanedText);
          break;
        case 'delete_order':
          await _handleDeleteOrder(cleanedText);
          break;
        case 'collect_address_data':
          await _handleCollectAddressData(cleanedText);
          break;
        case 'collect_payment_data':
          await _handleCollectPaymentData(cleanedText);
          break;
        case 'logout':
          await _handleLogout();
          break;
        case 'settings':
          await _handleSettings();
          break;
        case 'complete_order':
          await _handleCompleteOrder(cleanedText);
          break;
        default:
          await _handleUnknownCommand(cleanedText);
      }
    } catch (e) {
      print('Error processing voice command: $e');
      await _voiceService.speak('حدث خطأ أثناء معالجة الأمر. يرجى المحاولة مرة أخرى');
    }
    
    // إعادة بدء الاستماع المستمر
    if (_isContinuousListening) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await _startContinuousListening();
    }
  }
  
  /// البحث بالصوت
  Future<void> _handleSearch(String query) async {
    await _voiceService.speak('جاري البحث عن $query');
    _currentProducts = await DBService.searchProducts(query);
    
    if (_currentProducts.isEmpty) {
      await _voiceService.speak('لم أجد منتجات مطابقة');
      return;
    }
    
    // إذا وجد منتج واحد فقط → انتقل تلقائياً لصفحته
    if (_currentProducts.length == 1) {
      final product = _currentProducts[0];
      final name = product['name_ar'] ?? product['name'] ?? '';
      final price = product['price'] ?? 0;
      await _voiceService.speak('وجدت $name بسعر $price ريال. جاري فتح صفحة المنتج');
      _currentProductIndex = 0;
      
      // الانتقال التلقائي لصفحة المنتج
      if (onNavigateToProduct != null) {
        onNavigateToProduct!(product['id']);
      } else if (_currentContext != null && _currentContext!.mounted) {
        Navigator.push(
          _currentContext!,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: product['id'],
              userId: _currentUserId,
            ),
          ),
        );
      }
      return;
    }
    
    // إذا وجد أكثر من منتج → ينتقل للأول تلقائياً
    if (_currentProducts.length > 1) {
      final firstProduct = _currentProducts[0];
      final name = firstProduct['name_ar'] ?? firstProduct['name'] ?? '';
      final price = firstProduct['price'] ?? 0;
      await _voiceService.speak('وجدت ${_currentProducts.length} منتج. المنتج الأول: $name بسعر $price ريال. جاري فتح صفحة المنتج');
      _currentProductIndex = 0;
      
      // الانتقال التلقائي لصفحة المنتج الأول
      if (onNavigateToProduct != null) {
        onNavigateToProduct!(firstProduct['id']);
      } else if (_currentContext != null && _currentContext!.mounted) {
        Navigator.push(
          _currentContext!,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: firstProduct['id'],
              userId: _currentUserId,
            ),
          ),
        );
      }
    }
  }
  
  /// اختيار منتج بالصوت
  Future<void> _handleSelectProduct(String text) async {
    // استخراج رقم المنتج من النص
    final numberPattern = RegExp(r'\d+');
    final match = numberPattern.firstMatch(text);
    
    if (match != null) {
      final productNumber = int.parse(match.group(0)!);
      if (productNumber > 0 && productNumber <= _currentProducts.length) {
        final product = _currentProducts[productNumber - 1];
        _currentProductIndex = productNumber - 1;
        
        final name = product['name_ar'] ?? product['name'] ?? '';
        final price = product['price'] ?? 0;
        
        await _voiceService.speak('المنتج رقم $productNumber: $name. السعر: $price ريال. جاري فتح صفحة المنتج');
        
        // الانتقال التلقائي لصفحة المنتج
        if (onNavigateToProduct != null) {
          onNavigateToProduct!(product['id']);
        } else if (onProductSelected != null) {
          onProductSelected!(product);
        } else if (_currentContext != null && _currentContext!.mounted) {
          Navigator.push(
            _currentContext!,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: product['id'],
                userId: _currentUserId,
              ),
            ),
          );
        }
      } else {
        await _voiceService.speak('رقم المنتج غير صحيح. يرجى اختيار رقم بين 1 و ${_currentProducts.length}');
      }
    } else {
      // محاولة البحث بالاسم
      for (int i = 0; i < _currentProducts.length; i++) {
        final product = _currentProducts[i];
        final name = product['name_ar'] ?? product['name'] ?? '';
        if (text.contains(name.toLowerCase())) {
          _currentProductIndex = i;
          await _handleSelectProduct('المنتج رقم ${i + 1}');
          return;
        }
      }
      await _voiceService.speak('لم أتمكن من العثور على المنتج');
    }
  }
  
  /// التنقل بين المنتجات
  Future<void> _handleNavigation(String text) async {
    if (_currentProducts.isEmpty) {
      await _voiceService.speak('لا توجد منتجات للتنقل بينها');
      return;
    }
    
    if (text.contains('التالي') || text.contains('اللي بعد')) {
      if (_currentProductIndex < _currentProducts.length - 1) {
        _currentProductIndex++;
        final product = _currentProducts[_currentProductIndex];
        final name = product['name_ar'] ?? product['name'] ?? '';
        final price = product['price'] ?? 0;
        await _voiceService.speak('المنتج التالي: $name بسعر $price ريال. جاري فتح صفحة المنتج');
        
        // الانتقال التلقائي لصفحة المنتج
        if (onNavigateToProduct != null) {
          onNavigateToProduct!(product['id']);
        } else if (_currentContext != null && _currentContext!.mounted) {
          Navigator.push(
            _currentContext!,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: product['id'],
                userId: _currentUserId,
              ),
            ),
          );
        }
      } else {
        await _voiceService.speak('هذا آخر منتج');
      }
    } else if (text.contains('السابق') || text.contains('اللي قبل')) {
      if (_currentProductIndex > 0) {
        _currentProductIndex--;
        final product = _currentProducts[_currentProductIndex];
        final name = product['name_ar'] ?? product['name'] ?? '';
        final price = product['price'] ?? 0;
        await _voiceService.speak('المنتج السابق: $name بسعر $price ريال. جاري فتح صفحة المنتج');
        
        // الانتقال التلقائي لصفحة المنتج
        if (onNavigateToProduct != null) {
          onNavigateToProduct!(product['id']);
        } else if (_currentContext != null && _currentContext!.mounted) {
          Navigator.push(
            _currentContext!,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: product['id'],
                userId: _currentUserId,
              ),
            ),
          );
        }
      } else {
        await _voiceService.speak('هذا أول منتج');
      }
    }
  }
  
  /// إضافة للسلة بالصوت
  Future<void> _handleAddToCart(String text) async {
    Map<String, dynamic>? product;
    
    // محاولة الحصول على المنتج الحالي
    if (_currentProducts.isNotEmpty && _currentProductIndex >= 0 && _currentProductIndex < _currentProducts.length) {
      product = _currentProducts[_currentProductIndex] as Map<String, dynamic>?;
    } else {
      // إذا لم يكن هناك منتج محدد، جرب البحث في النص
      final productMatch = RegExp(r'[\u0600-\u06FF\s]+').firstMatch(text);
      if (productMatch != null) {
        final searchQuery = productMatch.group(0)!.trim();
        final products = await DBService.searchProducts(searchQuery);
        if (products.isNotEmpty) {
          product = products[0];
        }
      }
    }
    
    if (product == null) {
      await _voiceService.speak('لم يتم تحديد منتج. يرجى اختيار منتج أولاً');
      return;
    }
    
    await DBService.addToCart(product['id'], 1);
    
    final name = product['name_ar'] ?? product['name'] ?? '';
    await _voiceService.speak('تمت إضافة $name إلى السلة بنجاح. جاري فتح صفحة المنتج');
    
    if (onCartUpdate != null) {
      onCartUpdate!();
    }
    
      // الانتقال التلقائي لصفحة المنتج
      final productId = product['id'] as int?;
    if (productId != null) {
      if (onNavigateToProduct != null) {
        onNavigateToProduct!(productId);
      } else if (_currentContext != null && _currentContext!.mounted) {
        Navigator.push(
          _currentContext!,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: productId,
              userId: _currentUserId,
            ),
          ),
        );
      }
    }
  }
  
  /// عرض السلة بالصوت
  Future<void> _handleViewCart() async {
    final cartItems = await DBService.getCartItems();
    
    if (cartItems.isEmpty) {
      await _voiceService.speak('السلة فارغة');
      return;
    }
    
    double total = 0;
    String announcement = 'السلة تحتوي على ';
    
    for (int i = 0; i < cartItems.length; i++) {
      final item = cartItems[i];
      final name = item['name_ar'] ?? '';
      final quantity = item['quantity'] ?? 1;
      final price = item['price'] ?? 0;
      final itemTotal = price * quantity;
      total += itemTotal;
      
      announcement += 'المنتج رقم ${i + 1}: $name، الكمية: $quantity، السعر: $itemTotal ريال. ';
    }
    
    announcement += 'الإجمالي: $total ريال. جاري فتح صفحة السلة';
    
    await _voiceService.speak(announcement);
    
    // الانتقال التلقائي لصفحة السلة
    if (onNavigateToCart != null) {
      onNavigateToCart!();
    } else if (_currentContext != null && _currentContext!.mounted) {
      Navigator.push(
        _currentContext!,
        MaterialPageRoute(
          builder: (context) => CartScreen(userId: _currentUserId),
        ),
      );
    }
  }
  
  /// إتمام الشراء بالصوت
  Future<void> _handleCheckout() async {
    final cartItems = await DBService.getCartItems();
    
    if (cartItems.isEmpty) {
      await _voiceService.speak('السلة فارغة');
      return;
    }
    
    // حساب الإجمالي
    double total = 0;
    for (var item in cartItems) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (item['quantity'] as int?) ?? 1;
      total += price * quantity;
    }
    
    await _voiceService.speak('جاري فتح صفحة الدفع');
    
    // الانتقال التلقائي لصفحة الدفع
    if (onNavigateToCheckout != null) {
      onNavigateToCheckout!();
    } else if (_currentContext != null && _currentContext!.mounted) {
      Navigator.push(
        _currentContext!,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(
            userId: _currentUserId,
            total: total,
          ),
        ),
      );
    }
  }
  
  /// عرض المنتجات
  Future<void> _handleViewProducts() async {
    _currentProducts = await DBService.getAllProducts();
    
    if (_currentProducts.isEmpty) {
      await _voiceService.speak('لا توجد منتجات متاحة');
      return;
    }
    
    await _voiceService.speak('وجدت ${_currentProducts.length} منتج. جاري فتح صفحة المنتجات');
    
    // الانتقال التلقائي لصفحة المنتجات
    if (onNavigateToProducts != null) {
      onNavigateToProducts!();
    } else if (_currentContext != null && _currentContext!.mounted) {
      Navigator.push(
        _currentContext!,
        MaterialPageRoute(
          builder: (context) => ProductsScreen(userId: _currentUserId),
        ),
      );
    }
  }

  Future<void> _handleViewRecommendations() async {
    final list =
        await RecommendationService.getRecommendations(_currentUserId, limit: 12);
    if (list.isEmpty) {
      await _voiceService.speak(
        'لا توجد توصيات بعد. تصفّح المنتجات أو أضف للسلة لنبني اقتراحات تناسبك',
      );
      return;
    }
    final preview = list
        .take(3)
        .map((p) => p['name_ar'] ?? p['name'] ?? '')
        .where((s) => s.toString().isNotEmpty)
        .join('، ');
    await _voiceService.speak(
      'عرض ${list.length} منتج مقترح. منها: $preview',
    );
    if (_currentContext != null && _currentContext!.mounted) {
      Navigator.push(
        _currentContext!,
        MaterialPageRoute(
          builder: (context) =>
              RecommendationsScreen(userId: _currentUserId),
        ),
      );
    }
  }
  
  /// قراءة الوصف
  Future<void> _handleReadDescription() async {
    if (_currentProducts.isEmpty || _currentProductIndex < 0) {
      await _voiceService.speak('لم يتم اختيار منتج');
      return;
    }
    
    final product = _currentProducts[_currentProductIndex];
    final description = product['description_ar'] ?? product['description'] ?? '';
    
    if (description.isEmpty) {
      await _voiceService.speak('لا يوجد وصف لهذا المنتج');
    } else {
      await _voiceService.speak(description);
    }
  }
  
  /// حذف من السلة
  Future<void> _handleRemoveFromCart(String text) async {
    final cartItems = await DBService.getCartItems();
    
    if (cartItems.isEmpty) {
      await _voiceService.speak('السلة فارغة');
      return;
    }
    
    final numberPattern = RegExp(r'\d+');
    final match = numberPattern.firstMatch(text);
    
    if (match != null) {
      final itemNumber = int.parse(match.group(0)!);
      if (itemNumber > 0 && itemNumber <= cartItems.length) {
        final item = cartItems[itemNumber - 1];
        await DBService.removeFromCart(item['id']);
        
        final name = item['name_ar'] ?? '';
        await _voiceService.speak('تم حذف $name من السلة. جاري تحديث السلة');
        
        if (onCartUpdate != null) {
          onCartUpdate!();
        }
        
        // الانتقال التلقائي لصفحة السلة لتحديث العرض
        if (onNavigateToCart != null) {
          onNavigateToCart!();
        } else if (_currentContext != null && _currentContext!.mounted) {
          Navigator.push(
            _currentContext!,
            MaterialPageRoute(
              builder: (context) => CartScreen(userId: _currentUserId),
            ),
          );
        }
      } else {
        await _voiceService.speak('رقم المنتج غير صحيح');
      }
    } else {
      // إذا لم يذكر رقم، احذف أول عنصر
      if (cartItems.isNotEmpty) {
        final item = cartItems[0];
        await DBService.removeFromCart(item['id']);
        final name = item['name_ar'] ?? '';
        await _voiceService.speak('تم حذف $name من السلة. جاري تحديث السلة');
        
        if (onCartUpdate != null) {
          onCartUpdate!();
        }
        
        // الانتقال التلقائي لصفحة السلة
        if (onNavigateToCart != null) {
          onNavigateToCart!();
        } else if (_currentContext != null && _currentContext!.mounted) {
          Navigator.push(
            _currentContext!,
            MaterialPageRoute(
              builder: (context) => CartScreen(userId: _currentUserId),
            ),
          );
        }
      } else {
        await _voiceService.speak('لم أتمكن من تحديد المنتج المراد حذفه');
      }
    }
  }
  
  Future<void> _handleNavigateToAccount() async {
    await _voiceService.speak('جاري الانتقال إلى الحساب');
    
    // الانتقال التلقائي لصفحة الحساب
    if (onNavigateToProfile != null) {
      onNavigateToProfile!();
    } else if (_currentContext != null && _currentContext!.mounted) {
      Navigator.push(
        _currentContext!,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: _currentUserId),
        ),
      );
    } else if (onScreenChange != null) {
      onScreenChange!('profile');
    }
  }

  Future<void> _handleAddAddress(String text) async {
    if (_currentStep.isEmpty) {
      _currentStep = 'title';
      await _voiceService.speak('سأساعدك في إضافة عنوان جديد. ما هو اسم العنوان؟ مثلاً: المنزل أو العمل');
      return;
    }
    await _handleCollectAddressData(text);
  }

  Future<void> _handleCollectAddressData(String text) async {
    if (_currentStep == 'title') {
      _currentAddressTitle = text.trim();
      _currentStep = 'street';
      await _voiceService.speak('ما هو اسم الشارع؟');
    } else if (_currentStep == 'street') {
      _currentAddressStreet = text.trim();
      _currentStep = 'city';
      await _voiceService.speak('ما هي المدينة؟');
    } else if (_currentStep == 'city') {
      _currentAddressCity = text.trim();
      _currentStep = 'district';
      await _voiceService.speak('ما هو الحي أو المنطقة؟');
    } else if (_currentStep == 'district') {
      _currentAddressDistrict = text.trim();
      _currentStep = 'building';
      await _voiceService.speak('ما هو رقم المبنى؟');
    } else if (_currentStep == 'building') {
      _currentAddressBuilding = text.trim();
      _currentStep = 'apartment';
      await _voiceService.speak('ما هو رقم الشقة؟');
    } else if (_currentStep == 'apartment') {
      _currentAddressApartment = text.trim();
      _currentStep = 'postal';
      await _voiceService.speak('ما هو الرمز البريدي؟ إذا لم يكن لديك، قل "تخطي"');
    } else if (_currentStep == 'postal') {
      if (!text.toLowerCase().contains('تخطي') && !text.toLowerCase().contains('لا')) {
        _currentAddressPostal = text.trim();
      }
      await _saveAddress();
    }
  }

  Future<void> _saveAddress() async {
    try {
      await DBService.addAddress(
        userId: _currentUserId,
        title: _currentAddressTitle ?? 'عنوان جديد',
        street: _currentAddressStreet ?? '',
        city: _currentAddressCity ?? '',
        district: _currentAddressDistrict,
        buildingNumber: _currentAddressBuilding,
        apartmentNumber: _currentAddressApartment,
        postalCode: _currentAddressPostal,
      );
      await _voiceService.speak('تم إضافة العنوان بنجاح. جاري فتح صفحة العناوين');
      _resetAddressData();
      if (onAddressAdded != null) {
        onAddressAdded!();
      }
      
      // الانتقال التلقائي لصفحة العناوين
      if (_currentContext != null && _currentContext!.mounted) {
        Navigator.push(
          _currentContext!,
          MaterialPageRoute(
            builder: (context) => AddressesScreen(userId: _currentUserId),
          ),
        );
      }
    } catch (e) {
      await _voiceService.speak('فشل إضافة العنوان. يرجى المحاولة مرة أخرى');
      _resetAddressData();
    }
  }

  void _resetAddressData() {
    _currentStep = '';
    _currentAddressTitle = null;
    _currentAddressStreet = null;
    _currentAddressCity = null;
    _currentAddressDistrict = null;
    _currentAddressBuilding = null;
    _currentAddressApartment = null;
    _currentAddressPostal = null;
  }

  Future<void> _handleAddPaymentMethod(String text) async {
    if (_currentStep.isEmpty) {
      _currentStep = 'type';
      await _voiceService.speak('ما نوع طريقة الدفع؟ مثلاً: بطاقة ائتمان، محفظة رقمية، أو تحويل بنكي');
      return;
    }
    await _handleCollectPaymentData(text);
  }

  Future<void> _handleCollectPaymentData(String text) async {
    if (_currentStep == 'type') {
      final textLower = text.toLowerCase();
      if (textLower.contains('بطاقة') || textLower.contains('كارت') || textLower.contains('ائتمان')) {
        _currentPaymentType = 'بطاقة ائتمان';
        _currentStep = 'card_number';
        await _voiceService.speak('ما هو رقم البطاقة؟');
      } else if (textLower.contains('محفظة') || textLower.contains('سامسونج') || textLower.contains('جوجل') || textLower.contains('أبل')) {
        _currentPaymentType = 'محفظة رقمية';
        if (textLower.contains('سامسونج')) {
          _currentWalletProvider = 'Samsung Pay';
        } else if (textLower.contains('جوجل')) {
          _currentWalletProvider = 'Google Pay';
        } else if (textLower.contains('أبل') || textLower.contains('ابل')) {
          _currentWalletProvider = 'Apple Pay';
        } else {
          _currentWalletProvider = text.trim();
        }
        await _savePaymentMethod();
      } else if (textLower.contains('تحويل') || textLower.contains('بنكي') || textLower.contains('بنك')) {
        _currentPaymentType = 'تحويل بنكي';
        _currentStep = 'bank_name';
        await _voiceService.speak('ما هو اسم البنك؟');
      }
    } else if (_currentStep == 'card_number') {
      _currentCardNumber = text.replaceAll(RegExp(r'[^\d]'), '');
      _currentStep = 'card_holder';
      await _voiceService.speak('ما هو اسم حامل البطاقة؟');
    } else if (_currentStep == 'card_holder') {
      _currentCardHolder = text.trim();
      _currentStep = 'expiry_month';
      await _voiceService.speak('ما هو شهر انتهاء البطاقة؟ مثلاً: 12');
    } else if (_currentStep == 'expiry_month') {
      final monthMatch = RegExp(r'\d+').firstMatch(text);
      if (monthMatch != null) {
        _currentExpiryMonth = int.tryParse(monthMatch.group(0)!);
      }
      _currentStep = 'expiry_year';
      await _voiceService.speak('ما هو سنة انتهاء البطاقة؟ مثلاً: 2025');
    } else if (_currentStep == 'expiry_year') {
      final yearMatch = RegExp(r'\d+').firstMatch(text);
      if (yearMatch != null) {
        _currentExpiryYear = int.tryParse(yearMatch.group(0)!);
      }
      _currentStep = 'cvv';
      await _voiceService.speak('ما هو رقم CVV؟');
    } else if (_currentStep == 'cvv') {
      _currentCvv = text.replaceAll(RegExp(r'[^\d]'), '');
      await _savePaymentMethod();
    } else if (_currentStep == 'bank_name') {
      _currentBankName = text.trim();
      await _savePaymentMethod();
    }
  }

  Future<void> _savePaymentMethod() async {
    try {
      await DBService.addPaymentMethod(
        userId: _currentUserId,
        paymentType: _currentPaymentType ?? 'بطاقة ائتمان',
        cardNumber: _currentCardNumber,
        cardHolder: _currentCardHolder,
        expiryMonth: _currentExpiryMonth,
        expiryYear: _currentExpiryYear,
        cvv: _currentCvv,
        walletProvider: _currentWalletProvider,
        bankName: _currentBankName,
      );
      await _voiceService.speak('تم إضافة طريقة الدفع بنجاح. جاري فتح صفحة طرق الدفع');
      _resetPaymentData();
      if (onPaymentMethodAdded != null) {
        onPaymentMethodAdded!();
      }
      
      // الانتقال التلقائي لصفحة طرق الدفع
      if (_currentContext != null && _currentContext!.mounted) {
        Navigator.push(
          _currentContext!,
          MaterialPageRoute(
            builder: (context) => PaymentMethodsScreen(userId: _currentUserId),
          ),
        );
      }
    } catch (e) {
      await _voiceService.speak('فشل إضافة طريقة الدفع. يرجى المحاولة مرة أخرى');
      _resetPaymentData();
    }
  }

  void _resetPaymentData() {
    _currentStep = '';
    _currentPaymentType = null;
    _currentCardNumber = null;
    _currentCardHolder = null;
    _currentExpiryMonth = null;
    _currentExpiryYear = null;
    _currentCvv = null;
    _currentWalletProvider = null;
    _currentBankName = null;
  }

  Future<void> _handleDeleteOrder(String text) async {
    final orders = await DBService.getAllOrders();
    if (orders.isEmpty) {
      await _voiceService.speak('لا توجد طلبات للحذف');
      return;
    }
    
    final numberPattern = RegExp(r'\d+');
    final match = numberPattern.firstMatch(text);
    
    if (match != null) {
      final orderId = int.parse(match.group(0)!);
      final orderExists = orders.any((o) => o['id'] == orderId);
      
      if (orderExists) {
        await DBService.deleteOrder(orderId);
        await _voiceService.speak('تم حذف الطلب رقم $orderId بنجاح. جاري تحديث قائمة الطلبات');
        
        // الانتقال التلقائي لصفحة الطلبات لتحديث العرض
        if (_currentContext != null && _currentContext!.mounted) {
          Navigator.push(
            _currentContext!,
            MaterialPageRoute(
              builder: (context) => OrdersScreen(userId: _currentUserId),
            ),
          );
        }
      } else {
        await _voiceService.speak('الطلب رقم $orderId غير موجود');
      }
    } else {
      // إذا لم يذكر رقم، احذف آخر طلب
      if (orders.isNotEmpty) {
        final lastOrder = orders[0];
        final orderId = lastOrder['id'];
        await DBService.deleteOrder(orderId);
        await _voiceService.speak('تم حذف آخر طلب بنجاح. جاري تحديث قائمة الطلبات');
        
        // الانتقال التلقائي لصفحة الطلبات
        if (_currentContext != null && _currentContext!.mounted) {
          Navigator.push(
            _currentContext!,
            MaterialPageRoute(
              builder: (context) => OrdersScreen(userId: _currentUserId),
            ),
          );
        }
      } else {
        await _voiceService.speak('لم أتمكن من تحديد رقم الطلب المراد حذفه');
      }
    }
  }

  /// تسجيل الخروج
  Future<void> _handleLogout() async {
    await _voiceService.speak('جاري تسجيل الخروج');
    
    if (_currentContext != null && _currentContext!.mounted) {
      Navigator.pushAndRemoveUntil(
        _currentContext!,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  /// فتح الإعدادات
  Future<void> _handleSettings() async {
    await _voiceService.speak('جاري فتح الإعدادات');
    
    if (_currentContext != null && _currentContext!.mounted) {
      Navigator.push(
        _currentContext!,
        MaterialPageRoute(
          builder: (context) => SettingsScreen(userId: _currentUserId),
        ),
      );
    }
  }

  /// إتمام الطلب (في صفحة الدفع)
  Future<void> _handleCompleteOrder(String text) async {
    await _voiceService.speak('جاري إتمام الطلب');
    
    // هذا سيتم التعامل معه في checkout_screen
    if (onNavigateToCheckout != null) {
      onNavigateToCheckout!();
    }
  }

  Future<void> _handleUnknownCommand(String text) async {
    await _voiceService.speak('لم أفهم الأمر. الأوامر المتاحة: بحث، عرض المنتجات، السلة، إتمام الشراء، اذهب إلى الحساب، أضف عنوان، أضف طريقة دفع، احذف الطلب، تسجيل خروج، الإعدادات');
  }
  
  /// تحديث قائمة المنتجات الحالية
  void updateProducts(List<Map<String, dynamic>> products) {
    _currentProducts = products;
    _currentProductIndex = 0;
  }
  
  /// الحصول على المنتج الحالي
  Map<String, dynamic>? getCurrentProduct() {
    if (_currentProducts.isEmpty || _currentProductIndex < 0) {
      return null;
    }
    return _currentProducts[_currentProductIndex];
  }
  
  bool get isVoiceModeActive => _isVoiceModeActive;
  bool get isContinuousListening => _isContinuousListening;
}

