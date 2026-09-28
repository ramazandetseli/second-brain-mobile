import 'dart:io';
import 'package:dio/dio.dart';

class TranscriptionService {
  final Dio _dio;
  final String _apiKey;

  // Groq Whisper API Uç Noktası
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';

  TranscriptionService({
    Dio? dio,
    required String apiKey,
  })  : _dio = dio ?? Dio(),
        _apiKey = apiKey;

  Future<String> transcribeAudio({
    required String audioFilePath,
    String language = 'tr',
  }) async {
    final file = File(audioFilePath);
    if (!file.existsSync()) {
      throw Exception('Ses dosyası diskte bulunamadı: $audioFilePath');
    }

    try {
      final fileName = audioFilePath.split(Platform.pathSeparator).last;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: fileName,
        ),
        'model': 'whisper-large-v3', // Groq'un en kararlı Whisper modeli
        'response_format': 'json',
        'language': language,
      });

      final response = await _dio.post(
        _groqApiUrl,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'multipart/form-data',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final text = response.data['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
        return 'Ses kaydından anlaşılır bir metin çıkarılamadı.';
      } else {
        throw Exception('API Hatası: ${response.statusCode} - ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error']?['message'] ?? e.message;
      throw Exception('Transkript alınırken ağ hatası oluştu: $errorMessage');
    } catch (e) {
      throw Exception('Beklenmeyen bir hata oluştu: $e');
    }
  }
}