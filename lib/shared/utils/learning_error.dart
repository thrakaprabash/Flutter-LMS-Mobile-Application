import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';

String learningError(Object error) => error is DioException
    ? ApiException.fromDio(error).message
    : error is ApiException
    ? error.message
    : 'Unable to load learning content. Please try again.';
