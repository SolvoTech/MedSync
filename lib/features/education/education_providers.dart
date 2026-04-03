import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/datasources/education_remote_datasource.dart';
import '../../data/repositories/education_repository_impl.dart';
import '../../domain/models/education_article.dart';
import '../../domain/repositories/education_repository.dart';

final educationRemoteDataSourceProvider = Provider<EducationRemoteDataSource>((
  ref,
) {
  return EducationRemoteDataSource();
});

final educationRepositoryProvider = Provider<EducationRepository>((ref) {
  return EducationRepositoryImpl(ref.read(educationRemoteDataSourceProvider));
});

final publishedEducationArticlesProvider =
    FutureProvider.autoDispose<List<EducationArticle>>((ref) async {
      return ref.read(educationRepositoryProvider).getPublishedArticles();
    });

final educationArticleByIdProvider = FutureProvider.autoDispose
    .family<EducationArticle?, String>((ref, articleId) async {
      return ref.read(educationRepositoryProvider).getArticleById(articleId);
    });

final adminEducationArticlesProvider =
    FutureProvider.autoDispose<List<EducationArticle>>((ref) async {
      return ref.read(educationRepositoryProvider).getAllArticles();
    });
