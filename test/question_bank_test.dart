import 'package:flutter_test/flutter_test.dart';
import 'package:quizbaaz/data/models/localized_text.dart';
import 'package:quizbaaz/data/models/question_model.dart';
import 'package:quizbaaz/data/services/question_fingerprint.dart';
import 'package:quizbaaz/data/services/question_validator.dart';

/// Builds a valid trilingual question, with individual pieces overridable so a
/// test can break exactly one rule at a time.
QuestionModel buildQuestion({
  String id = 'math_ch1_q001',
  Map<String, String>? question,
  List<Map<String, String>>? options,
  int correctIndex = 1,
  Map<String, String>? explanation,
  int points = 10,
  int timeLimitSec = 15,
}) {
  return QuestionModel(
    id: id,
    questionText: LocalizedText(question ??
        const {
          'en': 'What is the HCF of 96 and 404?',
          'bn': '৯৬ এবং ৪০৪-এর গ.সা.গু. কত?',
          'hi': '96 और 404 का म.स.प. क्या है?',
        }),
    optionTexts: (options ??
            const [
              {'en': 'Two', 'bn': 'দুই', 'hi': 'दो'},
              {'en': 'Four', 'bn': 'চার', 'hi': 'चार'},
              {'en': 'Eight', 'bn': 'আট', 'hi': 'आठ'},
              {'en': 'Sixteen', 'bn': 'ষোলো', 'hi': 'सोलह'},
            ])
        .map(LocalizedText.new)
        .toList(),
    correctIndex: correctIndex,
    explanationText: LocalizedText(explanation ??
        const {
          'en': 'Euclid division gives 4 as the highest common factor.',
          'bn': 'ইউক্লিডের বিভাজন অনুসারে গ.সা.গু. ৪।',
          'hi': 'यूक्लिड विभाजन से म.स.प. 4 प्राप्त होता है।',
        }),
    points: points,
    timeLimitSec: timeLimitSec,
  );
}

