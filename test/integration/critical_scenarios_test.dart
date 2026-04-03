import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:med_syn/core/router/app_router.dart';
import 'package:med_syn/core/router/app_routes.dart';
import 'package:med_syn/domain/models/education_article.dart';
import 'package:med_syn/domain/repositories/education_repository.dart';
import 'package:med_syn/features/admin/admin_education_screen.dart';
import 'package:med_syn/features/education/education_providers.dart';

void main() {
  ProviderContainer createContainer(EducationRepository repository) {
    final container = ProviderContainer(
      overrides: [educationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen<AsyncValue<void>>(
      adminEducationActionControllerProvider,
      (_, __) {},
    );
    return container;
  }

  group('Critical scenarios', () {
    test('admin route guard redirects non-admin users', () {
      final nonAdminResult = resolveAppRedirect(
        matchedLocation: AppRoutes.adminControl,
        isAuthenticated: true,
        isAdmin: false,
      );
      final adminResult = resolveAppRedirect(
        matchedLocation: AppRoutes.adminControl,
        isAuthenticated: true,
        isAdmin: true,
      );

      expect(nonAdminResult, AppRoutes.home);
      expect(adminResult, isNull);
    });

    test('admin is blocked from user schedule and report routes', () {
      final scheduleResult = resolveAppRedirect(
        matchedLocation: AppRoutes.schedule,
        isAuthenticated: true,
        isAdmin: true,
      );
      final reportResult = resolveAppRedirect(
        matchedLocation: AppRoutes.report,
        isAuthenticated: true,
        isAdmin: true,
      );

      expect(scheduleResult, AppRoutes.home);
      expect(reportResult, AppRoutes.home);
    });

    test('publishing from admin flow exposes article in user feed', () async {
      final repository = _InMemoryEducationRepository(
        initialArticles: [
          _article(
            id: 'article-1',
            title: 'Panduan Tidur Sehat',
            status: 'draft',
          ),
        ],
      );
      final container = createContainer(repository);

      expect(
        await container.read(publishedEducationArticlesProvider.future),
        isEmpty,
      );

      await container
          .read(adminEducationActionControllerProvider.notifier)
          .setStatus(articleId: 'article-1', status: 'published');

      final actionState = container.read(
        adminEducationActionControllerProvider,
      );
      expect(actionState.hasError, isFalse);

      container.invalidate(adminEducationArticlesProvider);
      container.invalidate(publishedEducationArticlesProvider);

      final adminArticles = await container.read(
        adminEducationArticlesProvider.future,
      );
      final publishedArticles = await container.read(
        publishedEducationArticlesProvider.future,
      );

      expect(adminArticles.single.status, 'published');
      expect(publishedArticles, hasLength(1));
      expect(publishedArticles.single.id, 'article-1');
      expect(publishedArticles.single.isPublished, isTrue);
    });

    test('create and unpublish flow keeps feed consistent', () async {
      final repository = _InMemoryEducationRepository(initialArticles: []);
      final container = createContainer(repository);

      await container
          .read(adminEducationActionControllerProvider.notifier)
          .createArticle(
            const EducationArticleInput(
              title: 'Kontrol Gula Darah Harian',
              slug: 'kontrol-gula-darah-harian',
              content: 'Isi artikel edukasi',
              summary: 'Ringkasan artikel',
              category: 'Diabetes',
            ),
          );

      container.invalidate(adminEducationArticlesProvider);
      final afterCreate = await container.read(
        adminEducationArticlesProvider.future,
      );
      expect(afterCreate, hasLength(1));

      final createdId = afterCreate.single.id;

      await container
          .read(adminEducationActionControllerProvider.notifier)
          .setStatus(articleId: createdId, status: 'published');

      container.invalidate(publishedEducationArticlesProvider);
      final afterPublish = await container.read(
        publishedEducationArticlesProvider.future,
      );
      expect(afterPublish, hasLength(1));

      await container
          .read(adminEducationActionControllerProvider.notifier)
          .setStatus(articleId: createdId, status: 'draft');

      container.invalidate(publishedEducationArticlesProvider);
      final afterUnpublish = await container.read(
        publishedEducationArticlesProvider.future,
      );
      expect(afterUnpublish, isEmpty);
    });
  });
}

class _InMemoryEducationRepository implements EducationRepository {
  _InMemoryEducationRepository({
    required List<EducationArticle> initialArticles,
  }) : _articles = List<EducationArticle>.from(initialArticles);

  List<EducationArticle> _articles;
  int _counter = 0;

  @override
  Future<void> createArticle(EducationArticleInput input) async {
    _counter += 1;
    final now = DateTime.now().toUtc();
    _articles = [
      EducationArticle(
        id: 'generated-$_counter',
        authorId: 'admin-local',
        title: input.title,
        slug: input.slug,
        summary: input.summary,
        content: input.content,
        coverUrl: input.coverUrl,
        category: input.category,
        status: 'draft',
        publishedAt: null,
        createdAt: now,
        updatedAt: now,
      ),
      ..._articles,
    ];
  }

  @override
  Future<void> deleteArticle(String articleId) async {
    _articles = _articles.where((article) => article.id != articleId).toList();
  }

  @override
  Future<List<EducationArticle>> getAllArticles() async {
    final sorted = List<EducationArticle>.from(_articles)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  @override
  Future<EducationArticle?> getArticleById(String articleId) async {
    for (final article in _articles) {
      if (article.id == articleId) {
        return article;
      }
    }
    return null;
  }

  @override
  Future<List<EducationArticle>> getPublishedArticles() async {
    final published =
        _articles.where((article) => article.status == 'published').toList()
          ..sort((a, b) {
            final left =
                a.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final right =
                b.publishedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });
    return published;
  }

  @override
  Future<void> setArticleStatus({
    required String articleId,
    required String status,
  }) async {
    final now = DateTime.now().toUtc();
    _articles = _articles.map((article) {
      if (article.id != articleId) {
        return article;
      }

      final publishedAt = status == 'published'
          ? (article.publishedAt ?? now)
          : null;

      return EducationArticle(
        id: article.id,
        authorId: article.authorId,
        title: article.title,
        slug: article.slug,
        summary: article.summary,
        content: article.content,
        coverUrl: article.coverUrl,
        category: article.category,
        status: status,
        publishedAt: publishedAt,
        createdAt: article.createdAt,
        updatedAt: now,
      );
    }).toList();
  }

  @override
  Future<void> updateArticle(
    String articleId,
    EducationArticleInput input,
  ) async {
    final now = DateTime.now().toUtc();
    _articles = _articles.map((article) {
      if (article.id != articleId) {
        return article;
      }

      return EducationArticle(
        id: article.id,
        authorId: article.authorId,
        title: input.title,
        slug: input.slug,
        summary: input.summary,
        content: input.content,
        coverUrl: input.coverUrl,
        category: input.category,
        status: article.status,
        publishedAt: article.publishedAt,
        createdAt: article.createdAt,
        updatedAt: now,
      );
    }).toList();
  }
}

EducationArticle _article({
  required String id,
  required String title,
  required String status,
}) {
  final now = DateTime(2026, 4, 3, 10, 0, 0);
  return EducationArticle(
    id: id,
    authorId: 'admin-seed',
    title: title,
    slug: id,
    summary: 'Ringkasan $title',
    content: 'Konten $title',
    status: status,
    publishedAt: status == 'published' ? now : null,
    createdAt: now,
    updatedAt: now,
  );
}
