// ignore_for_file: avoid_print
//
// Obsidian → Firestore Exam Parser
//
// Reads .md exam files from a directory and outputs a structured
// `database_seed.json` ready for Firestore import.
//
// Usage:
//   dart run scripts/obsidian_parser.dart <input_directory> [output_file]
//
// Example:
//   dart run scripts/obsidian_parser.dart ../exams/
//   dart run scripts/obsidian_parser.dart ../exams/ seed.json
//
// Markdown Format:
//   See the Obsidian_Exam_Authoring_Guide.md for full documentation.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

// ─── Entry Point ───────────────────────────────────────────────────────────

void main(List<String> args) {
  if (args.isEmpty) {
    print('');
    print('╔══════════════════════════════════════════════════════╗');
    print('║   Obsidian → Firestore Exam Parser                  ║');
    print('╠══════════════════════════════════════════════════════╣');
    print('║                                                      ║');
    print('║  Usage:                                               ║');
    print('║    dart run scripts/obsidian_parser.dart <dir> [out]  ║');
    print('║                                                      ║');
    print('║  <dir>  Directory containing .md exam files           ║');
    print('║  [out]  Output JSON file (default: database_seed.json)║');
    print('║                                                      ║');
    print('╚══════════════════════════════════════════════════════╝');
    print('');
    exit(1);
  }

  final inputDir = Directory(args[0]);
  final outputPath = args.length > 1 ? args[1] : 'database_seed.json';

  if (!inputDir.existsSync()) {
    print('❌ Error: Directory "${args[0]}" does not exist.');
    exit(1);
  }

  final mdFiles =
      inputDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  if (mdFiles.isEmpty) {
    print('⚠️  No .md files found in "${args[0]}".');
    exit(0);
  }

  print('📂 Found ${mdFiles.length} exam file(s) in "${args[0]}"');
  print('');

  final List<Map<String, dynamic>> exams = [];
  int successCount = 0;
  int errorCount = 0;

  for (final file in mdFiles) {
    final fileName = file.uri.pathSegments.last;
    try {
      final content = file.readAsStringSync();
      final exam = _parseExamFile(content, fileName, file.parent.path);
      exams.add(exam);
      final qCount = (exam['questions'] as List).length;
      print('  ✅ $fileName → ${exam['title']} ($qCount questions)');
      successCount++;
    } catch (e) {
      print('  ❌ $fileName → Error: $e');
      errorCount++;
    }
  }

  // Write output
  final output = {'exams': exams};
  final jsonString = const JsonEncoder.withIndent('  ').convert(output);
  File(outputPath).writeAsStringSync(jsonString);

  print('');
  print('══════════════════════════════════════════════════════');
  print('  📊 Results: $successCount succeeded, $errorCount failed');
  print('  📄 Output:  $outputPath');
  print('══════════════════════════════════════════════════════');
}

// ─── File Parser ───────────────────────────────────────────────────────────

/// Parses a single .md exam file into a Firestore-ready map.
///
/// Expected format:
/// ```
/// ---
/// title: "Exam Title"
/// subject: "Mathematics"
/// group: "Grade 10"
/// difficulty: "medium"
/// duration_minutes: 30
/// xp_reward: 100
/// created_by: "admin"
/// status: "published"
/// ---
///
/// ## Q1
/// Question text with $LaTeX$...
///
/// - [ ] Option A
/// - [x] Option B (correct)
/// - [ ] Option C
/// - [ ] Option D
///
/// ## Q2
/// ...
///
/// ## Answer Key
///
/// ### Q1
/// Explanation for Q1...
///
/// ### Q2
/// Explanation for Q2...
/// ```
Map<String, dynamic> _parseExamFile(
  String content,
  String fileName,
  String dirPath,
) {
  // 1. Extract frontmatter
  final frontmatter = _extractFrontmatter(content);
  if (frontmatter.isEmpty) {
    throw FormatException('No YAML frontmatter found in $fileName');
  }

  // 2. Extract body (everything after second ---)
  final body = _extractBody(content);

  // 3. Split body into questions section and answer key section
  final sections = _splitAnswerKey(body);
  final questionsBody = sections['questions']!;
  final answerKeyBody = sections['answerKey']!;

  // 4. Parse individual questions
  final questions = _parseQuestions(questionsBody, dirPath);
  if (questions.isEmpty) {
    throw FormatException('No questions found in $fileName');
  }

  // 5. Parse answer key and merge explanations into questions
  final explanations = _parseAnswerKey(answerKeyBody);

  final subject = frontmatter['subject'] as String?;
  if (subject == null || subject.isEmpty) {
    throw FormatException(
      'Missing required field "subject" in frontmatter of $fileName',
    );
  }

  final group = frontmatter['group'] as String?;
  if (group == null || group.isEmpty) {
    throw FormatException(
      'Missing required field "group" in frontmatter of $fileName',
    );
  }

  for (final question in questions) {
    final qNum = question['order'] as int;
    final key = 'Q$qNum';
    if (explanations.containsKey(key)) {
      question['explanation'] = explanations[key];
    }
    // Inject denormalised metadata for random search
    question['subject'] = subject;
    question['group'] = group;
    // Add xpReward = points if not set
    question['xpReward'] ??= question['points'] ?? 1;
    question['random'] = _generateRandomDouble();
  }

  // 6. Build exam document
  final title = frontmatter['title'] as String? ?? _titleFromFileName(fileName);
  final now = DateTime.now().toUtc().toIso8601String();

  return {
    'title': title,
    'description': frontmatter['description'] as String? ?? '',
    'subject': subject,
    'group': group,
    'durationMinutes': _parseInt(frontmatter['duration_minutes'], 30),
    'createdBy': frontmatter['created_by'] as String? ?? 'obsidian_parser',
    'status': frontmatter['status'] as String? ?? 'draft',
    'xpReward': _parseInt(frontmatter['xp_reward'], 100),
    'questionCount': _parseInt(frontmatter['question_count'], questions.length),
    'createdAt': now,
    'updatedAt': now,
    'questions': questions,
  };
}

