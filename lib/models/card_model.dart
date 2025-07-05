import 'package:json_annotation/json_annotation.dart';

part 'card_model.g.dart';

@JsonSerializable()
class CardModel {
  final int? id;
  final String title;
  final String content; // Rich text content as JSON string
  final String? imagePath;
  final String? drawingPath;
  final DateTime createdAt;
  final DateTime lastReviewed;
  final int reviewCount;
  final int position; // Position in the queue

  CardModel({
    this.id,
    required this.title,
    required this.content,
    this.imagePath,
    this.drawingPath,
    required this.createdAt,
    required this.lastReviewed,
    this.reviewCount = 0,
    required this.position,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) =>
      _$CardModelFromJson(json);

  Map<String, dynamic> toJson() => _$CardModelToJson(this);

  // Create a copy with updated fields
  CardModel copyWith({
    int? id,
    String? title,
    String? content,
    String? imagePath,
    String? drawingPath,
    DateTime? createdAt,
    DateTime? lastReviewed,
    int? reviewCount,
    int? position,
  }) {
    return CardModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      drawingPath: drawingPath ?? this.drawingPath,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      position: position ?? this.position,
    );
  }

  // Convert to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imagePath': imagePath,
      'drawingPath': drawingPath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastReviewed': lastReviewed.millisecondsSinceEpoch,
      'reviewCount': reviewCount,
      'position': position,
    };
  }

  // Create from Map for database operations
  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      imagePath: map['imagePath'],
      drawingPath: map['drawingPath'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      lastReviewed: DateTime.fromMillisecondsSinceEpoch(map['lastReviewed']),
      reviewCount: map['reviewCount'] ?? 0,
      position: map['position'],
    );
  }
}

