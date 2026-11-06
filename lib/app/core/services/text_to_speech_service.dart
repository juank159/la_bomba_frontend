import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Voz de la app. Misma configuración que Food App (español de Colombia,
/// velocidad 0.48 en el celular) para que los avisos de pago suenen igual.
///
/// En web, `flutter_tts` usa la voz del navegador (speechSynthesis), donde
/// 1.0 es la velocidad normal (0.48 sonaría en cámara lenta).
class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _flutterTts = await createConfiguredTts();
    _isInitialized = true;
  }

  /// Crea un motor de voz ya configurado. Se usa también desde el handler de
  /// notificaciones en segundo plano (otro isolate, sin acceso al singleton).
  static Future<FlutterTts> createConfiguredTts() async {
    final tts = FlutterTts();
    try {
      // es-CO no existe en todos los celulares/navegadores: si falla, español
      // genérico. Nunca debe quedarse sin hablar por el idioma.
      final ok = await tts.isLanguageAvailable('es-CO');
      await tts.setLanguage(ok == true ? 'es-CO' : 'es-ES');
    } catch (_) {
      try {
        await tts.setLanguage('es-ES');
      } catch (_) {}
    }
    try {
      await tts.setSpeechRate(kIsWeb ? 1.0 : 0.48);
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);
      await tts.awaitSpeakCompletion(true);
    } catch (_) {}
    return tts;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      if (!_isInitialized) await initialize();
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('[TTS] no se pudo hablar "$text": $e');
    }
  }

  Future<void> speakProductNotFound() async {
    await speak("Producto no encontrado");
  }

  Future<void> stop() async {
    if (_isInitialized) {
      await _flutterTts?.stop();
    }
  }

  void dispose() {
    if (_isInitialized) {
      _flutterTts?.stop();
    }
  }
}
