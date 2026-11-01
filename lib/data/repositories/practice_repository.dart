/*
import '../../domain/models/question.dart';
import '../../utils/result.dart';
import '../services/question_api.dart';

/// The source of truth for practice questions. Owns the retry policy.
///
/// Keep the constructor and the signature of [nextQuestions] exactly.
class PracticeRepository {
  PracticeRepository({
    required this._api,
    required Future<void> Function(Duration) sleep,
    this._maxRetries = 2,
  })  : _sleep = sleep;

  // ignore: unused_field
  final QuestionApi _api;
  // ignore: unused_field
  final Future<void> Function(Duration) _sleep;
  // ignore: unused_field
  final int _maxRetries;

  /// TODO(W3): retry transient failures at most maxRetries times, waiting
  /// 1 s, 2 s, ... (Retry-After for 429, capped at 30 s). Return permanent
  /// failures after one call.
  Future<Result<List<Question>>> nextQuestions(String studentId) async {
    throw UnimplementedError('PracticeRepository.nextQuestions');
  }
}*/
import 'dart:math';
import '../../domain/models/question.dart';
import '../../utils/result.dart';
import '../services/api_failure.dart';
import '../services/question_api.dart';

class PracticeRepository {
  PracticeRepository({
    required this._api,
    required Future<void> Function(Duration) sleep,
    this._maxRetries = 2,
  })  : _sleep = sleep;

  final QuestionApi _api;
  final Future<void> Function(Duration) _sleep;
  final int _maxRetries;

  Future<Result<List<Question>>> nextQuestions(String studentId) async {
    int attempt = 0; 

    while (true) {
      final result = await _api.fetchNext(studentId: studentId);

      if (result is Ok<List<Question>>) {
        return result;
      }

      final failure = (result as Err<List<Question>>).failure;

        if (!failure.isTransient || attempt >= _maxRetries) {
        return result;
      }

      Duration waitDuration;
      if (failure is RateLimited) {
        final seconds = failure.retryAfter.inSeconds;
        waitDuration = Duration(seconds: seconds > 30 ? 30 : seconds);
      } else {
        waitDuration = Duration(seconds: pow(2, attempt).toInt());
      }

      await _sleep(waitDuration);

      attempt++;
    }
  }
}
