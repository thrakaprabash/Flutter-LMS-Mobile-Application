import 'package:dio/dio.dart';

import '../../auth/services/account_service.dart';
import '../../learning/learning_service.dart';

/// Instructor operations always use the authenticated transport and backend ownership checks.
class InstructorService {
  InstructorService(this.account);
  final AccountService account;

  Future<Map<String, dynamic>> get(String path, String key) async {
    final data = object((await account.request('GET', path))['data']);
    if (data[key] is Map) {
      return {...data, ...object(data[key])}..remove(key);
    }
    return data;
  }

  Future<LearningPage> list(String path, String key, int page) async =>
      LearningPage.decode(
        await account.request(
          'GET',
          '$path${path.contains('?') ? '&' : '?'}page=$page&limit=20',
        ),
        key,
      );

  Future<Map<String, dynamic>> save(
    String method,
    String path, [
    Map<String, dynamic>? data,
  ]) async => object((await account.request(method, path, data: data))['data']);

  Future<void> upload(
    String path,
    String field,
    MultipartFile file,
    ProgressCallback progress,
  ) async {
    await account.request(
      'POST',
      path,
      data: FormData.fromMap({field: file}),
      progress: progress,
    );
  }

  static void validateGrade(
    String status,
    num? marks,
    num maximum,
    String feedback,
  ) {
    if (!['GRADED', 'RESUBMISSION_REQUIRED'].contains(status)) {
      throw ArgumentError('Choose a grading status.');
    }
    if (status == 'GRADED' &&
        (marks == null || !marks.isFinite || marks < 0 || marks > maximum)) {
      throw ArgumentError('Marks must be between 0 and $maximum.');
    }
    if (status == 'RESUBMISSION_REQUIRED' && feedback.trim().isEmpty) {
      throw ArgumentError('Explain what the student needs to correct.');
    }
  }
}
