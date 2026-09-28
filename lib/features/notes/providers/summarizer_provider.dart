import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/note_summarizer_service.dart';

final summarizerServiceProvider = Provider<NoteSummarizerService>((ref) {
  // Transkriptte kullandığın aynı Groq API anahtarı
  final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  return NoteSummarizerService(apiKey: apiKey);
});