// ─── Frontmatter ───────────────────────────────────────────────────────────

/// Extracts YAML frontmatter between `---` delimiters into a Map.
///
/// Handles simple key: value pairs and key: "quoted value" pairs.
/// Does NOT use a full YAML parser to keep this script dependency-free.
Map<String, dynamic> _extractFrontmatter(String content) {
  final trimmed = content.trim();
  if (!trimmed.startsWith('---')) return {};

  final secondDash = trimmed.indexOf('---', 3);
  if (secondDash == -1) return {};

  final yamlBlock = trimmed.substring(3, secondDash).trim();
  final Map<String, dynamic> result = {};

  for (final line in yamlBlock.split('\n')) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) continue;

    final colonIndex = trimmedLine.indexOf(':');
    if (colonIndex == -1) continue;

    final key = trimmedLine.substring(0, colonIndex).trim().toLowerCase();
    var value = trimmedLine.substring(colonIndex + 1).trim();

    // Strip surrounding quotes
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }

    // Try numeric parsing
    final intVal = int.tryParse(value);
    if (intVal != null) {
      result[key] = intVal;
      continue;
    }
    final doubleVal = double.tryParse(value);
    if (doubleVal != null) {
      result[key] = doubleVal;
      continue;
    }

    // Boolean
    if (value.toLowerCase() == 'true') {
      result[key] = true;
      continue;
    }
    if (value.toLowerCase() == 'false') {
      result[key] = false;
      continue;
    }

    result[key] = value;
  }

  return result;
}

/// Extracts the body content after the closing `---` of the frontmatter.
String _extractBody(String content) {
  final trimmed = content.trim();
  if (!trimmed.startsWith('---')) return trimmed;

  final secondDash = trimmed.indexOf('---', 3);
  if (secondDash == -1) return trimmed;

  return trimmed.substring(secondDash + 3).trim();
}

// ─── Question Parsing ──────────────────────────────────────────────────────

/// Splits the body into a questions section and an answer key section.
///
/// The answer key starts at `## Answer Key` (case-insensitive).
Map<String, String> _splitAnswerKey(String body) {
  // Look for ## Answer Key header (case-insensitive)
  final answerKeyPattern = RegExp(
    r'^##\s+Answer\s*Key\s*$',
    multiLine: true,
    caseSensitive: false,
  );

  final match = answerKeyPattern.firstMatch(body);
  if (match == null) {
    return {'questions': body, 'answerKey': ''};
  }

  return {
    'questions': body.substring(0, match.start).trim(),
    'answerKey': body.substring(match.end).trim(),
  };
}

/// Parses the questions section into a list of question maps.
///
/// Questions are delimited by `## Q1`, `## Q2`, etc.
/// Options are markdown checkboxes: `- [ ]` (wrong) and `- [x]` (correct).
List<Map<String, dynamic>> _parseQuestions(
  String questionsBody,
  String dirPath,
) {
  if (questionsBody.trim().isEmpty) return [];

  // Split by ## Q<number> headers
  final headerPattern = RegExp(r'^##\s+Q(\d+)', multiLine: true);
  final matches = headerPattern.allMatches(questionsBody).toList();

  if (matches.isEmpty) return [];

  final List<Map<String, dynamic>> questions = [];

  for (int i = 0; i < matches.length; i++) {
    final match = matches[i];
    final qNumber = int.parse(match.group(1)!);

    // Get the content between this header and the next (or end)
    final start = match.end;
    final end = i + 1 < matches.length
        ? matches[i + 1].start
        : questionsBody.length;
    final block = questionsBody.substring(start, end).trim();

    final question = _parseSingleQuestion(block, qNumber, dirPath);
    questions.add(question);
  }

  return questions;
}

