import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final int totalNotes;
  final int audioNotesCount;
  final int textNotesCount;
  final bool isRecording;
  final String recordDuration;
  final String selectedFilter; // 'all', 'audio', 'text'
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddTextNote;

  const HomeHeader({
    super.key,
    required this.totalNotes,
    required this.audioNotesCount,
    required this.textNotesCount,
    required this.isRecording,
    required this.recordDuration,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onAddTextNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Satır: Başlık & Aksiyonlar
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
          const SizedBox(height: 14),

          // Arama Çubuğu
          SearchBar(
            hintText: 'Notlarda ara...',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 10),

          // Biçim Filtre Çipleri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context: context,
                  label: 'Tümü ($totalNotes)',
                  isSelected: selectedFilter == 'all',
                  onTap: () => onFilterChanged('all'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  label: 'Ses ($audioNotesCount)',
                  icon: Icons.mic_rounded,
                  isSelected: selectedFilter == 'audio',
                  onTap: () => onFilterChanged('audio'),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  label: 'Metin ($textNotesCount)',
                  icon: Icons.edit_note_rounded,
                  isSelected: selectedFilter == 'text',
                  onTap: () => onFilterChanged('text'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: 16) : null,
      onSelected: (_) => onTap(),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
      ),
      side: BorderSide(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.5)
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}