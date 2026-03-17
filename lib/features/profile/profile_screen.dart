import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_strings.dart';
import '../../core/extensions/string_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../data/remote/datasources/profile_remote_datasource.dart';
import '../../domain/models/user_profile.dart';
import '../auth/auth_controller.dart';
import '../static_pages/about_screen.dart';
import '../static_pages/help_support_screen.dart';
import '../static_pages/privacy_policy_screen.dart';
import '../static_pages/terms_screen.dart';
import 'appearance/appearance_screen.dart';
import 'care_persons/care_person_list_screen.dart';
import 'change_email/change_email_screen.dart';
import 'change_password/change_password_screen.dart';
import 'data_management/data_management_screen.dart';
import 'edit_avatar/edit_avatar_screen.dart';
import 'edit_profile/edit_profile_screen.dart';
import 'notification_settings/notification_settings_screen.dart';

final profileDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource();
});

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  return ref.read(profileDataSourceProvider).getCurrentProfile();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + name + email header
          Center(
            child: Column(
              children: [
                InkWell(
                  onTap: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditAvatarScreen()),
                    );
                    if (updated == true) {
                      ref.invalidate(currentProfileProvider);
                    }
                  },
                  borderRadius: BorderRadius.circular(40),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primaryContainer,
                    child: profileAsync.when(
                      data: (profile) {
                        if (profile?.avatarUrl != null) {
                          return ClipOval(
                            child: Image.network(
                              profile!.avatarUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                        return Text(
                          (profile?.fullName ?? 'U').initials,
                          style: textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, _) => const Icon(Icons.person, size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                profileAsync.when(
                  data: (profile) => Text(
                    profile?.fullName ?? 'User',
                    style: textTheme.titleLarge,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const Text('User'),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Account section
          _SectionHeader(title: 'AKUN'),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.person_outline,
                  label: AppStrings.editProfile,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                const Divider(height: 1, indent: 56),
                _MenuItem(
                  icon: Icons.lock_outline,
                  label: AppStrings.changePassword,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                ),
                const Divider(height: 1, indent: 56),
                _MenuItem(
                  icon: Icons.email_outlined,
                  label: AppStrings.changeEmail,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangeEmailScreen())),
                ),
                const Divider(height: 1, indent: 56),
                _MenuItem(
                  icon: Icons.photo_camera_outlined,
                  label: 'Foto Profil',
                  onTap: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditAvatarScreen()),
                    );
                    if (updated == true) {
                      ref.invalidate(currentProfileProvider);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Manage Members section
          _SectionHeader(title: 'KELOLA ANGGOTA'),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.people_outline,
                  label: AppStrings.carePersons,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CarePersonListScreen())),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Preferences section
          _SectionHeader(title: 'PREFERENSI'),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: AppStrings.notificationSettings,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                ),
                const Divider(height: 1, indent: 56),
                _MenuItem(
                  icon: Icons.palette_outlined,
                  label: AppStrings.appearance,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceScreen())),
                ),
                const Divider(height: 1, indent: 56),
                _MenuItem(
                  icon: Icons.storage_outlined,
                  label: AppStrings.dataManagement,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataManagementScreen())),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info section
          _SectionHeader(title: 'INFORMASI'),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.info_outline,
                  label: AppStrings.about,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                ),
                const Divider(height: 1, indent: 56),
                _MenuItem(
                  icon: Icons.privacy_tip_outlined,
                  label: AppStrings.privacyPolicy,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                ),
                const Divider(height: 1, indent: 56),
                _MenuItem(
                  icon: Icons.description_outlined,
                  label: AppStrings.termsConditions,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
                ),
                const Divider(height: 1, indent: 56),
                _MenuItem(
                  icon: Icons.help_outline,
                  label: AppStrings.helpSupport,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Logout + Delete
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuItem(
                  icon: Icons.logout,
                  label: AppStrings.logout,
                  color: colorScheme.error,
                  onTap: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'v1.0.0',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(label, style: TextStyle(color: effectiveColor)),
      trailing: Icon(
        Icons.chevron_right,
        color: effectiveColor.withValues(alpha: 0.5),
      ),
      onTap: onTap,
    );
  }
}
