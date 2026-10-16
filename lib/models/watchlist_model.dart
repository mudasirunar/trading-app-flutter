import 'package:equatable/equatable.dart';

/// User-curated portfolio asset watchlist collection.
class WatchlistModel extends Equatable {
  const WatchlistModel({
    required this.id,
    required this.name,
    required this.symbols,
    this.isDefault = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<String> symbols;
  final bool isDefault;
  final DateTime createdAt;

  WatchlistModel copyWith({
    String? id,
    String? name,
    List<String>? symbols,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return WatchlistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      symbols: symbols ?? this.symbols,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbols': symbols,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WatchlistModel.fromJson(Map<String, dynamic> json) {
    return WatchlistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      symbols: (json['symbols'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, symbols, isDefault, createdAt];
}
