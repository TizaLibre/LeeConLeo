import 'activity_ids.dart';

abstract final class ListeningPromptIds {
  static const clapAsk = '${ActivityIds.clap}.ask';
  static const clapShow = '${ActivityIds.clap}.show';
  static const clapYourTurn = '${ActivityIds.clap}.your_turn';

  static String clapSplit(String word) => '${ActivityIds.clap}.$word';
}
