import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_syn/domain/models/education_article.dart';
import 'package:med_syn/domain/repositories/education_repository.dart';
import 'package:med_syn/features/education/education_providers.dart';

void main() {
  EducationArticle article({
    required String id,
    required String status,
    DateTime? publishedAt,
  }) {
    final now = DateTime(2026, 4, 3, 10, 0, 0);
    return EducationArticle(
      id: id,
      authorId: 'admin-1',
      title: 'Article $id',
      slug: 'article-$id',
      summary: 'Summary $id',
      content: 'Content $id',
      status: status,
      publishedAt: publishedAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  ProviderContainer createContainer(EducationRepository repository) {
    final container = ProviderContainer(
      overrides: [educationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('education providers', () {
    test('publishedEducationArticlesProvider returns published data', () async {
      final repository = _FakeEducationRepository(
        publishedArticles: [
          article(
            id: 'pub-1',
            status: 'published',
            publishedAt: DateTime(2026, 4, 1),
          ),
        ],
        allArticles: [
          article(
            id: 'pub-1',
            status: 'published',
            publishedAt: DateTime(2026, 4, 1),
          ),
          article(id: 'draft-1', status: 'draft'),
        ],
      );
      final container = createContainer(repository);

      final result = await container.read(
        publishedEducationArticlesProvider.future,
      );

      expect(result, hasLength(1));
      expect(result.first.id, 'pub-1');
    });

    test('adminEducationArticlesProvider returns all data', () async {
      final repository = _FakeEducationRepository(
        publishedArticles: [
          article(
            id: 'pub-1',
            status: 'published',
            publishedAt: DateTime(2026, 4, 1),
          ),
        ],
        allArticles: [
          article(
            id: 'pub-1',
            status: 'published',
            publishedAt: DateTime(2026, 4, 1),
          ),
          article(id: 'draft-1', status: 'draft'),
        ],
      );
      final container = createContainer(repository);

      final result = await container.read(
        adminEducationArticlesProvider.future,
      );

      expect(result, hasLength(2));
    });

    test('educationArticleByIdProvider reads selected article', () async {
      final repository = _FakeEducationRepository(
        publishedArticles: [
          article(
            id: 'pub-1',
            status: 'published',
            publishedAt: DateTime(2026, 4, 1),
          ),
        ],
        allArticles: [
          article(
            id: 'pub-1',
            status: 'published',
            publishedAt: DateTime(2026, 4, 1),
          ),
          article(id: 'draft-1', status: 'draft'),
        ],
      );
      final container = createContainer(repository);

      final result = await container.read(
        educationArticleByIdProvider('draft-1').future,
      );

      expect(repository.lastRequestedId, 'draft-1');
      expect(result, isNotNull);
      expect(result!.id, 'draft-1');
    });
  });
}

class _FakeEducationRepository implements EducationRepository {
  _FakeEducationRepository({
    required this.publishedArticles,
    required this.allArticles,
  });

  final List<EducationArticle> publishedArticles;
  final List<EducationArticle> allArticles;
  String? lastRequestedId;

  @override
  Future<void> createArticle(EducationArticleInput input) async {}

  @override
  Future<void> deleteArticle(String articleId) async {}

  @override
  Future<List<EducationArticle>> getAllArticles() async {
    return allArticles;
  }

  @override
  Future<EducationArticle?> getArticleById(String articleId) async {
    lastRequestedId = articleId;
    for (final article in allArticles) {
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
