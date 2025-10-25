import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  late FlutterTts _flutterTts;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();
    
    // Configure TTS settings
    await _flutterTts.setLanguage("es-ES"); // Spanish
    await _flutterTts.setSpeechRate(0.5); // Normal speed
    await _flutterTts.setVolume(1.0); // Full volume
    await _flutterTts.setPitch(1.0); // Normal pitch

    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    await _flutterTts.speak(text);
  }

  Future<void> speakProductNotFound() async {
    await speak("Producto no encontrado");
  }

  Future<void> stop() async {
    if (_isInitialized) {
      await _flutterTts.stop();
    }
  }

  void dispose() {
    if (_isInitialized) {
      _flutterTts.stop();
    }
  }
}