import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../../core/services/gymcel_audio_handler.dart';
import '../../../core/services/workout_notification_service.dart';
import 'get_ready_overlay_widget.dart';

enum TimerPhase { execution, rest }

class GuidedWorkoutTimerWidget extends StatefulWidget {
  final int executionSeconds;
  final int restSeconds;
  final String exerciseName;
  final String setLabel;
  final VoidCallback onSetCompleted;
  final VoidCallback onClose;

  const GuidedWorkoutTimerWidget({
    super.key,
    required this.executionSeconds,
    required this.restSeconds,
    required this.exerciseName,
    required this.setLabel,
    required this.onSetCompleted,
    required this.onClose,
  });

  @override
  State<GuidedWorkoutTimerWidget> createState() => _GuidedWorkoutTimerWidgetState();
}

class _GuidedWorkoutTimerWidgetState extends State<GuidedWorkoutTimerWidget> {
  Timer? _timer;
  TimerPhase _phase = TimerPhase.execution;
  late int _remainingSeconds;
  late int _totalSeconds;
  bool _isPaused = false;
  bool _showGetReadyOverlay = true;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initSmartwatchNotifications();
    _startExecutionPhase();
  }

  Future<void> _initSmartwatchNotifications() async {
    try {
      final audioHandler = await GymcelAudioHandler.init();
      audioHandler.updateWorkoutSessionMedia(
        exerciseName: widget.exerciseName,
        setLabel: widget.setLabel,
        phaseText: _phase == TimerPhase.execution ? 'Trabajo' : 'Descanso',
        totalSeconds: _totalSeconds,
        remainingSeconds: _remainingSeconds,
        isPaused: _isPaused,
        onPlay: () {
          if (mounted) setState(() => _isPaused = false);
        },
        onPause: () {
          if (mounted) setState(() => _isPaused = true);
        },
        onSkipNext: () {
          if (!mounted) return;
          if (_phase == TimerPhase.execution) {
            _startRestPhase();
          } else {
            _timer?.cancel();
            _triggerAlert();
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) widget.onSetCompleted();
            });
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('Error inicializando controles multimedia: $e');
      debugPrintStack(stackTrace: stackTrace);
    }

    await WorkoutNotificationService.instance.initNotifications(
      onNotificationAction: (action) {
        if (!mounted) return;
        if (action == 'action_pause_resume') {
          setState(() {
            _isPaused = !_isPaused;
          });
          _updateSmartwatchNotification();
        } else if (action == 'action_skip_next') {
          if (_phase == TimerPhase.execution) {
            _startRestPhase();
          } else {
            _timer?.cancel();
            _triggerAlert();
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) widget.onSetCompleted();
            });
          }
        }
      },
    );
  }

  void _startExecutionPhase() {
    setState(() {
      _phase = TimerPhase.execution;
      _totalSeconds = widget.executionSeconds > 0 ? widget.executionSeconds : 45;
      _remainingSeconds = _totalSeconds;
      _isPaused = false;
      _showGetReadyOverlay = true;
    });
  }

  void _onGetReadyComplete() {
    setState(() {
      _showGetReadyOverlay = false;
    });
    WorkoutNotificationService.instance.sendDiscreteWatchAlert(
      title: '¡A ENTRENAR! - ${widget.exerciseName}',
      body: 'Serie ${widget.setLabel} en curso (${widget.executionSeconds}s trabajo)',
    );
    _runTimer();
  }

  void _startRestPhase() {
    _triggerAlert();
    WorkoutNotificationService.instance.triggerWristVibration();
    WorkoutNotificationService.instance.sendDiscreteWatchAlert(
      title: 'Serie Finalizada - ${widget.exerciseName}',
      body: 'Tiempo de descanso iniciado (${widget.restSeconds}s descanso)',
    );
    setState(() {
      _phase = TimerPhase.rest;
      _totalSeconds = widget.restSeconds > 0 ? widget.restSeconds : 90;
      _remainingSeconds = _totalSeconds;
      _isPaused = false;
      _showGetReadyOverlay = false;
    });
    _runTimer();
  }

  void _runTimer() {
    _timer?.cancel();
    _updateSmartwatchNotification();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;

      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        _updateSmartwatchNotification();
      } else {
        timer.cancel();
        if (_phase == TimerPhase.execution) {
          _startRestPhase();
        } else if (_phase == TimerPhase.rest) {
          _triggerAlert();
          WorkoutNotificationService.instance.triggerWristVibration();
          WorkoutNotificationService.instance.sendDiscreteWatchAlert(
            title: 'Descanso Finalizado - ${widget.exerciseName}',
            body: 'Comenzando siguiente serie...',
          );
          // Delay unmounting by 2 seconds so the completion bell sound plays in full!
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) {
              widget.onSetCompleted();
            }
          });
        }
      }
    });
  }

  void _updateSmartwatchNotification() {
    final phaseText = _phase == TimerPhase.execution ? 'Trabajo Activo' : 'Tiempo de Descanso';
    WorkoutNotificationService.instance.showWorkoutProgress(
      exerciseName: widget.exerciseName,
      setLabel: widget.setLabel,
      phaseText: phaseText,
      remainingSeconds: _remainingSeconds,
      isPaused: _isPaused,
    );

    if (GymcelAudioHandler.instance != null) {
      GymcelAudioHandler.instance!.updateWorkoutSessionMedia(
        exerciseName: widget.exerciseName,
        setLabel: widget.setLabel,
        phaseText: phaseText,
        totalSeconds: _totalSeconds,
        remainingSeconds: _remainingSeconds,
        isPaused: _isPaused,
        onPlay: () {
          if (mounted) setState(() => _isPaused = false);
        },
        onPause: () {
          if (mounted) setState(() => _isPaused = true);
        },
        onSkipNext: () {
          if (!mounted) return;
          if (_phase == TimerPhase.execution) {
            _startRestPhase();
          } else {
            _timer?.cancel();
            _triggerAlert();
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) widget.onSetCompleted();
            });
          }
        },
      );
    }
  }

  Future<void> _triggerAlert() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [0, 600, 200, 600]);
      }
      HapticFeedback.heavyImpact();
    } catch (_) {}

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/bell.mp3'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    WorkoutNotificationService.instance.cancelWorkoutNotification();
    if (GymcelAudioHandler.instance != null) {
      GymcelAudioHandler.instance!.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExecution = _phase == TimerPhase.execution;
    final progress = _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;
    final themeColor = isExecution ? const Color(0xFF00B0FF) : const Color(0xFF00E676);

    return Stack(
      children: [
        Card(
          elevation: 8,
          color: const Color(0xFF1E2822),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: themeColor, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Exercise name, set badge & close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.exerciseName} • Serie ${widget.setLabel}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: themeColor, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isExecution ? Icons.timer : Icons.bedtime,
                                  size: 12,
                                  color: themeColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isExecution ? 'TIEMPO DE TRABAJO' : 'TIEMPO DE DESCANSO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: themeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                      onPressed: () {
                        _timer?.cancel();
                        WorkoutNotificationService.instance.cancelWorkoutNotification();
                        if (GymcelAudioHandler.instance != null) {
                          GymcelAudioHandler.instance!.stop();
                        }
                        widget.onClose();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Circular Progress Indicator with Remaining Time Text
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_remainingSeconds}s',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                          Text(
                            isExecution ? 'de trabajo' : 'de descanso',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Controls: Play / Pause / Reanudar & Skip Buttons (Responsive Wrap layout)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPaused ? const Color(0xFF00E676) : Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPaused = !_isPaused;
                        });
                        _updateSmartwatchNotification();
                      },
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 18),
                      label: Text(
                        _isPaused ? 'Reanudar' : 'Pausar',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: themeColor),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () {
                        if (_phase == TimerPhase.execution) {
                          _startRestPhase();
                        } else {
                          _timer?.cancel();
                          _triggerAlert();
                          Future.delayed(const Duration(milliseconds: 1500), () {
                            if (mounted) {
                              widget.onSetCompleted();
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.skip_next, size: 18),
                      label: Text(
                        isExecution ? 'Pasar a Descanso' : 'Siguiente Serie',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Full Screen "3, 2, 1 PREPÁRATE" Animated Overlay before execution phase
        if (_showGetReadyOverlay)
          Positioned.fill(
            child: GetReadyOverlayWidget(
              onCountdownComplete: _onGetReadyComplete,
            ),
          ),
      ],
    );
  }
}
