class Exercise {
  final String id;
  final String name;
  final String category; // Pecho, Espalda, Piernas, Hombros, Brazos, Core, Cardio, TRX, Otros
  final String? equipment;
  final bool isCustom;
  final String trackingType; // 'reps', 'time' (seconds), or 'cardio' (minutes & incline/resistance)
  final String? notes;
  final String? localGifAsset;
  final String? hdGifUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.equipment,
    this.isCustom = false,
    this.trackingType = 'reps',
    this.notes,
    this.localGifAsset,
    this.hdGifUrl,
  });

  bool get isTimeBased => trackingType == 'time';
  bool get isCardio => trackingType == 'cardio';
  bool get isBodyweight =>
      category == 'Core' ||
      category == 'TRX' ||
      equipment == 'Peso corporal' ||
      equipment == 'TRX / Suspensión' ||
      equipment == 'Exterior';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'equipment': equipment,
      'is_custom': isCustom ? 1 : 0,
      'tracking_type': trackingType,
      'notes': notes,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      equipment: map['equipment'] as String?,
      isCustom: (map['is_custom'] as int?) == 1,
      trackingType: map['tracking_type'] as String? ?? 'reps',
      notes: map['notes'] as String?,
    );
  }
}
