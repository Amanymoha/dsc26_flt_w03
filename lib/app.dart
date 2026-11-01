/*import 'package:flutter/material.dart';

import 'data/repositories/practice_repository.dart';

/// The practice app. The tests only ever call this function.
///
/// TODO(W3): load on start; show loading, the list, the empty state or the
/// failure view; a refresh action in the app bar, disabled while loading.
/// Use ChangeNotifier, Riverpod or Bloc inside, your choice.
Widget buildPracticeApp({
  required PracticeRepository repository,
  String studentId = 'demo',
}) {
  return const MaterialApp(
    home: Scaffold(body: Center(child: Text('TODO: practice screen'))),
  );
}
*/
import 'package:flutter/material.dart';
import 'data/repositories/practice_repository.dart';
import 'data/services/api_failure.dart';
import 'domain/models/question.dart';
import 'utils/result.dart';

sealed class PracticeState {
  const PracticeState();
}

class LoadingState extends PracticeState {
  const LoadingState();
}

class EmptyState extends PracticeState {
  const EmptyState();
}

class LoadedState extends PracticeState {
  const LoadedState(this.questions);
  final List<Question> questions;
}

class ErrorState extends PracticeState {
  const ErrorState(this.failure);
  final ApiFailure failure;
}

class PracticeViewModel extends ChangeNotifier {
  PracticeViewModel({required this.repository, required this.studentId});

  final PracticeRepository repository;
  final String studentId;

  PracticeState _state = const LoadingState();
  PracticeState get state => _state;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> fetchQuestions() async {
    if (_state is LoadingState && state is! LoadingState) return;

    _state = const LoadingState();
    notifyListeners();

    final result = await repository.nextQuestions(studentId);

    if (_isDisposed) return;

    _state = switch (result) {
      Ok(value: final questions) =>
        questions.isEmpty ? const EmptyState() : LoadedState(questions),
      Err(failure: final failure) => ErrorState(failure),
    };
    
    notifyListeners();
  }
}

Widget buildPracticeApp({
  required PracticeRepository repository,
  String studentId = 'demo',
}) {
  return MaterialApp(
    home: PracticeScreen(repository: repository, studentId: studentId),
  );
}

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.repository, required this.studentId});
  final PracticeRepository repository;
  final String studentId;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PracticeViewModel(repository: widget.repository, studentId: widget.studentId);
    _viewModel.fetchQuestions(); 
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  String _getErrorMessage(ApiFailure failure) {
    return switch (failure) {
      Offline() => 'No connection, try again',
      TimedOut() => 'Slow connection, try again',
      ServerError() => 'Server is busy, try again',
      RateLimited() => 'Too many requests, please wait',
      Unauthorized() => 'Session expired, please sign in again',
      NotFound() => 'No questions found',
      BadResponse() || UnexpectedStatus() => 'Something went wrong',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final state = _viewModel.state;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Practice'),
            actions: [
              IconButton(
                key: const Key('practice-refresh'),
                icon: const Icon(Icons.refresh),
                onPressed: state is LoadingState ? null : _viewModel.fetchQuestions,
              ),
            ],
          ),
          body: Center(
            child: switch (state) {
              LoadingState() => const CircularProgressIndicator(
                  key: Key('practice-loading'),
                ),
              EmptyState() => const Text(
                  'you have finished today\'s practice',
                  key: Key('practice-empty'),
                ),
              LoadedState(questions: final list) => ListView.builder(
                  key: const Key('practice-list'),
                  itemCount: list.length,
                  itemBuilder: (context, i) => ListTile(
                    key: Key('question-${list[i].id}'),
                    title: Text(list[i].stem),
                  ),
                ),
              ErrorState(failure: final f) => Column(
                  key: const Key('practice-error'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_getErrorMessage(f)),
                    const SizedBox(height: 20),
                    if (f is Unauthorized)
                      ElevatedButton(
                        key: const Key('practice-signin'),
                        onPressed: _viewModel.fetchQuestions,
                        child: const Text('Sign In'),
                      )
                    else
                      ElevatedButton(
                        key: const Key('practice-retry'),
                        onPressed: _viewModel.fetchQuestions,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
            },
          ),
        );
      },
    );
  }
}