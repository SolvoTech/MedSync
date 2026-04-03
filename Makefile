.PHONY: check test test-critical release-gate size analyze db-refresh

check: size analyze test

size:
	bash tooling/check_dart_file_size.sh 500 lib

analyze:
	flutter analyze

test:
	flutter test

test-critical:
	flutter test test/core/router/app_router_test.dart
	flutter test test/features/auth/auth_controller_test.dart
	flutter test test/features/admin/admin_action_controller_test.dart
	flutter test test/integration/critical_scenarios_test.dart

release-gate: analyze test-critical

db-refresh:
	@command -v supabase >/dev/null || (echo "Supabase CLI belum terpasang" && exit 1)
	supabase db reset --linked --yes
