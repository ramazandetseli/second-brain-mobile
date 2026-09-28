class NoteModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final String? summary;
  final String? audioPath;
  
  final DateTime createdAt;
  final bool isSynced;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'General',
    this.summary,
    this.audioPath,
    required this.createdAt,
    this.isSynced = false,
  });

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    String? summary,
    String? audioPath,
    bool clearAudioPath = false,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      summary: summary ?? this.summary,
      audioPath: clearAudioPath ? null : (audioPath ?? this.audioPath),
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // SQLite tablosuna yazarken
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'audio_path': audioPath,
      'created_at': createdAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0, // SQLite'ta boolean yerine 1/0
    };
  }

  // SQLite tablosundan okurken
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      summary: map['summary'] as String?,
      audioPath: map['audio_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }
}