import '../models/education_article.dart';

abstract class EducationRepository {
  Future<List<EducationArticle>> getPublishedArticles();

  Future<List<EducationArticle>> getAllArticles();

  Future<EducationArticle?> getArticleById(String articleId);

  Future<void> createArticle(EducationArticleInput input);

  Future<void> updateArticle(String articleId, EducationArticleInput input);

  Future<void> setArticleStatus({
    required String articleId,
    required String status,
  });

  Future<void> deleteArticle(String articleId);
}
