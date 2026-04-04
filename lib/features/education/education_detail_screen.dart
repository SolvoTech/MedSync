import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/user_error_message.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import 'education_providers.dart';

class EducationDetailScreen extends ConsumerWidget {
  const EducationDetailScreen({super.key, required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(educationArticleByIdProvider(articleId));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr('Article Detail', 'Detail Edukasi')),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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

          final locale = AppStrings.languageCode == 'id' ? 'id_ID' : 'en_US';
          final publishedAt = article.publishedAt != null
              ? DateFormat(
                  'dd MMM yyyy',
                  locale,
                ).format(article.publishedAt!.toLocal())
              : '-';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _DetailCover(url: article.coverUrl),
                ),
                const SizedBox(height: 14),
                if ((article.category ?? '').trim().isNotEmpty)
                  Container(
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
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
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
  const _DetailCover({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final hasUrl = (url ?? '').trim().isNotEmpty;

    if (!hasUrl) {
      return _fallback(context);
    }

    return Image.network(
      url!,
      width: double.infinity,
      height: 240,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return _fallback(context);
      },
      errorBuilder: (context, error, stackTrace) {
        return _fallback(context);
      },
    );
  }

  Widget _fallback(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
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
