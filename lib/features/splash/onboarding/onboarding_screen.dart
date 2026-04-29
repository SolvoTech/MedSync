import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/local/preferences/app_preferences.dart';
import 'onboarding_page_model.dart';

/// Onboarding carousel per spec §5.1.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < OnboardingPageModel.pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _onGetStarted();
    }
  }

  void _onGetStarted() async {
    await AppPreferences.setOnboardingDone(true);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pages = OnboardingPageModel.pages;
    final isLastPage = _currentPage == pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: TextButton(
                      onPressed: _onGetStarted,
                      child: Text(AppStrings.skip),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: pages.length,
                    itemBuilder: (context, i) {
                      final page = pages[i];
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final compactWidth =
                              MediaQuery.sizeOf(context).width < 340;
                          final compactHeight = constraints.maxHeight < 520;
                          final imageHeight = compactHeight
                              ? 128.0
                              : compactWidth
                              ? 160.0
                              : 220.0;

                          return SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: compactWidth ? 20 : 32,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    page.icon,
                                    height: imageHeight,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(height: compactHeight ? 24 : 40),
                                  Text(
                                    page.title,
                                    textAlign: TextAlign.center,
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    page.description,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.55,
                                      ),
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Builder(
                  builder: (context) {
                    final compact = MediaQuery.sizeOf(context).width < 340;
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 20 : 32,
                        0,
                        compact ? 20 : 32,
                        compact ? 24 : 40,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(pages.length, (i) {
                              final isActive = i == _currentPage;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: isActive ? 26 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? colorScheme.primary
                                      : colorScheme.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: compact ? 24 : 32),
                          AppButton(
                            label: isLastPage
                                ? AppStrings.startNow
                                : AppStrings.next,
                            onPressed: _onNext,
                            isFullWidth: true,
                            useGradient: true,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
