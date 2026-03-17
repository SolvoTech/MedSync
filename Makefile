.PHONY: check test size analyze

check: size analyze test

size:
	bash tooling/check_dart_file_size.sh 500 lib

analyze:
	flutter analyze

test:
	flutter test test/widget_test.dart
