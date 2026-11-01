/// One practice question chosen for a student by the Masaraat backend.
/*final class Question {
  const Question({
    required this.id,
    required this.skillId,
    required this.stem,
    required this.choices,
  });

  final String id;
  final String skillId;
  final String stem;
  final List<String> choices;

  /// Reads one question from the API. Unknown fields are ignored.
  ///
  /// TODO(W3): throw a FormatException for a missing or wrongly typed field,
  /// or when `choices` is not a list of 2 to 6 non-empty strings.
  factory Question.fromJson(Map<String, Object?> json) {
    throw UnimplementedError('Question.fromJson');
  }
}*/
/// One practice question chosen for a student by the Masaraat backend.
library;
final class Question {
  const Question({
    required this.id,
    required this.skillId,
    required this.stem,
    required this.choices,
  });

  final String id;
  final String skillId;
  final String stem;
  final List<String> choices;

  /// Reads one question from the API. Unknown fields are ignored.
  factory Question.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Missing or invalid id');
    }

    final skillId = json['skillId'];
    if (skillId is! String || skillId.isEmpty) {
      throw const FormatException('Missing or invalid skillId');
    }

    final stem = json['stem'];
    if (stem is! String || stem.isEmpty) {
      throw const FormatException('Missing or invalid stem');
    }

    final choicesRaw = json['choices'];
    if (choicesRaw is! List || choicesRaw.length < 2 || choicesRaw.length > 6) {
      throw const FormatException('Invalid choices length (must be 2-6)');
    }

    final choices = <String>[];
    for (final choice in choicesRaw) {
      if (choice is! String || choice.isEmpty) {
        throw const FormatException('Invalid choice item');
      }
      choices.add(choice);
    }

    return Question(
      id: id,
      skillId: skillId,
      stem: stem,
      choices: choices,
    );
  }
}