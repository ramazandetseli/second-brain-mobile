import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';

class NotesNotifier extends StateNotifier<List<NoteModel>> {
  NotesNotifier() : super([]);

  void addNote(NoteModel note) {
    state = [...state, note];
  }

  void deleteNote(String id) {
    state = state.where((note) => note.id != id).toList();
  }

  void updateNote(NoteModel updatedNote) {
    state = state.map((note) {
      return note.id == updatedNote.id ? updatedNote : note;
    }).toList();
  }

  NoteModel createNoteDraft({
    String? audioPath,
    String title = '',
    String content = '',
  }) {
    return NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      audioPath: audioPath,
      createdAt: DateTime.now(),
      isSynced: false,
    );
  }

  void markAsSynced(String id) {
    state = state.map((note) {
      if (note.id == id) {
        return note.copyWith(isSynced: true);
      }
      return note;
    }).toList();
  }

  void clearNotes() {
    state = [];
  }

  void clearAllNotes() {
    state = [];
  }
  
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<NoteModel>>((ref) {
  return NotesNotifier();
});


