import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import 'note_detail_screen.dart';

class TopicItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  const TopicItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}

class TopicsScreen extends ConsumerStatefulWidget {
  const TopicsScreen({super.key});

  @override
  ConsumerState<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends ConsumerState<TopicsScreen> {
  String _selectedTopicId = 'all';

  final List<TopicItem> _topics = const [
    TopicItem(
      id: 'all',
      title: 'Tümü',
      icon: Icons.grid_view_rounded,
      color: Colors.blueAccent,
    ),
    TopicItem(
      id: 'ideas',
      title: 'Fikirler',
      icon: Icons.lightbulb_outline_rounded,
      color: Colors.amber,
    ),
    TopicItem(
      id: 'projects',
      title: 'Projeler',
      icon: Icons.rocket_launch_outlined,
      color: Colors.deepPurpleAccent,
    ),
    TopicItem(
      id: 'work',
      title: 'İş & Toplantı',
      icon: Icons.work_outline_rounded,
      color: Colors.teal,
    ),
    TopicItem(
      id: 'personal',
      title: 'Kişisel & Günlük',
      icon: Icons.person_outline_rounded,
      color: Colors.pinkAccent,
    ),
  ];

  // Şimdilik not içeriğine göre kategori eşleme (ileride AI otomatik etiketleyecek)
  bool _matchesTopic(NoteModel note, String topicId) {
    if (topicId == 'all') return true;

    final text = '${note.title} ${note.content}'.toLowerCase();
    switch (topicId) {
      case 'ideas':
        return text.contains('fikir') ||
            text.contains('düşünce') ||
            text.contains('yeni') ||
            text.contains('aklıma');
      case 'projects':
        return text.contains('proje') ||
            text.contains('kod') ||
            text.contains('flutter') ||
            text.contains('app');
      case 'work':
        return text.contains('toplantı') ||
            text.contains('iş') ||
            text.contains('görev') ||
            text.contains('müşteri');
      case 'personal':
        return text.contains('günlük') ||
            text.contains('ev') ||
            text.contains('spor') ||
            text.contains('kendim');
      default:
        return true;
    }
  }

  int _getTopicCount(List<NoteModel> notes, String topicId) {
    if (topicId == 'all') return notes.length;
    return notes.where((note) => _matchesTopic(note, topicId)).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allNotes = ref.watch(notesProvider);

    final filteredNotes = allNotes.where((note) {
      return _matchesTopic(note, _selectedTopicId);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konular & Etiketler'),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Yatay Kategori Seçim Listesi
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _topics.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final topic = _topics[index];
                final isSelected = _selectedTopicId == topic.id;
                final count = _getTopicCount(allNotes, topic.id);

                return FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: Icon(
                    topic.icon,
                    size: 18,
                    color: isSelected ? Colors.white : topic.color,
                  ),
                  label: Text('${topic.title} ($count)'),
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  backgroundColor:
                      theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  selectedColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedTopicId = topic.id;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Seçili Kategori Özeti ve Not Listesi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              '${filteredNotes.length} not bulundu',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),

          Expanded(
            child: filteredNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bu konuda henüz not yok',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            note.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NoteDetailScreen(note: note),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}