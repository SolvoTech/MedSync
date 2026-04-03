import '../../domain/models/education_article.dart';
import '../../domain/repositories/education_repository.dart';
import '../remote/datasources/education_remote_datasource.dart';

class EducationRepositoryImpl implements EducationRepository {
  EducationRepositoryImpl(this._remote);

  final EducationRemoteDataSource _remote;

  @override
  Future<List<EducationArticle>> getPublishedArticles() {
    return _remote.getPublishedArticles();
  }

  @override
  Future<List<EducationArticle>> getAllArticles() {
    return _remote.getAllArticles();
  }

  @override
  Future<EducationArticle?> getArticleById(String articleId) {
    return _remote.getArticleById(articleId);
  }

  @override
  Future<void> createArticle(EducationArticleInput input) {
    return _remote.createArticle(input);
  }

  @override
  Future<void> updateArticle(String articleId, EducationArticleInput input) {
    return _remote.updateArticle(articleId, input);
  }

  @override
  Future<void> setArticleStatus({
    required String articleId,
    required String status,
  }) {
    return _remote.setArticleStatus(articleId: articleId, status: status);
  }

  @override
  Future<void> deleteArticle(String articleId) {
    return _remote.deleteArticle(articleId);
  }
}
