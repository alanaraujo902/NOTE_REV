class CardModel {
  final int? id;
  final String title;
  final String content; // Conteúdo em Markdown
  final int deckId;
  final String? imagePath; // Caminho para imagem inserida
  final String? audioPath; // Caminho para arquivo de áudio
  final String? drawingPath; // Caminho para desenho salvo como PNG
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastViewed; // Última vez que foi visualizado
  final int viewCount; // Número de vezes visualizado

  CardModel({
    this.id,
    required this.title,
    required this.content,
    required this.deckId,
    this.imagePath,
    this.audioPath,
    this.drawingPath,
    required this.createdAt,
    required this.updatedAt,
    this.lastViewed,
    this.viewCount = 0,
  });

  // Construtor para criar um novo cartão
  factory CardModel.create({
    required String title,
    required int deckId,
    String content = '',
  }) {
    final now = DateTime.now();
    return CardModel(
      title: title,
      content: content,
      deckId: deckId,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Converter para Map para salvar no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'deck_id': deckId,
      'image_path': imagePath,
      'audio_path': audioPath,
      'drawing_path': drawingPath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'last_viewed': lastViewed?.millisecondsSinceEpoch,
      'view_count': viewCount,
    };
  }

  // Criar instância a partir do Map do banco de dados
  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      deckId: map['deck_id'],
      imagePath: map['image_path'],
      audioPath: map['audio_path'],
      drawingPath: map['drawing_path'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      lastViewed: map['last_viewed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_viewed'])
          : null,
      viewCount: map['view_count'] ?? 0,
    );
  }

  // Criar cópia com modificações
  CardModel copyWith({
    int? id,
    String? title,
    String? content,
    int? deckId,
    String? imagePath,
    String? audioPath,
    String? drawingPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastViewed,
    int? viewCount,
  }) {
    return CardModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      deckId: deckId ?? this.deckId,
      imagePath: imagePath ?? this.imagePath,
      audioPath: audioPath ?? this.audioPath,
      drawingPath: drawingPath ?? this.drawingPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastViewed: lastViewed ?? this.lastViewed,
      viewCount: viewCount ?? this.viewCount,
    );
  }

  // Marcar como visualizado
  CardModel markAsViewed() {
    return copyWith(
      lastViewed: DateTime.now(),
      viewCount: viewCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  // Verificar se tem mídia anexada
  bool get hasMedia => imagePath != null || audioPath != null;
  
  // Verificar se tem desenho
  bool get hasDrawing => drawingPath != null;

  @override
  String toString() {
    return 'CardModel{id: $id, title: $title, deckId: $deckId, viewCount: $viewCount}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          deckId == other.deckId;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ deckId.hashCode;
}

