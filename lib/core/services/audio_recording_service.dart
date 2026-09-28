import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecordingService {
  static final AudioRecordingService _instance = AudioRecordingService._internal();
  factory AudioRecordingService() => _instance;
  AudioRecordingService._internal();

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<void> _initRecorder() async {
    if (!_isRecorderInitialized) {
      await _recorder.openRecorder();
      _isRecorderInitialized = true;
    }
  }

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> startRecording() async {
    if (_isRecording) {
      throw Exception('Kayıt zaten devam ediyor');
    }

    if (!await hasPermission()) {
      throw Exception('Mikrofon izni verilmedi');
    }

    await _initRecorder();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // 1. Değişiklik: .aac yerine .m4a
      _currentRecordingPath = '${directory.path}/recording_$timestamp.m4a';

      // 2. Değişiklik: aacADTS yerine aacMP4
      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacMP4,
      );

      _isRecording = true;
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      throw Exception('Kayıt başlatılamadı: $e');
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) {
      throw Exception('Aktif bir kayıt yok');
    }

    try {
      final path = await _recorder.stopRecorder();
      _isRecording = false;
      final savedPath = _currentRecordingPath;
      _currentRecordingPath = null;
      return path ?? savedPath;
    } catch (e) {
      _isRecording = false;
      _currentRecordingPath = null;
      throw Exception('Kayıt durdurulamadı: $e');
    }
  }

  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stopRecorder();
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
      throw Exception('Kayıt iptal edilemedi: $e');
    }
  }

  void dispose() {
    if (_isRecorderInitialized) {
      _recorder.closeRecorder();
      _isRecorderInitialized = false;
    }
  }
}