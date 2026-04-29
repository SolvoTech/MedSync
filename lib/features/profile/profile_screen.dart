import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_gradients.dart';
import '../../core/router/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/image_cache_service.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../data/remote/datasources/profile_remote_datasource.dart';
import '../../domain/models/user_profile.dart';
import '../auth/auth_controller.dart';
import '../static_pages/about_screen.dart';
import '../static_pages/help_support_screen.dart';
import '../static_pages/privacy_policy_screen.dart';
import '../static_pages/terms_screen.dart';
import 'appearance/appearance_screen.dart';
import 'care_persons/care_person_list_screen.dart';
import 'change_password/change_password_screen.dart';
import 'data_management/data_management_screen.dart';
import 'edit_avatar/edit_avatar_screen.dart';
import 'edit_profile/edit_profile_screen.dart';
import 'notification_settings/notification_settings_screen.dart';

final profileDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource();
});

final authUserIdProvider = StreamProvider.autoDispose<String?>((ref) async* {
  final client = Supabase.instance.client;

  yield client.auth.currentUser?.id;
  yield* client.auth.onAuthStateChange
      .map((event) => event.session?.user.id)
      .distinct();
});

final _profileByUserIdProvider = FutureProvider.autoDispose
    .family<UserProfile?, String>((ref, userId) async {
      return ref.read(profileDataSourceProvider).getProfileById(userId);
    });

final currentProfileProvider = FutureProvider.autoDispose<UserProfile?>((
  ref,
) async {
  final authUserId = ref.watch(authUserIdProvider).valueOrNull;
  if (authUserId == null || authUserId.isEmpty) {
    return null;
  }

  return ref.watch(_profileByUserIdProvider(authUserId).future);
});

bool _isGenericDisplayName(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized == 'administrator' ||
      normalized == 'admin' ||
      normalized == 'pengguna' ||
      normalized == 'user';
}

String _formatIdentifierAsName(String value) {
  final cleaned = value.trim().replaceAll(RegExp(r'[_\-.]+'), ' ');
  if (cleaned.isEmpty) {
    return value.trim();
  }

  final words = cleaned
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .toList();

  return words.join(' ');
}

String? _usernameFromEmail(String? email) {
  if (email == null) {
    return null;
  }

  final normalized = email.trim();
  if (normalized.isEmpty || !normalized.contains('@')) {
    return null;
  }

  final localPart = normalized.split('@').first.trim();
  if (localPart.isEmpty) {
    return null;
  }

  return localPart;
}

