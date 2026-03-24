import 'package:flutter/material.dart';
import '../models/health_profile_model.dart';

class HealthProfileProvider with ChangeNotifier {
  HealthProfileModel _profile = HealthProfileModel();

  HealthProfileModel get profile => _profile;

  void setProfile(HealthProfileModel profile) {
    _profile = profile;
    notifyListeners();
  }

  void toggleAllergy(String allergy) {
    final updatedList = List<String>.from(_profile.allergies);

    if (updatedList.contains(allergy)) {
      updatedList.remove(allergy);
    } else {
      updatedList.add(allergy);
    }

    _profile = _profile.copyWith(allergies: updatedList);
    notifyListeners();
  }

  void toggleDiet(String diet) {
    final updatedList = List<String>.from(_profile.dietaryPreferences);

    if (updatedList.contains(diet)) {
      updatedList.remove(diet);
    } else {
      updatedList.add(diet);
    }

    _profile = _profile.copyWith(dietaryPreferences: updatedList);
    notifyListeners();
  }

  void toggleCondition(String condition) {
    final updatedList = List<String>.from(_profile.healthConditions);

    if (updatedList.contains(condition)) {
      updatedList.remove(condition);
    } else {
      updatedList.add(condition);
    }

    _profile = _profile.copyWith(healthConditions: updatedList);
    notifyListeners();
  }

  void clearProfile() {
    _profile = HealthProfileModel();
    notifyListeners();
  }
}