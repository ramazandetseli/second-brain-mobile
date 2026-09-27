import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import '../models/note_model.dart';

final notesProvider = StateNotifierProvider<NotesNotifier, List<NoteModel>>((ref) {
  return NotesNotifier();
});

class NotesNotifier extends StateNotifier<List<NoteModel>> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  NotesNotifier() : super([]) {
    loadNotes(); // Başlatıldığında veritabanındaki notları yükle
  }

  Future<void> loadNotes() async {
    try {
      final notes = await _dbHelper.getAllNotes();
      state = notes;
    } catch (_) {
      state = [];
    }
  }

  Future<void> addNote(NoteModel note) async {
    state = [note, ...state];
    await _dbHelper.insertNote(note);
  }

  Future<void> updateNote(NoteModel updatedNote) async {
    state = [
      for (final note in state)
        if (note.id == updatedNote.id) updatedNote else note,
    ];
    await _dbHelper.updateNote(updatedNote);
  }

  Future<void> deleteNote(String id) async {
    state = state.where((note) => note.id != id).toList();
    await _dbHelper.deleteNote(id);
  }

  Future<void> clearAllNotes() async {
    state = [];
    try {
      await _dbHelper.clearAllNotes();
    } catch (e) {
      print('Tüm notlar silinirken hata oluştu: $e');
    }
  }


  Future<void> addTextNote({required String title, required String content}) async {
    final newNote = NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? 'Başlıksız Not' : title.trim(),
      content: content.trim(),
      audioPath: null, // Ses kaydı yok
      createdAt: DateTime.now(),
      isSynced: false,
    );

    await addNote(newNote);
  }
}