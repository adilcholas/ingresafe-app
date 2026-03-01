import 'package:flutter/material.dart';
import '../models/health_profile_model.dart';

class HealthProfileProvider with ChangeNotifier {
  HealthProfileModel _profile = HealthProfileModel();

  HealthProfileModel get profile => _profile;

  void toggleAllergy(String allergy) {
    if (_profile.allergies.contains(allergy)) {
      _profile.allergies.remove(allergy);
    } else {
      _profile.allergies.add(allergy);
    }
    notifyListeners();
  }

  void toggleDiet(String diet) {
    if (_profile.dietaryPreferences.contains(diet)) {
      _profile.dietaryPreferences.remove(diet);
    } else {
      _profile.dietaryPreferences.add(diet);
    }
    notifyListeners();
  }

  void toggleCondition(String condition) {
    if (_profile.healthConditions.contains(condition)) {
      _profile.healthConditions.remove(condition);
    } else {
      _profile.healthConditions.add(condition);
    }
    notifyListeners();
  }

  void clearProfile() {
    _profile = HealthProfileModel();
    notifyListeners();
  }
}