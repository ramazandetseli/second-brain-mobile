import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:second_brain/core/services/note_summarizer_service.dart';
import 'package:second_brain/features/notes/providers/note_processing_provider.dart';
import 'package:second_brain/features/notes/providers/summarizer_provider.dart';
import 'package:second_brain/features/notes/providers/transcription_provider.dart';
import 'package:second_brain/features/notes/views/widgets/home/processing_card_wrapper.dart';
import '../../../core/services/audio_recording_service.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import 'note_detail_screen.dart';
import 'widgets/home/add_note_bottom_sheet.dart';
import 'widgets/home/empty_notes_view.dart';
import 'widgets/home/home_header.dart';
import 'widgets/home/note_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final AudioRecordingService _audioService = AudioRecordingService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;

  String? _currentlyPlayingPath;
  PlayerState _playerState = PlayerState.stopped;
  String _searchQuery = '';
  String _selectedFilter = 'all';
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
    _recordTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _recordDuration = 0;
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordDuration++);
    });
  }

  void _stopTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
    _recordDuration = 0;
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
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

  Future<void> _handleMicPress() async {
    try {
      if (!_isRecording) {
        if (!await _audioService.hasPermission()) return;
        if (_playerState == PlayerState.playing) await _audioPlayer.stop();

        await _audioService.startRecording();
        _startTimer();
        setState(() => _isRecording = true);
      } else {
    

        _stopTimer();
        final path = await _audioService.stopRecording();
        setState(() => _isRecording = false);

         if (path != null) {
          final now = DateTime.now();
          final noteId = now.millisecondsSinceEpoch.toString();

          final initialNote = NoteModel(
            id: noteId,
            title: 'Yeni Ses Kaydı',
            content: 'Ses işleniyor...',
            audioPath: path,
            category: 'Genel',
            createdAt: now,
          );

          // 1. Not listeye girdi
          await ref.read(notesProvider.notifier).addNote(initialNote);

          // 2. Transkript aşaması (Cyan Işık Başlar)
          ref.read(noteProcessingProvider(noteId).notifier).state = NoteProcessingState.transcribing;

          try {
            // API çağrısı ve minimum 1.2 sn animasyon süresi garantisi
            final results = await Future.wait([
              ref.read(transcriptionServiceProvider).transcribeAudio(audioFilePath: path),
              Future.delayed(const Duration(milliseconds: 1200)), // Gözün efekti görmesi için
            ]);

            final transcript = results[0] as String;

            await ref.read(notesProvider.notifier).updateNote(
              initialNote.copyWith(content: transcript),
            );

            // 3. AI Özetleme aşaması (Mor Işığa Geçiş)
            ref.read(noteProcessingProvider(noteId).notifier).state = NoteProcessingState.summarizing;

            final aiResults = await Future.wait([
              ref.read(summarizerServiceProvider).summarizeTranscript(transcript),
              Future.delayed(const Duration(milliseconds: 1400)), // Mor ışık ve analiz için bekleme
            ]);

            final aiResult = aiResults[0] as NoteAiResult;

            // 4. Veritabanını güncelle
            final finalizedNote = initialNote.copyWith(
              title: aiResult.title,
              content: transcript,
              summary: aiResult.summary,
              category: aiResult.category,
            );
            await ref.read(notesProvider.notifier).updateNote(finalizedNote);

            // 5. Tamamlandı (3 Kez Yeşil Flaş Yanar ve Biter)
            ref.read(noteProcessingProvider(noteId).notifier).state = NoteProcessingState.completed;

          } catch (e) {
            ref.read(noteProcessingProvider(noteId).notifier).state = NoteProcessingState.idle;
            await ref.read(notesProvider.notifier).updateNote(
              initialNote.copyWith(content: 'Hata oluştu: $e'),
            );
          }
        }
      }
    } catch (_) {
      _stopTimer();
      setState(() => _isRecording = false);
    }
  }

  void _openAddTextNoteModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddNoteBottomSheet(),
    );
  }


  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider);

    // Hem arama kelimesine hem de seçili çipe göre filtrele
    final notes = allNotes.where((note) {
      // 1. Arama filtresi
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          note.title.toLowerCase().contains(q) || note.content.toLowerCase().contains(q);

      // 2. Biçim (Çip) filtresi
      final matchesFormat = switch (_selectedFilter) {
        'audio' => note.audioPath != null,
        'text' => note.audioPath == null,
        _ => true,
      };

      return matchesSearch && matchesFormat;
    }).toList();

    final theme = Theme.of(context);

      final audioCount = allNotes.where((n) => n.audioPath != null).length;
      final textCount = allNotes.where((n) => n.audioPath == null).length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
          HomeHeader(
            totalNotes: allNotes.length,
            audioNotesCount: audioCount,
            textNotesCount: textCount,
            isRecording: _isRecording,
            recordDuration: _formatDuration(_recordDuration),
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            onAddTextNote: _openAddTextNoteModal,
          ),
            Expanded(
              child: notes.isEmpty
                  ? EmptyNotesView(isSearching: _searchQuery.isNotEmpty)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
  return ProcessingCardWrapper(
    noteId: note.id,
    child: NoteCard(
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
                        ),
                  );
                  },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleMicPress,
        backgroundColor: _isRecording ? Colors.redAccent : theme.colorScheme.primary,
        icon: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white),
        label: Text(
          _isRecording ? 'Kaydı Bitir' : 'Yeni Ses Notu',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}