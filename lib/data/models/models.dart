/// Modelos do conteúdo didático (carregados dos JSON em assets/content/).
library;

class Chapter {
  final String id;
  final String title;
  final int order;
  final String difficulty;
  final List<Lesson> lessons;
  final List<Exercise> exercises;

  const Chapter({
    required this.id,
    required this.title,
    required this.order,
    required this.difficulty,
    required this.lessons,
    required this.exercises,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      order: json['order'] as int,
      difficulty: json['difficulty'] as String,
      lessons: [
        for (final l in json['lessons'] as List)
          Lesson.fromJson(l as Map<String, dynamic>),
      ],
      exercises: [
        for (final e in json['exercises'] as List)
          Exercise.fromJson(e as Map<String, dynamic>),
      ],
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String body;
  final String example; // exemplo comentado, abre no editor

  const Lesson({
    required this.id,
    required this.title,
    required this.body,
    required this.example,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      example: json['example'] as String,
    );
  }
}

class Exercise {
  final String id;
  final String title;
  final String prompt;
  final String starterCode;
  final List<ExerciseTest> tests;
  final List<String> hints;

  const Exercise({
    required this.id,
    required this.title,
    required this.prompt,
    required this.starterCode,
    required this.tests,
    required this.hints,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      title: json['title'] as String,
      prompt: json['prompt'] as String,
      starterCode: json['starterCode'] as String,
      tests: [
        for (final t in json['tests'] as List)
          ExerciseTest.fromJson(t as Map<String, dynamic>),
      ],
      hints: [for (final h in (json['hints'] as List? ?? [])) h as String],
    );
  }
}

class ExerciseTest {
  final String name;
  final String code;

  const ExerciseTest({required this.name, required this.code});

  factory ExerciseTest.fromJson(Map<String, dynamic> json) {
    return ExerciseTest(
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }
}
