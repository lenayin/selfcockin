class StudyProgress {
  const StudyProgress({
    required this.dateKey,
    required this.dailyNewGoal,
    required this.phraseRatioPercent,
    required this.dailyReviewLimit,
    required this.completedNewToday,
    required this.reviewCompletedToday,
    required this.reviewDueToday,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalLearned,
    required this.totalReviews,
    required this.todayStudySeconds,
    required this.completedDates,
    required this.dailyCompleted,
    required this.dailyStudySeconds,
    required this.seenCardIds,
    required this.masteredCardIds,
    required this.reviewDueDates,
    required this.styleName,
    required this.reminderMinutes,
  });

  final String dateKey;
  final int dailyNewGoal;
  final int phraseRatioPercent;
  final int dailyReviewLimit;
  final int completedNewToday;
  final int reviewCompletedToday;
  final int reviewDueToday;
  final int currentStreak;
  final int longestStreak;
  final int totalLearned;
  final int totalReviews;
  final int todayStudySeconds;
  final Set<String> completedDates;
  final Map<String, int> dailyCompleted;
  final Map<String, int> dailyStudySeconds;
  final Set<String> seenCardIds;
  final Set<String> masteredCardIds;
  final Map<String, String> reviewDueDates;
  final String styleName;
  final int reminderMinutes;

  factory StudyProgress.empty({
    required String dateKey,
    required int dailyNewGoal,
    int phraseRatioPercent = 20,
    required int dailyReviewLimit,
    int completedNewToday = 0,
    int reviewDueToday = 0,
    String styleName = 'paper',
    int reminderMinutes = 20 * 60 + 30,
  }) {
    return StudyProgress(
      dateKey: dateKey,
      dailyNewGoal: dailyNewGoal,
      phraseRatioPercent: phraseRatioPercent,
      dailyReviewLimit: dailyReviewLimit,
      completedNewToday: completedNewToday,
      reviewCompletedToday: 0,
      reviewDueToday: reviewDueToday,
      currentStreak: 0,
      longestStreak: 0,
      totalLearned: 0,
      totalReviews: 0,
      todayStudySeconds: 0,
      completedDates: <String>{},
      dailyCompleted: <String, int>{},
      dailyStudySeconds: <String, int>{},
      seenCardIds: <String>{},
      masteredCardIds: <String>{},
      reviewDueDates: <String, String>{},
      styleName: styleName,
      reminderMinutes: reminderMinutes,
    );
  }

  factory StudyProgress.fromJson(Map<String, dynamic> json) {
    Map<String, int> intMap(Object? value) {
      final raw = value is Map ? value : const {};
      return raw.map(
        (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
      );
    }

    Map<String, String> stringMap(Object? value) {
      final raw = value is Map ? value : const {};
      return raw.map(
        (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
      )..removeWhere((_, value) => value.isEmpty);
    }

    Set<String> stringSet(Object? value) {
      if (value is! List) {
        return <String>{};
      }
      return value.whereType<String>().toSet();
    }

    return StudyProgress(
      dateKey: json['dateKey'] as String? ?? '',
      dailyNewGoal: (json['dailyNewGoal'] as num?)?.toInt() ?? 20,
      phraseRatioPercent: (json['phraseRatioPercent'] as num?)?.toInt() ?? 20,
      dailyReviewLimit: (json['dailyReviewLimit'] as num?)?.toInt() ?? 50,
      completedNewToday: (json['completedNewToday'] as num?)?.toInt() ?? 0,
      reviewCompletedToday:
          (json['reviewCompletedToday'] as num?)?.toInt() ?? 0,
      reviewDueToday: (json['reviewDueToday'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      totalLearned: (json['totalLearned'] as num?)?.toInt() ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      todayStudySeconds: (json['todayStudySeconds'] as num?)?.toInt() ?? 0,
      completedDates: stringSet(json['completedDates']),
      dailyCompleted: intMap(json['dailyCompleted']),
      dailyStudySeconds: intMap(json['dailyStudySeconds']),
      seenCardIds: stringSet(json['seenCardIds']),
      masteredCardIds: stringSet(json['masteredCardIds']),
      reviewDueDates: stringMap(json['reviewDueDates']),
      styleName: json['styleName'] as String? ?? 'paper',
      reminderMinutes: (json['reminderMinutes'] as num?)?.toInt() ?? 1230,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'dailyNewGoal': dailyNewGoal,
      'phraseRatioPercent': phraseRatioPercent,
      'dailyReviewLimit': dailyReviewLimit,
      'completedNewToday': completedNewToday,
      'reviewCompletedToday': reviewCompletedToday,
      'reviewDueToday': reviewDueToday,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalLearned': totalLearned,
      'totalReviews': totalReviews,
      'todayStudySeconds': todayStudySeconds,
      'completedDates': completedDates.toList()..sort(),
      'dailyCompleted': dailyCompleted,
      'dailyStudySeconds': dailyStudySeconds,
      'seenCardIds': seenCardIds.toList()..sort(),
      'masteredCardIds': masteredCardIds.toList()..sort(),
      'reviewDueDates': reviewDueDates,
      'styleName': styleName,
      'reminderMinutes': reminderMinutes,
    };
  }

  StudyProgress copyWith({
    String? dateKey,
    int? dailyNewGoal,
    int? phraseRatioPercent,
    int? dailyReviewLimit,
    int? completedNewToday,
    int? reviewCompletedToday,
    int? reviewDueToday,
    int? currentStreak,
    int? longestStreak,
    int? totalLearned,
    int? totalReviews,
    int? todayStudySeconds,
    Set<String>? completedDates,
    Map<String, int>? dailyCompleted,
    Map<String, int>? dailyStudySeconds,
    Set<String>? seenCardIds,
    Set<String>? masteredCardIds,
    Map<String, String>? reviewDueDates,
    String? styleName,
    int? reminderMinutes,
  }) {
    return StudyProgress(
      dateKey: dateKey ?? this.dateKey,
      dailyNewGoal: dailyNewGoal ?? this.dailyNewGoal,
      phraseRatioPercent: phraseRatioPercent ?? this.phraseRatioPercent,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      completedNewToday: completedNewToday ?? this.completedNewToday,
      reviewCompletedToday: reviewCompletedToday ?? this.reviewCompletedToday,
      reviewDueToday: reviewDueToday ?? this.reviewDueToday,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalLearned: totalLearned ?? this.totalLearned,
      totalReviews: totalReviews ?? this.totalReviews,
      todayStudySeconds: todayStudySeconds ?? this.todayStudySeconds,
      completedDates: completedDates ?? this.completedDates,
      dailyCompleted: dailyCompleted ?? this.dailyCompleted,
      dailyStudySeconds: dailyStudySeconds ?? this.dailyStudySeconds,
      seenCardIds: seenCardIds ?? this.seenCardIds,
      masteredCardIds: masteredCardIds ?? this.masteredCardIds,
      reviewDueDates: reviewDueDates ?? this.reviewDueDates,
      styleName: styleName ?? this.styleName,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    );
  }
}

class DailyStudyStat {
  const DailyStudyStat({
    required this.dateKey,
    required this.completed,
    required this.studySeconds,
    required this.completedDay,
  });

  final String dateKey;
  final int completed;
  final int studySeconds;
  final bool completedDay;
}
