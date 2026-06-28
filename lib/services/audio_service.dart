import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    _initListeners();
  }

  final AudioPlayer _player = AudioPlayer();

  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  final StreamController<void> _completionController =
      StreamController<void>.broadcast();
  final StreamController<int> _ayahController =
      StreamController<int>.broadcast();

  int _baseAyah = 0;

  void _initListeners() {
    _player.playingStream.listen((playing) {
      _playingController.add(playing);
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && _baseAyah > 0) {
        _ayahController.add(_baseAyah + index);
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _completionController.add(null);
      }
    });
  }

  Stream<bool> get playingStream => _playingController.stream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<void> get onPlaybackComplete => _completionController.stream;
  Stream<int> get currentAyahStream => _ayahController.stream;

  bool get isPlaying => _player.playing;

  Future<void> playAyah(
    int surahNumber,
    int ayahNumber, {
    String reciterKey = 'Mishari_Rashid_Alafasy_128kbps',
    int totalAyahs = 999,
    int batchSize = 4,
  }) async {
    try {
      await _player.stop();

      _baseAyah = ayahNumber;

      final count = (totalAyahs - ayahNumber + 1).clamp(1, batchSize);
      final sources = List.generate(
        count,
        (i) => _source(surahNumber, ayahNumber + i, reciterKey),
      );

      await _player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: 0,
      );
      await _player.play();
    } catch (e) {
      debugPrint('AudioService.playAyah error: $e');
    }
  }

  AudioSource _source(int surah, int ayah, String key) {
    final s = surah.toString().padLeft(3, '0');
    final a = ayah.toString().padLeft(3, '0');
    return AudioSource.uri(
        Uri.parse('https://everyayah.com/data/$key/$s$a.mp3'));
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.play();

  Future<void> stop() async {
    _baseAyah = 0;
    await _player.stop();
  }

  void dispose() {
    _baseAyah = 0;
    _player.stop();
  }
}
