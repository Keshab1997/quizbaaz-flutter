import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/models/localized_text.dart';
import '../../../data/models/question_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/question_bank_service.dart';
import '../../../data/services/question_fingerprint.dart';
import '../../../data/services/question_validator.dart';
import '../../widgets/glass_card.dart';
import 'widgets/trilingual_field.dart';

/// The question bank for one chapter.
///
/// Lists what is already there — the admin's first question is always "what do
/// I already have?" — and offers the two ways to add: by hand, or by
/// generating a batch.
///
/// Deletion is per question and confirmed. There is no "clear chapter": the
/// service underneath has no method for it, and this screen does not invent
/// one by looping.
class QuestionManagerScreen extends StatefulWidget {
  final String categoryId;
  final ChapterModel chapter;

  const QuestionManagerScreen({
    super.key,
    required this.categoryId,
    required this.chapter,
  });

  @override
  State<QuestionManagerScreen> createState() => _QuestionManagerScreenState();
}

enum _Filter { all, needsTranslation, ai, manual }

class _QuestionManagerScreenState extends State<QuestionManagerScreen> {
  final _bank = QuestionBankService();

  List<QuestionModel> _questions = [];
  Map<String, ValidationResult> _validation = {};
  bool _loading = true;
  String _search = '';
  _Filter _filter = _Filter.all;

  String get _chapterId => widget.chapter.chapterId;

  String get _actorUid =>
      context.read<AuthProvider>().firebaseUser?.uid ?? 'unknown';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    List<QuestionModel> questions;
    try {
      questions = await _bank.fetchQuestions(_chapterId);
    } catch (e) {
      questions = [];
      if (mounted) _toast('Could not load questions: $e', error: true);
    }

    // Validate what is already stored, so pre-existing gaps are visible rather
    // than only being caught on the way in.
    final results = QuestionValidator.validateBatch(questions);

