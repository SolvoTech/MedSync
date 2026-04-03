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
        title: Text(AppStrings.adminManageArticlesTitle),
        actions: [
          IconButton(
            tooltip: AppStrings.adminAddArticleTooltip,
            icon: const Icon(Icons.add),
            onPressed: actionState.isLoading
                ? null
                : () => _openEditor(context, ref),
          ),
          IconButton(
            tooltip: AppStrings.adminRefreshTooltip,
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
        label: Text(AppStrings.adminNewArticleButton),
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
                title: AppStrings.adminContentWorkspaceTitle,
                subtitle: AppStrings.adminEducationWorkspaceDraftSubtitle,
              ),
              const SizedBox(height: 14),
              AdminSectionTitle(
                title: AppStrings.adminArticleCollectionTitle,
                subtitle: AppStrings.adminArticleCollectionLoadingSubtitle,
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
                    title: AppStrings.adminContentWorkspaceTitle,
                    subtitle: AppStrings.adminEducationWorkspaceDraftSubtitle,
                    badge: '0',
                  ),
                  const SizedBox(height: 28),
                  AppEmptyState(
                    message: AppStrings.adminNoEducationArticleMessage,
                    subtitle: AppStrings.adminNoEducationArticleSubtitle,
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
                  title: AppStrings.adminContentWorkspaceTitle,
                  subtitle: AppStrings.adminEducationWorkspaceReviewSubtitle,
                  badge: '${articles.length}',
                ),
                const SizedBox(height: 14),
                AdminSectionTitle(
                  title: AppStrings.adminArticleCollectionTitle,
                  subtitle: AppStrings.adminArticleCollectionManageSubtitle,
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
                                        ? AppStrings.adminArticlePublishedChip
                                        : AppStrings.adminArticleDraftChip,
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
                              AppStrings.adminArticleMetaLabel(
                                slug: article.slug,
                                updatedDate: DateFormat(
                                  'dd MMM yyyy',
                                  locale,
                                ).format(dateLabel.toLocal()),
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
                                          ? AppStrings.adminUnpublishAction
                                          : AppStrings.adminPublishAction,
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
                      ? AppStrings.adminCreateArticleTitle
                      : AppStrings.adminEditArticleTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppStrings.adminArticleFieldTitleLabel,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: slugController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: AppStrings.adminArticleFieldSlugOptionalLabel,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: categoryController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText:
                        AppStrings.adminArticleFieldCategoryOptionalLabel,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: coverController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText:
                        AppStrings.adminArticleFieldCoverUrlOptionalLabel,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: summaryController,
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppStrings.adminArticleFieldSummaryOptionalLabel,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: AppStrings.adminArticleFieldContentLabel,
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
                                  AppStrings.adminArticleTitleRequiredMessage,
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
          ? AppStrings.adminArticleCreatedSuccess
          : AppStrings.adminArticleUpdatedSuccess,
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
          ? AppStrings.adminUnpublishArticleTitle
          : AppStrings.adminPublishArticleTitle,
      message: article.isPublished
          ? AppStrings.adminUnpublishArticleMessage
          : AppStrings.adminPublishArticleMessage,
      confirmLabel: article.isPublished
          ? AppStrings.adminUnpublishAction
          : AppStrings.adminPublishAction,
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
          ? AppStrings.adminArticleUnpublishedSuccess
          : AppStrings.adminArticlePublishedSuccess,
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
      title: AppStrings.adminDeleteArticleTitle,
      message: AppStrings.adminDeleteArticleMessage,
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

    context.showSuccessSnackBar(AppStrings.adminArticleDeletedSuccess);
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
