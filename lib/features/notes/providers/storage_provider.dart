import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'notes_provider.dart';

class StorageInfo {
  final int fileCount;
  final double sizeMb;

  const StorageInfo({required this.fileCount, required this.sizeMb});
  const StorageInfo.empty() : fileCount = 0, sizeMb = 0.0;
}

final storageStateProvider =
    StateNotifierProvider<StorageNotifier, AsyncValue<StorageInfo>>((ref) {
  return StorageNotifier(ref);
});

class StorageNotifier extends StateNotifier<AsyncValue<StorageInfo>> {
  final Ref _ref;

  StorageNotifier(this._ref) : super(const AsyncValue.loading()) {
    refreshStorageInfo();
  }

  // Diskteki ses dosyalarını tarayıp MB ve dosya sayısını hesaplar
  Future<void> refreshStorageInfo() async {
    state = const AsyncValue.loading();
    try {
      if (kIsWeb) {
        state = const AsyncValue.data(StorageInfo.empty());
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      int count = 0;
      int totalBytes = 0;

      final files = dir.listSync();
      for (final file in files) {
        if (file is File &&
            (file.path.endsWith('.m4a') || file.path.endsWith('.aac'))) {
          count++;
          totalBytes += await file.length();
        }
      }

      state = AsyncValue.data(
        StorageInfo(fileCount: count, sizeMb: totalBytes / (1024 * 1024)),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Yalnızca ses dosyalarını diskten siler ve notları metin notuna çevirir
  Future<void> clearOnlyAudioFiles() async {
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final files = dir.listSync();
        for (final file in files) {
          if (file is File &&
              (file.path.endsWith('.m4a') || file.path.endsWith('.aac'))) {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      } catch (_) {}
    }

    // SQLite'taki ve ekrandaki notların audioPath'ini null'a çeker
    final notes = _ref.read(notesProvider);
    for (final note in notes) {
      if (note.audioPath != null) {
        await _ref.read(notesProvider.notifier).updateNote(
              note.copyWith(clearAudioPath: true),
            );
      }
    }

    await refreshStorageInfo();
  }

  // Tüm notları ve sesleri kökten temizler
  Future<void> resetEntireApp() async {
    await clearOnlyAudioFiles();
    await _ref.read(notesProvider.notifier).clearAllNotes();
    await refreshStorageInfo();
  }
}