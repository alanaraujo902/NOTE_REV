class Deck {
  final int? id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Getter para compatibilidade
  String get name => title;

  Deck({
    this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  // Construtor para criar um novo baralho
  factory Deck.create(String title) {
    final now = DateTime.now();
    return Deck(
      title: title.isEmpty ? 'Baralho sem título' : title,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Converter para Map para salvar no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Criar instância a partir do Map do banco de dados
  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  // Criar cópia com modificações
  Deck copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Deck(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Deck{id: $id, title: $title, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Deck &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}

