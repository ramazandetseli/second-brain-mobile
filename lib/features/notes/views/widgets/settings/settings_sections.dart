import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:second_brain/features/notes/views/widgets/settings/storage_provider.dart';
import '../../../models/note_model.dart';
import '../../../providers/notes_provider.dart';
import '../../../providers/theme_provider.dart';

class SettingsSectionWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const SettingsSectionWrapper({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: child,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// 1. Görünüm Kartı
class AppearanceCard extends ConsumerWidget {
  const AppearanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Provider enum'ına değil, ekranın o anki gerçek karanlık/aydınlık durumuna bak:
    final isActuallyDark = theme.brightness == Brightness.dark;

    return SwitchListTile(
      secondary: Icon(
        isActuallyDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        color: theme.colorScheme.primary,
      ),
      title: const Text('Tema Modu'),
      subtitle: Text(
        isActuallyDark ? 'Karanlık tema' : 'Aydınlık tema',
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 13,
        ),
      ),
      value: isActuallyDark,
      onChanged: (val) {
        ref.read(themeModeProvider.notifier).toggleTheme(val);
      },
    );
  }
}

// 2. Yapay Zeka & Tercihler Kartı
class AiPreferencesCard extends StatefulWidget {
  const AiPreferencesCard({super.key});

  @override
  State<AiPreferencesCard> createState() => _AiPreferencesCardState();
}

class _AiPreferencesCardState extends State<AiPreferencesCard> {
  bool _autoSummarize = true;
  String _selectedLanguage = 'Türkçe';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.language_rounded, color: theme.colorScheme.primary),
          title: const Text('Transkript Dili'),
          subtitle: Text(
            _selectedLanguage,
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
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
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
          ),
          value: _autoSummarize,
          onChanged: (val) => setState(() => _autoSummarize = val),
        ),
      ],
    );
  }
}

// 3. Depolama Kartı
class StorageCard extends ConsumerWidget {
  final VoidCallback onClearAudio;
  final VoidCallback onResetAll;

  const StorageCard({
    super.key,
    required this.onClearAudio,
    required this.onResetAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storageState = ref.watch(storageStateProvider);

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.storage_rounded, color: theme.colorScheme.primary),
          title: const Text('Yerel Ses Depolama Alanı'),
          subtitle: storageState.when(
            data: (info) => Text(
              '${info.fileCount} ses kaydı (${info.sizeMb.toStringAsFixed(2)} MB)',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
            ),
            loading: () => const Text('Hesaplanıyor...', style: TextStyle(fontSize: 13)),
            error: (_, __) => const Text('Hesaplanamadı', style: TextStyle(fontSize: 13)),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(storageStateProvider.notifier).refreshStorageInfo(),
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ListTile(
          leading: const Icon(Icons.audio_file_outlined, color: Colors.orangeAccent),
          title: const Text(
            'Yalnızca Ses Dosyalarını Sil',
            style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Metin notları korunur, diskte yer açılır', style: TextStyle(fontSize: 12)),
          onTap: onClearAudio,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ListTile(
          leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
          title: const Text(
            'Tüm Verileri Sıfırla',
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Tüm sesleri ve not listesini kökten temizler', style: TextStyle(fontSize: 12)),
          onTap: onResetAll,
        ),
      ],
    );
  }
}

// 4. Bulut & Senkronizasyon Kartı
class CloudSyncCard extends ConsumerWidget {
  const CloudSyncCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allNotes = ref.watch(notesProvider);
    final unsyncedCount = allNotes.where((n) => !n.isSynced).length;

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.cloud_queue_rounded, color: theme.colorScheme.primary),
          title: const Text('Supabase Durumu'),
          subtitle: Text(
            unsyncedCount == 0 ? 'Tüm notlar güncel' : '$unsyncedCount not senkronize edilmeyi bekliyor',
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
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
            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${allNotes.length} not dışa aktarma için hazır.')),
            );
          },
        ),
      ],
    );
  }
}

// 5. Hakkında Kartı
class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
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
    );
  }
}