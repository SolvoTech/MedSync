import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_syn/domain/models/education_article.dart';
import 'package:med_syn/domain/repositories/education_repository.dart';
import 'package:med_syn/features/education/education_feed_screen.dart';
import 'package:med_syn/features/education/education_providers.dart';

void main() {
  EducationArticle article({
    required String id,
    required String title,
    String? summary,
    String? category,
  }) {
    final now = DateTime(2026, 4, 3, 10, 0, 0);
    return EducationArticle(
      id: id,
      authorId: 'admin-1',
      title: title,
      slug: id,
      summary: summary,
      content: 'Content',
      category: category,
      status: 'published',
      publishedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget buildSubject(EducationRepository repository) {
    return ProviderScope(
      overrides: [educationRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: EducationFeedScreen()),
    );
  }

  testWidgets('shows article list when published content exists', (
    WidgetTester tester,
  ) async {
    final repository = _FakeEducationRepository(
      publishedArticles: [
        article(
          id: 'a-1',
          title: 'Panduan Diet Seimbang',
          summary: 'Mulai dari porsi kecil dan konsisten.',
          category: 'Nutrisi',
        ),
      ],
    );

    await tester.pumpWidget(buildSubject(repository));
    await tester.pumpAndSettle();

    expect(find.text('Edukasi Kesehatan'), findsOneWidget);
    expect(find.text('Panduan Diet Seimbang'), findsOneWidget);
    expect(find.text('Nutrisi'), findsOneWidget);
  });

  testWidgets('shows empty state when no article is available', (
    WidgetTester tester,
  ) async {
    final repository = _FakeEducationRepository(publishedArticles: const []);

    await tester.pumpWidget(buildSubject(repository));
    await tester.pumpAndSettle();

    expect(find.text('Artikel edukasi belum tersedia.'), findsOneWidget);
  });
}

class _FakeEducationRepository implements EducationRepository {
  _FakeEducationRepository({required this.publishedArticles});

  final List<EducationArticle> publishedArticles;

  @override
  Future<void> createArticle(EducationArticleInput input) async {}

  @override
  Future<void> deleteArticle(String articleId) async {}

  @override
  Future<List<EducationArticle>> getAllArticles() async {
    return publishedArticles;
  }

  @override
  Future<EducationArticle?> getArticleById(String articleId) async {
    for (final article in publishedArticles) {
      if (article.id == articleId) {
        return article;
      }
    }
    return null;
  }

  @override
  Future<List<EducationArticle>> getPublishedArticles() async {
    return publishedArticles;
  }

  @override
  Future<void> setArticleStatus({
    required String articleId,
    required String status,
  }) async {}

  @override
  Future<void> updateArticle(
    String articleId,
    EducationArticleInput input,
  ) async {}
}
