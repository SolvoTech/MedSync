import '../../../core/constants/app_strings.dart';

/// Data model for a single onboarding page.
class OnboardingPageModel {
  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final String icon; // asset path

  static List<OnboardingPageModel> get pages => [
    OnboardingPageModel(
      title: AppStrings.onboardingMedicationTitle,
      description: AppStrings.onboardingMedicationDescription,
      icon: 'assets/images/medsync_hero_medication.png',
    ),
    OnboardingPageModel(
      title: AppStrings.onboardingHealthTitle,
      description: AppStrings.onboardingHealthDescription,
      icon: 'assets/images/onboarding_2.png',
    ),
    OnboardingPageModel(
      title: AppStrings.onboardingReportTitle,
      description: AppStrings.onboardingReportDescription,
      icon: 'assets/images/onboarding_3.png',
    ),
  ];
}
