import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecordingService {
  static final AudioRecordingService _instance = AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (_isRecording) {
      throw Exception('Recording is already in progress');
    }

    if (!await hasPermission()) {
      throw Exception('Microphone permission not granted');
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      throw Exception('Failed to start recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) {
      throw Exception('No recording in progress');
    }

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      _currentRecordingPath = null;
      return path;
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<void> pauseRecording() async {
    if (!_isRecording) {
      throw Exception('No recording in progress');
    }

    try {
      await _recorder.pause();
    } catch (e) {
      throw Exception('Failed to pause recording: $e');
    }
  }

  Future<void> resumeRecording() async {
    if (!_isRecording) {
      throw Exception('No recording in progress');
    }

    try {
      await _recorder.resume();
    } catch (e) {
      throw Exception('Failed to resume recording: $e');
    }
  }

  Future<void> cancelRecording() async {
    if (!_isRecording) {
      return;
    }

    try {
      await _recorder.stop();
      
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _isRecording = false;
      _currentRecordingPath = null;
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      throw Exception('Failed to cancel recording: $e');
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
