class IngredientModel {
  final String name;
  final String riskLevel; // Safe, Caution, Risky
  final String description;
  final String detailedExplanation;
  final String userImpact;
  final String regulatoryNote;

  IngredientModel({
    required this.name,
    required this.riskLevel,
    required this.description,
    required this.detailedExplanation,
    required this.userImpact,
    required this.regulatoryNote,
  });
}