import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../services/voice_service.dart';
import '../../services/api_client.dart';
import '../../services/session_manager.dart';
import '../../theme/app_theme.dart';
import 'products_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _LoginInputMode { unset, voice, manual }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierFocus = FocusNode();
  final VoiceService _voiceService = VoiceService();
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _voiceBusy = false;
  _LoginInputMode _inputMode = _LoginInputMode.unset;
  bool _welcomeInProgress = false;

  @override
  void initState() {
    super.initState();
    _initializeVoice().then((_) {
      if (mounted) _startWelcomeFlow();
    });
  }

  Future<void> _initializeVoice() async {
    await _voiceService.initialize();
  }

  /// ترحيب صوتي عند الدخول وسؤال المستخدم عن طريقة تسجيل الدخول
  Future<void> _startWelcomeFlow() async {
    if (_welcomeInProgress || _voiceBusy) return;
    _welcomeInProgress = true;
    if (mounted) setState(() => _voiceBusy = true);

    await _voiceService.speak(
      'أهلاً بك في يُسر. هل تفضّل تسجيل الدخول بالصوت أم باليد؟ قل: بالصوت، أو: باليد.',
    );
    await Future.delayed(const Duration(milliseconds: 800));

    var attempts = 0;
    while (attempts < 2 && mounted) {
      final choice = await _listenForLoginModeChoice();
      if (choice == _LoginInputMode.voice) {
        _welcomeInProgress = false;
        if (mounted) setState(() => _voiceBusy = false);
        await _activateVoiceLoginMode();
        return;
      }
      if (choice == _LoginInputMode.manual) {
        _welcomeInProgress = false;
        if (mounted) setState(() => _voiceBusy = false);
        await _activateManualLoginMode();
        return;
      }
      attempts++;
      if (attempts < 2 && mounted) {
        await _voiceService.speak(
          'لم أفهم إجابتك. قل بالصوت لتسجيل الدخول صوتياً، أو باليد للإدخال اليدوي.',
        );
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    _welcomeInProgress = false;
    if (mounted) setState(() => _voiceBusy = false);
    if (mounted && _inputMode == _LoginInputMode.unset) {
      await _activateManualLoginMode();
    }
  }

  Future<_LoginInputMode?> _listenForLoginModeChoice() async {
    final completer = Completer<_LoginInputMode?>();
    var settled = false;

    void finish(_LoginInputMode? mode) {
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
      finish(_parseLoginModeChoice(text));
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

  _LoginInputMode? _parseLoginModeChoice(String text) {
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
      return _LoginInputMode.voice;
    }
    if (normalized.contains('يد') ||
        normalized.contains('يدوي') ||
        normalized.contains('يدويا') ||
        normalized.contains('كتابه') ||
        normalized.contains('كتابة') ||
        normalized.contains('يدين')) {
      return _LoginInputMode.manual;
    }
    return null;
  }

  Future<void> _activateVoiceLoginMode() async {
    if (!mounted) return;
    setState(() => _inputMode = _LoginInputMode.voice);
    await _voiceService.speak(
      'تم اختيار تسجيل الدخول بالصوت. سنبدأ بإملاء البريد أو رقم الهاتف.',
    );
    await _dictateIdentifier();
    if (!mounted) return;
    await _dictatePassword();
    if (!mounted) return;
    await _voiceService.speak(
      'عند الانتهاء اضغط زر تسجيل الدخول أسفل الشاشة.',
    );
  }

  Future<void> _activateManualLoginMode() async {
    if (!mounted) return;
    setState(() => _inputMode = _LoginInputMode.manual);
    await _voiceService.speak(
      'تم اختيار الإدخال باليد. يمكنك كتابة البريد وكلمة المرور في الحقول.',
    );
    if (mounted) _identifierFocus.requestFocus();
  }

  /// إملاء الحقول بالصوت يقلّل الحاجة للمس بيدين في آن واحد (مناسب لذوي الإعاقة الحركية)
  Future<void> _dictateIdentifier() async {
    if (_voiceBusy && !_welcomeInProgress) return;
    if (mounted) setState(() => _voiceBusy = true);
    await _voiceService.initialize();
    await _voiceService.speak('قل البريد الإلكتروني أو رقم الجوال');
    await Future.delayed(const Duration(milliseconds: 2800));
    final prev = _voiceService.onSpeechResult;
    final completer = Completer<void>();
    var settled = false;
    void finish() {
      if (settled) return;
      settled = true;
      _voiceService.onSpeechResult = prev;
      if (mounted) setState(() => _voiceBusy = false);
      if (!completer.isCompleted) completer.complete();
    }

    _voiceService.onSpeechResult = (text) async {
      await _voiceService.stopListening();
      finish();
      if (text.isNotEmpty &&
          text != '__TIMEOUT__' &&
          mounted) {
        setState(() => _identifierController.text = text.trim());
      }
    };
    final ok = await _voiceService.startListening();
    if (!ok) {
      finish();
      await _voiceService.speak('تعذّر تشغيل الميكروفون');
      return completer.future;
    }
    Future.delayed(const Duration(seconds: 32), () {
      if (!settled) {
        _voiceService.stopListening();
        finish();
      }
    });
    return completer.future;
  }

  Future<void> _dictatePassword() async {
    if (_voiceBusy && !_welcomeInProgress) return;
    if (mounted) setState(() => _voiceBusy = true);
    await _voiceService.initialize();
    await _voiceService.speak(
      'قل كلمة المرور. يُفضّل استخدام سماعة لمنع الاستماع من حولك',
    );
    await Future.delayed(const Duration(milliseconds: 3200));
    final prev = _voiceService.onSpeechResult;
    final completer = Completer<void>();
    var settled = false;
    void finish() {
      if (settled) return;
      settled = true;
      _voiceService.onSpeechResult = prev;
      if (mounted) setState(() => _voiceBusy = false);
      if (!completer.isCompleted) completer.complete();
    }

    _voiceService.onSpeechResult = (text) async {
      await _voiceService.stopListening();
      finish();
      if (text.isNotEmpty &&
          text != '__TIMEOUT__' &&
          mounted) {
        setState(() => _passwordController.text = text.trim());
      }
    };
    final ok = await _voiceService.startListening();
    if (!ok) {
      finish();
      await _voiceService.speak('تعذّر تشغيل الميكروفون');
      return completer.future;
    }
    Future.delayed(const Duration(seconds: 32), () {
      if (!settled) {
        _voiceService.stopListening();
        finish();
      }
    });
    return completer.future;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _apiClient.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final userId = result['user_id'] ?? 1;
      final email = result['email'] as String?;
      final phone = result['phone'] as String?;
      final name = result['name'] as String?;

      // حفظ الجلسة
      await SessionManager.saveSession(
        userId: userId,
        email: email,
        phone: phone,
        name: name,
      );

      if (mounted) {
        _voiceService.speak(result['speak_text'] ?? 'تم تسجيل الدخول بنجاح');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductsScreen(userId: userId),
          ),
        );
      }
    } else {
      _voiceService.speak(result['speak_text'] ?? 'فشل تسجيل الدخول');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'خطأ في تسجيل الدخول',
            ),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _voiceService.stopSpeaking();
    _identifierFocus.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Two Overlapping Squares
                Center(
                  child: SizedBox(
                    width: 180,
                    height: 120,
                    child: Stack(
                      children: [
                        // Lighter Blue Square (Left/Behind) - larger and rotated
                        Positioned(
                          left: 0,
                          top: 10,
                          child: Transform.rotate(
                            angle: -8 * math.pi / 180,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppTheme.lighterBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        // Blue Square (Right/Front) - larger and rotated
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Transform.rotate(
                            angle: 8 * math.pi / 180,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Welcome Text
                const Center(
                  child: Text(
                    'أهلا بك',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: _identifierController,
                    focusNode: _identifierFocus,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني أو رقم الهاتف',
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      alignLabelWithHint: false,
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: AppTheme.iconGray,
                      ),
                      hintText: 'أدخل بريدك أو رقم هاتفك',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: _passwordController,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      alignLabelWithHint: false,
                      prefixIcon: const Icon(
                        Icons.lock_outlined,
                        color: AppTheme.iconGray,
                      ),
                      suffixIcon: IconButton(
                        tooltip: 'إظهار أو إخفاء كلمة المرور',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.iconGray,
                        ),
                        onPressed: () {
                          setState(
                              () => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      hintText: 'أدخل كلمة المرور',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'هذا الحقل مطلوب';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Remember Me and Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Forgot Password Link
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to forgot password screen
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'نسيت كلمة المرور ؟',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    // Remember Me Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() => _rememberMe = value ?? false);
                          },
                          activeColor: AppTheme.secondaryBlue,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const Text(
                          'تذكرني',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'تسجيل دخول بيد واحدة: استخدم الإملاء الصوتي للحقول، ثم زر الدخول أسفل الشاشة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withOpacity(0.95),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'إملاء البريد أو الهاتف بالصوت',
                        child: OutlinedButton.icon(
                          onPressed: _voiceBusy ? null : _dictateIdentifier,
                          icon: const Icon(Icons.mic, size: 22),
                          label: const Text(
                            'البريد أو الهاتف صوتاً',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'إملاء كلمة المرور بالصوت',
                        child: OutlinedButton.icon(
                          onPressed: _voiceBusy ? null : _dictatePassword,
                          icon: const Icon(Icons.mic_none, size: 22),
                          label: const Text(
                            'كلمة المرور صوتاً',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Semantics(
                  button: true,
                  label: 'تسجيل الدخول',
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _voiceBusy) ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryBlue,
                        foregroundColor: AppTheme.white,
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.white),
                              ),
                            )
                          : const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'سجل الان',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.yellow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'مستخدم جديد؟',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
