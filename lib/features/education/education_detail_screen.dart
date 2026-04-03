import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(title: const Text('Detail Edukasi')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorWidget(message: toUserErrorMessage(error)),
        data: (article) {
          if (article == null) {
            return const AppEmptyState(
              message: 'Artikel tidak ditemukan.',
              subtitle: 'Konten mungkin sudah dihapus atau dipindahkan.',
              icon: Icons.search_off,
            );
          }

          final publishedAt = article.publishedAt != null
              ? DateFormat('dd MMM yyyy').format(article.publishedAt!.toLocal())
              : '-';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  'Dipublikasi: $publishedAt',
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
                  ).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
