import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'audio_feedback_service.dart';

AudioFeedbackService createAudioFeedbackService() => WebAudioFeedbackService();

class WebAudioFeedbackService implements AudioFeedbackService {
  WebAudioFeedbackService() {
    _initWebAudio();
  }

  bool _isWebAudioInitialized = false;

  void _initWebAudio() {
    try {
      final global = globalContext;
      if (global.has('AudioContext') || global.has('webkitAudioContext')) {
        _isWebAudioInitialized = true;
      }
    } catch (_) {
      _isWebAudioInitialized = false;
    }
  }

  void _playTone(double frequency, double durationSeconds,
      {String type = 'sine', double gainLevel = 0.15}) {
    if (!_isWebAudioInitialized) return;

    try {
      final global = globalContext;
      final audioCtxConstructor = global.has('AudioContext')
          ? global.getProperty<JSFunction?>('AudioContext'.toJS)
          : global.getProperty<JSFunction?>('webkitAudioContext'.toJS);

      if (audioCtxConstructor == null) return;

      final audioContext = audioCtxConstructor.callAsConstructor<JSObject>();

      final osc = audioContext.callMethod<JSObject>('createOscillator'.toJS);
      final gain = audioContext.callMethod<JSObject>('createGain'.toJS);
      final destination = audioContext.getProperty<JSObject>('destination'.toJS);
      final currentTime = (audioContext.getProperty<JSNumber>('currentTime'.toJS)).toDartDouble;

      // Set oscillator parameters
      osc.setProperty('type'.toJS, type.toJS);
      final freqParam = osc.getProperty<JSObject>('frequency'.toJS);
      freqParam.callMethod('setValueAtTime'.toJS, frequency.toJS, currentTime.toJS);

      // Set gain envelope
      final gainParam = gain.getProperty<JSObject>('gain'.toJS);
      gainParam.callMethod('setValueAtTime'.toJS, 0.001.toJS, currentTime.toJS);
      gainParam.callMethod('linearRampToValueAtTime'.toJS, gainLevel.toJS, (currentTime + 0.01).toJS);
      gainParam.callMethod('exponentialRampToValueAtTime'.toJS, 0.0001.toJS, (currentTime + durationSeconds).toJS);

      // Connect nodes: osc -> gain -> destination
      osc.callMethod('connect'.toJS, gain);
      gain.callMethod('connect'.toJS, destination);

      // Start and Stop
      osc.callMethod('start'.toJS, currentTime.toJS);
      osc.callMethod('stop'.toJS, (currentTime + durationSeconds).toJS);
    } catch (_) {
      // Audio autoplay policy or context error gracefully handled
    }
  }

  @override
  void playCountdownTick(int secondsRemaining) {
    final freq = secondsRemaining == 1 ? 880.0 : 660.0;
    _playTone(freq, 0.08, type: 'triangle', gainLevel: 0.2);
  }

  @override
  void playRestComplete() {
    _playTone(587.33, 0.18, type: 'sine', gainLevel: 0.25);
    Future.delayed(const Duration(milliseconds: 140), () {
      _playTone(880.0, 0.4, type: 'sine', gainLevel: 0.3);
    });
  }

  @override
  void playPrFanfare() {
    _playTone(523.25, 0.12, type: 'triangle', gainLevel: 0.25);
    Future.delayed(const Duration(milliseconds: 120), () {
      _playTone(659.25, 0.12, type: 'triangle', gainLevel: 0.25);
      Future.delayed(const Duration(milliseconds: 120), () {
        _playTone(783.99, 0.15, type: 'triangle', gainLevel: 0.25);
        Future.delayed(const Duration(milliseconds: 150), () {
          _playTone(1046.50, 0.5, type: 'triangle', gainLevel: 0.35);
        });
      });
    });
  }

  @override
  void playButtonClick() {
    _playTone(1200.0, 0.03, type: 'sine', gainLevel: 0.08);
  }
}
