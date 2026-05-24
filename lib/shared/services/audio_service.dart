import 'package:audioplayers/audioplayers.dart';

class SoundPlayerService {
  final AudioPlayer _correctSoundPlayer = AudioPlayer();
  final AudioPlayer _wrongSoundPlayer = AudioPlayer();

  Future<void> playCorrect() async {
    await _correctSoundPlayer.stop(); // Останавливаем, если играет
    await _correctSoundPlayer.play(AssetSource('audio/correct.wav'));
  }

  Future<void> playWrong() async {
    await _correctSoundPlayer.stop();
    await _correctSoundPlayer.play(AssetSource('audio/wrong.mp3'));
  }

  Future<void> playWinGame() async {
    await _correctSoundPlayer.stop();
    await _correctSoundPlayer.play(AssetSource('audio/game_win.mp3'));
  }

  Future<void> playWinLevel() async {
    await _correctSoundPlayer.stop();
    await _correctSoundPlayer.play(AssetSource('audio/level_win.mp3'));
  }

  Future<void> dispose() async {
    await _correctSoundPlayer.stop();
    await _wrongSoundPlayer.stop();
  }
}
