// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:self_checkin/main.dart';
import 'package:self_checkin/models/vocab_item.dart';

void main() {
  testWidgets('loads the vocabulary check-in shell', (tester) async {
    const seed = VocabSeed(
      items: [
        VocabItem(
          id: 'word-0001',
          kind: VocabKind.word,
          term: 'abandon',
          meaning: '放弃；抛弃',
          example: 'He had to abandon his research.',
          senses: [],
        ),
      ],
      metadata: {'wordCardCount': 1, 'phraseCardCount': 0},
    );

    await tester.pumpWidget(const SelfCheckinApp(initialSeed: seed));
    await tester.pump();

    expect(find.text('今日任务'), findsOneWidget);
    expect(find.text('开始今日打卡'), findsOneWidget);
  });
}
