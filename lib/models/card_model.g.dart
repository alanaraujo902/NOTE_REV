// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardModel _$CardModelFromJson(Map<String, dynamic> json) => CardModel(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String,
      content: json['content'] as String,
      imagePath: json['imagePath'] as String?,
      drawingPath: json['drawingPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastReviewed: DateTime.parse(json['lastReviewed'] as String),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      position: (json['position'] as num).toInt(),
    );

Map<String, dynamic> _$CardModelToJson(CardModel instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'imagePath': instance.imagePath,
      'drawingPath': instance.drawingPath,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastReviewed': instance.lastReviewed.toIso8601String(),
      'reviewCount': instance.reviewCount,
      'position': instance.position,
    };
