import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/supabase_client.dart';
import '../admin/admin_home_screen.dart';
import 'home_screen.dart';

final homeRoleProvider = FutureProvider.autoDispose<bool>((ref) async {
  final client = SupabaseClientRef.maybeClient;
  final user = client?.auth.currentUser;

  if (client == null || user == null) {
    return false;
  }

  try {
    final row = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return (row?['role'] as String?) == 'admin';
  } catch (_) {
    return false;
  }
});

class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleState = ref.watch(homeRoleProvider);

    return roleState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const HomeScreen(),
      data: (isAdmin) => isAdmin ? const AdminHomeScreen() : const HomeScreen(),
    );
  }
}
