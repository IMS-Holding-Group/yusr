import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();
  
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _sttInitialized = false;
  String _ttsEngine = 'flutter_tts';
  double _pitch = 1.0;
  double _speechRate = 0.72;
  bool _callbackCalled = false;
  
  Function(String)? onSpeechResult;
  
  Future<void> initialize({String? ttsEngine}) async {
    _ttsEngine = ttsEngine ?? 'flutter_tts';
    await _tts.setLanguage("ar-SA");
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(_pitch);
    
    // Initialize STT once
    if (!_sttInitialized) {
      bool available = await _stt.initialize(
        onStatus: (status) {
          print('STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            if (_isListening && onSpeechResult != null) {
              print('STT stopped listening - status: $status');
              // لا نتوقف فوراً، نترك onResult أو timeout handler يتعامل معه
              // فقط إذا كان هناك callback لم يُستدعى بعد، نتحقق من النص الجزئي
            }
          }
        },
        onError: (error) {
          print('STT Error: ${error.errorMsg}, permanent: ${error.permanent}');
          // لا نتوقف فوراً عند timeout - نترك timeout handler يتعامل معه
          // فقط نتوقف عند أخطاء دائمة أخرى
          if (error.errorMsg != 'error_speech_timeout' && error.errorMsg != 'error_no_match') {
            if (error.permanent && _isListening) {
              print('STT permanent error (not timeout) - stopping');
              _isListening = false;
              if (!_callbackCalled && onSpeechResult != null) {
                _callbackCalled = true;
                Future.delayed(const Duration(milliseconds: 200), () {
                  onSpeechResult!('__TIMEOUT__');
                });
              }
            }
          } else {
            print('STT timeout/no match error - ignoring, will be handled by timeout handler');
          }
        },
      );
      _sttInitialized = available;
      print('STT initialized: $_sttInitialized');
    }
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _tts.setPitch(_pitch);
  }

  String get ttsEngine => _ttsEngine;
  double get pitch => _pitch;
  
  /// تصحيح نطق الكلمات العربية
  String _fixArabicPronunciation(String text) {
    text = text.replaceAll('السلة', 'السَّلَّة');
    text = text.replaceAll('سلة', 'سَّلَّة');
    
    text = text.replaceAll('جدة', 'جِدَّة');
    
    return text;
  }

  /// [rate] optional override (0.0–1.0). Use ~0.85 for short prompts.
  Future<void> speak(String text, {double? rate}) async {
    if (_isSpeaking) {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 150));
    }
    if (rate != null) {
      await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
    }
    _isSpeaking = true;
    final correctedText = _fixArabicPronunciation(text);
    final completer = Completer<void>();
    bool isCompleted = false;
    
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      if (!isCompleted) {
        isCompleted = true;
        completer.complete();
      }
    });
    
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      if (!isCompleted) {
        isCompleted = true;
        completer.complete();
      }
    });
    
    await _tts.speak(correctedText);
    
    try {
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _isSpeaking = false;
          if (!isCompleted) {
            isCompleted = true;
            completer.complete();
          }
        },
      );
    } catch (e) {
      _isSpeaking = false;
    } finally {
      if (rate != null) {
        await _tts.setSpeechRate(_speechRate);
      }
    }
  }
  
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }
  }
  
  /// [shortAnswer] faster timeouts for one-word replies (e.g. بالصوت / باليد).
  Future<bool> startListening({
    bool continuous = false,
    bool shortAnswer = false,
  }) async {
    final pauseFor = shortAnswer
        ? const Duration(seconds: 2)
        : const Duration(seconds: 5);
    final listenFor = shortAnswer
        ? const Duration(seconds: 12)
        : const Duration(seconds: 30);
    final idleTimeoutSeconds = shortAnswer ? 4 : 7;
    final minPartialLength = shortAnswer ? 2 : 3;
    print('=== startListening called ===');
    
    if (!_sttInitialized) {
      print('STT not initialized, initializing now...');
      await initialize();
      if (!_sttInitialized) {
        print('STT initialization failed');
        return false;
      }
    }
    
    // إيقاف أي استماع سابق
    if (_isListening) {
      print('Already listening, stopping first...');
      await _stt.stop();
      _isListening = false;
      _callbackCalled = false;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    // إيقاف أي كلام جاري
    if (_isSpeaking) {
      print('TTS is speaking, stopping first...');
      await _tts.stop();
      _isSpeaking = false;
      await Future.delayed(const Duration(milliseconds: 120));
    }
    
    String? lastPartialText;
    final DateTime listeningStartTime = DateTime.now();
    _callbackCalled = false;
    
    _isListening = true;
    print('Starting STT listening...');
    
    try {

      await _stt.listen(
        onResult: (result) {
          print('=== STT Result ===');
          print('Recognized: ${result.recognizedWords}');
          print('Final: ${result.finalResult}');
          print('Has confidence: ${result.hasConfidenceRating}');
          if (result.hasConfidenceRating) {
            print('Confidence: ${result.confidence}');
          }
          
          if (result.recognizedWords.isNotEmpty) {
            lastPartialText = result.recognizedWords;
            print('Updated lastPartialText: $lastPartialText');
          }
          
          // معالجة النتيجة النهائية
          if (result.finalResult && result.recognizedWords.isNotEmpty && !_callbackCalled) {
            print('Final result received: ${result.recognizedWords}');
            _isListening = false;
            _callbackCalled = true;
            if (onSpeechResult != null) {
              onSpeechResult!(result.recognizedWords);
            }
          } 
          // معالجة النتائج الجزئية
          else if (!result.finalResult && result.recognizedWords.isNotEmpty) {
            print('Partial result: ${result.recognizedWords}');
            
            // استخدام النص الجزئي بعد فترة قصيرة إذا لم تكن هناك نتيجة نهائية
            if (onSpeechResult != null &&
                result.recognizedWords.length >= minPartialLength &&
                !_callbackCalled) {
              final waitMs = shortAnswer ? 400 : 1000;
              Future.delayed(Duration(milliseconds: waitMs), () {
                if (_isListening && lastPartialText == result.recognizedWords && !_callbackCalled) {
                  print('Using partial result after 1 second: ${result.recognizedWords}');
                  _isListening = false;
                  _callbackCalled = true;
                  onSpeechResult!(result.recognizedWords);
                }
              });
            }
          }
        },
        localeId: "ar-SA",
        listenMode: stt.ListenMode.dictation,
        listenFor: listenFor,
        pauseFor: pauseFor,
        cancelOnError: false,
        partialResults: true,
        onSoundLevelChange: (level) {
          if (level > 0) {
            print('Sound detected! Level: $level');
          }
        },
        listenOptions: stt.SpeechListenOptions(
          autoPunctuation: false,
          enableHapticFeedback: true,
        ),
      );
      
      print('STT listening started successfully');
      
      // معالجة timeout بعد فترة (وقت كافٍ للتعرف على الكلام)
      Future.delayed(Duration(seconds: idleTimeoutSeconds), () {
        if (_isListening && !_callbackCalled) {
          final timeSinceStart = DateTime.now().difference(listeningStartTime).inSeconds;
          if (lastPartialText == null || lastPartialText!.isEmpty) {
            print('No speech detected after $timeSinceStart seconds - using timeout');
            _isListening = false;
            _callbackCalled = true;

            if (onSpeechResult != null) {
              Future.delayed(const Duration(milliseconds: 200), () {
                onSpeechResult!('__TIMEOUT__');
              });
            }
          } else {
            // إذا كان هناك نص جزئي، استخدمه فوراً
            print('Using last partial text after timeout: $lastPartialText');
            _isListening = false;
            _callbackCalled = true;
            if (onSpeechResult != null) {
              Future.delayed(const Duration(milliseconds: 200), () {
                onSpeechResult!(lastPartialText!);
              });
            }
          }
        }
      });
      
      return true;
    } catch (e, stackTrace) {
      print('Error starting STT listen: $e');
      print('Stack trace: $stackTrace');
      _isListening = false;
      return false;
    }
  }
  
  Future<void> stopListening() async {
    if (_isListening) {
      await _stt.stop();
      _isListening = false;
      _callbackCalled = false;
    }
  }
  
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _tts.setSpeechRate(_speechRate);
  }
  
  Future<void> setVolume(double volume) async {
    await _tts.setVolume(volume.clamp(0.0, 1.0));
  }
}