/// Parses a single question block into a structured map.
Map<String, dynamic> _parseSingleQuestion(
  String block,
  int order,
  String dirPath,
) {
  final lines = block.split('\n');

  // Separate question text, options, and metadata
  final textLines = <String>[];
  final options = <String>[];
  String correctAnswer = '';
  String questionType = 'mcq';
  int points = 1;
  String explanation = '';
  String? diagramUrl;

  bool inOptions = false;

  for (final rawLine in lines) {
    final line = rawLine.trimRight();

    // Check for checkbox option: - [ ] or - [x]
    final optionMatch = RegExp(r'^\s*-\s+\[([ xX])\]\s*(.+)$').firstMatch(line);
    if (optionMatch != null) {
      inOptions = true;
      final isCorrect = optionMatch.group(1)!.toLowerCase() == 'x';
      final optionText = optionMatch.group(2)!.trim();
      options.add(optionText);
      if (isCorrect) {
        correctAnswer = optionText;
      }
      continue;
    }

    // Check for metadata lines (bold key-value)
    final metaMatch = RegExp(r'^\*\*(\w+):\*\*\s*(.+)$').firstMatch(line);
    if (metaMatch != null) {
      final key = metaMatch.group(1)!.toLowerCase();
      final value = metaMatch.group(2)!.trim();
      switch (key) {
        case 'points':
          points = int.tryParse(value) ?? 1;
        case 'type':
          questionType = _normalizeQuestionType(value);
        case 'explanation':
          explanation = value;
        case 'diagramurl':
          diagramUrl = value;
      }
      continue;
    }

    // Check for blockquote explanation: > **Explanation:** ...
    final explanationMatch = RegExp(
      r'^\s*>\s*\*?\*?Explanation:?\*?\*?\s*(.+)$',
    ).firstMatch(line);
    if (explanationMatch != null) {
      explanation = explanationMatch.group(1)!.trim();
      continue;
    }

    // Skip empty lines between options section and metadata
    if (inOptions && line.trim().isEmpty) continue;

    // Check for markdown images ![alt](path) or ![[path]]
    final mdImageMatch = RegExp(
      r'!\[.*?\]\((.+?)\)|!\[\[(.+?)\]\]',
    ).firstMatch(line);
    if (mdImageMatch != null && diagramUrl == null) {
      diagramUrl = (mdImageMatch.group(1) ?? mdImageMatch.group(2))!.trim();
      final lineWithoutImg = line.replaceAll(mdImageMatch.group(0)!, '').trim();
      if (lineWithoutImg.isNotEmpty) {
        textLines.add(lineWithoutImg);
      }
      continue;
    }

    // It's question text
    if (!inOptions && line.trim().isNotEmpty) {
      textLines.add(line.trim());
    }
  }

  final questionText = textLines.join('\n').trim();

  // If no checkbox options but it's true/false, generate options
  if (options.isEmpty && questionType == 'true_false') {
    options.addAll(['True', 'False']);
  }

  if (diagramUrl != null && !diagramUrl!.startsWith('http')) {
    final imgFile = File(diagramUrl!);
    if (!imgFile.isAbsolute) {
      diagramUrl = File('$dirPath/$diagramUrl').absolute.path;
    }
  }

  return {
    'questionText': questionText,
    'questionType': questionType,
    'options': options,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'points': points,
    'order': order,
    if (diagramUrl != null) 'diagramUrl': diagramUrl,
  };
}

/// Parses the Answer Key section into a map of question number → explanation.
///
/// Format:
/// ```
/// ### Q1
/// Explanation text for Q1...
///
/// ### Q2
/// Explanation text for Q2...
/// ```
Map<String, String> _parseAnswerKey(String answerKeyBody) {
  if (answerKeyBody.trim().isEmpty) return {};

  final Map<String, String> explanations = {};
  final headerPattern = RegExp(r'^###\s+(Q\d+)', multiLine: true);
  final matches = headerPattern.allMatches(answerKeyBody).toList();

  for (int i = 0; i < matches.length; i++) {
    final key = matches[i].group(1)!;
    final start = matches[i].end;
    final end = i + 1 < matches.length
        ? matches[i + 1].start
        : answerKeyBody.length;

    final explanation = answerKeyBody
        .substring(start, end)
        .trim()
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .join('\n');

    if (explanation.isNotEmpty) {
      explanations[key] = explanation;
    }
  }

  return explanations;
}

// ─── Helpers ───────────────────────────────────────────────────────────────

/// Normalizes difficulty strings to match Firestore enum values.
String _normalizeDifficulty(String raw) {
  return switch (raw.toLowerCase().trim()) {
    'easy' => 'easy',
    'medium' => 'medium',
    'hard' => 'hard',
    'ultra_hard' || 'ultra-hard' || 'ultrahard' || 'very hard' => 'ultra_hard',
    _ => 'medium',
  };
}

/// Normalizes question type strings to match Firestore enum values.
String _normalizeQuestionType(String raw) {
  return switch (raw.toLowerCase().trim()) {
    'mcq' || 'multiple_choice' || 'multiple choice' => 'mcq',
    'true_false' || 'true/false' || 'truefalse' || 'tf' => 'true_false',
    'short_answer' || 'short answer' || 'short' => 'short_answer',
    _ => 'mcq',
  };
}

/// Safely parses an int from a dynamic value with a fallback.
int _parseInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Derives an exam title from the file name.
String _titleFromFileName(String fileName) {
  return fileName
      .replaceAll('.md', '')
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');
}

/// Generates a random double between 0 and 1.
double _generateRandomDouble() {
  return Random().nextDouble();
}
