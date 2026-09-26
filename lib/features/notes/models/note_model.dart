class NoteModel {
  final String id;
  final String title;
  final String content;
  final String? audioPath;
  final DateTime createdAt;
  final bool isSynced;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.audioPath,
    required this.createdAt,
    required this.isSynced,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'audioPath': audioPath,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      audioPath: map['audioPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isSynced: (map['isSynced'] as int) == 1,
    );
  }

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? audioPath,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
