import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/vocab_repository.dart';
import 'models/study_progress.dart';
import 'models/study_mode.dart';
import 'models/vocab_item.dart';
import 'services/progress_store.dart';
import 'services/reminder_service.dart';
import 'services/speech_service.dart';
import 'theme/app_theme.dart';
import 'ui/pages.dart';
import 'ui/shared_widgets.dart';

void main() {
  runApp(const SelfCheckinApp());
}

class SelfCheckinApp extends StatefulWidget {
  const SelfCheckinApp({
    this.initialSeed,
    this.initialDailyNewGoal = 20,
    this.initialDailyReviewLimit = 50,
    this.initialCompletedToday = 0,
    this.initialReviewDueToday = 0,
    super.key,
  });

  final VocabSeed? initialSeed;
  final int initialDailyNewGoal;
  final int initialDailyReviewLimit;
  final int initialCompletedToday;
  final int initialReviewDueToday;

  @override
  State<SelfCheckinApp> createState() => _SelfCheckinAppState();
}

enum _StudyPhase { learning, review }

class _SelfCheckinAppState extends State<SelfCheckinApp>
    with WidgetsBindingObserver {
  final _repository = const VocabRepository();
  final _progressStore = const ProgressStore();
  final _reminder = ReminderService();
  final _speech = SpeechService();
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final Future<VocabSeed> _seedFuture;

  AppStyle _style = AppStyle.paper;
  int _selectedIndex = 0;
  int _studyCursor = 0;
  int _reviewCursor = 0;
  int _dailyNewGoal = 20;
  int _phraseRatioPercent = 20;
  int _dailyReviewLimit = 50;
  int _completedNewToday = 7;
  int _reviewCompletedToday = 0;
  int _reviewDueToday = 18;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 30);
  _StudyPhase _studyPhase = _StudyPhase.learning;
  StudyMode _studyMode = StudyMode.flashcard;
  bool _revealed = false;
  SpeechState _speechState = SpeechState.idle;
  String _currentDateKey = _formatDate(DateTime.now());
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalLearned = 0;
  int _totalReviews = 0;
  int _todayStudySeconds = 0;
  final Set<String> _completedDates = <String>{};
  final Map<String, int> _dailyCompleted = <String, int>{};
  final Map<String, int> _dailyStudySeconds = <String, int>{};
  final Set<String> _seenCardIds = <String>{};
  final Set<String> _masteredCardIds = <String>{};
  final Map<String, String> _reviewDueDates = <String, String>{};
  DateTime? _studyStartedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dailyNewGoal = _bounded(widget.initialDailyNewGoal, 0, 100);
    _dailyReviewLimit = _bounded(widget.initialDailyReviewLimit, 0, 200);
    _completedNewToday = _bounded(
      widget.initialCompletedToday,
      0,
      _dailyNewGoal,
    );
    _reviewDueToday = _bounded(widget.initialReviewDueToday, 0, 500);
    _studyCursor = _completedNewToday;
    _speech.states.listen((state) {
      if (mounted) {
        setState(() => _speechState = state);
      }
    });
    _speech.messages.listen((message) {
      if (mounted) {
        _showSnack(message);
      }
    });
    _seedFuture = widget.initialSeed == null
        ? _repository.loadSeed()
        : Future.value(widget.initialSeed);
    if (widget.initialSeed == null) {
      unawaited(_restoreProgress());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: '自考英语打卡',
      theme: themeFor(_style),
      home: FutureBuilder<VocabSeed>(
        future: _seedFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorView(error: snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return const _LoadingView();
          }
          return _buildAppShell(seed: snapshot.data!);
        },
      ),
    );
  }

  Widget _buildAppShell({required VocabSeed seed}) {
    final studyItem = seed.items.isEmpty ? null : _currentStudyItem(seed);
    final pages = [
      DashboardPage(
        seed: seed,
        completedToday: _completedNewToday,
        newGoal: _dailyNewGoal,
        wordGoal: _wordGoalFor(seed),
        phraseGoal: _phraseGoalFor(seed),
        reviewCompletedToday: _reviewCompletedForGoal,
        reviewGoal: _reviewGoalToday,
        reviewDueToday: _pendingReviewToday,
        checkinFinished: _isCheckinFinished,
        currentStreak: _currentStreak,
        onStartStudy: () => _startStudy(seed),
        onOpenStylePicker: _openStylePicker,
        onOpenWordbook: () => _selectTab(2),
      ),
      studyItem == null
          ? _EmptyStudyPage(onExit: () => _selectTab(0))
          : StudyPage(
              item: studyItem,
              completedToday: _studyPhase == _StudyPhase.learning
                  ? _completedNewToday
                  : _reviewCompletedForGoal,
              totalToday: _studyPhase == _StudyPhase.learning
                  ? _dailyNewGoal
                  : _reviewGoalToday,
              sessionLabel: _studyPhase == _StudyPhase.learning
                  ? '今日学习'
                  : '今日复习',
              isReviewStage: _studyPhase == _StudyPhase.review,
              mode: _studyMode,
              onModeChanged: (mode) {
                setState(() {
                  _studyMode = mode;
                  _revealed = false;
                });
              },
              revealed: _revealed,
              onReveal: () => setState(() => _revealed = true),
              speechState: _speechState,
              onSpeak: () => _speak(studyItem.term),
              onStopSpeaking: _speech.stop,
              onRate: (rating) => _rateCard(seed, rating),
              onExit: () => _selectTab(0),
            ),
      WordbookPage(
        items: seed.items,
        speechState: _speechState,
        onSpeak: _speak,
        onStopSpeaking: _speech.stop,
      ),
      StatsPage(
        seed: seed,
        totalLearned: _totalLearned,
        masteredCount: _masteredCardIds.length,
        currentStreak: _currentStreak,
        longestStreak: _longestStreak,
        todayStudySeconds: _todayStudySeconds,
        dailyGoal: _dailyNewGoal + _reviewGoalToday,
        weeklyStats: _lastSevenDays(),
      ),
      SettingsPage(
        style: _style,
        dailyNewGoal: _dailyNewGoal,
        phraseRatioPercent: _phraseRatioPercent,
        dailyReviewLimit: _dailyReviewLimit,
        reminderTime: _reminderTime,
        onStyleChanged: _setStyle,
        onEditDailyNewGoal: _openDailyNewGoalPicker,
        onEditPhraseRatio: _openPhraseRatioPicker,
        onEditDailyReviewLimit: _openDailyReviewLimitPicker,
        onEditReminder: _openReminderTimePicker,
        onExportRecord: () => _exportStudyRecord(seed),
        onRestoreRecord: _restoreStudyRecord,
        onResetProgress: _confirmResetProgress,
      ),
    ];

    final palette = paletteFrom(context);
    return Scaffold(
      body: SafeArea(bottom: false, child: pages[_selectedIndex]),
      bottomNavigationBar: Container(
        color: palette.surface,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SizedBox(
                  width: double.infinity,
                  child: NavigationBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _selectTab,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.today_outlined),
                        selectedIcon: Icon(Icons.today_rounded),
                        label: '今日',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.style_outlined),
                        selectedIcon: Icon(Icons.style_rounded),
                        label: '学习',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.menu_book_outlined),
                        selectedIcon: Icon(Icons.menu_book_rounded),
                        label: '词库',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.insights_outlined),
                        selectedIcon: Icon(Icons.insights_rounded),
                        label: '统计',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: '设置',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speech.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshDateIfNeeded());
    }
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 1) {
        _revealed = false;
      }
    });
  }

  void _speak(String text) {
    unawaited(_speech.speak(text));
  }

  int get _reviewGoalToday => _minInt(_reviewDueToday, _dailyReviewLimit);

  int _phraseGoalFor(VocabSeed seed) {
    final words = seed.items
        .where((item) => item.kind == VocabKind.word)
        .length;
    final phrases = seed.items
        .where((item) => item.kind == VocabKind.phrase)
        .length;
    final total = _minInt(_dailyNewGoal, words + phrases);
    if (total <= 0 || phrases == 0) {
      return 0;
    }
    if (words == 0) {
      return total;
    }
    var target = (total * _phraseRatioPercent / 100).round();
    target = _bounded(target, _phraseRatioPercent > 0 ? 1 : 0, total - 1);
    target = _minInt(target, phrases);
    if (total - target > words) {
      target = total - words;
    }
    return target;
  }

  int _wordGoalFor(VocabSeed seed) =>
      _minInt(
        _dailyNewGoal,
        seed.items
            .where(
              (item) =>
                  item.kind == VocabKind.word || item.kind == VocabKind.phrase,
            )
            .length,
      ) -
      _phraseGoalFor(seed);

  int get _reviewCompletedForGoal =>
      _minInt(_reviewCompletedToday, _reviewGoalToday);

  int get _pendingReviewToday =>
      _maxInt(0, _reviewGoalToday - _reviewCompletedForGoal);

  bool get _hasNewCardsToday => _completedNewToday < _dailyNewGoal;

  bool get _isCheckinFinished => !_hasNewCardsToday && _pendingReviewToday == 0;

  void _startStudy(VocabSeed seed) {
    if (seed.items.isEmpty) {
      _showSnack('词库为空，暂时不能开始打卡');
      return;
    }
    if (_isCheckinFinished) {
      _showSnack('今天的打卡已经完成');
      return;
    }
    setState(() {
      _studyPhase = _hasNewCardsToday
          ? _StudyPhase.learning
          : _StudyPhase.review;
      _selectedIndex = 1;
      _revealed = false;
      _studyStartedAt ??= DateTime.now();
    });
  }

  void _rateCard(VocabSeed seed, int rating) {
    if (seed.items.isEmpty) {
      return;
    }
    String? message;
    setState(() {
      final item = _currentStudyItem(seed);
      _recordCardProgress(item, rating);
      if (_studyPhase == _StudyPhase.learning) {
        _completedNewToday = _minInt(_completedNewToday + 1, _dailyNewGoal);
        if (_hasNewCardsToday) {
          _studyCursor =
              (_studyCursor + 1) %
              _itemsForPhase(seed, _StudyPhase.learning).length;
        } else if (_pendingReviewToday > 0) {
          _studyPhase = _StudyPhase.review;
          _reviewCursor = 0;
          message = '新词已完成，进入今日复习';
        } else {
          _selectedIndex = 0;
          message = '今日打卡完成';
        }
      } else {
        _reviewCompletedToday = _minInt(
          _reviewCompletedToday + 1,
          _reviewGoalToday,
        );
        if (_pendingReviewToday > 0) {
          _reviewCursor =
              (_reviewCursor + 1) %
              _itemsForPhase(seed, _StudyPhase.review).length;
        } else {
          _selectedIndex = 0;
          message = '今日复习完成，打卡成功';
        }
      }
      if (_isCheckinFinished) {
        _recordTodayCompletion();
        _studyStartedAt = null;
      }
      _revealed = false;
    });
    unawaited(_persistProgress());
    if (message != null) {
      _showSnack(message!);
    }
  }

  Future<void> _openStylePicker() async {
    final sheetContext = _navigatorKey.currentContext;
    if (sheetContext == null) {
      return;
    }
    final chosen = await showModalBottomSheet<AppStyle>(
      context: sheetContext,
      showDragHandle: true,
      backgroundColor: paletteFrom(sheetContext).surface,
      builder: (bottomSheetContext) {
        final current = paletteFrom(bottomSheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择视觉风格',
                  style: Theme.of(bottomSheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  '同一套功能，不同的阅读氛围。',
                  style: Theme.of(bottomSheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...AppStyle.values.map(
                  (style) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _StyleChoice(
                      style: style,
                      selected: style == _style,
                      current: current,
                      onTap: () => Navigator.of(bottomSheetContext).pop(style),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (chosen != null && mounted) {
      _setStyle(chosen);
    }
  }

  Future<void> _openDailyNewGoalPicker() async {
    final chosen = await _openNumberSetting(
      title: '每日新词',
      current: _dailyNewGoal,
      min: 0,
      max: 80,
      step: 5,
      unit: '个',
    );
    if (chosen == null || !mounted) {
      return;
    }
    setState(() {
      _dailyNewGoal = chosen;
      _completedNewToday = _minInt(_completedNewToday, _dailyNewGoal);
      _syncStudyPhaseAfterPlanChange();
    });
    unawaited(_persistProgress());
    _showSnack('每日新词已调整为 $chosen 个');
  }

  Future<void> _openPhraseRatioPicker() async {
    final chosen = await _openNumberSetting(
      title: '词组占比',
      current: _phraseRatioPercent,
      min: 0,
      max: 50,
      step: 5,
      unit: '%',
    );
    if (chosen == null || !mounted) {
      return;
    }
    setState(() => _phraseRatioPercent = chosen);
    unawaited(_persistProgress());
    _showSnack('词组占比已调整为 $chosen%');
  }

  Future<void> _openDailyReviewLimitPicker() async {
    final chosen = await _openNumberSetting(
      title: '每日复习上限',
      current: _dailyReviewLimit,
      min: 0,
      max: 120,
      step: 5,
      unit: '个',
    );
    if (chosen == null || !mounted) {
      return;
    }
    setState(() {
      _dailyReviewLimit = chosen;
      _reviewCompletedToday = _minInt(_reviewCompletedToday, _reviewGoalToday);
      _syncStudyPhaseAfterPlanChange();
    });
    unawaited(_persistProgress());
    _showSnack('每日复习上限已调整为 $chosen 个');
  }

  Future<void> _openReminderTimePicker() async {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: '每日提醒',
      cancelText: '取消',
      confirmText: '保存',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _reminderTime = picked);
    unawaited(_persistProgress());
    unawaited(_reminder.scheduleDaily(picked));
    _showSnack('每日提醒已设为 ${_formatTimeOfDay(picked)}');
  }

  void _exportStudyRecord(VocabSeed seed) {
    final now = DateTime.now();
    final record = {
      'date': _formatDate(now),
      'course': seed.metadata['title'] as String? ?? '自考英语',
      'dailyNewGoal': _dailyNewGoal,
      'dailyReviewLimit': _dailyReviewLimit,
      'newCompletedToday': _completedNewToday,
      'reviewCompletedToday': _reviewCompletedForGoal,
      'reviewDueToday': _pendingReviewToday,
      'checkinFinished': _isCheckinFinished,
      'currentStreak': _currentStreak,
      'longestStreak': _longestStreak,
      'totalLearned': _totalLearned,
      'totalReviews': _totalReviews,
      'masteredCount': _masteredCardIds.length,
      'todayStudySeconds': _todayStudySeconds,
      'completedDates': _completedDates.toList()..sort(),
      'progress': _snapshot().toJson(),
      'reminderTime': _formatTimeOfDay(_reminderTime),
      'style': _style.name,
      'exportedAt': now.toIso8601String(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    Clipboard.setData(
      ClipboardData(text: encoder.convert(record)),
    ).catchError((_) {});
    _showSnack('学习记录已复制到剪贴板');
  }

  Future<void> _restoreStudyRecord() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      _showSnack('剪贴板没有可恢复的学习记录');
      return;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const FormatException();
      }
      final rawProgress = decoded['progress'] is Map
          ? decoded['progress']
          : decoded;
      final restored = StudyProgress.fromJson(
        Map<String, dynamic>.from(rawProgress as Map),
      );
      final progress = _forToday(restored, _formatDate(DateTime.now()));
      if (!mounted) {
        return;
      }
      setState(() {
        _applyProgress(progress);
        _selectedIndex = 0;
        _studyPhase = _StudyPhase.learning;
        _studyCursor = 0;
        _reviewCursor = 0;
        _revealed = false;
        _studyMode = StudyMode.flashcard;
      });
      await _persistProgress();
      _showSnack('学习记录已恢复');
    } catch (_) {
      _showSnack('学习记录格式无效，无法恢复');
    }
  }

  Future<void> _confirmResetProgress() async {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    final palette = paletteFrom(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: palette.surface,
          title: const Text('重新开始？'),
          content: const Text('这会清空今天的新学、复习进度和待复习记录。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('重新开始'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _selectedIndex = 0;
      _studyCursor = 0;
      _reviewCursor = 0;
      _completedNewToday = 0;
      _reviewCompletedToday = 0;
      _reviewDueToday = 0;
      _studyPhase = _StudyPhase.learning;
      _studyMode = StudyMode.flashcard;
      _revealed = false;
      _studyStartedAt = null;
    });
    unawaited(_persistProgress());
    _showSnack('学习记录已重置');
  }

  Future<int?> _openNumberSetting({
    required String title,
    required int current,
    required int min,
    required int max,
    required int step,
    required String unit,
  }) async {
    final sheetContext = _navigatorKey.currentContext;
    if (sheetContext == null) {
      return null;
    }
    var draft = _bounded(current, min, max);
    return showModalBottomSheet<int>(
      context: sheetContext,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: paletteFrom(sheetContext).surface,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final palette = paletteFrom(context);
            void shift(int delta) {
              setModalState(() {
                draft = _bounded(draft + delta, min, max);
              });
            }

            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 2, 22, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: draft <= min ? null : () => shift(-step),
                            icon: const Icon(Icons.remove_rounded),
                            tooltip: '减少',
                          ),
                          Expanded(
                            child: Text(
                              '$draft $unit',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: draft >= max ? null : () => shift(step),
                            icon: const Icon(Icons.add_rounded),
                            tooltip: '增加',
                          ),
                        ],
                      ),
                      Slider(
                        value: draft.toDouble(),
                        min: min.toDouble(),
                        max: max.toDouble(),
                        divisions: step <= 0 ? null : (max - min) ~/ step,
                        label: '$draft $unit',
                        activeColor: palette.accent,
                        onChanged: (value) {
                          setModalState(() {
                            draft = _snapToStep(value, min, max, step);
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      PrimaryAction(
                        label: '保存',
                        icon: Icons.check_rounded,
                        onPressed: () => Navigator.of(context).pop(draft),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  VocabItem _currentStudyItem(VocabSeed seed) {
    final items = _itemsForPhase(seed, _studyPhase);
    final cursor = _studyPhase == _StudyPhase.learning
        ? _studyCursor
        : _reviewCursor;
    return items[cursor % items.length];
  }

  List<VocabItem> _itemsForPhase(VocabSeed seed, _StudyPhase phase) {
    if (phase == _StudyPhase.learning) {
      return _itemsForNewPhase(seed);
    }
    if (phase == _StudyPhase.review) {
      final scheduled = seed.items
          .where((item) {
            final dueDate = _reviewDueDates[item.id];
            return dueDate != null && dueDate.compareTo(_currentDateKey) <= 0;
          })
          .toList(growable: false);
      if (scheduled.isNotEmpty) {
        return scheduled;
      }
    }
    final filtered = seed.items
        .where(
          (item) => phase == _StudyPhase.learning
              ? item.kind == VocabKind.word
              : item.kind == VocabKind.phrase,
        )
        .toList(growable: false);
    return filtered.isEmpty ? seed.items : filtered;
  }

  List<VocabItem> _itemsForNewPhase(VocabSeed seed) {
    final words = seed.items
        .where((item) => item.kind == VocabKind.word)
        .toList(growable: false);
    final phrases = seed.items
        .where((item) => item.kind == VocabKind.phrase)
        .toList(growable: false);
    final total = _minInt(_dailyNewGoal, words.length + phrases.length);
    if (total == 0) {
      return seed.items;
    }
    final phraseGoal = _phraseGoalFor(seed);
    final wordGoal = total - phraseGoal;
    final dayOffset = DateTime.parse(
      _currentDateKey,
    ).difference(DateTime(2026, 1, 1)).inDays;
    var wordIndex = 0;
    var phraseIndex = 0;
    final queue = <VocabItem>[];
    for (var slot = 0; slot < total; slot += 1) {
      final expectedPhrases = (slot + 1) * phraseGoal / total;
      final choosePhrase =
          phraseIndex < phraseGoal &&
          (wordIndex >= wordGoal || expectedPhrases > phraseIndex + .5);
      if (choosePhrase) {
        queue.add(phrases[(dayOffset + phraseIndex) % phrases.length]);
        phraseIndex += 1;
      } else {
        queue.add(words[(dayOffset + wordIndex) % words.length]);
        wordIndex += 1;
      }
    }
    return queue;
  }

  void _syncStudyPhaseAfterPlanChange() {
    if (_selectedIndex != 1) {
      return;
    }
    if (_studyPhase == _StudyPhase.learning && !_hasNewCardsToday) {
      if (_pendingReviewToday > 0) {
        _studyPhase = _StudyPhase.review;
      } else {
        _selectedIndex = 0;
      }
      _revealed = false;
    }
    if (_studyPhase == _StudyPhase.review && _pendingReviewToday == 0) {
      _selectedIndex = 0;
      _revealed = false;
    }
  }

  void _setStyle(AppStyle style) {
    setState(() => _style = style);
    unawaited(_persistProgress());
  }

  Future<void> _restoreProgress() async {
    final today = _formatDate(DateTime.now());
    final saved = await _progressStore.load();
    if (!mounted) {
      return;
    }
    final progress = saved == null
        ? StudyProgress.empty(
            dateKey: today,
            dailyNewGoal: _dailyNewGoal,
            dailyReviewLimit: _dailyReviewLimit,
          )
        : _forToday(saved, today);
    setState(() => _applyProgress(progress));
    await _persistProgress();
    await _reminder.scheduleDaily(_reminderTime);
  }

  Future<void> _refreshDateIfNeeded() async {
    if (widget.initialSeed != null) {
      return;
    }
    final today = _formatDate(DateTime.now());
    if (today == _currentDateKey) {
      return;
    }
    final progress = _forToday(_snapshot(), today);
    if (!mounted) {
      return;
    }
    setState(() {
      _applyProgress(progress);
      _selectedIndex = 0;
      _studyPhase = _StudyPhase.learning;
      _studyCursor = 0;
      _reviewCursor = 0;
      _revealed = false;
    });
    await _persistProgress();
  }

  StudyProgress _forToday(StudyProgress progress, String today) {
    if (progress.dateKey == today) {
      return progress.copyWith(
        currentStreak: _calculateStreak(progress.completedDates, today),
      );
    }
    final completedReviews = _minInt(
      progress.reviewCompletedToday,
      _minInt(progress.reviewDueToday, progress.dailyReviewLimit),
    );
    final pendingReviews = _maxInt(
      0,
      progress.reviewDueToday - completedReviews,
    );
    final scheduledReviews = progress.reviewDueDates.values
        .where((dateKey) => dateKey.compareTo(today) <= 0)
        .length;
    return progress.copyWith(
      dateKey: today,
      completedNewToday: 0,
      reviewCompletedToday: 0,
      reviewDueToday: _maxInt(pendingReviews, scheduledReviews),
      currentStreak: _calculateStreak(progress.completedDates, today),
      todayStudySeconds: 0,
    );
  }

  void _applyProgress(StudyProgress progress) {
    _currentDateKey = progress.dateKey;
    _dailyNewGoal = _bounded(progress.dailyNewGoal, 0, 100);
    _phraseRatioPercent = _bounded(progress.phraseRatioPercent, 0, 50);
    _dailyReviewLimit = _bounded(progress.dailyReviewLimit, 0, 200);
    _completedNewToday = _bounded(progress.completedNewToday, 0, _dailyNewGoal);
    _studyCursor = _completedNewToday;
    _reviewCursor = 0;
    _reviewCompletedToday = _maxInt(0, progress.reviewCompletedToday);
    _reviewDueToday = _maxInt(0, progress.reviewDueToday);
    _currentStreak = progress.currentStreak;
    _longestStreak = progress.longestStreak;
    _totalLearned = progress.totalLearned;
    _totalReviews = progress.totalReviews;
    _todayStudySeconds = progress.todayStudySeconds;
    _completedDates
      ..clear()
      ..addAll(progress.completedDates);
    _dailyCompleted
      ..clear()
      ..addAll(progress.dailyCompleted);
    _dailyStudySeconds
      ..clear()
      ..addAll(progress.dailyStudySeconds);
    _seenCardIds
      ..clear()
      ..addAll(progress.seenCardIds);
    _masteredCardIds
      ..clear()
      ..addAll(progress.masteredCardIds);
    _reviewDueDates
      ..clear()
      ..addAll(progress.reviewDueDates);
    _style = _styleFromName(progress.styleName);
    _reminderTime = _timeFromMinutes(progress.reminderMinutes);
  }

  StudyProgress _snapshot() {
    return StudyProgress(
      dateKey: _currentDateKey,
      dailyNewGoal: _dailyNewGoal,
      phraseRatioPercent: _phraseRatioPercent,
      dailyReviewLimit: _dailyReviewLimit,
      completedNewToday: _completedNewToday,
      reviewCompletedToday: _reviewCompletedToday,
      reviewDueToday: _reviewDueToday,
      currentStreak: _currentStreak,
      longestStreak: _longestStreak,
      totalLearned: _totalLearned,
      totalReviews: _totalReviews,
      todayStudySeconds: _todayStudySeconds,
      completedDates: Set<String>.from(_completedDates),
      dailyCompleted: Map<String, int>.from(_dailyCompleted),
      dailyStudySeconds: Map<String, int>.from(_dailyStudySeconds),
      seenCardIds: Set<String>.from(_seenCardIds),
      masteredCardIds: Set<String>.from(_masteredCardIds),
      reviewDueDates: Map<String, String>.from(_reviewDueDates),
      styleName: _style.name,
      reminderMinutes: _reminderTime.hour * 60 + _reminderTime.minute,
    );
  }

  Future<void> _persistProgress() async {
    if (widget.initialSeed != null) {
      return;
    }
    await _progressStore.save(_snapshot());
  }

  void _recordCardProgress(VocabItem item, int rating) {
    final now = DateTime.now();
    final elapsed = _studyStartedAt == null
        ? 1
        : _maxInt(1, now.difference(_studyStartedAt!).inSeconds);
    _todayStudySeconds += elapsed;
    _dailyStudySeconds[_currentDateKey] =
        (_dailyStudySeconds[_currentDateKey] ?? 0) + elapsed;
    _dailyCompleted[_currentDateKey] =
        (_dailyCompleted[_currentDateKey] ?? 0) + 1;
    _studyStartedAt = now;

    if (_seenCardIds.add(item.id)) {
      _totalLearned += 1;
    }
    _totalReviews += 1;
    if (rating == 3) {
      _masteredCardIds.add(item.id);
    } else if (rating == 0) {
      _masteredCardIds.remove(item.id);
    }
    _scheduleReview(item.id, rating);
  }

  void _scheduleReview(String cardId, int rating) {
    final today = DateTime.parse(_currentDateKey);
    final days = switch (rating) {
      0 => 0,
      1 => 1,
      2 => 3,
      _ => 7,
    };
    _reviewDueDates[cardId] = _formatDate(today.add(Duration(days: days)));
    if (_studyPhase == _StudyPhase.learning && rating == 0) {
      _reviewDueToday += 1;
    } else if (_studyPhase == _StudyPhase.review && rating > 0) {
      _reviewDueToday = _maxInt(0, _reviewDueToday - 1);
    }
  }

  void _recordTodayCompletion() {
    if (_completedDates.add(_currentDateKey)) {
      _currentStreak = _calculateStreak(_completedDates, _currentDateKey);
      _longestStreak = _maxInt(_longestStreak, _currentStreak);
    }
    final planned = _dailyNewGoal + _reviewGoalToday;
    _dailyCompleted[_currentDateKey] = _maxInt(
      _dailyCompleted[_currentDateKey] ?? 0,
      planned,
    );
  }

  List<DailyStudyStat> _lastSevenDays() {
    final today = DateTime.parse(_currentDateKey);
    return List<DailyStudyStat>.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final key = _formatDate(date);
      return DailyStudyStat(
        dateKey: key,
        completed: _dailyCompleted[key] ?? 0,
        studySeconds: _dailyStudySeconds[key] ?? 0,
        completedDay: _completedDates.contains(key),
      );
    });
  }

  int _calculateStreak(Set<String> dates, String today) {
    var anchor = DateTime.parse(today);
    if (!dates.contains(_formatDate(anchor))) {
      anchor = anchor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (dates.contains(_formatDate(anchor))) {
      streak += 1;
      anchor = anchor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  AppStyle _styleFromName(String name) {
    return AppStyle.values.firstWhere(
      (style) => style.name == name,
      orElse: () => AppStyle.paper,
    );
  }

  TimeOfDay _timeFromMinutes(int minutes) {
    final normalized = minutes.clamp(0, 23 * 60 + 59);
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }

  void _showSnack(String message) {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StyleChoice extends StatelessWidget {
  const _StyleChoice({
    required this.style,
    required this.selected,
    required this.current,
    required this.onTap,
  });

  final AppStyle style;
  final bool selected;
  final AppPalette current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = paletteFor(style);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? preview.accentSoft : current.surface,
          borderRadius: BorderRadius.circular(preview.radius),
          border: Border.all(
            color: selected ? preview.accent : current.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 40,
              decoration: BoxDecoration(
                color: preview.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: preview.line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Swatch(color: preview.accent),
                  const SizedBox(width: 4),
                  _Swatch(color: preview.secondary),
                  const SizedBox(width: 4),
                  _Swatch(color: preview.ink),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? preview.accent : current.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('词库加载失败\n$error', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _EmptyStudyPage extends StatelessWidget {
  const _EmptyStudyPage({required this.onExit});

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_outlined, size: 42),
          const SizedBox(height: 14),
          Text('词库暂无内容', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '请先导入词库，再开始今日打卡。',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          PrimaryAction(
            label: '返回今日',
            icon: Icons.arrow_back_rounded,
            onPressed: onExit,
          ),
        ],
      ),
    );
  }
}

int _bounded(int value, int min, int max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}

int _minInt(int first, int second) => first < second ? first : second;

int _maxInt(int first, int second) => first > second ? first : second;

int _snapToStep(double value, int min, int max, int step) {
  if (step <= 0) {
    return _bounded(value.round(), min, max);
  }
  final steps = ((value - min) / step).round();
  return _bounded(min + steps * step, min, max);
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
