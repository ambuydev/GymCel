import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class GetReadyOverlayWidget extends StatefulWidget {
  final VoidCallback onCountdownComplete;

  const GetReadyOverlayWidget({
    super.key,
    required this.onCountdownComplete,
  });

  @override
  State<GetReadyOverlayWidget> createState() => _GetReadyOverlayWidgetState();
}

class _GetReadyOverlayWidgetState extends State<GetReadyOverlayWidget> with SingleTickerProviderStateMixin {
  int _countdown = 3;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _startStep();
  }

  void _startStep() {
    _controller.reset();
    _controller.forward();
    _triggerTickFeedback();

    _timer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
        _startStep();
      } else if (_countdown == 1) {
        setState(() {
          _countdown = 0; // 0 represents "¡A ENTRENAR!"
        });
        _controller.reset();
        _controller.forward();
        _triggerGoFeedback();

        _timer = Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            widget.onCountdownComplete();
          }
        });
      }
    });
  }

  Future<void> _triggerTickFeedback() async {
    HapticFeedback.mediumImpact();
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 80);
      }
    } catch (_) {}
  }

  Future<void> _triggerGoFeedback() async {
    HapticFeedback.heavyImpact();
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [0, 200, 100, 200]);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _countdown > 0 ? '$_countdown' : '¡A ENTRENAR!';

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PREPÁRATE',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 24),
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  displayText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _countdown > 0 ? 96 : 38,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF00E676),
                    shadows: const [
                      Shadow(
                        color: Color(0xFF00E676),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
