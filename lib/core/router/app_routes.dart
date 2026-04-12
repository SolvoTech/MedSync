class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboardingProfile = '/onboarding-profile';
  static const String onboarding = '/onboarding';

  static const String home = '/home';
  static const String schedule = '/schedule';
  static const String report = '/report';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String healthConnect = '/health-connect';
  static const String adminControl = '/admin-control';
  static const String adminUserActivityBase = '/admin-control/user';
  static const String adminEducation = '/admin-education';
  static const String education = '/education';

  static String adminUserActivity(String userId) =>
      '$adminUserActivityBase/$userId';
  static String educationDetail(String articleId) => '/education/$articleId';
}
