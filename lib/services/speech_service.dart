import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum SpeechState { idle, speaking }

class SpeechService {
  SpeechService() {
    _tts.setStartHandler(() => _setState(SpeechState.speaking));
    _tts.setCompletionHandler(() => _setState(SpeechState.idle));
    _tts.setCancelHandler(() => _setState(SpeechState.idle));
    _tts.setErrorHandler((_) {
      _setState(SpeechState.idle);
    });
    _audioCompleteSubscription = _audioPlayer.onPlayerComplete.listen(
      (_) => _setState(SpeechState.idle),
    );
  }

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _stateController = StreamController<SpeechState>.broadcast();
  final _messageController = StreamController<String>.broadcast();
  late final StreamSubscription<void> _audioCompleteSubscription;
  SpeechState _state = SpeechState.idle;
  bool _configured = false;
  Future<String?>? _configurationFuture;

  static const _engineErrorMessage = '系统语音播放失败，网络发音也暂时不可用。';
  static const _missingEngineMessage = '设备没有可用的文字转语音引擎，请先在系统设置中启用或安装语音服务。';
  static const _missingEnglishVoiceMessage = '当前设备没有可用的英文语音包，请在系统设置中安装英语语音后重试。';
  static const _networkAudioErrorMessage = '网络发音暂时不可用，请检查网络连接后重试。';

  SpeechState get state => _state;
  Stream<SpeechState> get states => _stateController.stream;
  Stream<String> get messages => _messageController.stream;

  Future<String?> configure() async {
    if (_configured) {
      return null;
    }
    final activeConfiguration = _configurationFuture;
    if (activeConfiguration != null) {
      return activeConfiguration;
    }
    final configuration = _configure();
    _configurationFuture = configuration;
    final result = await configuration;
    _configurationFuture = null;
    return result;
  }

  Future<String?> _configure() async {
    try {
      // Do not wait for the whole utterance. Some Android-compatible TTS
      // engines never complete the callback after an initialization error.
      await _tts.awaitSpeakCompletion(false);

      if (defaultTargetPlatform == TargetPlatform.android) {
        final engines = _stringList(await _tts.getEngines);
        if (engines.isEmpty) {
          return _missingEngineMessage;
        }

        final languageReady = await _tryAndroidEngines(engines);
        if (!languageReady) {
          return _missingEnglishVoiceMessage;
        }
        await _tts.setQueueMode(0);
        try {
          await _tts.setAudioAttributesForNavigation();
        } catch (_) {
          // Audio attributes are optional on Android-compatible devices.
        }
      } else {
        final result = await _tts.setLanguage('en-US');
        if (!_isSuccess(result)) {
          return _missingEnglishVoiceMessage;
        }
      }

      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _configured = true;
      return null;
    } catch (_) {
      return _engineErrorMessage;
    }
  }

  Future<bool> _tryAndroidEngines(List<String> engines) async {
    final defaultEngine = await _safeDefaultEngine();
    final orderedEngines = <String>[
      if (defaultEngine != null && engines.contains(defaultEngine))
        defaultEngine,
      ...engines.where((engine) => engine != defaultEngine),
    ];

    for (final engine in orderedEngines) {
      try {
        await _tts.setEngine(engine);
        if (await _hasEnglishVoice()) {
          return true;
        }
      } catch (_) {
        // Continue with the next installed engine.
      }
    }
    return false;
  }

  Future<bool> _hasEnglishVoice() async {
    const languages = <String>['en-US', 'en-GB', 'en-AU', 'en'];
    for (final language in languages) {
      final available = await _tts.isLanguageAvailable(language);
      if (available == true) {
        final result = await _tts.setLanguage(language);
        if (_isSuccess(result)) {
          return true;
        }
      }
    }

    // A few Android-compatible engines expose voices but do not report
    // language availability consistently.
    final voices = await _tts.getVoices;
    if (voices is List) {
      for (final voice in voices) {
        if (voice is! Map) {
          continue;
        }
        final locale = voice['locale']?.toString().toLowerCase() ?? '';
        if (!locale.startsWith('en')) {
          continue;
        }
        final name = voice['name']?.toString();
        if (name == null || name.isEmpty) {
          continue;
        }
        final result = await _tts.setVoice({
          'name': name,
          'locale': voice['locale'].toString(),
        });
        if (_isSuccess(result)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<String?> _safeDefaultEngine() async {
    try {
      final value = await _tts.getDefaultEngine;
      final engine = value?.toString().trim();
      return engine == null || engine.isEmpty ? null : engine;
    } catch (_) {
      return null;
    }
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  bool _isSuccess(dynamic value) =>
      value == true || value == 1 || value == null;

  Future<String?> speak(String text) async {
    final value = text.trim();
    if (value.isEmpty) {
      return null;
    }
    final configurationError = await configure();
    if (configurationError != null) {
      return _playNetworkAudio(value);
    }
    await _tts.stop();
    await _audioPlayer.stop();
    _setState(SpeechState.speaking);
    try {
      final result = await _tts.speak(value, focus: true);
      if (!_isSuccess(result)) {
        _setState(SpeechState.idle);
        return _playNetworkAudio(value);
      }
      return null;
    } catch (_) {
      _setState(SpeechState.idle);
      return _playNetworkAudio(value);
    }
  }

  Future<String?> _playNetworkAudio(String text) async {
    try {
      await _tts.stop();
      await _audioPlayer.stop();
      _setState(SpeechState.speaking);
      final url = Uri.https('dict.youdao.com', '/dictvoice', <String, String>{
        'audio': text,
        'type': '2',
      }).toString();
      await _audioPlayer.play(
        UrlSource(url, mimeType: 'audio/mpeg'),
        volume: 1.0,
      );
      return null;
    } catch (_) {
      _setState(SpeechState.idle);
      _messageController.add(_networkAudioErrorMessage);
      return _engineErrorMessage;
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    await _audioPlayer.stop();
    _setState(SpeechState.idle);
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _audioCompleteSubscription.cancel();
    await _audioPlayer.dispose();
    await _stateController.close();
    await _messageController.close();
  }

  void _setState(SpeechState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}
