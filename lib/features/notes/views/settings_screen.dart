import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:second_brain/features/notes/views/widgets/settings/settings_sections.dart';
import 'package:second_brain/features/notes/views/widgets/settings/storage_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _handleClearAudio(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Ses Dosyalarını Temizle',
      content: 'Diskteki tüm ses kayıtları silinecek, ancak not başlıkları ve metinleri korunacaktır. Emin misin?',
      confirmText: 'Sesleri Sil',
      confirmColor: Colors.orangeAccent,
    );

    if (confirmed == true) {
      await ref.read(storageStateProvider.notifier).clearOnlyAudioFiles();
    }
  }

  Future<void> _handleResetAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showConfirmDialog(
      context: context,
      title: 'Tüm Verileri Sıfırla',
      content: 'Tüm ses kayıtları ve aldığın tüm notlar tamamen silinecektir. Bu işlem geri alınamaz. Emin misin?',
      confirmText: 'Her Şeyi Sil',
      confirmColor: Colors.redAccent,
    );

    if (confirmed == true) {
      await ref.read(storageStateProvider.notifier).resetEntireApp();
    }
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
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

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SettingsSectionWrapper(
            title: 'GÖRÜNÜM',
            child: AppearanceCard(),
          ),
          const SettingsSectionWrapper(
            title: 'YAPAY ZEKA & TRANSKRİPT',
            child: AiPreferencesCard(),
          ),
          SettingsSectionWrapper(
            title: 'DEPOLAMA VE TEMİZLİK',
            child: StorageCard(
              onClearAudio: () => _handleClearAudio(context, ref),
              onResetAll: () => _handleResetAll(context, ref),
            ),
          ),
          const SettingsSectionWrapper(
            title: 'BULUT & SENKRONİZASYON',
            child: CloudSyncCard(),
          ),
          const SettingsSectionWrapper(
            title: 'HAKKINDA',
            child: AboutCard(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}