void main() {
  group('QuestionFingerprint.normalise', () {
    test('ignores case, punctuation and spacing', () {
      const a = 'What is the HCF of 96 and 404?';
      const b = '  what   is the hcf of 96 and 404  ';
      expect(QuestionFingerprint.normalise(a),
          QuestionFingerprint.normalise(b));
    });

    test('keeps digits — different numbers are different questions', () {
      expect(
        QuestionFingerprint.fingerprint('Find the HCF of 96 and 404'),
        isNot(QuestionFingerprint.fingerprint('Find the HCF of 18 and 24')),
      );
    });

    test('preserves non-Latin scripts', () {
      final normalised =
          QuestionFingerprint.normalise('গ.সা.গু. কত? — ৯৬ ও ৪০৪');
      expect(normalised, contains('গ'));
      expect(normalised, contains('৯৬'));
      expect(normalised, isNot(contains('.')));
    });

    test('an empty stem has no fingerprint', () {
      expect(QuestionFingerprint.fingerprint('   '), '');
    });
  });

  group('QuestionFingerprint.similarity', () {
    test('rephrasings of the same question score high', () {
      final score = QuestionFingerprint.similarity(
        'What is the HCF of 96 and 404?',
        'Find the HCF of 96 and 404.',
      );
      expect(score, greaterThanOrEqualTo(0.85));
    });

    test('different questions in the same topic score low', () {
      final score = QuestionFingerprint.similarity(
        'What is the HCF of 96 and 404?',
        'State the fundamental theorem of arithmetic.',
      );
      expect(score, lessThan(0.4));
    });

    test('findNearDuplicate reports the closest match above the threshold', () {
      final match = QuestionFingerprint.findNearDuplicate(
        'Find the HCF of 96 and 404.',
        {
          'math_ch1_q014': 'What is the HCF of 96 and 404?',
          'math_ch1_q020': 'Define an irrational number.',
        },
      );
      expect(match, isNotNull);
      expect(match!.questionId, 'math_ch1_q014');
    });

    test('returns null when nothing is close', () {
      expect(
        QuestionFingerprint.findNearDuplicate(
            'Define an irrational number.', {'q1': 'What is 2 plus 2?'}),
        isNull,
      );
    });
  });

  group('QuestionFingerprint.nextSequence', () {
    test('continues from the highest id, not the count', () {
      // The gap matters: q002 was deleted. Reusing 3 would overwrite q003.
      expect(
        QuestionFingerprint.nextSequence(
            ['math_ch1_q001', 'math_ch1_q003', 'math_ch1_q004']),
        5,
      );
    });

    test('starts at 1 for an empty chapter', () {
      expect(QuestionFingerprint.nextSequence(const []), 1);
    });

    test('ignores ids that do not follow the convention', () {
      expect(
        QuestionFingerprint.nextSequence(['legacy-question', 'math_ch1_q007']),
        8,
      );
    });

    test('builds zero-padded ids', () {
      expect(QuestionFingerprint.buildId('math_ch1', 42), 'math_ch1_q042');
      expect(QuestionFingerprint.buildId('math_ch1', 7), 'math_ch1_q007');
    });
  });

  group('QuestionValidator — accepts good content', () {
    test('a complete trilingual question is clean', () {
      final result = QuestionValidator.validate(buildQuestion());
      expect(result.isAcceptable, isTrue);
      expect(result.isClean, isTrue, reason: result.summary);
    });
  });

  group('QuestionValidator — rejects what a model actually gets wrong', () {
    test('correct_index past the end of the options', () {
      final result =
          QuestionValidator.validate(buildQuestion(correctIndex: 4));
      expect(result.isAcceptable, isFalse);
      expect(result.summary, contains('correct_index'));
    });

    test('negative correct_index', () {
      expect(
        QuestionValidator.validate(buildQuestion(correctIndex: -1))
            .isAcceptable,
        isFalse,
      );
    });

    test('an option that lost a language', () {
      final result = QuestionValidator.validate(buildQuestion(options: const [
        {'en': 'Two', 'bn': 'দুই', 'hi': 'दो'},
        {'en': 'Four', 'bn': 'চার'}, // no Hindi
        {'en': 'Eight', 'bn': 'আট', 'hi': 'आठ'},
        {'en': 'Sixteen', 'bn': 'ষোলো', 'hi': 'सोलह'},
      ]));
      expect(result.isAcceptable, isFalse);
      expect(result.rejections.map((i) => i.message).join(),
          contains('missing "hi"'));
    });

    test('two options identical in one language', () {
      final result = QuestionValidator.validate(buildQuestion(options: const [
        {'en': 'Two', 'bn': 'দুই', 'hi': 'दो'},
        // Distinct in English, collapsed in Bangla — unanswerable in bn.
        {'en': 'Twice', 'bn': 'দুই', 'hi': 'दुगुना'},
        {'en': 'Eight', 'bn': 'আট', 'hi': 'आठ'},
        {'en': 'Sixteen', 'bn': 'ষোলো', 'hi': 'सोलह'},
      ]));
      expect(result.isAcceptable, isFalse);
      expect(result.rejections.map((i) => i.message).join(),
          contains('identical in "bn"'));
    });

    test('a translation that is just the English pasted back', () {
      final result = QuestionValidator.validate(buildQuestion(question: const {
        'en': 'What is the HCF of 96 and 404?',
        'bn': 'What is the HCF of 96 and 404?',
        'hi': '96 और 404 का म.स.प. क्या है?',
      }));
      expect(result.isAcceptable, isFalse);
      expect(result.summary, contains('identical to English'));
    });

    test('but identical numeric or symbolic text is allowed', () {
      // "H2O" is the same in every language; that is not a skipped translation.
      final result = QuestionValidator.validate(buildQuestion(options: const [
        {'en': 'H2O', 'bn': 'H2O', 'hi': 'H2O'},
        {'en': 'CO2', 'bn': 'CO2', 'hi': 'CO2'},
        {'en': 'NaCl', 'bn': 'NaCl', 'hi': 'NaCl'},
        {'en': 'O2', 'bn': 'O2', 'hi': 'O2'},
      ]));
      expect(result.isAcceptable, isTrue, reason: result.summary);
    });

    test('a single technical term kept in English is allowed', () {
      // The authoring guide says a term may stay in English when that is what
      // the classroom uses. Only multi-word prose counts as untranslated.
      final result = QuestionValidator.validate(buildQuestion(options: const [
        {'en': 'Router', 'bn': 'Router', 'hi': 'Router'},
        {'en': 'Switch', 'bn': 'Switch', 'hi': 'Switch'},
        {'en': 'Modem', 'bn': 'মডেম', 'hi': 'मॉडेम'},
        {'en': 'Hub', 'bn': 'হাব', 'hi': 'हब'},
      ]));
      expect(result.isAcceptable, isTrue, reason: result.summary);
    });

    test('too few options', () {
      final result = QuestionValidator.validate(buildQuestion(
        options: const [
          {'en': 'Yes', 'bn': 'হ্যাঁ', 'hi': 'हाँ'},
        ],
        correctIndex: 0,
      ));
      expect(result.isAcceptable, isFalse);
    });

    test('three options are allowed but warned about', () {
      final result = QuestionValidator.validate(buildQuestion(
        options: const [
          {'en': 'Two', 'bn': 'দুই', 'hi': 'दो'},
          {'en': 'Four', 'bn': 'চার', 'hi': 'चार'},
          {'en': 'Eight', 'bn': 'আট', 'hi': 'आठ'},
        ],
      ));
      expect(result.isAcceptable, isTrue);
      expect(result.warnings, isNotEmpty);
    });

    test('an empty stem', () {
      final result =
          QuestionValidator.validate(buildQuestion(question: const {}));
      expect(result.isAcceptable, isFalse);
    });

    test('out-of-range points and time limit', () {
      expect(QuestionValidator.validate(buildQuestion(points: 0)).isAcceptable,
          isFalse);
      expect(
        QuestionValidator.validate(buildQuestion(timeLimitSec: 2)).isAcceptable,
        isFalse,
      );
    });

    test('a missing explanation is a warning, not a rejection', () {
      final result =
          QuestionValidator.validate(buildQuestion(explanation: const {}));
      expect(result.isAcceptable, isTrue);
      expect(result.warnings, isNotEmpty);
    });
  });

  group('QuestionValidator — duplicates', () {
    test('an exact duplicate is rejected', () {
      final question = buildQuestion();
      final fingerprint = QuestionFingerprint.fingerprint(
          question.questionText.resolve('en'));

      final result = QuestionValidator.validate(
        question,
        existingFingerprints: {fingerprint},
      );
      expect(result.isAcceptable, isFalse);
      expect(result.summary, contains('already in the chapter'));
    });

    test('a near-duplicate is flagged for review, not rejected', () {
      final result = QuestionValidator.validate(
        buildQuestion(question: const {
          'en': 'Find the HCF of 96 and 404.',
          'bn': '৯৬ ও ৪০৪-এর গ.সা.গু. নির্ণয় করো।',
          'hi': '96 और 404 का म.स.प. ज्ञात कीजिए।',
        }),
        existingStems: const {
          'math_ch1_q014': 'What is the HCF of 96 and 404?',
        },
      );
      expect(result.isAcceptable, isTrue,
          reason: 'a near-duplicate is a judgement call for the admin');
      expect(result.nearDuplicate, isNotNull);
      expect(result.nearDuplicate!.questionId, 'math_ch1_q014');
    });

    test('a batch cannot duplicate itself', () {
      final results = QuestionValidator.validateBatch([
        buildQuestion(id: 'math_ch1_q001'),
        buildQuestion(id: 'math_ch1_q002'), // same stem as the first
      ]);
      expect(results[0].isAcceptable, isTrue);
      expect(results[1].isAcceptable, isFalse,
          reason: 'the second copy must be caught within the same batch');
    });
  });

  group('the append guarantee', () {
    test('generating into a full chapter grows it — 40 + 10 = 50', () {
      // The failure this whole design exists to prevent: a new batch replacing
      // the chapter instead of extending it.
      final existing = List.generate(
        40,
        (i) => buildQuestion(
          id: QuestionFingerprint.buildId('math_ch1', i + 1),
          question: {
            'en': 'Existing question number ${i + 1}?',
            'bn': 'পুরোনো প্রশ্ন ${i + 1}?',
            'hi': 'पुराना प्रश्न ${i + 1}?',
          },
        ),
      );

      final nextStart =
          QuestionFingerprint.nextSequence(existing.map((q) => q.id));
      expect(nextStart, 41);

      final generated = List.generate(
        10,
        (i) => buildQuestion(
          id: QuestionFingerprint.buildId('math_ch1', nextStart + i),
          question: {
            'en': 'Newly generated question number ${i + 1}?',
            'bn': 'নতুন প্রশ্ন ${i + 1}?',
            'hi': 'नया प्रश्न ${i + 1}?',
          },
        ),
      );

      final results = QuestionValidator.validateBatch(
        generated,
        existingStems: {
          for (final q in existing) q.id: q.questionText.resolve('en'),
        },
        existingFingerprints: {
          for (final q in existing)
            QuestionFingerprint.fingerprint(q.questionText.resolve('en')),
        },
      );
      expect(results.every((r) => r.isAcceptable), isTrue,
          reason: results.map((r) => r.summary).join(' | '));

      // Appending, the way the service will: existing first, new after.
      final merged = <String, QuestionModel>{
        for (final q in existing) q.id: q,
        for (final q in generated) q.id: q,
      };

      expect(merged.length, 50);
      expect(merged.keys.toSet().length, 50, reason: 'ids must stay unique');
      for (final q in existing) {
        expect(merged.containsKey(q.id), isTrue,
            reason: '${q.id} was lost — this is the bug we must never ship');
      }
      expect(merged.containsKey('math_ch1_q041'), isTrue);
      expect(merged.containsKey('math_ch1_q050'), isTrue);
    });

    test('re-running the same batch is idempotent, not additive', () {
      final batch = List.generate(
        3,
        (i) => buildQuestion(
          id: QuestionFingerprint.buildId('math_ch1', i + 1),
          question: {
            'en': 'Question ${i + 1}?',
            'bn': 'প্রশ্ন ${i + 1}?',
            'hi': 'प्रश्न ${i + 1}?',
          },
        ),
      );

      // Writing by document id twice must not create six documents.
      final bank = <String, QuestionModel>{};
      for (final q in [...batch, ...batch]) {
        bank[q.id] = q;
      }
      expect(bank.length, 3);
    });
  });
}
