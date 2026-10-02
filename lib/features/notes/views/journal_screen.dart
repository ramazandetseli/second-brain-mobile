import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../providers/summarizer_provider.dart';
import 'note_detail_screen.dart';
import 'widgets/daily/journal_date_bar.dart';
import 'widgets/daily/journal_prompt_card.dart';
import 'widgets/daily/journal_completed_card.dart';
import 'widgets/daily/text_journal_modal.dart';
import 'widgets/daily/streak_celebration_dialog.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _calculateCurrentStreak(List<NoteModel> journals) {
    if (journals.isEmpty) return 0;
    final entryDates = journals
        .map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (!entryDates.any((d) => _isSameDay(d, today) || _isSameDay(d, yesterday))) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = entryDates.any((d) => _isSameDay(d, today)) ? today : yesterday;
    while (entryDates.any((d) => _isSameDay(d, checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _handleSaveEntry({String? textContent, String? audioPath}) async {
    final now = DateTime.now();
    final noteId = now.millisecondsSinceEpoch.toString();

    final aiResult = await ref.read(summarizerServiceProvider).summarizeTranscript(
          textContent ?? 'Sesli günlük kaydı',
        );

    final journalNote = NoteModel(
      id: noteId,
      title: aiResult.title.isEmpty ? 'Günün Günlüğü' : aiResult.title,
      content: textContent ?? 'Sesli günlük analizi',
      summary: aiResult.summary,
      category: 'Günlük',
      audioPath: audioPath,
      createdAt: now,
    );

    await ref.read(notesProvider.notifier).addNote(journalNote);

    final updated = ref.read(notesProvider).where((n) => n.category == 'Günlük').toList();
    final newStreak = _calculateCurrentStreak(updated);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => JournalCelebrationDialog(
          streak: newStreak,
          onDismiss: () => setState(() {}),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allNotes = ref.watch(notesProvider);
    final journals = allNotes.where((n) => n.category == 'Günlük').toList();
    final streakCount = _calculateCurrentStreak(journals);

    final recordedDates = journals
        .map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet();

    final dayEntry = journals.cast<NoteModel?>().firstWhere(
          (n) => n != null && _isSameDay(n.createdAt, _selectedDate),
          orElse: () => null,
        );

    final isSelectedToday = _isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Dinamik Ambient Arka Plan Işıltısı (Karanlıkta mor tül, aydınlıkta pastel ton)
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            height: 360,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 0.9,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Ana Sayfa İçeriği
          SafeArea(
            child: Column(
              children: [
                // Minimalist ve Lüks AppBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Günlük',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSelectedToday ? 'Bugünün muhasebesi' : 'Geçmiş kayıt',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),

                      // Zarif Süreklilik Rozeti
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: streakCount > 0
                                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: streakCount > 0
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$streakCount gün',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: streakCount > 0
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // 3. Haftalık Akıllı Tarih Şeridi
                JournalDateBar(
                  selectedDate: _selectedDate,
                  recordedDates: recordedDates,
                  onDateSelected: (date) => setState(() => _selectedDate = date),
                ),

                const SizedBox(height: 16),

                // 4. Günlük Kartı (Kaydedilmiş veya Kayıt Bekleyen)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    child: dayEntry != null
                        ? JournalCompletedCard(
                            entry: dayEntry,
                            onTapDetail: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NoteDetailScreen(note: dayEntry),
                                ),
                              );
                            },
                          )
                        : JournalPromptCard(
                            isToday: isSelectedToday,
                            onVoiceTap: () {
                              // Ses kaydı akışı
                            },
                            onTextTap: () async {
                              final text = await showTextJournalModal(context);
                              if (text != null && text.isNotEmpty) {
                                _handleSaveEntry(textContent: text);
                              }
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}