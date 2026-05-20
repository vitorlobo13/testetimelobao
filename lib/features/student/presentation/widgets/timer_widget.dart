import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Widget de cronômetro para descanso
class TimerWidget extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const TimerWidget({
    super.key,
    required this.durationSeconds,
    required this.onComplete,
    this.onSkip,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _isRunning = false;
        widget.onComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    _startTimer();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remainingSeconds / widget.durationSeconds);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Descanso',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Cronômetro circular
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progresso circular
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remainingSeconds <= 5 ? AppColors.error : AppColors.teal,
                    ),
                  ),
                ),

                // Tempo restante
                Text(
                  _formatTime(_remainingSeconds),
                  style: AppTextStyles.displayMedium.copyWith(
                    color: _remainingSeconds <= 5 
                        ? AppColors.error 
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botões de controle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pausar/Retomar
              IconButton(
                onPressed: _isRunning ? _pauseTimer : _resumeTimer,
                icon: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow,
                  size: 32,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(width: 16),

              // Pular
              if (widget.onSkip != null)
                IconButton(
                  onPressed: () {
                    _timer?.cancel();
                    widget.onSkip!();
                  },
                  icon: const Icon(Icons.skip_next, size: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}