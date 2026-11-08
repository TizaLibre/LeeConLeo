import '../../core/content/models/spoken_line.dart';

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.target,
    required this.promptId,
    required this.options,
    this.optionNames = const {},
    this.stepId,
    this.activityId,
    this.promptTail,
    this.extraLines = const [],
    this.demoLines = const [],
  });

  final String id;
  final String target;
  final String promptId;
  final List<String> options;
  final Map<String, SpokenLine> optionNames;
  final String? stepId;
  final String? activityId;
  final SpokenLine? promptTail;
  final List<SpokenLine> extraLines;
  final List<SpokenLine> demoLines;
}
