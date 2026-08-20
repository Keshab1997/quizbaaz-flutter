import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/repositories/quiz_repository.dart';
import '../../../data/providers/quiz_provider.dart';
import '../../widgets/glass_card.dart';
import '../daily_quiz/daily_quiz_screen.dart';

class ChapterListScreen extends StatefulWidget {
  const ChapterListScreen({Key? key}) : super(key: key);

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  final QuizRepository _repository = QuizRepository();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    final list = await _repository.getCategoriesAndChapters();
    setState(() {
      _categories = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text(
          'Chapter Question Bank',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              itemCount: _categories.length,
              itemBuilder: (context, catIndex) {
                final category = _categories[catIndex];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        category.categoryName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neonCyan,
                        ),
                      ),
                    ),
                    ...category.chapters.map((ch) => _buildChapterTile(context, ch)).toList(),
                    const SizedBox(height: 14),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildChapterTile(BuildContext context, ChapterModel chapter) {
    final isLocked = !chapter.isUnlocked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        borderRadius: 18,
        borderColor: isLocked ? Colors.white10 : AppColors.neonPurple.withOpacity(0.3),
        onTap: isLocked
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔒 Complete previous chapter to unlock!')),
                );
              }
            : () {
                context.read<QuizProvider>().startChapterQuiz(chapter.jsonFile);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyQuizScreen()),
                );
              },
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isLocked ? Colors.white.withOpacity(0.05) : AppColors.neonPurple.withOpacity(0.2),
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock, color: AppColors.textMuted)
                    : Text(
                        '${chapter.chapterNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neonGold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isLocked ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                  ),
                  if (chapter.titleBn != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      chapter.titleBn!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${chapter.totalQuestions} Questions  •  ${chapter.description}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isLocked)
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.neonGold),
          ],
        ),
      ),
    );
  }
}
