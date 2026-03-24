import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/health_profile_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_spacing.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/common/selectable_chip.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProv = context.read<UserProvider>();
      if (userProv.isAuthenticated) {
        context.read<HealthProfileProvider>().setProfile(userProv.healthProfile);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HealthProfileProvider>(context);

    final allergies = [
      "Nuts",
      "Dairy",
      "Gluten",
      "Soy",
      "Egg",
      "Shellfish",
      "Artificial Colors",
    ];

    final diets = [
      "Vegan",
      "Vegetarian",
      "Keto",
      "Halal",
      "Jain",
      "Sugar-Free",
    ];

    final conditions = [
      "Diabetes",
      "Lactose Intolerance",
      "High Blood Pressure",
      "Heart Condition",
    ];

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Health Profile")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    /// Header
                    const Text(
                      "Personalize Your Safety Analysis",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Select your allergies and preferences to get accurate warnings.",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    /// Allergies Section
                    const Text(
                      "Allergies",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      children: allergies.map((item) {
                        return SelectableChip(
                          label: item,
                          isSelected: provider.profile.allergies.contains(item),
                          onTap: () => provider.toggleAllergy(item),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    /// Dietary Preferences
                    const Text(
                      "Dietary Preferences",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      children: diets.map((item) {
                        return SelectableChip(
                          label: item,
                          isSelected: provider.profile.dietaryPreferences
                              .contains(item),
                          onTap: () => provider.toggleDiet(item),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    /// Health Conditions
                    const Text(
                      "Health Conditions (Optional)",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      children: conditions.map((item) {
                        return SelectableChip(
                          label: item,
                          isSelected: provider.profile.healthConditions
                              .contains(item),
                          onTap: () => provider.toggleCondition(item),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              /// Bottom Buttons
              Column(
                children: [
                  PrimaryButton(
                    text: "Save & Continue",
                    onPressed: () {
                      // Sync health profile to Firestore if user is signed in
                      final userProv = context.read<UserProvider>();
                      if (userProv.isAuthenticated) {
                        userProv.updateHealthProfileLocally(provider.profile);
                      }
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    child: const Text("Skip for Now"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
