class TriggeredRule {
  const TriggeredRule({
    required this.id,
    required this.category,
    required this.description,
  });

  final String id;
  final String category;
  final String description;

  factory TriggeredRule.fromJson(Map<String, dynamic> json) {
    return TriggeredRule(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.sources = const <String>[],
    this.confidence,
    this.confidenceLabel,
    this.safetyAction = 'pass',
    this.triggeredRules = const <TriggeredRule>[],
  });

  final String role;
  final String text;
  final List<String> sources;
  final int? confidence;
  final String? confidenceLabel;
  final String safetyAction;
  final List<TriggeredRule> triggeredRules;
}

const List<String> kSuggestedQuestions = [
  'Comment prevenir une hypoglycemie ?',
  'Quel sport est recommande ?',
  'Quand faut-il consulter ?',
  'Comment lire mon HbA1c ?',
];
