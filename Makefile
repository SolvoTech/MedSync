.PHONY: check test size analyze db-refresh

check: size analyze test

size:
	bash tooling/check_dart_file_size.sh 500 lib

analyze:
	flutter analyze

test:
	flutter test test/widget_test.dart

db-refresh:
	@command -v supabase >/dev/null || (echo "Supabase CLI belum terpasang" && exit 1)
	supabase db reset --linked --yes
