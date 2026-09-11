import 'package:flutter/material.dart';

import 'data/vocab_repository.dart';
import 'models/vocab_item.dart';
import 'services/speech_service.dart';
import 'theme/app_theme.dart';
import 'ui/pages.dart';
import 'ui/shared_widgets.dart';

void main() {
  runApp(const SelfCheckinApp());
}

class SelfCheckinApp extends StatefulWidget {
  const SelfCheckinApp({this.initialSeed, super.key});

  final VocabSeed? initialSeed;

  @override
  State<SelfCheckinApp> createState() => _SelfCheckinAppState();
}

class _SelfCheckinAppState extends State<SelfCheckinApp> {
  final _repository = const VocabRepository();
  final _speech = SpeechService();
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final Future<VocabSeed> _seedFuture;

  AppStyle _style = AppStyle.paper;
  int _selectedIndex = 0;
  int _studyCursor = 0;
  int _completedToday = 7;
  bool _revealed = false;
  SpeechState _speechState = SpeechState.idle;

  static const int _dailyGoal = 20;

  @override
  void initState() {
    super.initState();
    _speech.states.listen((state) {
      if (mounted) {
        setState(() => _speechState = state);
      }
    });
    _seedFuture = widget.initialSeed == null
        ? _repository.loadSeed()
        : Future.value(widget.initialSeed);
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
    final pages = [
      DashboardPage(
        seed: seed,
        completedToday: _completedToday,
        newGoal: _dailyGoal,
        onStartStudy: () => _startStudy(seed),
        onOpenStylePicker: _openStylePicker,
        onOpenWordbook: () => _selectTab(2),
      ),
      StudyPage(
        item: seed.items[_studyCursor % seed.items.length],
        completedToday: _completedToday,
        totalToday: _dailyGoal,
        revealed: _revealed,
        onReveal: () => setState(() => _revealed = true),
        speechState: _speechState,
        onSpeak: () =>
            _speech.speak(seed.items[_studyCursor % seed.items.length].term),
        onStopSpeaking: _speech.stop,
        onRate: (rating) => _rateCard(seed, rating),
        onExit: () => _selectTab(0),
      ),
      WordbookPage(
        items: seed.items,
        speechState: _speechState,
        onSpeak: _speech.speak,
        onStopSpeaking: _speech.stop,
      ),
      StatsPage(seed: seed),
      SettingsPage(
        style: _style,
        onStyleChanged: (style) => setState(() => _style = style),
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
    _speech.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 1) {
        _revealed = false;
      }
    });
  }

  void _startStudy(VocabSeed seed) {
    if (seed.items.isEmpty) {
      return;
    }
    setState(() {
      _selectedIndex = 1;
      _revealed = false;
    });
  }

  void _rateCard(VocabSeed seed, int rating) {
    if (seed.items.isEmpty) {
      return;
    }
    setState(() {
      _completedToday = (_completedToday + 1).clamp(0, _dailyGoal);
      _studyCursor = (_studyCursor + 1) % seed.items.length;
      _revealed = false;
    });
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
      setState(() => _style = chosen);
    }
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
