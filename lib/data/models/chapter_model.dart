class CategoryModel {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String colorHex;
  final int totalChapters;
  final List<ChapterModel> chapters;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.colorHex,
    required this.totalChapters,
    required this.chapters,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? '',
      categoryIcon: json['category_icon'] ?? '',
      colorHex: json['color_hex'] ?? '#3B82F6',
      totalChapters: json['total_chapters'] ?? 0,
      chapters: (json['chapters'] as List? ?? [])
          .map((c) => ChapterModel.fromJson(c))
          .toList(),
    );
  }
}

class ChapterModel {
  final String chapterId;
  final int chapterNumber;
  final String title;
  final String? titleBn;
  final String description;
  final int totalQuestions;
  final String jsonFile;
  final bool isUnlocked;
  final int stars;
  final int bestScore;

  ChapterModel({
    required this.chapterId,
    required this.chapterNumber,
    required this.title,
    this.titleBn,
    required this.description,
    required this.totalQuestions,
    required this.jsonFile,
    required this.isUnlocked,
    required this.stars,
    required this.bestScore,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      chapterId: json['chapter_id'] ?? '',
      chapterNumber: json['chapter_number'] ?? 1,
      title: json['title'] ?? '',
      titleBn: json['title_bn'],
      description: json['description'] ?? '',
      totalQuestions: json['total_questions'] ?? 10,
      jsonFile: json['json_file'] ?? '',
      isUnlocked: json['is_unlocked'] ?? true,
      stars: json['stars'] ?? 0,
      bestScore: json['best_score'] ?? 0,
    );
  }
}
