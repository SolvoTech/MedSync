import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/user_error_message.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_skeleton.dart';
import 'education_providers.dart';

String _resolvedDateLocale() {
  final preferred = AppStrings.languageCode == 'id' ? 'id_ID' : 'en_US';
  try {
    return DateFormat.localeExists(preferred) ? preferred : 'en_US';
  } catch (_) {
    return 'en_US';
  }
}

class EducationDetailScreen extends ConsumerWidget {
  const EducationDetailScreen({super.key, required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(educationArticleByIdProvider(articleId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.tr('Article Detail', 'Detail Edukasi'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: state.when(
        loading: () {
          final compact = MediaQuery.sizeOf(context).width < 340;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 16,
              12,
              compact ? 12 : 16,
              28,
            ),
            children: [
              AppLoadingSkeleton(
                width: double.infinity,
                height: compact ? 176 : 240,
                borderRadius: 12,
              ),
              const SizedBox(height: 14),
              const AppLoadingSkeleton(
                width: 120,
                height: 24,
                borderRadius: 999,
              ),
              const SizedBox(height: 10),
              const AppLoadingSkeleton(width: double.infinity, height: 32),
              const SizedBox(height: 8),
              const AppLoadingSkeleton(width: 180, height: 18),
              const SizedBox(height: 18),
              const AppLoadingSkeleton(width: double.infinity, height: 16),
              const SizedBox(height: 8),
              const AppLoadingSkeleton(width: double.infinity, height: 16),
              const SizedBox(height: 8),
              const AppLoadingSkeleton(width: double.infinity, height: 16),
            ],
          );
        },
        error: (error, _) => AppErrorWidget(message: toUserErrorMessage(error)),
        data: (article) {
          if (article == null) {
            return AppEmptyState(
              message: AppStrings.tr(
                'Article not found.',
                'Artikel tidak ditemukan.',
              ),
              subtitle: AppStrings.tr(
                'Content may have been deleted or moved.',
                'Konten mungkin sudah dihapus atau dipindahkan.',
              ),
              icon: Icons.search_off,
            );
          }

          final locale = _resolvedDateLocale();
          final publishedAt = article.publishedAt != null
              ? DateFormat(
                  'dd MMM yyyy',
                  locale,
                ).format(article.publishedAt!.toLocal())
              : '-';

          final compact = MediaQuery.sizeOf(context).width < 340;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 16,
              12,
              compact ? 12 : 16,
              28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _DetailCover(
                    url: article.coverUrl,
                    height: compact ? 176 : 240,
                  ),
                ),
                const SizedBox(height: 14),
                if ((article.category ?? '').trim().isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        article.category!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  article.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.tr(
                    'Published: $publishedAt',
                    'Dipublikasi: $publishedAt',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if ((article.summary ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    article.summary!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  article.content,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.7),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailCover extends StatelessWidget {
  const _DetailCover({required this.url, required this.height});

  final String? url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasUrl = (url ?? '').trim().isNotEmpty;

    if (!hasUrl) {
      return _fallback(context);
    }

    return CachedNetworkImage(
      imageUrl: url!,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, imageUrl) => _fallback(context),
      errorWidget: (context, imageUrl, error) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: double.infinity,
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
        size: 44,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
