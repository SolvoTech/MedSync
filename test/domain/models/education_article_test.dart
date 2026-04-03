import 'package:flutter_test/flutter_test.dart';
import 'package:med_syn/domain/models/education_article.dart';

void main() {
  group('EducationArticle.fromMap', () {
    test('parses map and marks published article', () {
      final article = EducationArticle.fromMap({
        'id': 'article-1',
        'author_id': 'admin-1',
        'title': 'Judul',
        'slug': 'judul',
        'summary': 'Ringkasan',
        'content': 'Konten',
        'cover_url': 'https://example.com/cover.png',
        'category': 'Nutrisi',
        'status': 'published',
        'published_at': '2026-04-03T10:00:00Z',
        'created_at': '2026-04-01T10:00:00Z',
        'updated_at': '2026-04-02T10:00:00Z',
      });

      expect(article.id, 'article-1');
      expect(article.isPublished, isTrue);
      expect(article.publishedAt, isNotNull);
      expect(
        article.updatedAt.toUtc().toIso8601String(),
        '2026-04-02T10:00:00.000Z',
      );
    });

    test('falls back updatedAt to createdAt when updated_at is missing', () {
      final article = EducationArticle.fromMap({
        'id': 'article-2',
        'author_id': 'admin-1',
        'title': 'Judul Draft',
        'slug': 'judul-draft',
        'content': 'Konten Draft',
        'status': 'draft',
        'created_at': '2026-04-01T10:00:00Z',
      });

      expect(article.isPublished, isFalse);
      expect(article.publishedAt, isNull);
      expect(
        article.updatedAt.toUtc().toIso8601String(),
        '2026-04-01T10:00:00.000Z',
      );
    });
  });
}
