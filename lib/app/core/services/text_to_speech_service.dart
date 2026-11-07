import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'web_speech_bridge.dart';

/// Voz de la app. Misma configuración que Food App (español, velocidad
/// 0.48 en el celular) para que los avisos de pago suenen igual.
///
/// Por plataforma:
/// - Android/iOS: flutter_tts (también desde el isolate de segundo plano,
///   ver [createConfiguredTts]: así habla con el celular bloqueado).
/// - Web: la voz del navegador vía `labombaSpeak` (web/index.html), la
///   misma que usa el service worker con la pestaña en segundo plano.
/// - Windows: flutter_tts con SAPI/WinRT. Ahí `setLanguage` del plugin elige
///   mal la voz y "esperar a que termine" responde desde otro hilo, así que
///   se busca la voz en español a mano y se habla sin esperar.
class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  FlutterTts? _flutterTts;
  Future<FlutterTts>? _initializing;

  /// Lo último anunciado por clave (ej. el id del cobro Bre-B), para no
  /// decir dos veces el mismo pago (push + confirmación del diálogo).
  final Map<String, DateTime> _spokenKeys = {};
  static const _dedupeWindow = Duration(minutes: 2);

  static bool get _isWindows => !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  Future<void> initialize() async {
    _flutterTts ??= await (_initializing ??= createConfiguredTts());
  }

  /// Orden de preferencia de la voz: Colombia, Latinoamérica, España.
  static const _spanishLocales = ['es-co', 'es-419', 'es-us', 'es-mx', 'es-es'];

  /// Crea un motor de voz ya configurado. Se usa también desde el handler de
  /// notificaciones en segundo plano (otro isolate, sin acceso al singleton).
  static Future<FlutterTts> createConfiguredTts() async {
    final tts = FlutterTts();
    // Nunca debe quedarse sin hablar por el idioma: si no hay voz en
    // español, habla con la que tenga el equipo. En Android/iOS se deja
    // como estaba (es-CO, si no es-ES), que ya suena bien.
    if (!(_isWindows && await _pickSpanishVoice(tts))) {
      try {
        final ok = await tts.isLanguageAvailable('es-CO');
        await tts.setLanguage(ok == true ? 'es-CO' : 'es-ES');
      } catch (_) {}
    }
    try {
      await tts.setSpeechRate(kIsWeb ? 1.0 : 0.48);
      await tts.setVolume(1.0);
      await tts.setPitch(1.0);
      if (!_isWindows) await tts.awaitSpeakCompletion(true);
    } catch (_) {}
    return tts;
  }

  /// Windows: busca entre las voces instaladas la mejor en español y la
  /// fija (el `setLanguage` del plugin en Windows se queda con la que sea).
  static Future<bool> _pickSpanishVoice(FlutterTts tts) async {
    try {
      final voices = (await tts.getVoices as List?) ?? const [];
      final candidates = voices
          .whereType<Map>()
          .map((v) => {'name': '${v['name'] ?? ''}', 'locale': '${v['locale'] ?? ''}'})
          .where((v) => v['locale']!.toLowerCase().replaceAll('_', '-').startsWith('es'))
          .toList();
      if (candidates.isEmpty) return false;
      int rank(Map<String, String> v) {
        final i = _spanishLocales.indexOf(v['locale']!.toLowerCase().replaceAll('_', '-'));
        return i < 0 ? _spanishLocales.length : i;
      }

      candidates.sort((a, b) => rank(a).compareTo(rank(b)));
      final voice = candidates.first;
      await tts.setVoice(voice);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Dice [text]. Con [key] (ej. el id del cobro) no repite lo mismo.
  Future<void> speak(String text, {String? key}) async {
    if (text.trim().isEmpty) return;
    if (key != null && key.isNotEmpty) {
      final now = DateTime.now();
      _spokenKeys.removeWhere((_, at) => now.difference(at) > _dedupeWindow);
      if (_spokenKeys.containsKey(key)) return;
      _spokenKeys[key] = now;
    }
    if (kIsWeb && webSpeak(text, key: key)) return;
    try {
      await initialize();
      // Windows: el plugin ignora `speak` si cree que sigue hablando (a veces
      // nunca se entera de que terminó); parar antes lo destraba.
      if (_isWindows) await _flutterTts!.stop();
      await _flutterTts!.speak(text);
    } catch (e) {
      debugPrint('[TTS] no se pudo hablar "$text": $e');
    }
  }

  Future<void> speakProductNotFound() async {
    await speak("Producto no encontrado");
  }

  Future<void> stop() async {
    await _flutterTts?.stop();
  }

  void dispose() {
    _flutterTts?.stop();
  }
}
