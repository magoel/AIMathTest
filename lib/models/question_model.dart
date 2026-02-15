class QuestionModel {
  final String id;
  final String type;
  final String question;
  final String correctAnswer;
  final String topic;

  const QuestionModel({
    required this.id,
    this.type = 'fill_in_blank',
    required this.question,
    required this.correctAnswer,
    required this.topic,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> data) {
    return QuestionModel(
      id: data['id'] ?? '',
      type: data['type'] ?? 'fill_in_blank',
      question: data['question'] ?? '',
      correctAnswer: data['correctAnswer'] ?? '',
      topic: data['topic'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'question': question,
    'correctAnswer': correctAnswer,
    'topic': topic,
  };
}
