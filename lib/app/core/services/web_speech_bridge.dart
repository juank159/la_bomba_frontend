// Voz del navegador (solo web). En las demás plataformas no hace nada: ahí
// habla flutter_tts. Ver `labombaSpeak` en web/index.html.
export 'web_speech_bridge_stub.dart' if (dart.library.js_interop) 'web_speech_bridge_web.dart';
