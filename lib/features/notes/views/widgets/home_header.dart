import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final int totalNotes;
  final bool isRecording;
  final String recordDuration;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddTextNote;

  const HomeHeader({
    super.key,
    required this.totalNotes,
    required this.isRecording,
    required this.recordDuration,
    required this.onSearchChanged,
    required this.onAddTextNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Second Brain',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalNotes not kayıtlı',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (isRecording)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            recordDuration,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.edit_note_rounded),
                    tooltip: 'Yazılı Not Ekle',
                    onPressed: onAddTextNote,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SearchBar(
            hintText: 'Notlarda ara...',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            onChanged: onSearchChanged,
          ),
        ],
      ),
    );
  }
}