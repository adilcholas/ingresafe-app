class IngredientModel {
  final String name;
  final String riskLevel; // Safe | Caution | Risky
  final String description;
  final String detailedExplanation;
  final String userImpact;
  final String regulatoryNote;

  /// Used for personalized health-profile matching
  final String? allergenKey;
  final String? conditionKey;

  IngredientModel({
    required this.name,
    required this.riskLevel,
    required this.description,
    required this.detailedExplanation,
    required this.userImpact,
    required this.regulatoryNote,
    this.allergenKey,
    this.conditionKey,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'riskLevel': riskLevel,
        'description': description,
        'detailedExplanation': detailedExplanation,
        'userImpact': userImpact,
        'regulatoryNote': regulatoryNote,
        'allergenKey': allergenKey,
        'conditionKey': conditionKey,
      };

  factory IngredientModel.fromMap(Map<String, dynamic> map) => IngredientModel(
        name: map['name'] as String? ?? '',
        riskLevel: map['riskLevel'] as String? ?? 'Caution',
        description: map['description'] as String? ?? '',
        detailedExplanation: map['detailedExplanation'] as String? ?? '',
        userImpact: map['userImpact'] as String? ?? '',
        regulatoryNote: map['regulatoryNote'] as String? ?? '',
        allergenKey: map['allergenKey'] as String?,
        conditionKey: map['conditionKey'] as String?,
      );
}
