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
                for (var index = 0; index < articles.length; index++) ...[
                  if (index > 0) const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      final article = articles[index];
                      final statusColor = article.isPublished
                          ? const Color(0xFF2F855A)
                          : const Color(0xFF805AD5);
                      final dateLabel = article.updatedAt;
                      final locale = _resolvedDateLocale();
                      final isCompactCard =
                          isCompact || MediaQuery.of(context).size.width < 360;

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
                                        ?.copyWith(fontWeight: FontWeight.w700),
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
                              maxLines: isCompactCard ? 3 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((article.summary ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                article.summary!,
                                maxLines: isCompactCard ? 3 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compactActions =
                                    isCompactCard || constraints.maxWidth < 360;

                                if (compactActions) {
                                  return Column(
                                    children: [
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
                                              label: Text(
                                                AppStrings.edit,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
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
                                                    ? AppStrings
                                                          .adminUnpublishAction
                                                    : AppStrings
                                                          .adminPublishAction,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: actionState.isLoading
                                              ? null
                                              : () => _deleteArticle(
                                                  context,
                                                  ref,
                                                  article,
                                                ),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          label: Text(AppStrings.delete),
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Row(
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
                                        label: Text(
                                          AppStrings.edit,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                );
                              },
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

class _ArticleEditorResult {
  const _ArticleEditorResult({
    required this.title,
    required this.slugInput,
    required this.summary,
    required this.content,
    required this.category,
    required this.coverUrl,
  });

  final String title;
  final String slugInput;
  final String summary;
  final String content;
  final String category;
  final String? coverUrl;
}

class _ArticleEditorSheet extends ConsumerStatefulWidget {
  const _ArticleEditorSheet({this.article});

  final EducationArticle? article;

  @override
  ConsumerState<_ArticleEditorSheet> createState() =>
      _ArticleEditorSheetState();
}

class _ArticleEditorSheetState extends ConsumerState<_ArticleEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  static const int _maxCoverBytes = 5 * 1024 * 1024;

  late final TextEditingController _titleController;
  late final TextEditingController _slugController;
  late final TextEditingController _categoryController;
  late final TextEditingController _summaryController;
  late final TextEditingController _contentController;
  late final String _initialTitle;
  late final String _initialSlug;
  late final String _initialCategory;
  late final String _initialSummary;
  late final String _initialContent;
  late final String _initialCoverUrl;

  Uint8List? _coverBytes;
  XFile? _coverFile;
  String? _coverUrl;
  bool _isSaving = false;

  bool get _isEditing => widget.article != null;

  bool get _hasUnsavedChanges {
    return _normalized(_titleController.text) != _normalized(_initialTitle) ||
        _normalized(_slugController.text) != _normalized(_initialSlug) ||
        _normalized(_categoryController.text) !=
            _normalized(_initialCategory) ||
        _normalized(_summaryController.text) != _normalized(_initialSummary) ||
        _normalized(_contentController.text) != _normalized(_initialContent) ||
        _normalized(_coverUrl ?? '') != _normalized(_initialCoverUrl) ||
        _coverFile != null;
  }

  @override
  void initState() {
    super.initState();
    final article = widget.article;

    _titleController = TextEditingController(text: article?.title ?? '');
    _slugController = TextEditingController(text: article?.slug ?? '');
    _categoryController = TextEditingController(text: article?.category ?? '');
    _summaryController = TextEditingController(text: article?.summary ?? '');
    _contentController = TextEditingController(text: article?.content ?? '');
    _coverUrl = article?.coverUrl;

    _initialTitle = article?.title ?? '';
    _initialSlug = article?.slug ?? '';
    _initialCategory = article?.category ?? '';
    _initialSummary = article?.summary ?? '';
    _initialContent = article?.content ?? '';
    _initialCoverUrl = article?.coverUrl ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _categoryController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
    String? helper,
  }) {
    final fillColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final borderRadius = BorderRadius.circular(16);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.4,
        ),
      ),
    );
  }

  String _normalized(String value) => value.trim();

  Future<void> _maybeCloseEditor() async {
    if (_isSaving) {
      return;
    }

    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await AppDialog.showConfirm(
      context,
      title: AppStrings.adminArticleDiscardChangesTitle,
      message: AppStrings.adminArticleDiscardChangesMessage,
      confirmLabel: AppStrings.adminArticleDiscardChangesAction,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickCover(ImageSource source) async {
    if (_isSaving) {
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 84,
        maxWidth: 1800,
      );

      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Image file is empty.');
      }

      if (bytes.lengthInBytes > _maxCoverBytes) {
        if (!mounted) {
          return;
        }

        context.showWarningSnackBar(
          AppStrings.adminArticleCoverTooLargeMessage(
            (_maxCoverBytes / (1024 * 1024)).round(),
          ),
        );
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _coverFile = pickedFile;
        _coverBytes = bytes;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      context.showErrorSnackBar(
        toUserErrorMessage(
          error,
          fallback: AppStrings.tr(
            'Failed to choose image. Please try again.',
            'Gagal memilih gambar. Silakan coba lagi.',
          ),
        ),
      );
    }
  }

  void _clearCover() {
    if (_isSaving) {
      return;
    }

    setState(() {
      _coverBytes = null;
      _coverFile = null;
      _coverUrl = null;
    });
  }

  String _detectExtension(XFile file) {
    final source = (file.name.isNotEmpty ? file.name : file.path)
        .trim()
        .toLowerCase();

    if (source.endsWith('.png')) {
      return 'png';
    }
    if (source.endsWith('.webp')) {
      return 'webp';
    }
    return 'jpg';
  }

  String _contentTypeForExtension(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _slugFragment(String value) {
    var normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');

    if (normalized.isEmpty) {
      return 'article-cover';
    }

    if (normalized.length > 40) {
      normalized = normalized.substring(0, 40);
    }

    return normalized;
  }

  Future<String> _uploadCoverImage() async {
    final file = _coverFile;
    final bytes = _coverBytes;

    if (file == null || bytes == null) {
      throw Exception('No image selected.');
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to upload image.');
    }

    final extension = _detectExtension(file);
    final contentType = _contentTypeForExtension(extension);
    final titlePart = _slugFragment(_titleController.text);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${user.id}/$titlePart-$timestamp.$extension';

    await client.storage
        .from('education-covers')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    return client.storage.from('education-covers').getPublicUrl(path);
  }

  String _coverUploadErrorMessage(Object error) {
    if (error is StorageException) {
      final lower = error.message.toLowerCase();

      if (lower.contains('bucket') && lower.contains('not found')) {
        return AppStrings.tr(
          'Cover storage is not configured yet. Please contact admin.',
          'Penyimpanan cover belum dikonfigurasi. Silakan hubungi admin.',
        );
      }

      if (lower.contains('permission') ||
          lower.contains('row-level security')) {
        return AppStrings.tr(
          'You do not have permission to upload article cover.',
          'Anda tidak memiliki izin untuk mengunggah cover artikel.',
        );
      }
    }

    return toUserErrorMessage(
      error,
      fallback: AppStrings.adminArticleCoverUploadFailedMessage,
    );
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      var coverUrl = _coverUrl?.trim();
      if (_coverFile != null && _coverBytes != null) {
        coverUrl = await _uploadCoverImage();
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        _ArticleEditorResult(
          title: _titleController.text,
          slugInput: _slugController.text,
          summary: _summaryController.text,
          content: _contentController.text,
          category: _categoryController.text,
          coverUrl: coverUrl,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      context.showErrorSnackBar(_coverUploadErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScaler = media.textScaler.scale(1);
    final isCompact = media.size.width < 390 || textScaler > 1.1;
    final horizontalPadding = isCompact ? 14.0 : 18.0;
    final actionPaddingBottom = media.padding.bottom > 0
        ? media.padding.bottom + 6
        : 14.0;

    return PopScope(
      canPop: !_isSaving && !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _maybeCloseEditor();
      },
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: isCompact ? 0.97 : 0.93,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isCompact ? 38 : 42,
                        height: isCompact ? 38 : 42,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isEditing ? Icons.edit_note : Icons.auto_awesome,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? AppStrings.adminEditArticleTitle
                                  : AppStrings.adminCreateArticleTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEditing
                                  ? AppStrings.adminEditArticleEditorSubtitle
                                  : AppStrings.adminCreateArticleEditorSubtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.68),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isSaving ? null : _maybeCloseEditor,
                        tooltip: AppStrings.close,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        20,
                      ),
                      children: [
                        AppCard(
                          padding: EdgeInsets.all(isCompact ? 12 : 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.image_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      AppStrings.adminArticleCoverFieldTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  if (_coverFile != null ||
                                      ((_coverUrl ?? '').trim().isNotEmpty))
                                    TextButton.icon(
                                      onPressed: _isSaving ? null : _clearCover,
                                      icon: const Icon(Icons.delete_outline),
                                      label: Text(
                                        AppStrings
                                            .adminArticleCoverRemoveAction,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.35),
                                    ),
                                    child: _coverBytes != null
                                        ? Image.memory(
                                            _coverBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : ((_coverUrl ?? '').trim().isNotEmpty)
                                        ? CachedNetworkImage(
                                            imageUrl: _coverUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, imageUrl) =>
                                                const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                            errorWidget:
                                                (
                                                  context,
                                                  imageUrl,
                                                  error,
                                                ) => Center(
                                                  child: Text(
                                                    AppStrings
                                                        .adminArticleCoverPreviewUnavailable,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                          )
                                        : Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .add_photo_alternate_outlined,
                                                    size: isCompact ? 30 : 34,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    AppStrings
                                                        .adminArticleCoverEmptyHint,
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              if (_coverFile != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _coverFile!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.72),
                                      ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                AppStrings.adminArticleCoverUploadOnSaveHint,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.72),
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: _isSaving
                                        ? null
                                        : () => _pickCover(ImageSource.gallery),
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                    ),
                                    label: Text(
                                      AppStrings
                                          .adminArticleCoverSelectGalleryAction,
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _isSaving
                                        ? null
                                        : () => _pickCover(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt_outlined),
                                    label: Text(
                                      AppStrings
                                          .adminArticleCoverUseCameraAction,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          textInputAction: TextInputAction.next,
                          decoration: _fieldDecoration(
                            context,
                            label: AppStrings.adminArticleFieldTitleLabel,
                            icon: Icons.title,
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return AppStrings.fieldRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _slugController,
                          textInputAction: TextInputAction.next,
                          decoration: _fieldDecoration(
                            context,
                            label:
                                AppStrings.adminArticleFieldSlugOptionalLabel,
                            icon: Icons.link,
                            helper: AppStrings.adminArticleSlugAutoGenerateHint,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _categoryController,
                          textInputAction: TextInputAction.next,
                          decoration: _fieldDecoration(
                            context,
                            label: AppStrings
                                .adminArticleFieldCategoryOptionalLabel,
                            icon: Icons.category_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _summaryController,
                          textInputAction: TextInputAction.newline,
                          maxLines: 3,
                          decoration: _fieldDecoration(
                            context,
                            label: AppStrings
                                .adminArticleFieldSummaryOptionalLabel,
                            icon: Icons.notes_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _contentController,
                          minLines: 8,
                          maxLines: 14,
                          decoration: _fieldDecoration(
                            context,
                            label: AppStrings.adminArticleFieldContentLabel,
                            icon: Icons.article_outlined,
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return AppStrings.fieldRequired;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    actionPaddingBottom,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _maybeCloseEditor,
                          child: Text(AppStrings.cancel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _submit,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            _isSaving ? AppStrings.saving : AppStrings.save,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
