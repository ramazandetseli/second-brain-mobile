  import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/transcription_service.dart';

// NOT: Canlı ortamda API anahtarını flutter_dotenv veya --dart-define ile vermelisin
final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  return TranscriptionService(apiKey: apiKey);
});