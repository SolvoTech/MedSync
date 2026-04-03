import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/user_error_message.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_widget.dart';
import '../../core/widgets/app_loading_skeleton.dart';
import 'education_providers.dart';

class EducationFeedScreen extends ConsumerWidget {
  const EducationFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(publishedEducationArticlesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edukasi Kesehatan'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
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
                borderRadius: 20,
              ),
              SizedBox(height: 10),
              AppLoadingSkeleton(
                width: double.infinity,
                height: 130,
                borderRadius: 20,
              ),
              SizedBox(height: 10),
              AppLoadingSkeleton(
                width: double.infinity,
                height: 130,
                borderRadius: 20,
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
                children: const [
                  SizedBox(height: 80),
                  AppEmptyState(
                    message: 'Artikel edukasi belum tersedia.',
                    subtitle:
                        'Cek kembali nanti untuk konten kesehatan terbaru.',
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
                final publishedAt = article.publishedAt != null
                    ? DateFormat(
                        'dd MMM yyyy',
                      ).format(article.publishedAt!.toLocal())
                    : '-';

                return AppCard(
                  onTap: () =>
                      context.push(AppRoutes.educationDetail(article.id)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if ((article.summary ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          article.summary!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.75),
                              ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if ((article.category ?? '').trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                article.category!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            publishedAt,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
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
}
