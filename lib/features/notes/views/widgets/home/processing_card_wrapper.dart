import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:second_brain/features/notes/providers/note_processing_provider.dart';

class ProcessingCardWrapper extends ConsumerStatefulWidget {
  final String noteId;
  final Widget child;

  const ProcessingCardWrapper({
    super.key,
    required this.noteId,
    required this.child,
  });

  @override
  ConsumerState<ProcessingCardWrapper> createState() => _ProcessingCardWrapperState();
}

class _ProcessingCardWrapperState extends ConsumerState<ProcessingCardWrapper>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _pulseCount = 0;

  @override
  void initState() {
    super.initState();
    // 1. Dönen ışık kontrolcüsü (transcribing & summarizing)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // 2. 3 kez yanıp sönme kontrolcüsü (completed)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseCount++;
        if (_pulseCount < 3) {
          _pulseController.forward();
        } else {
          // 3 yanıp sönme tamamlandı, normale dön
          ref.read(noteProcessingProvider(widget.noteId).notifier).state =
              NoteProcessingState.idle;
        }
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(noteProcessingProvider(widget.noteId));

    // Completed durumuna geçildiğinde yanıp sönmeyi başlat
    if (status == NoteProcessingState.completed &&
        !_pulseController.isAnimating &&
        _pulseCount == 0) {
      _pulseController.forward();
    }

    if (status == NoteProcessingState.idle) {
      return widget.child;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arka Plandaki Işık / Neon Efekti
          if (status == NoteProcessingState.transcribing ||
              status == NoteProcessingState.summarizing)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, _) {
                  final isTranscribing = status == NoteProcessingState.transcribing;
                  final colors = isTranscribing
                      ? [Colors.cyanAccent, Colors.blueAccent, Colors.transparent]
                      : [Colors.purpleAccent, Colors.pinkAccent, Colors.transparent];

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: SweepGradient(
                        colors: colors,
                        transform: GradientRotation(
                          _rotationController.value * 2 * math.pi,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          if (status == NoteProcessingState.completed)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(
                            alpha: 0.8 * _pulseAnimation.value,
                          ),
                          blurRadius: 16 * _pulseAnimation.value,
                          spreadRadius: 3 * _pulseAnimation.value,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.greenAccent.withValues(
                          alpha: _pulseAnimation.value,
                        ),
                        width: 2.5,
                      ),
                    ),
                  );
                },
              ),
            ),

          // İçerik Kartı (Arka plandan 2px içeri çekilmiş)
          Container(
            margin: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusBanner(context, status),
                widget.child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(BuildContext context, NoteProcessingState status) {
    if (status == NoteProcessingState.completed) return const SizedBox.shrink();

    final isTranscribing = status == NoteProcessingState.transcribing;
    final color = isTranscribing ? Colors.cyanAccent : Colors.purpleAccent;
    final text = isTranscribing
        ? 'Transkript Çıkarılıyor...'
        : 'AI Analiz Ediyor & Özetliyor...';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}