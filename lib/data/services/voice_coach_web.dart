import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import '../../domain/services/voice_coach_service.dart';

VoiceCoachService createVoiceCoachService() => WebVoiceCoachService();

class WebVoiceCoachService implements VoiceCoachService {
  WebVoiceCoachService();

  bool _isSpeaking = false;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> speak(String text, {double rate = 1.0, double pitch = 1.0}) async {
    if (text.trim().isEmpty) return;

    try {
      final global = globalContext;
      if (!global.has('speechSynthesis') || !global.has('SpeechSynthesisUtterance')) {
        return;
      }

      final synth = global.getProperty<JSObject>('speechSynthesis'.toJS);
      final utteranceConstructor = global.getProperty<JSFunction>('SpeechSynthesisUtterance'.toJS);

      // Cancel ongoing speech
      synth.callMethod('cancel'.toJS);

      final utterance = utteranceConstructor.callAsConstructor<JSObject>(text.toJS);

      utterance.setProperty('rate'.toJS, rate.toJS);
      utterance.setProperty('pitch'.toJS, pitch.toJS);
      utterance.setProperty('lang'.toJS, 'en-US'.toJS);

      _isSpeaking = true;

      final onEndFn = () {
        _isSpeaking = false;
      }.toJS;

      utterance.setProperty('onend'.toJS, onEndFn);
      utterance.setProperty('onerror'.toJS, onEndFn);

      synth.callMethod('speak'.toJS, utterance);
    } catch (e) {
      debugPrint('[VoiceCoach] Error synthesizing speech: $e');
      _isSpeaking = false;
    }
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    try {
      final global = globalContext;
      if (global.has('speechSynthesis')) {
        final synth = global.getProperty<JSObject>('speechSynthesis'.toJS);
        synth.callMethod('cancel'.toJS);
      }
    } catch (_) {}
  }
}
