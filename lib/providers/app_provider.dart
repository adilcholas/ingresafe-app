import 'package:flutter/material.dart';

class AppProvider with ChangeNotifier {
  bool isProfileCompleted = false;

  void completeProfile() {
    isProfileCompleted = true;
    notifyListeners();
  }
}
