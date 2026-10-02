import 'package:flutter/material.dart';

class JournalPromptCard extends StatelessWidget {
  final bool isToday;
  final VoidCallback onVoiceTap;
  final VoidCallback onTextTap;

  const JournalPromptCard({
    super.key,
    required this.isToday,
    required this.onVoiceTap,
    required this.onTextTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isToday ? Icons.nightlight_round : Icons.history_rounded,
              color: theme.colorScheme.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isToday ? 'Bugünü Henüz Mühürlemedin' : 'Bu Güne Ait Kayıt Yok',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
          ),
          const SizedBox(height: 8),
          Text(
            isToday
                ? 'Günün nasıl geçti? Neler öğrendin veya seni ne yordu? İster sesinle serbestçe anlat, ister yaz.'
                : 'Geçmiş günlere yeni kayıt eklenemez. Yalnızca geçmişte tamamladığın günlükleri inceleyebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          if (isToday) ...[
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    onPressed: onVoiceTap,
                    icon: const Icon(Icons.mic_rounded, size: 20),
                    label: const Text('Sesle Dök', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    onPressed: onTextTap,
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text('Yazarak Dök', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}