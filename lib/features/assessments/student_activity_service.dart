import 'package:dio/dio.dart';

import '../auth/services/account_service.dart';
import '../learning/learning_service.dart';

class StudentActivityService {
  StudentActivityService(this.account);
  final AccountService account;

  Future<Map<String, dynamic>> get(String path, {String? key}) async {
    final data = object((await account.request('GET', path))['data']);
    return key == null ? data : object(data[key] ?? data);
  }

  Future<LearningPage> list(
    String path,
    String key,
    int page, {
    bool public = false,
  }) async => LearningPage.decode(
    await account.request(
      'GET',
      '$path${path.contains('?') ? '&' : '?'}page=$page&limit=20',
      public: public,
    ),
    key,
  );

  Future<Map<String, dynamic>> mutate(
    String method,
    String path, {
    Object? data,
  }) async => object((await account.request(method, path, data: data))['data']);

  Future<Map<String, dynamic>> submitAssignment(
    String id, {
    required String text,
    MultipartFile? file,
  }) {
    if (text.trim().isEmpty && file == null) {
      throw ArgumentError('Add an answer or choose a file.');
    }
    return mutate(
      'POST',
      '/api/v1/assignments/$id/submissions',
      data: FormData.fromMap({
        if (text.trim().isNotEmpty) 'textAnswer': text.trim(),
        'file': ?file,
      }),
    );
  }
}
