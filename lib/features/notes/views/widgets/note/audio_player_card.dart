import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class AudioPlayerCard extends StatefulWidget {
  final String audioPath;

  const AudioPlayerCard({
    super.key,
    required this.audioPath,
  });

  @override
  State<AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<AudioPlayerCard> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlayerInit = false;
  bool _isPlaying = false;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription? _playerSubscription;

  // Akıcılık ve gecikme önleyici değişkenler
  bool _isDragging = false;
  double _dragPositionMs = 0.0;
  int _lastSeekTimestamp = 0; // Seek sonrası gelen eski paketleri yutmak için

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
    // 100 ms yerine 250 ms: Platform channel'ı boğmadan akıcı sayaç sağlar
    await _player.setSubscriptionDuration(const Duration(milliseconds: 250));
    if (mounted) setState(() => _isPlayerInit = true);
  }

  Future<void> _togglePlay() async {
    if (!_isPlayerInit) return;

    if (_isPlaying) {
      await _player.pausePlayer();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      if (_player.isPaused) {
        await _player.resumePlayer();
        if (mounted) setState(() => _isPlaying = true);
      } else {
        await _player.startPlayer(
          fromURI: widget.audioPath,
          whenFinished: () {
            if (mounted) {
              setState(() {
                _isPlaying = false;
                _currentPosition = Duration.zero;
              });
            }
          },
        );
        if (mounted) setState(() => _isPlaying = true);

        _playerSubscription?.cancel();
        _playerSubscription = _player.onProgress?.listen((e) {
          final now = DateTime.now().millisecondsSinceEpoch;
          // Sürüklerken VEYA seek yapıldıktan sonraki ilk 350 ms boyunca
          // native taraftan gelen eski verileri yut (titremeyi engeller)
          if (_isDragging || (now - _lastSeekTimestamp < 350)) return;

          if (mounted) {
            setState(() {
              _currentPosition = e.position;
              _totalDuration = e.duration;
            });
          }
        });
      }
    }
  }

  // Parmak kaldırıldığında anında tepki veren optimize edilmiş seek
  void _onSeekCompleted(double valueInMs) {
    if (!_isPlayerInit) return;

    final target = Duration(milliseconds: valueInMs.toInt());
    _lastSeekTimestamp = DateTime.now().millisecondsSinceEpoch;

    // 1. UI'ı ANINDA yeni konuma oturt (native motoru bekleme)
    setState(() {
      _currentPosition = target;
      _dragPositionMs = valueInMs;
      _isDragging = false;
    });

    // 2. Native oynatıcıya komutu arkada asenkron ilet (await ile UI'ı kilitleme)
    _player.seekToPlayer(target);
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxMs = _totalDuration.inMilliseconds.toDouble();

    final currentMs = _isDragging
        ? _dragPositionMs
        : _currentPosition.inMilliseconds.toDouble();

    final sliderVal = (maxMs > 0 && currentMs <= maxMs) ? currentMs : 0.0;

    final displayPosition = _isDragging
        ? Duration(milliseconds: _dragPositionMs.toInt())
        : _currentPosition;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton.filled(
                  iconSize: 22,
                  icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  onPressed: _isPlayerInit ? _togglePlay : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: theme.colorScheme.primary,
                      thumbColor: theme.colorScheme.primary,
                    ),
                    child: Slider(
                      value: sliderVal,
                      min: 0.0,
                      max: maxMs > 0 ? maxMs : 1.0,
                      onChangeStart: maxMs > 0
                          ? (val) {
                              setState(() {
                                _isDragging = true;
                                _dragPositionMs = val;
                              });
                            }
                          : null,
                      onChanged: maxMs > 0
                          ? (val) {
                              setState(() {
                                _dragPositionMs = val;
                              });
                            }
                          : null,
                      onChangeEnd: maxMs > 0
                          ? (val) => _onSeekCompleted(val)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 60, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _format(displayPosition),
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: _isDragging ? FontWeight.bold : FontWeight.normal,
                      color: _isDragging
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _format(_totalDuration),
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  onPressed: () {
                    if (_isPlayerInit) {
                      final newPosition = _currentPosition - const Duration(seconds: 5);
                      if (newPosition < _totalDuration) {
                        _onSeekCompleted(newPosition.inMilliseconds.toDouble());
                      } else {
                        _onSeekCompleted(_totalDuration.inMilliseconds.toDouble());
                      }
                    }
                  },
                  child: Icon(Icons.replay_5_rounded, size: 20),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  onPressed: () {
                    if (_isPlayerInit) {
                      final newPosition = _currentPosition + const Duration(seconds: 5);
                      if (newPosition < _totalDuration) {
                        _onSeekCompleted(newPosition.inMilliseconds.toDouble());
                      } else {
                        _onSeekCompleted(_totalDuration.inMilliseconds.toDouble());
                      }
                    }
                  },
                  child: Icon(Icons.forward_5_rounded, size: 20),
                ),
              ],
            )
          ],
        ),
       
      ),
    );
  }
}