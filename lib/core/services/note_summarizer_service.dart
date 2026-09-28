import 'dart:convert';
import 'package:dio/dio.dart';

class NoteAiResult {
  final String title;
  final String summary;
  final String category;

  const NoteAiResult({
    required this.title,
    required this.summary,
    required this.category,
  });

  factory NoteAiResult.fromMap(Map<String, dynamic> map) {
    return NoteAiResult(
      title: map['title'] as String? ?? 'Başlıksız Not',
      summary: map['summary'] as String? ?? '',
      category: map['category'] as String? ?? 'Genel',
    );
  }
}

class NoteSummarizerService {
  final Dio _dio;
  final String _apiKey;

  static const String _groqChatUrl = 'https://api.groq.com/openai/v1/chat/completions';

  NoteSummarizerService({
    Dio? dio,
    required String apiKey,
  })  : _dio = dio ?? Dio(),
        _apiKey = apiKey;

  Future<NoteAiResult> summarizeTranscript(String transcript) async {
    if (transcript.trim().isEmpty) {
      return const NoteAiResult(
        title: 'Boş Not',
        summary: 'Özet çıkarılacak bir metin bulunamadı.',
        category: 'Genel',
      );
    }

    const systemPrompt = '''
Sen kullanıcıların sesli düşüncelerini organize eden bir Second Brain asistanısın.
Sana verilen transkripti analiz et ve YALNIZCA geçerli bir JSON objesi olarak yanıt ver. 

İstenen JSON formatı:
{
  "title": "Metnin ana fikrini anlatan 3-5 kelimelik net ve profesyonel başlık",
  "summary": "Metindeki ana noktaları ve varsa aksiyon adımlarını içeren madde imli özet (Örn: • Madde 1\\n• Madde 2)",
  "category": "Metne en uygun kategori: Fikirler, Projeler, İş, Kişisel veya Genel arasından biri"
}

Asla JSON dışında bir metin veya markdown bloğu (```json gibi) ekleme. Doğrudan JSON döndür.
''';

    try {
      final response = await _dio.post(
        _groqChatUrl,
        data: {
          'model': 'qwen/qwen3.8-27b',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'Transkript:\n$transcript'},
          ],
          'temperature': 0.2, // Tutarlı ve yapılandırılmış JSON için düşük sıcaklık
          'response_format': {'type': 'json_object'},
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 25),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final content = response.data['choices'][0]['message']['content'] as String;
        final Map<String, dynamic> parsedJson = jsonDecode(content);
        return NoteAiResult.fromMap(parsedJson);
      } else {
        throw Exception('Özet API Hatası: ${response.statusCode}');
      }
    } catch (e) {
      // LLM çağrısı başarısız olsa bile notu kaybetmemek için güvenli fallback
      return NoteAiResult(
        title: 'Ses Kaydı',
        summary: 'Otomatik özet oluşturulamadı: $e',
        category: 'Genel',
      );
    }
  }
}