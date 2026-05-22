import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_gradients.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/user_error_message.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_skeleton.dart';
import '../../domain/models/education_article.dart';
import 'education_providers.dart';

String _resolvedDateLocale() {
  final preferred = AppStrings.languageCode == 'id' ? 'id_ID' : 'en_US';
  try {
    return DateFormat.localeExists(preferred) ? preferred : 'en_US';
  } catch (_) {
    return 'en_US';
  }
}

class EducationFeedScreen extends ConsumerWidget {
  const EducationFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(publishedEducationArticlesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.tr('Health Articles', 'Artikel Kesehatan'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.tr('Refresh', 'Muat Ulang'),
            onPressed: () => ref.invalidate(publishedEducationArticlesProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(publishedEducationArticlesProvider);
          await ref.read(publishedEducationArticlesProvider.future);
        },
        child: state.when(
          loading: () => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: const [
              AppLoadingSkeleton(
                width: double.infinity,
                height: 130,
                borderRadius: 12,
              ),
              SizedBox(height: 10),
              AppLoadingSkeleton(
                width: double.infinity,
                height: 130,
                borderRadius: 12,
              ),
              SizedBox(height: 10),
              AppLoadingSkeleton(
                width: double.infinity,
                height: 130,
                borderRadius: 12,
              ),
            ],
          ),
          error: (error, _) => AppErrorWidget(
            message: toUserErrorMessage(error),
            onRetry: () => ref.invalidate(publishedEducationArticlesProvider),
          ),
          data: (articles) {
            if (articles.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  AppEmptyState(
                    message: AppStrings.tr(
                      'No educational articles available yet.',
                      'Artikel edukasi belum tersedia.',
                    ),
                    subtitle: AppStrings.tr(
                      'Please check back later for the latest health content.',
                      'Cek kembali nanti untuk konten kesehatan terbaru.',
                    ),
                    icon: Icons.menu_book_outlined,
                    actionLabel: AppStrings.tr('Refresh', 'Muat Ulang'),
                    onAction: () =>
                        ref.invalidate(publishedEducationArticlesProvider),
                  ),
                ],
              );
            }

            final featured = articles.first;
            final highlights = articles.skip(1).toList();

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: highlights.length + 2,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const _EducationHero();
                }

                if (index == 1) {
                  return _FeaturedArticleCard(article: featured);
                }

                final article = highlights[index - 2];
                return _ArticleListCard(article: article);
              },
            );
          },
        ),
      ),
    );
  }
}

class _EducationHero extends StatelessWidget {
  const _EducationHero();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: EdgeInsets.zero,
      gradient: AppGradients.softSky,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.primary,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.tr('Health education', 'Edukasi kesehatan'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppStrings.tr(
                      'Read practical guidance for safer daily care.',
                      'Baca panduan praktis untuk perawatan harian yang lebih aman.',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedArticleCard extends StatelessWidget {
  const _FeaturedArticleCard({required this.article});

  final EducationArticle article;

  @override
  Widget build(BuildContext context) {
    final locale = _resolvedDateLocale();
    final publishedAt = article.publishedAt != null
        ? DateFormat(
            'dd MMM yyyy',
            locale,
          ).format(article.publishedAt!.toLocal())
        : '-';

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(AppRoutes.educationDetail(article.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ArticleCover(
            url: article.coverUrl,
            height: MediaQuery.sizeOf(context).width < 340 ? 170 : 220,
            showGradient: true,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 340 ? 12 : 16,
              14,
              MediaQuery.sizeOf(context).width < 340 ? 12 : 16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if ((article.category ?? '').trim().isNotEmpty)
                      Flexible(child: _ArticleChip(label: article.category!)),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        publishedAt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if ((article.summary ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    article.summary!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.72),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleListCard extends StatelessWidget {
  const _ArticleListCard({required this.article});

  final EducationArticle article;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    final xxs = width < 340;
    final hasSummary = (article.summary ?? '').trim().isNotEmpty;
    final cardHeight = hasSummary
        ? (compact ? 150.0 : 162.0)
        : (compact ? 128.0 : 138.0);
    final imageWidth = compact ? 108.0 : 116.0;
    final locale = _resolvedDateLocale();
    final publishedAt = article.publishedAt != null
        ? DateFormat(
            'dd MMM yyyy',
            locale,
          ).format(article.publishedAt!.toLocal())
        : '-';

    if (xxs) {
      return AppCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push(AppRoutes.educationDetail(article.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: _ArticleCover(
                url: article.coverUrl,
                height: 128,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if ((article.category ?? '').trim().isNotEmpty)
                        Flexible(child: _ArticleChip(label: article.category!)),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          publishedAt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasSummary) ...[
                    const SizedBox(height: 6),
                    Text(
                      article.summary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.35,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(AppRoutes.educationDetail(article.id)),
      child: SizedBox(
        height: cardHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: imageWidth,
                child: _ArticleCover(
                  url: article.coverUrl,
                  height: cardHeight,
                  width: imageWidth,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((article.category ?? '').trim().isNotEmpty) ...[
                      _ArticleChip(label: article.category!),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((article.summary ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        article.summary!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      publishedAt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleChip extends StatelessWidget {
  const _ArticleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.58,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ArticleCover extends StatelessWidget {
  const _ArticleCover({
    required this.url,
    required this.height,
    this.width,
    this.showGradient = false,
  });

  final String? url;
  final double height;
  final double? width;
  final bool showGradient;

  @override
  Widget build(BuildContext context) {
    final hasUrl = (url ?? '').trim().isNotEmpty;

    Widget image;
    if (hasUrl) {
      image = CachedNetworkImage(
        imageUrl: url!,
        width: width ?? double.infinity,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, imageUrl) =>
            _coverFallback(context, width: width, height: height),
        errorWidget: (context, imageUrl, error) =>
            _coverFallback(context, width: width, height: height),
      );
    } else {
      image = _coverFallback(context, width: width, height: height);
    }

    if (!showGradient) {
      return image;
    }

    return Stack(
      children: [
        image,
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverFallback(
    BuildContext context, {
    required double? width,
    required double height,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Icon(
        Icons.menu_book_rounded,
        size: 34,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
