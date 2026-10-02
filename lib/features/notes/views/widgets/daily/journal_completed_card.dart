import 'package:flutter/material.dart';
import '../../../models/note_model.dart';

class JournalCompletedCard extends StatelessWidget {
  final NoteModel entry;
  final VoidCallback onTapDetail;

  const JournalCompletedCard({
    super.key,
    required this.entry,
    required this.onTapDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAudio = entry.audioPath != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 15),
                    SizedBox(width: 6),
                    Text(
                      'Günün Kaydı Mühürlendi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (hasAudio) ...[
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 16,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            entry.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.4),
          ),
          const SizedBox(height: 12),
          Text(
            entry.summary ?? entry.content,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onTapDetail,
              icon: const Icon(Icons.auto_stories_rounded, size: 18),
              label: const Text('Günlüğü & AI Analizini Oku'),
            ),
          ),
        ],
      ),
    );
  }
}