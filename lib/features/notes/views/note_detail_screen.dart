import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final NoteModel note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);

    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    if (widget.note.audioPath == null) return;

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playerState = PlayerState.stopped;
        });
      }
    });

    // Kayıtlı ses dosyasını hazırla ve süresini al
    _audioPlayer.setSource(DeviceFileSource(widget.note.audioPath!));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _toggleAudio() async {
    if (widget.note.audioPath == null) return;

    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(widget.note.audioPath!));
    }
  }

  void _saveChanges() {
    final updatedNote = NoteModel(
      id: widget.note.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      audioPath: widget.note.audioPath,
      createdAt: widget.note.createdAt,
      isSynced: false,
    );

    ref.read(notesProvider.notifier).updateNote(updatedNote);

    setState(() => _hasChanges = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Not güncellendi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAudio = widget.note.audioPath != null;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Kaydet',
              onPressed: _saveChanges,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Sil',
            onPressed: () {
              ref.read(notesProvider.notifier).deleteNote(widget.note.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ses Çalma ve İlerleme Çubuğu Kartı
            if (hasAudio) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton.filled(
                          iconSize: 28,
                          icon: Icon(
                            _playerState == PlayerState.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          onPressed: _toggleAudio,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ses Kaydı',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        min: 0.0,
                        max: _duration.inMilliseconds.toDouble() > 0
                            ? _duration.inMilliseconds.toDouble()
                            : 1.0,
                        value: _position.inMilliseconds
                            .toDouble()
                            .clamp(0.0, _duration.inMilliseconds.toDouble()),
                        onChanged: (val) async {
                          final target = Duration(milliseconds: val.toInt());
                          await _audioPlayer.seek(target);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Başlık Alanı
            TextField(
              controller: _titleController,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Başlık',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) {
                if (!_hasChanges) setState(() => _hasChanges = true);
              },
            ),
            const SizedBox(height: 8),

            // Tarih Etiketi
            Text(
              '${widget.note.createdAt.day}.${widget.note.createdAt.month}.${widget.note.createdAt.year} · ${widget.note.createdAt.hour.toString().padLeft(2, '0')}:${widget.note.createdAt.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const Divider(height: 28),

            // İçerik Alanı
            TextField(
              controller: _contentController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              decoration: const InputDecoration(
                hintText: 'Transkript veya not içeriği...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) {
                if (!_hasChanges) setState(() => _hasChanges = true);
              },
            ),
          ],
        ),
      ),
    );
  }
}