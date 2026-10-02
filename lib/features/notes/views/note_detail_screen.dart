import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:second_brain/features/notes/views/widgets/note/audio_player_card.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final NoteModel note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;

  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playerState = state);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handlePlayAudio(String? path) async {
    if (path == null) return;
    if (!File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses dosyası diskte bulunamadı.')),
      );
      return;
    }

    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else if (_playerState == PlayerState.paused) {
      await _audioPlayer.resume();
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
    }
  }

  Future<void> _saveChanges(NoteModel currentNote) async {
    final updatedTitle = _titleController.text.trim();
    final updatedContent = _contentController.text.trim();

    if (updatedContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not içeriği boş bırakılamaz.')),
      );
      return;
    }

    final updatedNote = currentNote.copyWith(
      title: updatedTitle.isEmpty ? 'Başlıksız Not' : updatedTitle,
      content: updatedContent,
    );

    await ref.read(notesProvider.notifier).updateNote(updatedNote);

    if (mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Değişiklikler kaydedildi.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _cancelEditing(NoteModel currentNote) {
    setState(() {
      _titleController.text = currentNote.title;
      _contentController.text = currentNote.content;
      _isEditing = false;
    });
  }

  Future<void> _deleteNote(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notu Sil'),
        content: const Text('Bu notu silmek istediğinden emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(notesProvider.notifier).deleteNote(id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    final currentNote = ref.watch(notesProvider).firstWhere(
          (n) => n.id == widget.note.id,
          orElse: () => widget.note,
        );
    
    final hasAudio = currentNote.audioPath != null;
    final _isPlaying = _playerState == PlayerState.playing;
    
    
    final hasAudioPath = currentNote.audioPath != null;
    final isAudioOnDisk = hasAudioPath && File(currentNote.audioPath!).existsSync();
    final isAudioDeleted = hasAudioPath && !isAudioOnDisk;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Notu Düzenle' : ''),
        actions: [
          if (_isEditing) ...[
            TextButton(
              onPressed: () => _cancelEditing(currentNote),
              child: const Text('İptal'),
            ),
            IconButton(
              icon: const Icon(Icons.check_rounded, color: Colors.green),
              tooltip: 'Kaydet',
              onPressed: () => _saveChanges(currentNote),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Düzenle',
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Sil',
              onPressed: () => _deleteNote(currentNote.id),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tür Etiketi ve Tarih
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasAudio
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasAudio ? 'Ses Notu' : 'Metin Notu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasAudio
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${currentNote.createdAt.day}.${currentNote.createdAt.month}.${currentNote.createdAt.year} '
                    '${currentNote.createdAt.hour.toString().padLeft(2, '0')}:${currentNote.createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Başlık Alanı
              if (_isEditing)
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Başlık',
                    border: UnderlineInputBorder(),
                  ),
                )
              else
                SelectableText(
                  currentNote.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),

              const SizedBox(height: 16),

if (isAudioOnDisk) ...[
  AudioPlayerCard(audioPath: currentNote.audioPath!),
  const SizedBox(height: 16),
]
// 2. Ses yolu var ama fiziksel dosya silinmişse: Bilgilendirme Rozeti
else if (isAudioDeleted) ...[
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.mic_off_rounded,
          size: 18,
          color: theme.colorScheme.error.withValues(alpha: 0.75),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Ses dosyası depolama tasarrufu için temizlenmiş. Transkript ve özet metinleri korunuyor.',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 16),
],
              // Varsa AI Özeti Kartı
if (currentNote.summary != null && currentNote.summary!.isNotEmpty) ...[
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: theme.colorScheme.primary.withValues(alpha: 0.3),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'YAPAY ZEKA ÖZETİ',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SelectableText(
          currentNote.summary!,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 20),
],

              // İçerik / Transkript Alanı
              Text(
                'İÇERİK',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              if (_isEditing)
                TextField(
                  controller: _contentController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  minLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Not içeriği...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: SelectableText(
                    currentNote.content,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}