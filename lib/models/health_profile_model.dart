class HealthProfileModel {
  List<String> allergies;
  List<String> dietaryPreferences;
  List<String> healthConditions;

  HealthProfileModel({
    this.allergies = const [],
    this.dietaryPreferences = const [],
    this.healthConditions = const [],
  });
}