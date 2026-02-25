class QuestionModel {
  final String id;
  final String type; // 'fill_in_blank' or 'multiple_choice'
  final String question;
  final String correctAnswer;
  final String topic;
  final List<String>? choices; // null for fill-in-blank, 4 options for MCQ

  const QuestionModel({
    required this.id,
    this.type = 'fill_in_blank',
    required this.question,
    required this.correctAnswer,
    required this.topic,
    this.choices,
  });

  bool get isMultipleChoice => type == 'multiple_choice' && choices != null;

  factory QuestionModel.fromMap(Map<String, dynamic> data) {
    return QuestionModel(
      id: data['id'] ?? '',
      type: data['type'] ?? 'fill_in_blank',
      question: data['question'] ?? '',
      correctAnswer: data['correctAnswer'] ?? '',
      topic: data['topic'] ?? '',
      choices: data['choices'] != null
          ? List<String>.from(data['choices'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'question': question,
    'correctAnswer': correctAnswer,
    'topic': topic,
    if (choices != null) 'choices': choices,
  };
}
