import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:second_brain/core/services/audio_recording_service.dart';

class AudioRecordingNotifier extends StateNotifier<bool> {
  final AudioRecordingService _recordingService;

  AudioRecordingNotifier(this._recordingService) : super(false);

  Future<String?> startRecording() async {
    try {
      if (!await _recordingService.hasPermission()) {
        throw Exception('Mikrofon izni verilmedi');
      }

      await _recordingService.startRecording();
      state = true;
      return null;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final audioPath = await _recordingService.stopRecording();
      state = false;
      return audioPath;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _recordingService.cancelRecording();
      state = false;
    } catch (e) {
      state = false;
      rethrow;
    }
  }
}

final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  return AudioRecordingService();
});

final audioRecordingProvider = StateNotifierProvider<AudioRecordingNotifier, bool>((ref) {
  final recordingService = ref.watch(audioRecordingServiceProvider);
  return AudioRecordingNotifier(recordingService);
});
