import 'package:flutter/material.dart';

import '../models/study_progress.dart';
import '../models/study_mode.dart';
import '../models/vocab_item.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import 'shared_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.seed,
    required this.completedToday,
    required this.newGoal,
    required this.wordGoal,
    required this.phraseGoal,
    required this.reviewCompletedToday,
    required this.reviewGoal,
    required this.reviewDueToday,
    required this.checkinFinished,
    required this.currentStreak,
    required this.onStartStudy,
    required this.onOpenStylePicker,
    required this.onOpenWordbook,
    super.key,
  });

  final VocabSeed seed;
  final int completedToday;
  final int newGoal;
  final int wordGoal;
  final int phraseGoal;
  final int reviewCompletedToday;
  final int reviewGoal;
  final int reviewDueToday;
  final bool checkinFinished;
  final int currentStreak;
  final VoidCallback onStartStudy;
  final VoidCallback onOpenStylePicker;
  final VoidCallback onOpenWordbook;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    final totalToday = newGoal + reviewGoal;
    final completedPlan = completedToday + reviewCompletedToday;
    final progress = totalToday == 0 ? 1.0 : completedPlan / totalToday;
    final daysToExam = _daysUntilExam();
    final actionLabel = checkinFinished
        ? '今日已完成'
        : completedToday >= newGoal
        ? '开始今日复习'
        : '开始今日打卡';
    final actionIcon = checkinFinished
        ? Icons.check_circle_rounded
        : completedToday >= newGoal
        ? Icons.refresh_rounded
        : Icons.play_arrow_rounded;

    return AppPage(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SmallLabel('2026 下半年'),
                      const SizedBox(height: 8),
                      Text(
                        '准备好，开始\n今天的积累。',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                IconAction(
                  icon: Icons.tune_rounded,
                  tooltip: '切换视觉风格',
                  onPressed: onOpenStylePicker,
                ),
              ],
            ),
            const SizedBox(height: 22),
            AppCard(
              color: palette.accent,
              borderColor: palette.accent,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '今日任务',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: palette.isDark
                                    ? const Color(0xFF142014)
                                    : Colors.white,
                              ),
                        ),
                      ),
                      Text(
                        '$completedPlan / $totalToday',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: palette.isDark
                                  ? const Color(0xFF142014)
                                  : Colors.white,
                              fontSize: 18,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 10,
                      backgroundColor: Colors.white.withAlpha(
                        palette.isDark ? 40 : 65,
                      ),
                      valueColor: AlwaysStoppedAnimation(
                        palette.isDark ? const Color(0xFF142014) : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    checkinFinished
                        ? '今天的打卡已经完成'
                        : completedToday >= newGoal
                        ? '新词已完成，还有 $reviewDueToday 个待复习。'
                        : '还差 ${newGoal - completedToday} 个新词，保持节奏。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.isDark
                          ? const Color(0xFF284126)
                          : Colors.white.withAlpha(220),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                MetricTile(
                  value: '$reviewDueToday',
                  label: '待复习',
                  icon: Icons.refresh_rounded,
                  color: palette.secondary,
                ),
                const SizedBox(width: 12),
                MetricTile(
                  value: '$currentStreak 天',
                  label: '连续打卡',
                  icon: Icons.local_fire_department_rounded,
                  color: palette.secondary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              color: palette.surfaceAlt,
              borderColor: palette.surfaceAlt,
              shadow: false,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.event_available_rounded,
                      color: palette.secondary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '考试倒计时',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '还有 $daysToExam 天 · ${seed.examDateLabel}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: palette.muted),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SectionHeading(
              title: '今天学什么',
              action: TextButton.icon(
                onPressed: onOpenWordbook,
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('浏览词库'),
                style: TextButton.styleFrom(
                  foregroundColor: palette.accent,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PlanRow(
              icon: Icons.auto_stories_rounded,
              title: '高频单词',
              detail: '${seed.wordCount} 张卡片 · 今日 $wordGoal 个',
              color: palette.accent,
              onTap: onStartStudy,
            ),
            const SizedBox(height: 10),
            _PlanRow(
              icon: Icons.forum_rounded,
              title: '词组搭配',
              detail: '${seed.phraseCount} 张卡片 · 今日 $phraseGoal 个',
              color: palette.secondary,
              onTap: onOpenWordbook,
            ),
            const SizedBox(height: 22),
            PrimaryAction(
              label: actionLabel,
              onPressed: checkinFinished ? null : onStartStudy,
              icon: actionIcon,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _todayLabel(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudyPage extends StatelessWidget {
  const StudyPage({
    required this.item,
    required this.completedToday,
    required this.totalToday,
    required this.sessionLabel,
    required this.isReviewStage,
    required this.mode,
    required this.onModeChanged,
    required this.revealed,
    required this.speechState,
    required this.onSpeak,
    required this.onStopSpeaking,
    required this.onReveal,
    required this.onRate,
    required this.onExit,
    super.key,
  });

  final VocabItem item;
  final int completedToday;
  final int totalToday;
  final String sessionLabel;
  final bool isReviewStage;
  final StudyMode mode;
  final ValueChanged<StudyMode> onModeChanged;
  final bool revealed;
  final SpeechState speechState;
  final VoidCallback onSpeak;
  final VoidCallback onStopSpeaking;
  final VoidCallback onReveal;
  final ValueChanged<int> onRate;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    final progress = totalToday == 0 ? 1.0 : completedToday / totalToday;
    return AppPage(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onExit,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '退出学习',
                  style: IconButton.styleFrom(
                    foregroundColor: palette.ink,
                    fixedSize: const Size(42, 42),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SmallLabel(sessionLabel),
                      const SizedBox(height: 4),
                      Text(
                        '$completedToday / $totalToday',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                SoftPill(
                  label: isReviewStage ? '复习阶段' : item.kindLabel,
                  icon: isReviewStage
                      ? Icons.refresh_rounded
                      : item.kind == VocabKind.word
                      ? Icons.auto_stories_rounded
                      : Icons.forum_rounded,
                  color: isReviewStage
                      ? palette.secondary
                      : item.kind == VocabKind.word
                      ? palette.accent
                      : palette.secondary,
                  backgroundColor: isReviewStage
                      ? palette.secondarySoft
                      : item.kind == VocabKind.word
                      ? palette.accentSoft
                      : palette.secondarySoft,
                ),
                PopupMenuButton<StudyMode>(
                  tooltip: '切换练习模式',
                  initialValue: mode,
                  onSelected: onModeChanged,
                  icon: const Icon(Icons.tune_rounded),
                  itemBuilder: (context) => StudyMode.values
                      .map(
                        (item) => PopupMenuItem<StudyMode>(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ThinProgressBar(value: progress),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: onReveal,
              child: AppCard(
                color: palette.surface,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                radius: palette.radius + 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SmallLabel(
                          item.kind == VocabKind.word ? 'WORD' : 'PHRASE',
                          color: palette.secondary,
                        ),
                        const Spacer(),
                        _SpeechButton(
                          state: speechState,
                          onSpeak: onSpeak,
                          onStop: onStopSpeaking,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.sourceRows.isEmpty
                              ? '#'
                              : '#${item.sourceRows.first.toString().padLeft(3, '0')}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 42),
                    GestureDetector(
                      onTap: speechState == SpeechState.speaking
                          ? onStopSpeaking
                          : onSpeak,
                      child: Text(
                        _promptForMode(item, mode),
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    if (mode == StudyMode.flashcard &&
                        item.phonetic.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        item.phonetic,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: palette.accent,
                          fontSize: 17,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: revealed
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: _RevealHint(palette: palette),
                      secondChild: _AnswerBlock(item: item, mode: mode),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!revealed)
              mode == StudyMode.spelling
                  ? _SpellingInput(item: item, onSubmit: onReveal)
                  : PrimaryAction(
                      label: _revealLabel(mode),
                      onPressed: onReveal,
                      icon: Icons.visibility_rounded,
                    )
            else
              _RatingGrid(onRate: onRate),
            const SizedBox(height: 18),
            Center(
              child: Text(
                revealed ? '根据记忆程度选择一个评价' : '点击卡片或按钮查看答案',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechButton extends StatelessWidget {
  const _SpeechButton({
    required this.state,
    required this.onSpeak,
    required this.onStop,
  });

  final SpeechState state;
  final VoidCallback onSpeak;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    final speaking = state == SpeechState.speaking;
    return Tooltip(
      message: speaking ? '停止朗读' : '朗读单词',
      child: IconButton(
        onPressed: speaking ? onStop : onSpeak,
        icon: Icon(
          speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
          color: palette.accent,
          size: 20,
        ),
        style: IconButton.styleFrom(
          backgroundColor: palette.accentSoft,
          fixedSize: const Size(40, 40),
        ),
      ),
    );
  }
}

class WordbookPage extends StatefulWidget {
  const WordbookPage({
    required this.items,
    required this.speechState,
    required this.onSpeak,
    required this.onStopSpeaking,
    super.key,
  });

  final List<VocabItem> items;
  final SpeechState speechState;
  final ValueChanged<String> onSpeak;
  final VoidCallback onStopSpeaking;

  @override
  State<WordbookPage> createState() => _WordbookPageState();
}

class _WordbookPageState extends State<WordbookPage> {
  final _searchController = TextEditingController();
  VocabKind? _filter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    final query = _searchController.text.trim().toLowerCase();
    final visibleItems = widget.items
        .where((item) {
          final matchesFilter = _filter == null || item.kind == _filter;
          final matchesQuery =
              query.isEmpty ||
              item.term.toLowerCase().contains(query) ||
              item.meaning.toLowerCase().contains(query) ||
              item.collocations.toLowerCase().contains(query) ||
              item.exampleTranslation.toLowerCase().contains(query);
          return matchesFilter && matchesQuery;
        })
        .take(60)
        .toList();

    return AppPage(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SmallLabel('COLLECTION'),
                      const SizedBox(height: 8),
                      Text(
                        '词库',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                SoftPill(
                  label: '${widget.items.length} 张卡片',
                  icon: Icons.layers_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: '搜索英文、中文或搭配',
                prefixIcon: Icon(Icons.search_rounded),
                suffixIcon: Icon(Icons.tune_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: '全部',
                  selected: _filter == null,
                  onSelected: () => setState(() => _filter = null),
                ),
                _FilterChip(
                  label: '单词',
                  selected: _filter == VocabKind.word,
                  onSelected: () => setState(() => _filter = VocabKind.word),
                ),
                _FilterChip(
                  label: '词组',
                  selected: _filter == VocabKind.phrase,
                  onSelected: () => setState(() => _filter = VocabKind.phrase),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  query.isEmpty ? '最近收录' : '搜索结果',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  '${visibleItems.length}${visibleItems.length == 60 ? '+' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (visibleItems.isEmpty)
              AppCard(
                shadow: false,
                child: Row(
                  children: [
                    Icon(Icons.search_off_rounded, color: palette.muted),
                    const SizedBox(width: 10),
                    Text(
                      '没有找到匹配的词条',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              )
            else
              ...visibleItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _VocabListTile(
                    item: item,
                    onTap: () => _showItem(context, item),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showItem(BuildContext context, VocabItem item) {
    final palette = paletteFrom(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: palette.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SoftPill(label: item.kindLabel),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.term,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    _SpeechButton(
                      state: widget.speechState,
                      onSpeak: () => widget.onSpeak(item.term),
                      onStop: widget.onStopSpeaking,
                    ),
                  ],
                ),
                if (item.phonetic.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.phonetic,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: palette.accent),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  item.meaning,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (item.collocations.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  Text(
                    item.collocations,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (item.example.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  Text(
                    item.example,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (item.exampleTranslation.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    SmallLabel('中文翻译', color: palette.accent),
                    const SizedBox(height: 3),
                    Text(
                      item.exampleTranslation,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: palette.ink),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class StatsPage extends StatelessWidget {
  const StatsPage({
    required this.seed,
    required this.totalLearned,
    required this.masteredCount,
    required this.currentStreak,
    required this.longestStreak,
    required this.todayStudySeconds,
    required this.dailyGoal,
    required this.weeklyStats,
    super.key,
  });

  final VocabSeed seed;
  final int totalLearned;
  final int masteredCount;
  final int currentStreak;
  final int longestStreak;
  final int todayStudySeconds;
  final int dailyGoal;
  final List<DailyStudyStat> weeklyStats;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    final totalCards = seed.items.length;
    final masteryPercent = totalCards == 0
        ? 0
        : (masteredCount / totalCards * 100).round().clamp(0, 100);
    final maxCompleted = weeklyStats.fold<int>(
      dailyGoal,
      (max, item) => item.completed > max ? item.completed : max,
    );
    final weeklyCompleted = weeklyStats.fold<int>(
      0,
      (total, item) => total + item.completed,
    );
    return AppPage(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SmallLabel('PROGRESS'),
            const SizedBox(height: 8),
            Text('学习统计', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 22),
            Row(
              children: [
                MetricTile(
                  value: '$totalLearned',
                  label: '累计学习',
                  icon: Icons.menu_book_rounded,
                  color: palette.accent,
                ),
                const SizedBox(width: 12),
                MetricTile(
                  value: '$masteryPercent%',
                  label: '掌握进度',
                  icon: Icons.track_changes_rounded,
                  color: palette.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                MetricTile(
                  value: '$longestStreak 天',
                  label: '最长连续',
                  icon: Icons.local_fire_department_rounded,
                  color: palette.secondary,
                ),
                const SizedBox(width: 12),
                MetricTile(
                  value: _formatDuration(todayStudySeconds),
                  label: '今日用时',
                  icon: Icons.timer_outlined,
                  color: palette.accent,
                ),
              ],
            ),
            const SizedBox(height: 26),
            SectionHeading(
              title: '最近 7 天',
              action: SoftPill(
                label: '目标 $dailyGoal / 天',
                icon: Icons.flag_rounded,
              ),
            ),
            const SizedBox(height: 13),
            AppCard(
              shadow: false,
              child: Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: weeklyStats
                          .map(
                            (item) => _WeekBar(
                              day: _weekdayLabel(item.dateKey),
                              value: maxCompleted == 0
                                  ? 0
                                  : item.completed / maxCompleted,
                              active: item.dateKey == weeklyStats.last.dateKey,
                              completed: item.completed,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: palette.muted,
                        size: 16,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '最近 7 天已完成 $weeklyCompleted 个词条，保持每天一点点。',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SectionHeading(title: '词库分布'),
            const SizedBox(height: 13),
            AppCard(
              shadow: false,
              child: Column(
                children: [
                  _DistributionRow(
                    label: '高频单词',
                    value: '${seed.wordCount}',
                    progress: totalCards == 0 ? 0 : seed.wordCount / totalCards,
                    color: palette.accent,
                  ),
                  const SizedBox(height: 18),
                  _DistributionRow(
                    label: '词组搭配',
                    value: '${seed.phraseCount}',
                    progress: totalCards == 0
                        ? 0
                        : seed.phraseCount / totalCards,
                    color: palette.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.style,
    required this.dailyNewGoal,
    required this.phraseRatioPercent,
    required this.dailyReviewLimit,
    required this.reminderTime,
    required this.onStyleChanged,
    required this.onEditDailyNewGoal,
    required this.onEditPhraseRatio,
    required this.onEditDailyReviewLimit,
    required this.onEditReminder,
    required this.onExportRecord,
    required this.onRestoreRecord,
    required this.onResetProgress,
    super.key,
  });

  final AppStyle style;
  final int dailyNewGoal;
  final int phraseRatioPercent;
  final int dailyReviewLimit;
  final TimeOfDay reminderTime;
  final ValueChanged<AppStyle> onStyleChanged;
  final VoidCallback onEditDailyNewGoal;
  final VoidCallback onEditPhraseRatio;
  final VoidCallback onEditDailyReviewLimit;
  final VoidCallback onEditReminder;
  final VoidCallback onExportRecord;
  final VoidCallback onRestoreRecord;
  final VoidCallback onResetProgress;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    return AppPage(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SmallLabel('PREFERENCES'),
            const SizedBox(height: 8),
            Text('设置', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            SectionHeading(title: '视觉风格'),
            const SizedBox(height: 12),
            ...AppStyle.values.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _StyleOption(
                  style: item,
                  selected: item == style,
                  onTap: () => onStyleChanged(item),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionHeading(title: '学习计划'),
            const SizedBox(height: 12),
            AppCard(
              shadow: false,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.add_circle_outline_rounded,
                    title: '每日新词',
                    value: '$dailyNewGoal 个',
                    color: palette.accent,
                    onTap: onEditDailyNewGoal,
                  ),
                  Divider(height: 1, color: palette.line),
                  _SettingRow(
                    icon: Icons.forum_outlined,
                    title: '词组占比',
                    value: '$phraseRatioPercent%',
                    color: palette.secondary,
                    onTap: onEditPhraseRatio,
                  ),
                  Divider(height: 1, color: palette.line),
                  _SettingRow(
                    icon: Icons.refresh_rounded,
                    title: '每日复习上限',
                    value: '$dailyReviewLimit 个',
                    color: palette.secondary,
                    onTap: onEditDailyReviewLimit,
                  ),
                  Divider(height: 1, color: palette.line),
                  _SettingRow(
                    icon: Icons.notifications_none_rounded,
                    title: '每日提醒',
                    value: reminderTime.format(context),
                    color: palette.accent,
                    onTap: onEditReminder,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionHeading(title: '数据'),
            const SizedBox(height: 12),
            AppCard(
              shadow: false,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.download_rounded,
                    title: '导出学习记录',
                    value: '',
                    color: palette.accent,
                    onTap: onExportRecord,
                  ),
                  Divider(height: 1, color: palette.line),
                  _SettingRow(
                    icon: Icons.upload_rounded,
                    title: '恢复学习记录',
                    value: '',
                    color: palette.accent,
                    onTap: onRestoreRecord,
                  ),
                  Divider(height: 1, color: palette.line),
                  _SettingRow(
                    icon: Icons.restart_alt_rounded,
                    title: '重新开始',
                    value: '',
                    color: palette.secondary,
                    onTap: onResetProgress,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        shadow: false,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(24),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: palette.muted,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealHint extends StatelessWidget {
  const _RevealHint({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 138,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_rounded, color: palette.muted, size: 25),
          const SizedBox(height: 10),
          Text('先想一想，再揭晓答案', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({required this.item, required this.mode});

  final VocabItem item;
  final StudyMode mode;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mode != StudyMode.flashcard) ...[
          Text(
            item.term,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (item.phonetic.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.phonetic,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.accent),
            ),
          ],
          const SizedBox(height: 12),
        ],
        Text(
          item.meaning.isEmpty ? '暂无释义' : item.meaning,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 21),
        ),
        if (item.partOfSpeech.isNotEmpty) ...[
          const SizedBox(height: 8),
          SoftPill(
            label: item.partOfSpeech,
            color: palette.secondary,
            backgroundColor: palette.secondarySoft,
          ),
        ],
        if (item.collocations.isNotEmpty) ...[
          const SizedBox(height: 18),
          SmallLabel('常用搭配', color: palette.accent),
          const SizedBox(height: 5),
          Text(
            item.collocations,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.ink),
          ),
        ],
        if (item.example.isNotEmpty) ...[
          const SizedBox(height: 16),
          SmallLabel('例句', color: palette.accent),
          const SizedBox(height: 5),
          Text(
            item.example,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.ink,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (item.exampleTranslation.isNotEmpty) ...[
            const SizedBox(height: 7),
            SmallLabel('中文翻译', color: palette.accent),
            const SizedBox(height: 3),
            Text(
              item.exampleTranslation,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.ink),
            ),
          ],
        ],
      ],
    );
  }
}

class _SpellingInput extends StatefulWidget {
  const _SpellingInput({required this.item, required this.onSubmit});

  final VocabItem item;
  final VoidCallback onSubmit;

  @override
  State<_SpellingInput> createState() => _SpellingInputState();
}

class _SpellingInputState extends State<_SpellingInput> {
  final _controller = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    final answer = _controller.text.trim().toLowerCase();
    final correct = answer == widget.item.term.trim().toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() => _submitted = false),
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            hintText: '输入英文拼写',
            prefixIcon: Icon(Icons.keyboard_rounded),
          ),
        ),
        const SizedBox(height: 10),
        PrimaryAction(
          label: '检查拼写',
          icon: Icons.check_rounded,
          onPressed: _submit,
        ),
        if (_submitted) ...[
          const SizedBox(height: 8),
          Text(
            correct ? '拼写正确' : '正确答案：${widget.item.term}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: correct ? palette.accent : palette.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) {
      return;
    }
    setState(() => _submitted = true);
    widget.onSubmit();
  }
}

String _promptForMode(VocabItem item, StudyMode mode) {
  switch (mode) {
    case StudyMode.flashcard:
      return item.term;
    case StudyMode.translation:
    case StudyMode.spelling:
      return item.meaning.isEmpty ? '暂无释义' : item.meaning;
    case StudyMode.cloze:
      return _clozeExample(item);
  }
}

String _clozeExample(VocabItem item) {
  if (item.example.isEmpty) {
    return item.meaning.isEmpty ? '暂无例句' : item.meaning;
  }
  final pattern = RegExp(RegExp.escape(item.term), caseSensitive: false);
  final replaced = item.example.replaceFirst(pattern, '______');
  return replaced == item.example ? '${item.example}\n\n（请回忆目标词）' : replaced;
}

String _revealLabel(StudyMode mode) {
  switch (mode) {
    case StudyMode.flashcard:
      return '显示释义';
    case StudyMode.translation:
      return '显示英文';
    case StudyMode.spelling:
      return '显示答案';
    case StudyMode.cloze:
      return '显示完整例句';
  }
}

class _RatingGrid extends StatelessWidget {
  const _RatingGrid({required this.onRate});

  final ValueChanged<int> onRate;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    final ratings = [
      (0, '不认识', '10 分钟', palette.secondary),
      (1, '模糊', '1 天后', palette.secondary),
      (2, '认识', '3 天后', palette.accent),
      (3, '熟练', '7 天后', palette.accent),
    ];
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: ratings
          .map(
            (rating) => OutlinedButton(
              onPressed: () => onRate(rating.$1),
              style: OutlinedButton.styleFrom(
                foregroundColor: rating.$4,
                side: BorderSide(color: rating.$4.withAlpha(120)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(palette.radius * .62),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rating.$2,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rating.$3,
                    style: TextStyle(color: palette.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: palette.accentSoft,
      backgroundColor: palette.surface,
      side: BorderSide(color: selected ? palette.accent : palette.line),
      labelStyle: TextStyle(
        color: selected ? palette.accent : palette.muted,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      showCheckmark: false,
    );
  }
}

class _VocabListTile extends StatelessWidget {
  const _VocabListTile({required this.item, required this.onTap});

  final VocabItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    final color = item.kind == VocabKind.word
        ? palette.accent
        : palette.secondary;
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        shadow: false,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 49,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.term,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        item.kind == VocabKind.word ? '单词' : '词组',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.meaning,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: palette.ink),
                  ),
                  if (item.phonetic.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.phonetic,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: palette.muted),
          ],
        ),
      ),
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({
    required this.day,
    required this.value,
    required this.completed,
    this.active = false,
  });

  final String day;
  final double value;
  final int completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Tooltip(
              message: '$completed 个词条',
              child: Container(
                width: 22,
                height: 118 * value.clamp(0, 1),
                decoration: BoxDecoration(
                  color: active ? palette.accent : palette.accentSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          day,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: active ? palette.accent : palette.muted,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

String _weekdayLabel(String dateKey) {
  final date = DateTime.parse(dateKey);
  const labels = ['一', '二', '三', '四', '五', '六', '日'];
  return labels[date.weekday - 1];
}

String _formatDuration(int seconds) {
  if (seconds < 60) {
    return '${seconds}s';
  }
  final minutes = seconds ~/ 60;
  if (minutes < 60) {
    return '${minutes}m';
  }
  return '${minutes ~/ 60}h ${minutes % 60}m';
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 9),
        ThinProgressBar(
          value: progress,
          backgroundColor: color.withAlpha(28),
          valueColor: color,
          height: 9,
        ),
      ],
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final AppStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = paletteFrom(context);
    final preview = paletteFor(style);
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        color: selected ? preview.accentSoft : current.surface,
        borderColor: selected ? preview.accent : current.line,
        shadow: false,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 44,
              decoration: BoxDecoration(
                color: preview.background,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: preview.line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ColorDot(color: preview.accent),
                  const SizedBox(width: 4),
                  _ColorDot(color: preview.secondary),
                  const SizedBox(width: 4),
                  _ColorDot(color: preview.ink),
                ],
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preview.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? preview.accent : current.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (value.isNotEmpty)
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

String _todayLabel() {
  final now = DateTime.now();
  return '${now.year}年${now.month}月${now.day}日';
}

int _daysUntilExam() {
  final now = DateTime.now();
  final examDate = DateTime(2026, 10, 24);
  final difference = examDate
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  return difference < 0 ? 0 : difference;
}
