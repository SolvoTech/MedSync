import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/user_error_message.dart';
import '../../core/extensions/context_ext.dart';
import '../../core/services/image_cache_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_skeleton.dart';
import '../../domain/models/education_article.dart';
import '../education/education_providers.dart';
import 'widgets/admin_ui.dart';

part 'admin_education_editor_sheet.dart';

String _resolvedDateLocale() {
  final preferred = AppStrings.languageCode == 'id' ? 'id_ID' : 'en_US';
  try {
    return DateFormat.localeExists(preferred) ? preferred : 'en_US';
  } catch (_) {
    return 'en_US';
  }
}

final adminEducationActionControllerProvider =
    AutoDisposeNotifierProvider<
      AdminEducationActionController,
      AsyncValue<void>
    >(AdminEducationActionController.new);

enum AdminArticleStatusFilter { all, published, draft }

final adminArticleStatusFilterProvider =
    StateProvider.autoDispose<AdminArticleStatusFilter>(
      (ref) => AdminArticleStatusFilter.all,
    );

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
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 390 || media.textScaler.scale(1) > 1.1;
    final pagePadding = EdgeInsets.fromLTRB(
      isCompact ? 12 : 16,
      isCompact ? 10 : 12,
      isCompact ? 12 : 16,
      isCompact ? 20 : 24,
    );

    final articlesState = ref.watch(adminEducationArticlesProvider);
    final actionState = ref.watch(adminEducationActionControllerProvider);
    final articleFilter = ref.watch(adminArticleStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.adminManageArticlesTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!isCompact)
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
      floatingActionButton: isCompact
          ? FloatingActionButton(
              onPressed: actionState.isLoading
                  ? null
                  : () => _openEditor(context, ref),
              child: const Icon(Icons.post_add),
            )
          : FloatingActionButton.extended(
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
            padding: pagePadding,
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
                borderRadius: 12,
              ),
              const SizedBox(height: 10),
              const AppLoadingSkeleton(
                width: double.infinity,
                height: 140,
                borderRadius: 12,
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
                padding: pagePadding,
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

            final filteredArticles = switch (articleFilter) {
              AdminArticleStatusFilter.all => articles,
              AdminArticleStatusFilter.published =>
                articles.where((article) => article.isPublished).toList(),
              AdminArticleStatusFilter.draft =>
                articles.where((article) => !article.isPublished).toList(),
            };

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: pagePadding,
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
                _ArticleStatusFilterBar(
                  selected: articleFilter,
                  articles: articles,
                  onChanged: (value) {
                    ref.read(adminArticleStatusFilterProvider.notifier).state =
                        value;
                  },
                ),
                const SizedBox(height: 10),
                if (filteredArticles.isEmpty)
                  AppEmptyState(
                    message: AppStrings.tr(
                      'No articles in this status.',
                      'Tidak ada artikel pada status ini.',
                    ),
                    subtitle: AppStrings.tr(
                      'Change the status filter to view other articles.',
                      'Ubah filter status untuk melihat artikel lain.',
                    ),
                    icon: Icons.filter_alt_off_outlined,
                  )
                else
                  for (
                    var index = 0;
                    index < filteredArticles.length;
                    index++
                  ) ...[
                    if (index > 0) const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final article = filteredArticles[index];
                        final statusColor = article.isPublished
                            ? const Color(0xFF2F855A)
                            : const Color(0xFF805AD5);
                        final dateLabel = article.updatedAt;
                        final locale = _resolvedDateLocale();
                        final isCompactCard =
                            isCompact ||
                            MediaQuery.of(context).size.width < 360;

                        return AppCard(
                          padding: EdgeInsets.all(isCompactCard ? 12 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isCompactCard)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.title,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        article.isPublished
                                            ? AppStrings
                                                  .adminArticlePublishedChip
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
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        article.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        article.isPublished
                                            ? AppStrings
                                                  .adminArticlePublishedChip
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
                                maxLines: isCompactCard ? 3 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((article.summary ?? '')
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  article.summary!,
                                  maxLines: isCompactCard ? 3 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.tonalIcon(
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
                                      label: Text(
                                        AppStrings.edit,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<_ArticleCardAction>(
                                    tooltip: AppStrings.tr(
                                      'More actions',
                                      'Aksi lainnya',
                                    ),
                                    onSelected: (action) {
                                      if (action ==
                                          _ArticleCardAction.publish) {
                                        _togglePublish(context, ref, article);
                                      } else {
                                        _deleteArticle(context, ref, article);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: _ArticleCardAction.publish,
                                        enabled: !actionState.isLoading,
                                        child: ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            article.isPublished
                                                ? Icons.unpublished_outlined
                                                : Icons.publish_outlined,
                                          ),
                                          title: Text(
                                            article.isPublished
                                                ? AppStrings
                                                      .adminUnpublishAction
                                                : AppStrings.adminPublishAction,
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: _ArticleCardAction.delete,
                                        enabled: !actionState.isLoading,
                                        child: ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          title: Text(AppStrings.delete),
                                        ),
                                      ),
                                    ],
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
    final result = await showModalBottomSheet<_ArticleEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ArticleEditorSheet(article: article);
      },
    );

    if (result == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final slugInput = result.slugInput.trim().isEmpty
        ? result.title.trim()
        : result.slugInput.trim();
    final normalizedSlug = _slugify(slugInput);
    final finalSlug = article == null
        ? '$normalizedSlug-${DateTime.now().millisecondsSinceEpoch}'
        : normalizedSlug;

    final existingArticles = ref
        .read(adminEducationArticlesProvider)
        .valueOrNull;
    final hasDuplicateSlug = existingArticles?.any(
      (item) =>
          item.id != article?.id &&
          item.slug.trim().toLowerCase() == finalSlug.trim().toLowerCase(),
    );

    if (hasDuplicateSlug == true) {
      context.showWarningSnackBar(
        AppStrings.adminArticleSlugAlreadyUsedMessage,
      );
      return;
    }

    final coverUrl = result.coverUrl?.trim();
    final previousCoverUrl = article?.coverUrl?.trim();

    final input = EducationArticleInput(
      title: result.title.trim(),
      slug: finalSlug,
      summary: result.summary.trim(),
      content: result.content.trim(),
      category: result.category.trim(),
      coverUrl: (coverUrl == null || coverUrl.isEmpty) ? null : coverUrl,
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
      context.showErrorSnackBar(
        _buildArticleActionErrorMessage(actionState.error),
      );
      return;
    }

    final nextCoverUrl = (coverUrl == null || coverUrl.isEmpty)
        ? null
        : coverUrl;
    if ((previousCoverUrl ?? '') != (nextCoverUrl ?? '')) {
      await ImageCacheService.evictUrl(previousCoverUrl);
      await ImageCacheService.evictUrl(nextCoverUrl);
    }

    if (!context.mounted) {
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

  String _buildArticleActionErrorMessage(Object? error) {
    if (error is PostgrestException && error.code == '23505') {
      return AppStrings.adminArticleSlugAlreadyUsedMessage;
    }

    if (error != null) {
      return toUserErrorMessage(error);
    }

    return AppStrings.errorGeneral;
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

enum _ArticleCardAction { publish, delete }

class _ArticleStatusFilterBar extends StatelessWidget {
  const _ArticleStatusFilterBar({
    required this.selected,
    required this.articles,
    required this.onChanged,
  });

  final AdminArticleStatusFilter selected;
  final List<EducationArticle> articles;
  final ValueChanged<AdminArticleStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final publishedCount = articles.where((item) => item.isPublished).length;
    final draftCount = articles.length - publishedCount;

    return AdminToolbarCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: Text(
              AppStrings.tr(
                'All (${articles.length})',
                'Semua (${articles.length})',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            selected: selected == AdminArticleStatusFilter.all,
            onSelected: (_) => onChanged(AdminArticleStatusFilter.all),
          ),
          ChoiceChip(
            label: Text(
              AppStrings.tr(
                'Published ($publishedCount)',
                'Terbit ($publishedCount)',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            selected: selected == AdminArticleStatusFilter.published,
            onSelected: (_) => onChanged(AdminArticleStatusFilter.published),
          ),
          ChoiceChip(
            label: Text(
              AppStrings.tr('Draft ($draftCount)', 'Draf ($draftCount)'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            selected: selected == AdminArticleStatusFilter.draft,
            onSelected: (_) => onChanged(AdminArticleStatusFilter.draft),
          ),
        ],
      ),
    );
  }
}
