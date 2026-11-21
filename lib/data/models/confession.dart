import '../../core/utils/date_utils.dart';

/// Data model representing an effective confession event.
class Confession {
  final int? id;
  final DateTime date;
  final String parish;
  final String? notes;
  final DateTime createdAt;

  Confession({
    this.id,
    required this.date,
    required this.parish,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Normalized date without time components.
  DateTime get normalizedDate => RenovoDateUtils.normalizeDate(date);

  Confession copyWith({
    int? id,
    DateTime? date,
    String? parish,
    String? notes,
    DateTime? createdAt,
  }) {
    return Confession(
      id: id ?? this.id,
      date: date ?? this.date,
      parish: parish ?? this.parish,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': RenovoDateUtils.normalizeDate(date).toIso8601String(),
      'parish': parish.trim(),
      'notes': notes?.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Confession.fromMap(Map<String, dynamic> map) {
    return Confession(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      parish: map['parish'] as String,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Confession &&
        other.id == id &&
        RenovoDateUtils.isSameDay(other.date, date) &&
        other.parish == parish &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    final norm = RenovoDateUtils.normalizeDate(date);
    return Object.hash(id, norm.year, norm.month, norm.day, parish, notes);
  }
}
