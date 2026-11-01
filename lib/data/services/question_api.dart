/*
import 'package:http/http.dart' as http;

import '../../domain/models/question.dart';
import '../../utils/result.dart';

/// One call to the Masaraat questions API. Holds no state and never retries.
///
/// Keep the constructor and the signature of [fetchNext] exactly.
class QuestionApi {
  QuestionApi({
    required this._client,
    required Uri baseUrl,
    this._timeout = const Duration(seconds: 10),
  })  : _baseUrl = baseUrl;

  // ignore: unused_field
  final http.Client _client;
  // ignore: unused_field
  final Uri _baseUrl;
  // ignore: unused_field
  final Duration _timeout;

  /// `GET {baseUrl}/v1/students/{studentId}/next-questions?limit={limit}`.
  ///
  /// TODO(W3): see the README for the URL, headers, parsing, status mapping
  /// and network failures. Never throws for network or server problems.
  Future<Result<List<Question>>> fetchNext({
    required String studentId,
    int limit = 10,
  }) async {
    throw UnimplementedError('QuestionApi.fetchNext');
  }
}*/
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../domain/models/question.dart';
import '../../utils/result.dart';
import 'api_failure.dart'; 

class QuestionApi {
  QuestionApi({
    required this._client,
    required Uri baseUrl,
    this._timeout = const Duration(seconds: 10),
  })  : _baseUrl = baseUrl;

  final http.Client _client;
  final Uri _baseUrl;
  final Duration _timeout;

  Future<Result<List<Question>>> fetchNext({
    required String studentId,
    int limit = 10,
  }) async {
    if (limit < 1 || limit > 50) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 50');
    }

    final newPathSegments = List<String>.from(_baseUrl.pathSegments);
    if (newPathSegments.isNotEmpty && newPathSegments.last.isEmpty) {
      newPathSegments.removeLast();
    }
    newPathSegments.addAll(['v1', 'students', studentId, 'next-questions']);

    final uri = _baseUrl.replace(
      pathSegments: newPathSegments,
      queryParameters: {'limit': limit.toString()},
    );

    try {
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(_timeout);

      switch (response.statusCode) {
        case 200:
          try {
            final body = utf8.decode(response.bodyBytes);
            final json = jsonDecode(body);
            
            if (json is! Map<String, Object?> || json['questions'] is! List) {
              return const Err(BadResponse('Invalid JSON structure'));
            }

            final questionsList = json['questions'] as List;
            final questions = questionsList
                .map((item) => Question.fromJson(item as Map<String, Object?>))
                .toList();
                
            return Ok(questions);
          } catch (e) {
            return Err(BadResponse(e.toString()));
          }
          
        case 401:
          return const Err(Unauthorized());
          
        case 404:
          return const Err(NotFound());
          
        case 429:
          final retryAfterHeader = response.headers['retry-after'];
          final seconds = int.tryParse(retryAfterHeader ?? '') ?? 5;
          return Err(RateLimited(Duration(seconds: seconds)));
          
        case >= 500 && < 600:
          return Err(ServerError(response.statusCode));
          
        default:
          return Err(UnexpectedStatus(response.statusCode));
      }
    } on TimeoutException {
      return const Err(TimedOut());
    } on http.ClientException {
      return const Err(Offline());
    } catch (e) {
      return Err(BadResponse(e.toString()));
    }
  }
}