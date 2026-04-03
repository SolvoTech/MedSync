class EducationArticle {
  const EducationArticle({
    required this.id,
    required this.authorId,
    required this.title,
    required this.slug,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.summary,
    this.coverUrl,
    this.category,
    this.publishedAt,
  });

  final String id;
  final String authorId;
  final String title;
  final String slug;
  final String? summary;
  final String content;
  final String? coverUrl;
  final String? category;
  final String status;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPublished => status == 'published';

  factory EducationArticle.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(String key, {DateTime? fallback}) {
      final raw = map[key];
      if (raw is String) {
        return DateTime.tryParse(raw) ?? (fallback ?? DateTime.now());
      }
      if (raw is DateTime) {
        return raw;
      }
      return fallback ?? DateTime.now();
    }

    DateTime? parseNullableDate(String key) {
      final raw = map[key];
      if (raw == null) {
        return null;
      }
      if (raw is String) {
        return DateTime.tryParse(raw);
      }
      if (raw is DateTime) {
        return raw;
      }
      return null;
    }

    return EducationArticle(
      id: map['id'] as String,
      authorId: map['author_id'] as String,
      title: map['title'] as String,
      slug: map['slug'] as String,
      summary: map['summary'] as String?,
      content: map['content'] as String,
      coverUrl: map['cover_url'] as String?,
      category: map['category'] as String?,
      status: (map['status'] as String?) ?? 'draft',
      publishedAt: parseNullableDate('published_at'),
      createdAt: parseDate('created_at'),
      updatedAt: parseDate('updated_at', fallback: parseDate('created_at')),
    );
  }
}

class EducationArticleInput {
  const EducationArticleInput({
    required this.title,
    required this.slug,
    required this.content,
    this.summary,
    this.coverUrl,
    this.category,
  });

  final String title;
  final String slug;
  final String content;
  final String? summary;
  final String? coverUrl;
  final String? category;
}