    if (!mounted) return;
    setState(() {
      _questions = questions;
      _validation = {
        for (var i = 0; i < questions.length; i++) questions[i].id: results[i]
      };
      _loading = false;
    });
  }

  List<QuestionModel> get _visible {
    final needle = _search.trim().toLowerCase();
    return _questions.where((q) {
      if (needle.isNotEmpty) {
        final haystack = [
          q.id,
          ...q.questionText.toJson().values,
          for (final o in q.optionTexts) ...o.toJson().values,
        ].join(' ').toLowerCase();
        if (!haystack.contains(needle)) return false;
      }

      switch (_filter) {
        case _Filter.needsTranslation:
          return !q.isFullyTranslated;
        case _Filter.ai:
        case _Filter.manual:
          // Provenance lives on the Firestore document, not the model; until
          // that is surfaced these behave as "all". Kept so the chips are in
          // place for the generator work.
          return true;
        case _Filter.all:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final untranslated =
        _questions.where((q) => !q.isFullyTranslated).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Question Bank',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              widget.chapter.titleText.resolve('en'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'generate',
            backgroundColor: AppColors.neonPurple,
            onPressed: _generateWithAi,
            icon: const Icon(Icons.auto_awesome_rounded, size: 19),
            label: const Text('Generate 10'),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'manual',
            backgroundColor: AppColors.neonCyan,
            foregroundColor: AppColors.bgDark,
            onPressed: () => _editQuestion(null),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add'),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.neonCyan))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.neonCyan,
              backgroundColor: AppColors.surfaceElevated,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 150),
                children: [
                  _header(untranslated),
                  const SizedBox(height: 12),
                  _searchBox(),
                  const SizedBox(height: 10),
                  _filterChips(),
                  const SizedBox(height: 12),
                  if (_questions.isEmpty)
                    _emptyState()
                  else if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(
                        child: Text('Nothing matches that filter.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                  for (var i = 0; i < visible.length; i++)
                    _questionCard(visible[i], i + 1),
                ],
              ),
            ),
    );
  }

  Widget _header(int untranslated) {
    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('${_questions.length}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.neonCyan)),
                const Text('Questions',
                    style: TextStyle(
                        fontSize: 10.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text('$untranslated',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: untranslated == 0
                            ? AppColors.neonGreen
                            : AppColors.neonGold)),
                const Text('Need translation',
                    style: TextStyle(
                        fontSize: 10.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'q${QuestionFingerprint.nextSequence(_questions.map((q) => q.id)).toString().padLeft(3, '0')}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neonPurple),
                ),
                const Text('Next id',
                    style: TextStyle(
                        fontSize: 10.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(Icons.quiz_outlined, size: 46, color: AppColors.textMuted),
          const SizedBox(height: 14),
          const Text('No questions in this chapter yet',
              style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add one by hand, or generate a batch and review it before saving.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      style: const TextStyle(color: Colors.white, fontSize: 14),
      onChanged: (v) => setState(() => _search = v),
      decoration: InputDecoration(
        hintText: 'Search question text or id…',
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _filterChips() {
    const labels = {
      _Filter.all: 'All',
      _Filter.needsTranslation: 'Needs translation',
      _Filter.ai: 'AI',
      _Filter.manual: 'Manual',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entry in labels.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.value,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _filter == entry.key
                            ? AppColors.bgDark
                            : AppColors.textSecondary)),
                selected: _filter == entry.key,
                showCheckmark: false,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                selectedColor: AppColors.neonCyan,
                side: BorderSide(
                    color: _filter == entry.key
                        ? AppColors.neonCyan
                        : Colors.white12),
                onSelected: (_) => setState(() => _filter = entry.key),
              ),
            ),
        ],
      ),
    );
  }

  Widget _questionCard(QuestionModel question, int position) {
    final result = _validation[question.id];
    final hasIssue = result != null && !result.isClean;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        borderRadius: 16,
        padding: EdgeInsets.zero,
        borderColor: hasIssue
            ? AppColors.neonGold.withValues(alpha: 0.35)
            : null,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            iconColor: AppColors.textSecondary,
            collapsedIconColor: AppColors.textSecondary,
            title: Text(
              question.questionText.resolve('en'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.35),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                children: [
                  Text('$position · ${question.id}',
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  _languageDots(question),
                  if (hasIssue) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.error_outline_rounded,
                        size: 12, color: AppColors.neonGold),
                  ],
                ],
              ),
            ),
            children: [
              for (final code in ['en', 'bn', 'hi'])
                _languageBlock(question, code),
              if (hasIssue) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.neonGold.withValues(alpha: 0.1),
                  ),
                  child: Text(result.summary,
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.neonGold,
                          height: 1.35)),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _editQuestion(question),
                    icon: const Icon(Icons.edit_rounded,
                        size: 15, color: AppColors.neonCyan),
                    label: const Text('Edit',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.neonCyan)),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(question),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 15, color: AppColors.neonRed),
                    label: const Text('Delete',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.neonRed)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageDots(QuestionModel question) {
    return Row(
      children: [
        for (final code in ['en', 'bn', 'hi'])
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              code.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: question.questionText.has(code) &&
                        question.optionTexts.every((o) => o.has(code))
                    ? AppColors.neonGreen
                    : AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _languageBlock(QuestionModel question, String code) {
    final stem = question.questionText.has(code)
        ? question.questionText.resolve(code)
        : null;
    if (stem == null) return const SizedBox.shrink();

    final options = question.optionsIn(code);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(code.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                  color: AppColors.neonCyan)),
          const SizedBox(height: 3),
          Text(stem,
              style: const TextStyle(
                  fontSize: 12.5, color: Colors.white, height: 1.35)),
          const SizedBox(height: 5),
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    i == question.correctIndex
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 12,
                    color: i == question.correctIndex
                        ? AppColors.neonGreen
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      options[i],
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        fontWeight: i == question.correctIndex
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: i == question.correctIndex
                            ? AppColors.neonGreen
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (question.explanationText.has(code)) ...[
            const SizedBox(height: 5),
            Text('💡 ${question.explanationText.resolve(code)}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted, height: 1.35)),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- actions --

  void _generateWithAi() {
    // Phase D. The button is here now so the screen's shape is settled and the
    // review flow has somewhere to land.
    _toast('AI generation lands in the next step — see docs/11.');
  }

  Future<void> _editQuestion(QuestionModel? existing) async {
    final draft = await showModalBottomSheet<QuestionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionSheet(
        existing: existing,
        suggestedId: QuestionFingerprint.buildId(
          _slug,
          QuestionFingerprint.nextSequence(_questions.map((q) => q.id)),
        ),
        existingStems: {
          for (final q in _questions)
            if (existing == null || q.id != existing.id)
              q.id: q.questionText.resolve('en'),
        },
      ),
    );
    if (draft == null) return;

    try {
      if (existing == null) {
        final result = await _bank.appendQuestions(
          chapterId: _chapterId,
          questions: [draft],
          actorUid: _actorUid,
          source: 'manual',
        );
        _toast('Added · ${result.countLabel}');
      } else {
        await _bank.updateQuestion(
          chapterId: _chapterId,
          question: draft,
          actorUid: _actorUid,
        );
        _toast('Updated ${draft.id}');
      }
      await _load();
    } catch (e) {
      _toast('Save failed: $e', error: true);
    }
  }

  /// `math_ch_01` → `math_ch_01`; used as the id prefix for new questions.
  String get _slug => _chapterId;

  Future<void> _confirmDelete(QuestionModel question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgNavy,
        title: const Text('Delete this question?',
            style: TextStyle(fontSize: 16, color: Colors.white)),
        content: Text(
          '${question.id}\n\n"${question.questionText.resolve('en')}"\n\n'
          'Only this question is removed. The rest of the chapter is untouched.',
          style: const TextStyle(
              fontSize: 12.5, color: AppColors.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.neonRed),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _bank.deleteQuestion(
        chapterId: _chapterId,
        questionId: question.id,
        actorUid: _actorUid,
      );
      _toast('Deleted ${question.id}');
      await _load();
    } catch (e) {
      _toast('Delete failed: $e', error: true);
    }
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.neonRed : null,
      ));
  }
}

// =========================================================== question sheet ==

/// Add/edit form for a single question.
///
/// Validates with the same [QuestionValidator] the generator uses, live as the
/// admin types, so a hand-written question cannot be saved in a state a
/// generated one would have been rejected for.
class _QuestionSheet extends StatefulWidget {
  final QuestionModel? existing;
  final String suggestedId;
  final Map<String, String> existingStems;

  const _QuestionSheet({
    required this.existing,
    required this.suggestedId,
    required this.existingStems,
  });

  @override
  State<_QuestionSheet> createState() => _QuestionSheetState();
}

class _QuestionSheetState extends State<_QuestionSheet> {
  late final TextEditingController _id;
  late final TextEditingController _points;
  late final TextEditingController _timeLimit;

  late LocalizedText _question;
  late List<LocalizedText> _options;
  late LocalizedText _explanation;
  late int _correctIndex;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _id = TextEditingController(text: e?.id ?? widget.suggestedId);
    _points = TextEditingController(text: '${e?.points ?? 10}');
    _timeLimit = TextEditingController(text: '${e?.timeLimitSec ?? 15}');
    _question = e?.questionText ?? const LocalizedText.empty();
    _options = e?.optionTexts.toList() ??
        List.generate(4, (_) => const LocalizedText.empty());
    _explanation = e?.explanationText ?? const LocalizedText.empty();
    _correctIndex = e?.correctIndex ?? 0;
  }

  @override
  void dispose() {
    _id.dispose();
    _points.dispose();
    _timeLimit.dispose();
    super.dispose();
  }

  QuestionModel get _draft => QuestionModel(
        id: _id.text.trim(),
        questionText: _question,
        optionTexts: _options,
        correctIndex: _correctIndex,
        explanationText: _explanation,
        points: int.tryParse(_points.text.trim()) ?? 10,
        timeLimitSec: int.tryParse(_timeLimit.text.trim()) ?? 15,
      );

  ValidationResult get _result => QuestionValidator.validate(
        _draft,
        existingStems: widget.existingStems,
      );

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null
                          ? 'New question'
                          : 'Edit ${widget.existing!.id}',
                      style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _idRow(),
                    const SizedBox(height: 16),
                    TrilingualField(
                      label: 'Question',
                      initialValue: _question,
                      minLines: 2,
                      maxLines: 5,
                      onChanged: (v) => setState(() => _question = v),
                    ),
                    const SizedBox(height: 18),
                    const Text('OPTIONS — tap the circle to mark the answer',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    for (var i = 0; i < _options.length; i++) _optionRow(i),
                    const SizedBox(height: 6),
                    _optionButtons(),
                    const SizedBox(height: 18),
                    TrilingualField(
                      label: 'Explanation',
                      initialValue: _explanation,
                      required: false,
                      minLines: 2,
                      maxLines: 4,
                      helperText: 'shown on the review screen',
                      onChanged: (v) => setState(() => _explanation = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _numberField(_points, 'Points')),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _numberField(_timeLimit, 'Seconds')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _validationBar(result),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: result.isAcceptable
                        ? AppColors.neonCyan
                        : Colors.white12,
                    foregroundColor: result.isAcceptable
                        ? AppColors.bgDark
                        : AppColors.textMuted,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: result.isAcceptable
                      ? () => Navigator.pop(context, _draft)
                      : null,
                  child: const Text('Save question',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _idRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _id,
            enabled: widget.existing == null,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
                color: widget.existing == null
                    ? Colors.white
                    : AppColors.textMuted,
                fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Question id',
              labelStyle: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _optionRow(int index) {
    final isCorrect = index == _correctIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _correctIndex = index),
              child: Icon(
                isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 22,
                color:
                    isCorrect ? AppColors.neonGreen : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TrilingualField(
              label: 'Option ${String.fromCharCode(65 + index)}'
                  '${isCorrect ? '  ✓ correct' : ''}',
              initialValue: _options[index],
              minLines: 1,
              maxLines: 2,
              onChanged: (v) => setState(() => _options[index] = v),
            ),
          ),
          if (_options.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: IconButton(
                iconSize: 16,
                color: AppColors.textMuted,
                icon: const Icon(Icons.remove_circle_outline_rounded),
                onPressed: () => setState(() {
                  _options.removeAt(index);
                  if (_correctIndex >= _options.length) {
                    _correctIndex = _options.length - 1;
                  }
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _optionButtons() {
    if (_options.length >= 6) return const SizedBox.shrink();
    return TextButton.icon(
      onPressed: () =>
          setState(() => _options.add(const LocalizedText.empty())),
      icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.neonCyan),
      label: const Text('Add option',
          style: TextStyle(fontSize: 12, color: AppColors.neonCyan)),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Live feedback strip above the save button — the same rules the generator
  /// applies, so the two paths cannot disagree about what is publishable.
  Widget _validationBar(ValidationResult result) {
    if (result.isClean) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                size: 14, color: AppColors.neonGreen),
            SizedBox(width: 7),
            Text('Ready to save',
                style: TextStyle(fontSize: 12, color: AppColors.neonGreen)),
          ],
        ),
      );
    }

    final blocking = result.rejections;
    final colour =
        blocking.isEmpty ? AppColors.neonGold : AppColors.neonRed;
    final messages = (blocking.isEmpty ? result.warnings : blocking)
        .map((i) => i.toString())
        .take(3)
        .join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 14, color: colour),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              result.nearDuplicate != null && blocking.isEmpty
                  ? 'Similar to ${result.nearDuplicate!.questionId} '
                      '(${result.nearDuplicate!.scoreLabel}) · $messages'
                  : messages,
              style: TextStyle(fontSize: 11.5, color: colour, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
