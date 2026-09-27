import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _audioStorageMb = 0.0;
  int _audioFileCount = 0;
  bool _isLoadingStorage = true;

  // Ekstra Tercihler
  bool _autoSummarize = true;
  String _selectedLanguage = 'Türkçe';

  @override
  void initState() {
    super.initState();
    _calculateStorage();
  }

  Future<void> _calculateStorage() async {
    if (kIsWeb) {
      setState(() {
        _isLoadingStorage = false;
        _audioFileCount = 0;
        _audioStorageMb = 0.0;
      });
      return;
    }

    setState(() => _isLoadingStorage = true);
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

      if (mounted) {
        setState(() {
          _audioFileCount = count;
          _audioStorageMb = totalBytes / (1024 * 1024);
          _isLoadingStorage = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStorage = false);
      }
    }
  }

  // 1. Sadece Ses Dosyalarını Sil (Metinler Kalır)
  Future<void> _clearOnlyAudioFiles() async {
    if (kIsWeb) {
      _showSnackBar('Web tarayıcısında dosya sistemi temizliği desteklenmiyor.', isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'Ses Dosyalarını Temizle',
      content: 'Diskteki tüm ses kayıtları silinecek, ancak not başlıkları ve metinleri korunacaktır. Emin misin?',
      confirmText: 'Sesleri Sil',
      confirmColor: Colors.orangeAccent,
    );

    if (confirmed == true) {
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

        // Riverpod'daki notların ses yollarını güvenle boşa çıkar
        final notes = ref.read(notesProvider);
        for (final note in notes) {
          if (note.audioPath != null) {
            final updatedNote = NoteModel(
              id: note.id,
              title: note.title,
              content: note.content,
              audioPath: null,
              createdAt: note.createdAt,
              isSynced: note.isSynced,
            );
            ref.read(notesProvider.notifier).updateNote(updatedNote);
          }
        }

        await _calculateStorage();
        _showSnackBar('Ses dosyaları silindi, not metinleri korundu.');
      } catch (e) {
        _showSnackBar('Hata oluştu: $e', isError: true);
      }
    }
  }

  // 2. Uygulamayı Tamamen Sıfırla (Fabrika Ayarları)
  Future<void> _resetEntireApp() async {
    final confirmed = await _showConfirmDialog(
      title: 'Tüm Verileri Sıfırla',
      content: 'Tüm ses kayıtları ve aldığın tüm notlar tamamen silinecektir. Bu işlem geri alınamaz. Emin misin?',
      confirmText: 'Her Şeyi Sil',
      confirmColor: Colors.redAccent,
    );

    if (confirmed == true) {
      try {
        // 1. Dosya sistemini temizle (Sadece Mobilde)
        if (!kIsWeb) {
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
        }

        // 2. Riverpod ve SQLite'ı temizle
        await ref.read(notesProvider.notifier).clearAllNotes();

        // 3. Depolama sayacını güncelle
        await _calculateStorage();

        _showSnackBar('Uygulama sıfırlandı, tüm veriler silindi.');
      } catch (e) {
        _showSnackBar('Sıfırlama sırasında bir hata oluştu: $e', isError: true);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final allNotes = ref.watch(notesProvider);
    final unsyncedCount = allNotes.where((n) => !n.isSynced).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Görünüm
          _buildSectionHeader(theme, 'GÖRÜNÜM'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              secondary: Icon(
                themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Karanlık Mod'),
              subtitle: Text(
                themeMode == ThemeMode.dark ? 'Karanlık tema devrede' : 'Aydınlık tema devrede',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              value: themeMode == ThemeMode.dark,
              onChanged: (val) {
                ref.read(themeModeProvider.notifier).state =
                    val ? ThemeMode.dark : ThemeMode.light;
              },
            ),
          ),
          const SizedBox(height: 16),

          // 2. Yapay Zeka & Dil Tercihleri
          _buildSectionHeader(theme, 'YAPAY ZEKA & TRANSKRİPT'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language_rounded, color: theme.colorScheme.primary),
                  title: const Text('Transkript Dili'),
                  subtitle: Text(
                    _selectedLanguage,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              title: const Text('Türkçe'),
                              trailing: _selectedLanguage == 'Türkçe' ? const Icon(Icons.check) : null,
                              onTap: () {
                                setState(() => _selectedLanguage = 'Türkçe');
                                Navigator.pop(ctx);
                              },
                            ),
                            ListTile(
                              title: const Text('English'),
                              trailing: _selectedLanguage == 'English' ? const Icon(Icons.check) : null,
                              onTap: () {
                                setState(() => _selectedLanguage = 'English');
                                Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  secondary: Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
                  title: const Text('Otomatik Özet Çıkar'),
                  subtitle: Text(
                    'Kayıt bitince AI ana fikirleri maddelesin',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  value: _autoSummarize,
                  onChanged: (val) {
                    setState(() => _autoSummarize = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Depolama & Temizlik
          _buildSectionHeader(theme, 'DEPOLAMA VE TEMİZLİK'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.storage_rounded, color: theme.colorScheme.primary),
                  title: const Text('Yerel Ses Depolama Alanı'),
                  subtitle: Text(
                    _isLoadingStorage
                        ? 'Hesaplanıyor...'
                        : '$_audioFileCount ses kaydı (${_audioStorageMb.toStringAsFixed(2)} MB)',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _calculateStorage,
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.audio_file_outlined, color: Colors.orangeAccent),
                  title: const Text(
                    'Yalnızca Ses Dosyalarını Sil',
                    style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Metin notları korunur, diskte yer açılır',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: _clearOnlyAudioFiles,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                  title: const Text(
                    'Tüm Verileri Sıfırla',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Tüm sesleri ve not listesini kökten temizler',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: _resetEntireApp,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Bulut & Senkronizasyon
          _buildSectionHeader(theme, 'BULUT & SENKRONİZASYON'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.cloud_queue_rounded, color: theme.colorScheme.primary),
                  title: const Text('Supabase Durumu'),
                  subtitle: Text(
                    unsyncedCount == 0
                        ? 'Tüm notlar güncel'
                        : '$unsyncedCount not senkronize edilmeyi bekliyor',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  trailing: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: unsyncedCount == 0 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.upload_file_rounded, color: theme.colorScheme.primary),
                  title: const Text('Notları Dışa Aktar'),
                  subtitle: Text(
                    '${allNotes.length} notu metin dosyası olarak yedekle',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    _showSnackBar('${allNotes.length} not dışa aktarma için hazır.');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Hakkında & Sistem Bilgisi
          _buildSectionHeader(theme, 'HAKKINDA'),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.psychology_alt_rounded, color: theme.colorScheme.primary),
                  title: const Text('Second Brain Mobile'),
                  subtitle: const Text('Sürüm 1.0.0 · Flutter & Riverpod'),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.mic_external_on_rounded, color: theme.colorScheme.primary),
                  title: const Text('Ses Motoru'),
                  subtitle: const Text('AAC ADTS · 128 kbps · Düşük Gecikme'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}