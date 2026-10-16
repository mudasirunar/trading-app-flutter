import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Immutable model representing an authenticated user account.
class UserModel extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String token;
  final String accountType; // 'pro' | 'practice'
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.token,
    required this.accountType,
    required this.createdAt,
  });

  bool get isPro => accountType.toLowerCase() == 'pro';

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? token,
    String? accountType,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      token: token ?? this.token,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'token': token,
      'accountType': accountType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      token: map['token'] as String? ?? '',
      accountType: map['accountType'] as String? ?? 'practice',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [id, email, displayName, token, accountType, createdAt];
}
