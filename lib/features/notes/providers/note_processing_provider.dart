import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NoteProcessingState {
  idle,         // Normal not (işlem yok)
  transcribing, // Whisper sesi metne döküyor (mavi/cyan ışık)
  summarizing,  // Qwen özetliyor ve konu çıkarıyor (mor/amber ışık)
  completed,    // Tamamlandı (3 kez yeşil ışık yanıp söner)
}

final noteProcessingProvider =
    StateProvider.family<NoteProcessingState, String>((ref, noteId) {
  return NoteProcessingState.idle;
});