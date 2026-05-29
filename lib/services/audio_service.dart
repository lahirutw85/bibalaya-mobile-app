import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Map<String, dynamic> _audioMap = {};
  bool _initialized = false;
  String? _playingId;

  String? get playingId => _playingId;
  AudioPlayer get player => _audioPlayer;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/audio_map.json');
      _audioMap = jsonDecode(jsonStr);
      _initialized = true;
    } catch (e) {
      print("Error initializing AudioService: $e");
    }
  }

  bool chapterAudioExists(String book, int chapter, String version) {
    if (version != 'SINBIBLE') return false;
    final key = "${book.toUpperCase()}_FULL_CH_$chapter";
    return _audioMap.containsKey(key);
  }

  Future<void> playChapter(String book, int chapter) async {
    await init();
    final key = "${book.toUpperCase()}_FULL_CH_$chapter";
    final fileId = _audioMap[key];
    if (fileId == null) return;

    final url = "https://docs.google.com/uc?export=download&id=$fileId";
    _playingId = "chapter-$book-$chapter";
    
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      print("Error playing audio: $e");
      _playingId = null;
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _playingId = null;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
