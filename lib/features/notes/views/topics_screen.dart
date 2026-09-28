import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:second_brain/features/notes/views/widgets/home/empty_notes_view.dart';
import 'package:second_brain/features/notes/views/widgets/home/note_card.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import 'note_detail_screen.dart';

class TopicsScreen extends ConsumerStatefulWidget {
  const TopicsScreen({super.key});

  @override
  ConsumerState<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends ConsumerState<TopicsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingPath;
  PlayerState _playerState = PlayerState.stopped;

  String _selectedTopic = 'all'; // 'all' veya spesifik kategori adı

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
          if (state == PlayerState.completed || state == PlayerState.stopped) {
            _currentlyPlayingPath = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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

    if (_currentlyPlayingPath == path && _playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else if (_currentlyPlayingPath == path && _playerState == PlayerState.paused) {
      await _audioPlayer.resume();
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(path));
      setState(() => _currentlyPlayingPath = path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);

    // 1. Kategorileri ve her kategorideki not sayısını dinamik hesapla
    final Map<String, int> topicCounts = {};
    for (final note in allNotes) {
      final topic = note.category.trim().isEmpty ? 'Genel' : note.category.trim();
      topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
    }

    final availableTopics = topicCounts.keys.toList()..sort();

    // 2. Seçili konuya göre notları filtrele
    final filteredNotes = _selectedTopic == 'all'
        ? allNotes
        : allNotes.where((n) => n.category.trim() == _selectedTopic).toList();

    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konular',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${availableTopics.length} farklı konu başlığı',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Dinamik Konu Çipleri
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _buildTopicChip(
                    label: 'Tümü (${allNotes.length})',
                    isSelected: _selectedTopic == 'all',
                    onTap: () => setState(() => _selectedTopic = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ...availableTopics.map((topic) {
                    final count = topicCounts[topic] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildTopicChip(
                        label: '#$topic ($count)',
                        isSelected: _selectedTopic == topic,
                        onTap: () => setState(() => _selectedTopic = topic),
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Filtrelenmiş Notlar Listesi
            Expanded(
              child: filteredNotes.isEmpty
                  ? const EmptyNotesView(isSearching: false)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return NoteCard(
                          note: note,
                          isPlaying: _currentlyPlayingPath == note.audioPath &&
                              _playerState == PlayerState.playing,
                          onPlayAudio: () => _handlePlayAudio(note.audioPath),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteDetailScreen(note: note),
                            ),
                          ),
                          onDelete: () =>
                              ref.read(notesProvider.notifier).deleteNote(note.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => onTap(),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
      ),
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.5)
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}