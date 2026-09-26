import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String _supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String _supabasePublishableKey = 'YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY';

  SupabaseClient? _client;

  Future<void> initialize() async {
    if (_client != null) return;

    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabasePublishableKey,
    );

    _client = Supabase.instance.client;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase client not initialized. Call initialize() first.');
    }
    return _client!;
  }

  bool get isInitialized => _client != null;
}