String _resolveDisplayName({
  required UserProfile? profile,
  required User? user,
}) {
  final fullName = profile?.fullName.trim();
  if (fullName != null &&
      fullName.isNotEmpty &&
      !_isGenericDisplayName(fullName)) {
    return fullName;
  }

  final profileUsername = profile?.username?.trim();
  if (profileUsername != null && profileUsername.isNotEmpty) {
    return _formatIdentifierAsName(profileUsername);
  }

  final metadataName = (user?.userMetadata?['full_name'] as String?)?.trim();
  if (metadataName != null &&
      metadataName.isNotEmpty &&
      !_isGenericDisplayName(metadataName)) {
    return metadataName;
  }

  final emailUsername =
      _usernameFromEmail(profile?.internalEmail) ??
      _usernameFromEmail(user?.email);
  if (emailUsername != null) {
    return _formatIdentifierAsName(emailUsername);
  }

  return AppStrings.tr('User', 'Pengguna');
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authUserIdProvider);

    final profileAsync = ref.watch(currentProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final user = Supabase.instance.client.auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = profileAsync.asData?.value?.role == 'admin';
    final displayName = _resolveDisplayName(
      profile: profileAsync.asData?.value,
      user: user,
    );
    final compact = MediaQuery.sizeOf(context).width < 340;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                height: compact ? 160 : 170,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryFor(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 20,
                      8,
                      compact ? 16 : 20,
                      0,
                    ),
                    child: Text(
                      AppStrings.profileTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: compact ? 100 : 106,
                left: compact ? 16 : 20,
                right: compact ? 16 : 20,
                child: Container(
                  padding: EdgeInsets.all(compact ? 12 : 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(
                                0xFF0F1419,
                              ).withValues(alpha: 0.05),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                    border: isDark
                        ? Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditAvatarScreen(),
                            ),
                          );
                          if (updated == true) {
                            await ImageCacheService.clearAll();
                            ref.invalidate(currentProfileProvider);
                          }
                        },
                        borderRadius: BorderRadius.circular(40),
                        child: profileAsync.when(
                          data: (profile) => AppAvatar(
                            size: compact ? 56 : 64,
                            imageUrl: profile?.avatarUrl,
                            name: displayName,
                            showRing: true,
                          ),
                          loading: () => CircleAvatar(
                            radius: compact ? 28 : 32,
                            backgroundColor: colorScheme.primaryContainer,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          error: (_, _) => AppAvatar(
                            size: compact ? 56 : 64,
                            name: displayName,
                            showRing: true,
                          ),
                        ),
                      ),
                      SizedBox(width: compact ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            profileAsync.when(
                              data: (profile) => Text(
                                _resolveDisplayName(
                                  profile: profile,
                                  user: user,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              loading: () => Text(displayName),
                              error: (_, _) => Text(displayName),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 52 : 56),

          // Menu sections
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account section
                _SectionHeader(title: AppStrings.tr('ACCOUNT', 'AKUN')),
                const SizedBox(height: 8),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.person_outline,
                        label: AppStrings.editProfile,
                        color: const Color(0xFF4299E1),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                      ),
                      _MenuDivider(),
                      _MenuItem(
                        icon: Icons.lock_outline,
                        label: AppStrings.changePassword,
                        color: const Color(0xFF805AD5),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        ),
                      ),
                      _MenuDivider(),
                      _MenuItem(
                        icon: Icons.photo_camera_outlined,
                        label: AppStrings.tr('Profile Photo', 'Foto Profil'),
                        color: const Color(0xFFED8936),
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditAvatarScreen(),
                            ),
                          );
                          if (updated == true) {
                            await ImageCacheService.clearAll();
                            ref.invalidate(currentProfileProvider);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Manage Members section
                _SectionHeader(
                  title: AppStrings.tr('MANAGE MEMBERS', 'KELOLA ANGGOTA'),
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.people_outline,
                        label: AppStrings.carePersons,
                        color: const Color(0xFF4299E1),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CarePersonListScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Preferences section
                _SectionHeader(
                  title: AppStrings.tr('PREFERENCES', 'PREFERENSI'),
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        label: AppStrings.notificationSettings,
                        color: const Color(0xFFE53E3E),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsScreen(),
                          ),
                        ),
                      ),
                      _MenuDivider(),
                      _MenuItem(
                        icon: Icons.palette_outlined,
                        label: AppStrings.appearance,
                        color: const Color(0xFF805AD5),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AppearanceScreen(),
                          ),
                        ),
                      ),
                      _MenuDivider(),
                      _MenuItem(
                        icon: Icons.storage_outlined,
                        label: AppStrings.dataManagement,
                        color: const Color(0xFF38A169),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DataManagementScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Info section
                _SectionHeader(
                  title: AppStrings.tr('INFORMATION', 'INFORMASI'),
                ),
                const SizedBox(height: 8),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (isAdmin != true) ...[
                        _MenuItem(
                          icon: Icons.menu_book_outlined,
                          label: AppStrings.tr(
                            'Health Articles',
                            'Edukasi Kesehatan',
                          ),
                          color: const Color(0xFF2B6CB0),
                          onTap: () => context.go(AppRoutes.education),
                        ),
                        _MenuDivider(),
                      ],
                      _MenuItem(
                        icon: Icons.notifications_none_rounded,
                        label: AppStrings.notificationTitle,
                        color: const Color(0xFFE53E3E),
                        onTap: () => context.push(AppRoutes.notifications),
                      ),
                      _MenuDivider(),
                      _MenuItem(
                        icon: Icons.info_outline,
                        label: AppStrings.about,
                        color: const Color(0xFF4299E1),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        ),
                      ),
                      _MenuDivider(),
                      _MenuItem(
                        icon: Icons.privacy_tip_outlined,
                        label: AppStrings.privacyPolicy,
                        color: const Color(0xFF38A169),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyScreen(),
                          ),
                        ),
                      ),
                      _MenuDivider(),
                      _MenuItem(
                        icon: Icons.description_outlined,
                        label: AppStrings.termsConditions,
                        color: const Color(0xFFED8936),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsScreen(),
                          ),
                        ),
                      ),
                      _MenuDivider(),
                      _MenuItem(
                        icon: Icons.help_outline,
                        label: AppStrings.helpSupport,
                        color: const Color(0xFF805AD5),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Logout
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.logout,
                        label: AppStrings.logout,
                        color: colorScheme.error,
                        isDestructive: true,
                        onTap: () async {
                          final shouldLogout = await AppDialog.showConfirm(
                            context,
                            title: AppStrings.tr(
                              'Sign out from your account?',
                              'Keluar dari akun?',
                            ),
                            message: AppStrings.tr(
                              'You will need to sign in again to access your data.',
                              'Anda perlu masuk kembali untuk mengakses data Anda.',
                            ),
                            confirmLabel: AppStrings.logout,
                            cancelLabel: AppStrings.cancel,
                            isDestructive: true,
                            icon: Icons.logout,
                          );

                          if (shouldLogout != true) {
                            return;
                          }

                          await ref
                              .read(authControllerProvider.notifier)
                              .signOut();
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
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTextColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: effectiveTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurface.withValues(alpha: 0.3),
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
