import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/audio_recording_service.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import 'note_detail_screen.dart';
import 'widgets/add_note_bottom_sheet.dart';
import 'widgets/empty_notes_view.dart';
import 'widgets/home_header.dart';
import 'widgets/note_card.dart';

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
          ref.read(notesProvider.notifier).addNote(
                NoteModel(
                  id: now.millisecondsSinceEpoch.toString(),
                  title: 'Ses Kaydı (${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')})',
                  content: 'Ses kaydedildi. Transkript bekleniyor...',
                  audioPath: path,
                  createdAt: now,
                ),
              );
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
    final notes = allNotes.where((note) {
      final q = _searchQuery.toLowerCase();
      return note.title.toLowerCase().contains(q) || note.content.toLowerCase().contains(q);
    }).toList();

    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              totalNotes: allNotes.length,
              isRecording: _isRecording,
              recordDuration: _formatDuration(_recordDuration),
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