enum StudyMode { flashcard, translation, spelling, cloze }

extension StudyModeLabel on StudyMode {
  String get label {
    switch (this) {
      case StudyMode.flashcard:
        return '闪卡';
      case StudyMode.translation:
        return '中译英';
      case StudyMode.spelling:
        return '拼写练习';
      case StudyMode.cloze:
        return '例句挖空';
    }
  }
}
