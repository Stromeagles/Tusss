import 'dart:convert';
import 'package:flutter/material.dart';

/// Tek bir kullanıcı koleksiyonu / klasörü
class CardCollection {
  final String id;
  final String name;
  final String emoji;
  final int colorValue; // Color.value
  final List<String> cardIds; // Flashcard + ClinicalCase ID'leri karışık
  final DateTime createdAt;
  final DateTime updatedAt;

  const CardCollection({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.cardIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Color get color => Color(colorValue);

  CardCollection copyWith({
    String? name,
    String? emoji,
    int? colorValue,
    List<String>? cardIds,
    DateTime? updatedAt,
  }) {
    return CardCollection(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      cardIds: cardIds ?? this.cardIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'colorValue': colorValue,
        'cardIds': cardIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CardCollection.fromJson(Map<String, dynamic> json) => CardCollection(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        colorValue: (json['colorValue'] as num).toInt(),
        cardIds: List<String>.from(json['cardIds'] as List),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  static String encodeList(List<CardCollection> list) =>
      json.encode(list.map((c) => c.toJson()).toList());

  static List<CardCollection> decodeList(String source) {
    final decoded = json.decode(source) as List;
    return decoded
        .map((e) => CardCollection.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Predefined renk + emoji seçenekleri
class CollectionPresets {
  static const colors = [
    Color(0xFF00D4FF), // cyan
    Color(0xFFA371F7), // violet
    Color(0xFFF78166), // coral
    Color(0xFF4CAF50), // green
    Color(0xFFFF9800), // orange
    Color(0xFFE91E63), // pink
    Color(0xFF2196F3), // blue
    Color(0xFF9C27B0), // purple
  ];

  static const emojis = [
    '📚', '🧠', '🔬', '💉', '🩺', '⚗️', '🎯', '⭐',
    '🏆', '💊', '🦠', '🫀', '🫁', '🩻', '🧬', '📋',
  ];
}
