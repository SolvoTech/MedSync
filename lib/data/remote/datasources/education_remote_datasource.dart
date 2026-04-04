import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/education_article.dart';
import '../supabase_client.dart';

class EducationRemoteDataSource {
  Future<List<EducationArticle>> getPublishedArticles() async {
    final client = _requireClient();
    final rows =
        await client
                .from('education_articles')
                .select()
                .eq('status', 'published')
                .order('published_at', ascending: false)
            as List<dynamic>;

    return rows
        .cast<Map<String, dynamic>>()
        .map(EducationArticle.fromMap)
        .toList();
  }

  Future<List<EducationArticle>> getAllArticles() async {
    final client = _requireClient();
    final rows =
        await client
                .from('education_articles')
                .select()
                .order('updated_at', ascending: false)
            as List<dynamic>;

    return rows
        .cast<Map<String, dynamic>>()
        .map(EducationArticle.fromMap)
        .toList();
  }

  Future<EducationArticle?> getArticleById(String articleId) async {
    final client = _requireClient();
    final row = await client
        .from('education_articles')
        .select()
        .eq('id', articleId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return EducationArticle.fromMap(row);
  }

  Future<void> createArticle(EducationArticleInput input) async {
    final client = _requireClient();
    final actorId = _requireCurrentUser(client).id;

    await client.from('education_articles').insert({
      'author_id': actorId,
      'title': input.title.trim(),
      'slug': input.slug.trim(),
      'summary': _optional(input.summary),
      'content': input.content.trim(),
      'cover_url': _optional(input.coverUrl),
      'category': _optional(input.category),
      'status': 'draft',
    });

    await _insertAuditLog(
      client,
      action: 'create_education_article',
      metadata: {'slug': input.slug, 'title': input.title},
    );
  }

  Future<void> updateArticle(
    String articleId,
    EducationArticleInput input,
  ) async {
    final client = _requireClient();
    _requireCurrentUser(client);

    await client
        .from('education_articles')
        .update({
          'title': input.title.trim(),
          'slug': input.slug.trim(),
          'summary': _optional(input.summary),
          'content': input.content.trim(),
          'cover_url': _optional(input.coverUrl),
          'category': _optional(input.category),
        })
        .eq('id', articleId);

    await _insertAuditLog(
      client,
      action: 'update_education_article',
      metadata: {'article_id': articleId, 'slug': input.slug},
    );
  }

  Future<void> setArticleStatus({
    required String articleId,
    required String status,
  }) async {
    final client = _requireClient();
    _requireCurrentUser(client);

    await client
        .from('education_articles')
        .update({'status': status})
        .eq('id', articleId);

    await _insertAuditLog(
      client,
      action: status == 'published'
          ? 'publish_education_article'
          : 'unpublish_education_article',
      metadata: {'article_id': articleId, 'status': status},
    );
  }

  Future<void> deleteArticle(String articleId) async {
    final client = _requireClient();
    _requireCurrentUser(client);

    await client.from('education_articles').delete().eq('id', articleId);

    await _insertAuditLog(
      client,
      action: 'delete_education_article',
      metadata: {'article_id': articleId},
    );
  }

  SupabaseClient _requireClient() {
    final client = SupabaseClientRef.maybeClient;
    if (client == null) {
      throw Exception('Supabase belum diinisialisasi.');
    }
    return client;
  }

  User _requireCurrentUser(SupabaseClient client) {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Anda harus login terlebih dahulu.');
    }
    return user;
  }

  String? _optional(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  Future<void> _insertAuditLog(
    SupabaseClient client, {
    required String action,
    required Map<String, dynamic> metadata,
  }) async {
    final actorId = client.auth.currentUser?.id;

    try {
      await client.rpc(
        'admin_insert_audit_log',
        params: {
          'action_name': action,
          'target_user_id': null,
          'metadata': metadata,
        },
      );
      return;
    } catch (_) {
      // Best-effort logging: CRUD should still succeed even if RPC is missing.
    }

    if (actorId == null) {
      return;
    }

    try {
      await client.from('admin_audit_logs').insert({
        'actor_id': actorId,
        'target_user_id': null,
        'action': action,
        'metadata': metadata,
      });
    } catch (_) {
      // Ignore audit sink failures to avoid blocking main CRUD operations.
    }
  }
}
