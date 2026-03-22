class HealthProfileModel {
  final List<String> allergies;
  final List<String> dietaryPreferences;
  final List<String> healthConditions;

  HealthProfileModel({
    List<String>? allergies,
    List<String>? dietaryPreferences,
    List<String>? healthConditions,
  }) : allergies = allergies ?? [],
       dietaryPreferences = dietaryPreferences ?? [],
       healthConditions = healthConditions ?? [];

  HealthProfileModel copyWith({
    List<String>? allergies,
    List<String>? dietaryPreferences,
    List<String>? healthConditions,
  }) {
    return HealthProfileModel(
      allergies: allergies ?? this.allergies,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      healthConditions: healthConditions ?? this.healthConditions,
    );
  }
}
