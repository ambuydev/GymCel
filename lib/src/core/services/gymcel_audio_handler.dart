import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

class GymcelAudioHandler extends BaseAudioHandler with SeekHandler {
  static GymcelAudioHandler? instance;

  void Function()? onPlayCallback;
  void Function()? onPauseCallback;
  void Function()? onSkipNextCallback;

  static Future<GymcelAudioHandler> init() async {
    if (instance != null) return instance!;

    final handler = await AudioService.init(
      builder: () => GymcelAudioHandler._(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'gymcel_media_channel',
        androidNotificationChannelName: 'Control Multimedia Gymcel',
        androidStopForegroundOnPause: false,
        notificationColor: Color(0xFF00E676),
      ),
    );

    instance = handler;
    return handler;
  }

  GymcelAudioHandler._();

  void updateWorkoutSessionMedia({
    required String exerciseName,
    required String setLabel,
    required String phaseText,
    required int totalSeconds,
    required int remainingSeconds,
    required bool isPaused,
    void Function()? onPlay,
    void Function()? onPause,
    void Function()? onSkipNext,
  }) {
    onPlayCallback = onPlay;
    onPauseCallback = onPause;
    onSkipNextCallback = onSkipNext;

    final elapsedSeconds = (totalSeconds - remainingSeconds).clamp(0, totalSeconds);

    mediaItem.add(
      MediaItem(
        id: exerciseName,
        album: 'Gymcel Gym Tracker',
        title: '$exerciseName ($setLabel)',
        artist: '$phaseText: ${remainingSeconds}s',
        duration: Duration(seconds: totalSeconds > 0 ? totalSeconds : 45),
      ),
    );

    playbackState.add(
      PlaybackState(
        controls: [
          if (isPaused) MediaControl.play else MediaControl.pause,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.playPause,
        },
        androidCompactActionIndices: const [0, 1],
        processingState: AudioProcessingState.ready,
        playing: !isPaused,
        updatePosition: Duration(seconds: elapsedSeconds),
      ),
    );
  }

  @override
  Future<void> play() async {
    if (onPlayCallback != null) onPlayCallback!();
  }

  @override
  Future<void> pause() async {
    if (onPauseCallback != null) onPauseCallback!();
  }

  @override
  Future<void> skipToNext() async {
    if (onSkipNextCallback != null) onSkipNextCallback!();
  }

  @override
  Future<void> stop() async {
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }
}
