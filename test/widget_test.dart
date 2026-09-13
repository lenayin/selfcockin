// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:self_checkin/main.dart';
import 'package:self_checkin/models/vocab_item.dart';

void main() {
  const seed = VocabSeed(
    items: [
      VocabItem(
        id: 'word-0001',
        kind: VocabKind.word,
        term: 'abandon',
        meaning: '放弃；抛弃',
        example: 'He had to abandon his research.',
        exampleTranslation: '他不得不放弃研究。',
        senses: [],
      ),
    ],
    metadata: {'wordCardCount': 1, 'phraseCardCount': 0},
  );
  const phraseSeed = VocabSeed(
    items: [
      VocabItem(
        id: 'phrase-0001',
        kind: VocabKind.phrase,
        term: 'take part in',
        meaning: '参加',
        example: 'All students should take part in the sports meeting.',
        exampleTranslation: '所有学生都应参加运动会。',
        senses: [],
      ),
    ],
    metadata: {'wordCardCount': 0, 'phraseCardCount': 1},
  );

  testWidgets('loads the vocabulary check-in shell', (tester) async {
    await tester.pumpWidget(const SelfCheckinApp(initialSeed: seed));
    await tester.pump();

    expect(find.text('今日任务'), findsOneWidget);
    expect(find.text('开始今日打卡'), findsOneWidget);
  });

  testWidgets('moves from new words into the review stage', (tester) async {
    await tester.pumpWidget(
      const SelfCheckinApp(
        initialSeed: seed,
        initialDailyNewGoal: 1,
        initialCompletedToday: 0,
        initialReviewDueToday: 1,
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('开始今日打卡'));
    await tester.tap(find.text('开始今日打卡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('显示释义'));
    await tester.pump();
    expect(find.text('中文翻译'), findsOneWidget);
    expect(find.text('他不得不放弃研究。'), findsOneWidget);
    await tester.ensureVisible(find.text('认识'));
    await tester.tap(find.text('认识'));
    await tester.pump();

    expect(find.text('今日复习'), findsOneWidget);
    expect(find.text('复习阶段'), findsOneWidget);
  });

  testWidgets('finishes the check-in when there is no review', (tester) async {
    await tester.pumpWidget(
      const SelfCheckinApp(
        initialSeed: seed,
        initialDailyNewGoal: 1,
        initialCompletedToday: 0,
        initialReviewDueToday: 0,
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('开始今日打卡'));
    await tester.tap(find.text('开始今日打卡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('显示释义'));
    await tester.pump();
    await tester.ensureVisible(find.text('认识'));
    await tester.tap(find.text('认识'));
    await tester.pump();

    expect(find.text('今日已完成'), findsOneWidget);
    expect(find.text('今日打卡完成'), findsOneWidget);
  });

  testWidgets('can switch to translation practice mode', (tester) async {
    await tester.pumpWidget(
      const SelfCheckinApp(initialSeed: seed, initialDailyNewGoal: 1),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('开始今日打卡'));
    await tester.tap(find.text('开始今日打卡'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('切换练习模式'));
    await tester.tap(find.byTooltip('切换练习模式'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('中译英'));
    await tester.tap(find.text('中译英'));
    await tester.pumpAndSettle();

    expect(find.text('放弃；抛弃'), findsWidgets);
    expect(find.text('显示英文'), findsOneWidget);
  });

  testWidgets('shows Chinese translation for phrase examples', (tester) async {
    await tester.pumpWidget(
      const SelfCheckinApp(initialSeed: phraseSeed, initialDailyNewGoal: 1),
    );
    await tester.pump();

    await tester.ensureVisible(find.text('开始今日打卡'));
    await tester.tap(find.text('开始今日打卡'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('显示释义'));
    await tester.pump();

    expect(find.text('中文翻译'), findsOneWidget);
    expect(find.text('所有学生都应参加运动会。'), findsOneWidget);
  });

  testWidgets('daily new word setting can be changed', (tester) async {
    await tester.pumpWidget(const SelfCheckinApp(initialSeed: seed));
    await tester.pump();

    await tester.tap(find.text('设置'));
    await tester.pump();
    await tester.ensureVisible(find.text('每日新词'));
    await tester.tap(find.text('每日新词'));
    await tester.pumpAndSettle();

    expect(find.text('20 个'), findsWidgets);
    await tester.ensureVisible(find.byIcon(Icons.add_rounded));
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.ensureVisible(find.text('保存'));
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('25 个'), findsOneWidget);
  });

  testWidgets('data settings actions are wired', (tester) async {
    await tester.pumpWidget(const SelfCheckinApp(initialSeed: seed));
    await tester.pump();

    await tester.tap(find.text('设置'));
    await tester.pump();
    await tester.ensureVisible(find.text('导出学习记录'));
    await tester.tap(find.text('导出学习记录'));
    await tester.pumpAndSettle();

    expect(find.text('学习记录已复制到剪贴板'), findsOneWidget);

    await tester.tap(find.text('重新开始'));
    await tester.pumpAndSettle();
    expect(find.text('重新开始？'), findsOneWidget);
    await tester.tap(find.text('重新开始').last);
    await tester.pumpAndSettle();

    expect(find.text('开始今日打卡'), findsOneWidget);
  });
}
