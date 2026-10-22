import '../../../shared/models/learning_page.dart';
import '../../../shared/providers/auth_provider.dart';

class AdminService {
  AdminService(this.auth);
  final AuthProvider auth;

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) {
    if (!auth.authenticated || auth.role != 'ADMIN') {
      throw StateError('Administrator access required.');
    }
    return auth.service.request(method, '/api/v1/$path', data: data);
  }

  Future<LearningPage> list(
    String feature,
    int page,
    Map<String, String> filters, {
    String? courseId,
  }) async {
    final path = switch (feature) {
      'users' => 'users',
      'categories' => 'categories',
      'courses' => 'courses/admin/all',
      'enrollments' => 'enrollments/admin/all',
      'reviews' when courseId != null =>
        'courses/${Uri.encodeComponent(courseId)}/reviews',
      _ => throw StateError('Select a course first.'),
    };
    final query = <String, String>{
      'page': '$page',
      'limit': '20',
      if (feature == 'categories') 'activeOnly': 'false',
      ...filters,
    };
    return LearningPage.decode(
      await request('GET', '$path?${Uri(queryParameters: query).query}'),
      feature,
    );
  }
}
