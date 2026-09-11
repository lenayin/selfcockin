import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum SpeechState { idle, speaking }

class SpeechService {
  SpeechService() {
    _tts.setStartHandler(() => _setState(SpeechState.speaking));
    _tts.setCompletionHandler(() => _setState(SpeechState.idle));
    _tts.setCancelHandler(() => _setState(SpeechState.idle));
    _tts.setErrorHandler((_) => _setState(SpeechState.idle));
  }

  final FlutterTts _tts = FlutterTts();
  final _stateController = StreamController<SpeechState>.broadcast();
  SpeechState _state = SpeechState.idle;
  bool _configured = false;

  SpeechState get state => _state;
  Stream<SpeechState> get states => _stateController.stream;

  Future<void> configure() async {
    if (_configured) {
      return;
    }
    _configured = true;
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _tts.setQueueMode(0);
    }
  }

  Future<void> speak(String text) async {
    final value = text.trim();
    if (value.isEmpty) {
      return;
    }
    await configure();
    await _tts.stop();
    _setState(SpeechState.speaking);
    try {
      await _tts.speak(value);
    } catch (_) {
      _setState(SpeechState.idle);
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _setState(SpeechState.idle);
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _stateController.close();
  }

  void _setState(SpeechState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}
