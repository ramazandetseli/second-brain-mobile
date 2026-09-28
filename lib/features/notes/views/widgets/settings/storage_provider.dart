import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:second_brain/features/notes/providers/notes_provider.dart';
import 'package:second_brain/features/notes/views/widgets/settings/storage_service.dart';


final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final storageStateProvider =
    StateNotifierProvider<StorageNotifier, AsyncValue<StorageInfo>>((ref) {
  return StorageNotifier(ref);
});

class StorageNotifier extends StateNotifier<AsyncValue<StorageInfo>> {
  final Ref _ref;

  StorageNotifier(this._ref) : super(const AsyncValue.loading()) {
    refreshStorageInfo();
  }

  StorageService get _service => _ref.read(storageServiceProvider);

  Future<void> refreshStorageInfo() async {
    state = const AsyncValue.loading();
    try {
      final info = await _service.getAudioStorageInfo();
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 1. Sadece ses dosyalarını sil ve notları güncelle
  Future<void> clearOnlyAudioFiles() async {
    await _service.deleteAudioFiles();

    // Notların audioPath referanslarını null'a çek
    final notes = _ref.read(notesProvider);
    for (final note in notes) {
      if (note.audioPath != null) {
        await _ref.read(notesProvider.notifier).updateNote(
              note.copyWith(audioPath: null),
            );
      }
    }

    await refreshStorageInfo();
  }

  // 2. Uygulamayı tamamen sıfırla
  Future<void> resetEntireApp() async {
    await _service.deleteAudioFiles();
    await _ref.read(notesProvider.notifier).clearAllNotes();
    await refreshStorageInfo();
  }
}