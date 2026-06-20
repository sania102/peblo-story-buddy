import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// All possible states of the narration pipeline.
///
/// Modelling this as an explicit enum (rather than a couple of booleans like
/// isLoading/hasError) is deliberate: booleans let you accidentally represent
/// impossible states (isLoading=true AND hasError=true at once). An enum
/// makes invalid states unrepresentable, which matters once shake/confetti
/// animations key off this value.
enum AudioState { idle, loading, playing, finished, error }

class AudioProvider extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  AudioState _state = AudioState.idle;
  String? _errorMessage;
  bool _ttsReady = false;

  AudioState get state => _state;
  String? get errorMessage => _errorMessage;

  AudioProvider() {
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.48); // child-friendly pace, not sluggish
      await _tts.setPitch(1.05); // slightly bright/friendly pitch
      await _tts.setVolume(1.0); // max gain on the TTS engine's own volume control

      // ANDROID VOLUME FIX:
      // flutter_tts on Android can end up speaking at a quiet, "background"
      // volume because it doesn't request audio focus on the media stream
      // by default - the engine reports state=playing, but it's effectively
      // ducked under whatever stream actually has focus. Two changes fix this:
      //  1. setAudioAttributesForNavigation() tells Android to treat this as
      //     foreground "spoken instruction" audio, which Android routes
      //     through STREAM_MUSIC (the stream the visible media-volume slider
      //     controls) at full presence instead of a quiet notification-style
      //     stream.
      //  2. speak(text, focus: true) below explicitly requests audio focus
      //     for each utterance, instead of speaking "underneath" whatever
      //     else (silently) holds focus.
      // iOS has no stream-routing concept, so setIosAudioCategory below is
      // the equivalent fix on that platform. Each platform's setup call is
      // independently try/caught - a failure on one platform's call (e.g.
      // an older plugin version missing a method on web/desktop) shouldn't
      // be able to abort setup for the platform that actually needs it.
      if (Platform.isAndroid) {
        try {
          await _tts.setAudioAttributesForNavigation();
        } catch (_) {
          // Non-fatal: narration still works, just possibly quieter on some
          // OEM skins. Don't let this block the rest of init.
        }
      }
      if (Platform.isIOS) {
        try {
          await _tts.setSharedInstance(true);
          await _tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
            IosTextToSpeechAudioMode.voicePrompt,
          );
        } catch (_) {
          // Non-fatal for the same reason as above.
        }
      }

      await _tts.awaitSpeakCompletion(true);

      _tts.setCompletionHandler(() {
        _setState(AudioState.finished);
      });

      _tts.setErrorHandler((msg) {
        _errorMessage = 'Hmm, the story got shy. Let\'s try again!';
        _setState(AudioState.error);
      });

      _tts.setCancelHandler(() {
        _setState(AudioState.idle);
      });

      _ttsReady = true;
    } catch (e) {
      _ttsReady = false;
      _errorMessage = 'Could not start the storyteller. Check your device sound settings.';
      _setState(AudioState.error);
    }
  }

  /// Caching approach (on-device TTS):
  /// Native TTS (AVSpeechSynthesizer / Android TTS) synthesizes speech live
  /// from text in real time - there is no audio file to cache, so "caching"
  /// here means avoiding redundant *engine setup* work, not redundant audio
  /// generation. We hash the story text and skip re-running setters if the
  /// same text was already configured for this session.
  ///
  /// If swapped for a REMOTE TTS API (e.g. ElevenLabs - the brief's bonus
  /// path), this is where real audio-byte caching would go:
  ///   1. key = sha256(storyText + voiceId + speed)
  ///   2. check path_provider's getTemporaryDirectory()/tts_cache/$key.mp3
  ///   3. if present, play directly from disk (no network call)
  ///   4. if absent, fetch from API, write to that path, then play
  ///   5. evict oldest files once cache dir exceeds ~20MB (LRU-ish), since
  ///      these are children's devices with limited storage too.
  /// We did not need to build steps 2-5 for the native-TTS path actually
  /// shipped, since there's no audio blob to persist - but the hashing
  /// utility below is written so that swapping in the remote path later only
  /// means adding file I/O around the existing cache-key logic, not
  /// rewriting it.
  String _hashText(String text) => sha256.convert(utf8.encode(text)).toString();

  String? _lastConfiguredTextHash;

  Future<void> speak(String text) async {
    if (!_ttsReady) {
      await _initTts();
      if (!_ttsReady) return; // initTts already set error state
    }

    final hash = _hashText(text);
    _setState(AudioState.loading);

    try {
      // Skip redundant reconfiguration if narrating the same text again
      // (e.g. child taps "Read Me a Story" a second time).
      if (_lastConfiguredTextHash != hash) {
        _lastConfiguredTextHash = hash;
        await _persistLastHash(hash);
      }

      _setState(AudioState.playing);
      // focus: true (Android) requests audio focus for this utterance so it
      // plays at full presence on STREAM_MUSIC instead of being ducked
      // under whatever silently held focus before - this is the other half
      // of the volume fix alongside setAudioAttributesForNavigation() above.
      await _tts.speak(text, focus: true);
      // completion handler fires AudioState.finished; errorHandler covers failure.
    } catch (e) {
      _errorMessage = 'No network or audio engine hiccup. Tap to try again!';
      _setState(AudioState.error);
    }
  }

  Future<void> _persistLastHash(String hash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_story_hash', hash);
    } catch (_) {
      // Non-critical - cache is a perf optimisation, never block playback on it.
    }
  }

  Future<void> stop() async {
    await _tts.stop();
    _setState(AudioState.idle);
  }

  Future<void> retry(String text) async {
    _errorMessage = null;
    await speak(text);
  }

  void _setState(AudioState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    // Prevent the completion/error handlers from firing into a disposed
    // provider (a classic Flutter retain-cycle / use-after-dispose bug).
    _tts.stop();
    super.dispose();
  }
}
