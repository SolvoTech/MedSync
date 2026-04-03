import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/user_error_message.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_skeleton.dart';
import '../../domain/models/education_article.dart';
import '../education/education_providers.dart';
import 'widgets/admin_ui.dart';

final adminEducationActionControllerProvider =
    AutoDisposeNotifierProvider<
      AdminEducationActionController,
      AsyncValue<void>
    >(AdminEducationActionController.new);

class AdminEducationActionController
    extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> createArticle(EducationArticleInput input) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(educationRepositoryProvider).createArticle(input);
    });
  }

  Future<void> updateArticle(
    String articleId,
    EducationArticleInput input,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(educationRepositoryProvider)
          .updateArticle(articleId, input);
    });
  }

  Future<void> setStatus({
    required String articleId,
    required String status,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(educationRepositoryProvider)
          .setArticleStatus(articleId: articleId, status: status);
    });
  }

  Future<void> deleteArticle(String articleId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(educationRepositoryProvider).deleteArticle(articleId);
    });
  }
}

class AdminEducationScreen extends ConsumerWidget {
  const AdminEducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesState = ref.watch(adminEducationArticlesProvider);
    final actionState = ref.watch(adminEducationActionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr('Manage Articles', 'Kelola Edukasi')),
        actions: [
          IconButton(
            tooltip: AppStrings.tr('Add Article', 'Tambah Artikel'),
            icon: const Icon(Icons.add),
            onPressed: actionState.isLoading
                ? null
                : () => _openEditor(context, ref),
          ),
          IconButton(
            tooltip: AppStrings.tr('Refresh', 'Muat Ulang'),
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminEducationArticlesProvider),
          ),
        ],
        bottom: actionState.isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: actionState.isLoading
            ? null
            : () => _openEditor(context, ref),
        icon: const Icon(Icons.post_add),
        label: Text(AppStrings.tr('New Article', 'Artikel Baru')),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminEducationArticlesProvider);
          await ref.read(adminEducationArticlesProvider.future);
        },
        child: articlesState.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              AdminIntroCard(
                icon: Icons.menu_book_outlined,
                title: AppStrings.tr(
                  'Content Workspace',
                  'Ruang Kelola Konten',
                ),
                subtitle: AppStrings.tr(
                  'Draft, publish, and update educational content shown to users.',
                  'Buat draf, publikasikan, dan perbarui konten edukasi untuk pengguna.',
                ),
              ),
              const SizedBox(height: 14),
              AdminSectionTitle(
                title: AppStrings.tr('Article Collection', 'Koleksi Artikel'),
                subtitle: AppStrings.tr(
                  'Loading article records...',
                  'Memuat data artikel...',
                ),
                icon: Icons.article_outlined,
              ),
              const SizedBox(height: 8),
              const AppLoadingSkeleton(
                width: double.infinity,
                height: 140,
                borderRadius: 20,
              ),
              const SizedBox(height: 10),
              const AppLoadingSkeleton(
                width: double.infinity,
                height: 140,
                borderRadius: 20,
              ),
            ],
          ),
          error: (error, _) => AppErrorWidget(
            message: toUserErrorMessage(error),
            onRetry: () => ref.invalidate(adminEducationArticlesProvider),
          ),
          data: (articles) {
            if (articles.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  AdminIntroCard(
                    icon: Icons.menu_book_outlined,
                    title: AppStrings.tr(
                      'Content Workspace',
                      'Ruang Kelola Konten',
                    ),
                    subtitle: AppStrings.tr(
                      'Draft, publish, and update educational content shown to users.',
                      'Buat draf, publikasikan, dan perbarui konten edukasi untuk pengguna.',
                    ),
                    badge: '0',
                  ),
                  const SizedBox(height: 28),
                  AppEmptyState(
                    message: AppStrings.tr(
                      'No educational articles yet.',
                      'Belum ada artikel edukasi.',
                    ),
                    subtitle: AppStrings.tr(
                      'Create your first article for users.',
                      'Buat artikel pertama untuk pengguna.',
                    ),
                    icon: Icons.menu_book_outlined,
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                AdminIntroCard(
                  icon: Icons.menu_book_outlined,
                  title: AppStrings.tr(
                    'Content Workspace',
                    'Ruang Kelola Konten',
                  ),
                  subtitle: AppStrings.tr(
                    'Review and publish educational articles with one tap.',
                    'Tinjau dan publikasikan artikel edukasi dalam satu sentuhan.',
                  ),
                  badge: '${articles.length}',
                ),
                const SizedBox(height: 14),
                AdminSectionTitle(
                  title: AppStrings.tr('Article Collection', 'Koleksi Artikel'),
                  subtitle: AppStrings.tr(
                    'Manage draft and published content.',
                    'Kelola konten draf dan yang sudah terbit.',
                  ),
                  icon: Icons.article_outlined,
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < articles.length; index++) ...[
                  if (index > 0) const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final article = articles[index];
                      final statusColor = article.isPublished
                          ? const Color(0xFF2F855A)
                          : const Color(0xFF805AD5);
                      final dateLabel = article.updatedAt;
                      final locale = AppStrings.languageCode == 'id'
                          ? 'id_ID'
                          : 'en_US';

                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    article.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    article.isPublished
                                        ? AppStrings.tr('PUBLISHED', 'TERBIT')
                                        : AppStrings.tr('DRAFT', 'DRAF'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.tr(
                                'Slug: ${article.slug} | Updated: ${DateFormat('dd MMM yyyy', locale).format(dateLabel.toLocal())}',
                                'Slug: ${article.slug} | Update: ${DateFormat('dd MMM yyyy', locale).format(dateLabel.toLocal())}',
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                            if ((article.summary ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                article.summary!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: actionState.isLoading
                                        ? null
                                        : () => _openEditor(
                                            context,
                                            ref,
                                            article: article,
                                          ),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    label: Text(AppStrings.edit),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: actionState.isLoading
                                        ? null
                                        : () => _togglePublish(
                                            context,
                                            ref,
                                            article,
                                          ),
                                    icon: Icon(
                                      article.isPublished
                                          ? Icons.unpublished_outlined
                                          : Icons.publish_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      article.isPublished
                                          ? AppStrings.tr(
                                              'Unpublish',
                                              'Batalkan Publikasi',
                                            )
                                          : AppStrings.tr(
                                              'Publish',
                                              'Publikasikan',
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: actionState.isLoading
                                      ? null
                                      : () => _deleteArticle(
                                          context,
                                          ref,
                                          article,
                                        ),
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: AppStrings.delete,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    EducationArticle? article,
  }) async {
    final titleController = TextEditingController(text: article?.title ?? '');
    final slugController = TextEditingController(text: article?.slug ?? '');
    final summaryController = TextEditingController(
      text: article?.summary ?? '',
    );
    final categoryController = TextEditingController(
      text: article?.category ?? '',
    );
    final coverController = TextEditingController(
      text: article?.coverUrl ?? '',
    );
    final contentController = TextEditingController(
      text: article?.content ?? '',
    );

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  article == null
                      ? AppStrings.tr('Create Article', 'Buat Artikel')
                      : AppStrings.tr('Edit Article', 'Edit Artikel'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('Title', 'Judul'),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: slugController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr(
                      'Slug (optional)',
                      'Slug (opsional)',
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoryController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr(
                      'Category (optional)',
                      'Kategori (opsional)',
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: coverController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr(
                      'Cover URL (optional)',
                      'Cover URL (opsional)',
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: summaryController,
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr(
                      'Summary (optional)',
                      'Ringkasan (opsional)',
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: AppStrings.tr('Content', 'Konten'),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty ||
                              contentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppStrings.tr(
                                    'Title and content are required.',
                                    'Judul dan konten wajib diisi.',
                                  ),
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pop(true);
                        },
                        child: Text(AppStrings.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != true) {
      return;
    }

    final slugInput = slugController.text.trim().isEmpty
        ? titleController.text.trim()
        : slugController.text.trim();
    final normalizedSlug = _slugify(slugInput);

    final input = EducationArticleInput(
      title: titleController.text.trim(),
      slug: article == null
          ? '$normalizedSlug-${DateTime.now().millisecondsSinceEpoch}'
          : normalizedSlug,
      summary: summaryController.text,
      content: contentController.text,
      category: categoryController.text,
      coverUrl: coverController.text,
    );

    if (article == null) {
      await ref
          .read(adminEducationActionControllerProvider.notifier)
          .createArticle(input);
    } else {
      await ref
          .read(adminEducationActionControllerProvider.notifier)
          .updateArticle(article.id, input);
    }

    final actionState = ref.read(adminEducationActionControllerProvider);
    if (!context.mounted) {
      return;
    }

    if (actionState.hasError) {
      context.showErrorSnackBar(toUserErrorMessage(actionState.error!));
      return;
    }

    context.showSuccessSnackBar(
      article == null
          ? AppStrings.tr('Article created.', 'Artikel berhasil dibuat.')
          : AppStrings.tr('Article updated.', 'Artikel berhasil diperbarui.'),
    );
    ref.invalidate(adminEducationArticlesProvider);
  }

  Future<void> _togglePublish(
    BuildContext context,
    WidgetRef ref,
    EducationArticle article,
  ) async {
    final nextStatus = article.isPublished ? 'draft' : 'published';
    final confirmed = await AppDialog.showConfirm(
      context,
      title: article.isPublished
          ? AppStrings.tr('Unpublish article?', 'Unpublish artikel?')
          : AppStrings.tr('Publish article?', 'Publish artikel?'),
      message: article.isPublished
          ? AppStrings.tr(
              'This article will no longer be visible to users.',
              'Artikel tidak akan terlihat oleh user.',
            )
          : AppStrings.tr(
              'This article will be visible to users immediately.',
              'Artikel akan langsung terlihat oleh user.',
            ),
      confirmLabel: article.isPublished
          ? AppStrings.tr('Unpublish', 'Batalkan Publikasi')
          : AppStrings.tr('Publish', 'Publikasikan'),
      cancelLabel: AppStrings.cancel,
      isDestructive: article.isPublished,
      icon: article.isPublished ? Icons.unpublished_outlined : Icons.publish,
    );

    if (confirmed != true) {
      return;
    }

    await ref
        .read(adminEducationActionControllerProvider.notifier)
        .setStatus(articleId: article.id, status: nextStatus);

    final actionState = ref.read(adminEducationActionControllerProvider);
    if (!context.mounted) {
      return;
    }

    if (actionState.hasError) {
      context.showErrorSnackBar(toUserErrorMessage(actionState.error!));
      return;
    }

    context.showSuccessSnackBar(
      article.isPublished
          ? AppStrings.tr(
              'Article unpublished successfully.',
              'Artikel berhasil di-unpublish.',
            )
          : AppStrings.tr(
              'Article published successfully.',
              'Artikel berhasil dipublish.',
            ),
    );
    ref.invalidate(adminEducationArticlesProvider);
  }

  Future<void> _deleteArticle(
    BuildContext context,
    WidgetRef ref,
    EducationArticle article,
  ) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: AppStrings.tr('Delete article?', 'Hapus artikel?'),
      message: AppStrings.tr(
        'Deleted articles cannot be restored.',
        'Artikel yang dihapus tidak dapat dikembalikan.',
      ),
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (confirmed != true) {
      return;
    }

    await ref
        .read(adminEducationActionControllerProvider.notifier)
        .deleteArticle(article.id);

    final actionState = ref.read(adminEducationActionControllerProvider);
    if (!context.mounted) {
      return;
    }

    if (actionState.hasError) {
      context.showErrorSnackBar(toUserErrorMessage(actionState.error!));
      return;
    }

    context.showSuccessSnackBar(
      AppStrings.tr('Article deleted.', 'Artikel berhasil dihapus.'),
    );
    ref.invalidate(adminEducationArticlesProvider);
  }

  String _slugify(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');

    if (normalized.isEmpty) {
      return 'artikel';
    }
    return normalized;
  }
}
