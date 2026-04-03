import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/user_error_message.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_skeleton.dart';
import '../../domain/models/education_article.dart';
import '../education/education_providers.dart';

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
        title: const Text('Kelola Edukasi'),
        actions: [
          IconButton(
            tooltip: 'Tambah Artikel',
            icon: const Icon(Icons.add),
            onPressed: actionState.isLoading
                ? null
                : () => _openEditor(context, ref),
          ),
          IconButton(
            tooltip: 'Refresh',
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
        label: const Text('Artikel Baru'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminEducationArticlesProvider);
          await ref.read(adminEducationArticlesProvider.future);
        },
        child: articlesState.when(
          loading: () => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: const [
              AppLoadingSkeleton(
                width: double.infinity,
                height: 140,
                borderRadius: 20,
              ),
              SizedBox(height: 10),
              AppLoadingSkeleton(
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
                children: const [
                  SizedBox(height: 80),
                  AppEmptyState(
                    message: 'Belum ada artikel edukasi.',
                    subtitle:
                        'Buat artikel pertama untuk ditampilkan kepada pengguna.',
                    icon: Icons.menu_book_outlined,
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: articles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final article = articles[index];
                final statusColor = article.isPublished
                    ? const Color(0xFF2F855A)
                    : const Color(0xFF805AD5);
                final dateLabel = article.updatedAt;

                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              article.title,
                              style: Theme.of(context).textTheme.titleMedium
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
                              article.isPublished ? 'PUBLISHED' : 'DRAFT',
                              style: Theme.of(context).textTheme.labelSmall
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
                        'Slug: ${article.slug} | Update: ${DateFormat('dd MMM yyyy').format(dateLabel.toLocal())}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
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
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: actionState.isLoading
                                  ? null
                                  : () => _togglePublish(context, ref, article),
                              icon: Icon(
                                article.isPublished
                                    ? Icons.unpublished_outlined
                                    : Icons.publish_outlined,
                                size: 18,
                              ),
                              label: Text(
                                article.isPublished ? 'Unpublish' : 'Publish',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: actionState.isLoading
                                ? null
                                : () => _deleteArticle(context, ref, article),
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Hapus',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
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
                  article == null ? 'Buat Artikel' : 'Edit Artikel',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Judul',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: slugController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Slug (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoryController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Kategori (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: coverController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Cover URL (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: summaryController,
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ringkasan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Konten',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty ||
                              contentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Judul dan konten wajib diisi.'),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Simpan'),
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
          ? 'Artikel berhasil dibuat.'
          : 'Artikel berhasil diperbarui.',
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
      title: article.isPublished ? 'Unpublish artikel?' : 'Publish artikel?',
      message: article.isPublished
          ? 'Artikel tidak akan terlihat oleh user.'
          : 'Artikel akan langsung terlihat oleh user.',
      confirmLabel: article.isPublished ? 'Unpublish' : 'Publish',
      cancelLabel: 'Batal',
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
          ? 'Artikel berhasil di-unpublish.'
          : 'Artikel berhasil dipublish.',
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
      title: 'Hapus artikel?',
      message: 'Artikel yang dihapus tidak dapat dikembalikan.',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
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

    context.showSuccessSnackBar('Artikel berhasil dihapus.');
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
