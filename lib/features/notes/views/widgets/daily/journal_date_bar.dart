import 'package:flutter/material.dart';

class JournalDateBar extends StatefulWidget {
  final DateTime selectedDate;
  final Set<DateTime> recordedDates;
  final ValueChanged<DateTime> onDateSelected;

  const JournalDateBar({
    super.key,
    required this.selectedDate,
    required this.recordedDates,
    required this.onDateSelected,
  });

  @override
  State<JournalDateBar> createState() => _JournalDateBarState();
}

class _JournalDateBarState extends State<JournalDateBar> {
  late DateTime _displayedWeekMonday;

  @override
  void initState() {
    super.initState();
    _displayedWeekMonday = _getMondayOf(widget.selectedDate);
  }

  @override
  void didUpdateWidget(covariant JournalDateBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameDay(oldWidget.selectedDate, widget.selectedDate)) {
      final newMonday = _getMondayOf(widget.selectedDate);
      if (!_isSameDay(newMonday, _displayedWeekMonday)) {
        setState(() {
          _displayedWeekMonday = newMonday;
        });
      }
    }
  }

  // Verilen tarihin ait olduğu haftanın Pazartesi gününü bulur
  DateTime _getMondayOf(DateTime date) {
    final clean = DateTime(date.year, date.month, date.day);
    return clean.subtract(Duration(days: clean.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }

  void _previousWeek() {
    setState(() {
      _displayedWeekMonday = _displayedWeekMonday.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _displayedWeekMonday = _displayedWeekMonday.add(const Duration(days: 7));
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    widget.onDateSelected(today);
    setState(() {
      _displayedWeekMonday = _getMondayOf(today);
    });
  }

  Future<void> _openDatePicker() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (picked != null) {
      final cleanPicked = DateTime(picked.year, picked.month, picked.day);
      widget.onDateSelected(cleanPicked);
      setState(() {
        _displayedWeekMonday = _getMondayOf(cleanPicked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Aktif haftanın 7 gününü hesapla (Pazartesi'den Pazar'a)
    final weekDays = List.generate(7, (index) {
      return _displayedWeekMonday.add(Duration(days: index));
    });

    // ISO-8601: Haftanın temsil ettiği ayı belirlemek için Perşembe gününün ayına bakılır
    final midWeekDay = weekDays[3];
    final isCurrentWeek = weekDays.any((d) => _isSameDay(d, today));

    return Column(
      children: [
        // 1. Üst Kontrol Barı: [ < ]  Ekim 2026  [ > ]  + Bugüne Dön & Takvim Butonu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              // Önceki Hafta Oku
              IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _previousWeek,
              ),

              const SizedBox(width: 4),

              // Ay ve Yıl Başlığı
              Text(
                '${_getMonthName(midWeekDay.month)} ${midWeekDay.year}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(width: 4),

              // Sonraki Hafta Oku
              IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _nextWeek,
              ),

              const Spacer(),

              // Eğer bu haftada değilsek 'Bugüne Dön' butonu belirir
              if (!isCurrentWeek) ...[
                GestureDetector(
                  onTap: _goToToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Bugün',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Klasik Aylık Izgara Takvimini Açan Buton
              IconButton.filledTonal(
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.calendar_month_rounded),
                onPressed: _openDatePicker,
              ),
            ],
          ),
        ),

        // 2. 7 Günlük Sabit Izgara Şeridi (Kaydırma jesti destekli)
        GestureDetector(
          onHorizontalDragEnd: (details) {
            // Sağa/Sola parmak kaydırarak hafta değiştirme (Swipe)
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -200) {
                _nextWeek(); // Sola kaydırınca sonraki hafta
              } else if (details.primaryVelocity! > 200) {
                _previousWeek(); // Sağa kaydırınca önceki hafta
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weekDays.map((date) {
                final isSelected = _isSameDay(date, widget.selectedDate);
                final isDayToday = _isSameDay(date, today);
                final hasEntry = widget.recordedDates.any((d) => _isSameDay(d, date));

                const dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                final dayLabel = dayNames[date.weekday - 1];

                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onDateSelected(date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : isDayToday
                                ? theme.colorScheme.surfaceContainerHighest
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Günlük Girişi Varlık Noktası
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasEntry
                                  ? (isSelected ? Colors.white : const Color(0xFF10B981))
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}