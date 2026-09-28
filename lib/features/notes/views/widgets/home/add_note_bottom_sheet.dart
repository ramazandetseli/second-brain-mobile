import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:second_brain/features/notes/providers/notes_provider.dart';

class AddNoteBottomSheet extends ConsumerStatefulWidget {
  const AddNoteBottomSheet({super.key});

  @override
  ConsumerState<AddNoteBottomSheet> createState() => _AddNoteBottomSheetState();
}

class _AddNoteBottomSheetState extends ConsumerState<AddNoteBottomSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _customCategoryController = TextEditingController();

  final List<String> _predefinedCategories = [
    'Genel',
    'Fikirler',
    'Projeler',
    'İş',
    'Kişisel',
  ];

  late String _selectedCategory;
  bool _isCustomCategory = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _predefinedCategories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not içeriği boş olamaz.')),
      );
      return;
    }

    final finalCategory = _isCustomCategory
        ? (_customCategoryController.text.trim().isEmpty
            ? 'Genel'
            : _customCategoryController.text.trim())
        : _selectedCategory;

    setState(() => _isSaving = true);
    try {
      await ref.read(notesProvider.notifier).addTextNote(
            title: _titleController.text,
            content: content,
            category: finalCategory,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yeni Not',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Kategori Çipleri
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._predefinedCategories.map((cat) {
                    final isSelected = !_isCustomCategory && _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('#$cat'),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _isCustomCategory = false;
                            _selectedCategory = cat;
                          });
                        },
                        selectedColor: theme.colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    );
                  }),
                  ChoiceChip(
                    label: const Text('+ Özel'),
                    selected: _isCustomCategory,
                    onSelected: (_) {
                      setState(() => _isCustomCategory = true);
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _isCustomCategory ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            if (_isCustomCategory) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customCategoryController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Yeni konu adı (örn: Seyahat)',
                  prefixText: '#',
                  isDense: true,
                ),
              ),
            ],

            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Başlık (İsteğe bağlı)',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            const Divider(),
            TextField(
              controller: _contentController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'Aklındakileri yaz...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveNote,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_isSaving ? 'Kaydediliyor...' : 'Notu Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}