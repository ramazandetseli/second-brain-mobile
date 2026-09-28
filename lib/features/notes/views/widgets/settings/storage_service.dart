import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class StorageInfo {
  final int fileCount;
  final double sizeMb;

  const StorageInfo({required this.fileCount, required this.sizeMb});
  const StorageInfo.empty() : fileCount = 0, sizeMb = 0.0;
}

class StorageService {
  Future<StorageInfo> getAudioStorageInfo() async {
    if (kIsWeb) return const StorageInfo.empty();

    try {
      final dir = await getApplicationDocumentsDirectory();
      int count = 0;
      int totalBytes = 0;

      final files = dir.listSync();
      for (final file in files) {
        if (file is File &&
            (file.path.endsWith('.aac') || file.path.endsWith('.m4a'))) {
          count++;
          totalBytes += await file.length();
        }
      }

      return StorageInfo(
        fileCount: count,
        sizeMb: totalBytes / (1024 * 1024),
      );
    } catch (_) {
      return const StorageInfo.empty();
    }
  }

  Future<void> deleteAudioFiles() async {
    if (kIsWeb) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync();
      for (final file in files) {
        if (file is File &&
            (file.path.endsWith('.aac') || file.path.endsWith('.m4a'))) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}