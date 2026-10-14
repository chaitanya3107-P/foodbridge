enum AwarenessContentType {
  tip,
  poster,
  faq,
  campaign;

  String get displayName {
    switch (this) {
      case AwarenessContentType.tip:
        return 'Prevention Tip';
      case AwarenessContentType.poster:
        return 'Poster & Infographic';
      case AwarenessContentType.faq:
        return 'FAQ';
      case AwarenessContentType.campaign:
        return 'Campaign Event';
    }
  }

  static AwarenessContentType fromString(String val) {
    switch (val.toLowerCase()) {
      case 'poster':
        return AwarenessContentType.poster;
      case 'faq':
        return AwarenessContentType.faq;
      case 'campaign':
        return AwarenessContentType.campaign;
      default:
        return AwarenessContentType.tip;
    }
  }
}

class AwarenessContent {
  final String contentId;
  final String title;
  final AwarenessContentType type;
  final String category;
  final String body;
  final String sourceReviewer;
  final DateTime publishedDate;
  final bool isPublished;
  final DateTime? campaignDate;
  final String? bannerImageUrl;

  const AwarenessContent({
    required this.contentId,
    required this.title,
    required this.type,
    required this.category,
    required this.body,
    required this.sourceReviewer,
    required this.publishedDate,
    this.isPublished = true,
    this.campaignDate,
    this.bannerImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'title': title,
      'type': type.name,
      'category': category,
      'body': body,
      'sourceReviewer': sourceReviewer,
      'publishedDate': publishedDate.toIso8601String(),
      'isPublished': isPublished,
      'campaignDate': campaignDate?.toIso8601String(),
      'bannerImageUrl': bannerImageUrl,
    };
  }

  factory AwarenessContent.fromMap(Map<String, dynamic> map, String id) {
    return AwarenessContent(
      contentId: id,
      title: map['title'] ?? '',
      type: AwarenessContentType.fromString(map['type'] ?? 'tip'),
      category: map['category'] ?? 'General Awareness',
      body: map['body'] ?? '',
      sourceReviewer: map['sourceReviewer'] ?? 'NGO Educational Board',
      publishedDate: map['publishedDate'] != null
          ? DateTime.parse(map['publishedDate'])
          : DateTime.now(),
      isPublished: map['isPublished'] ?? true,
      campaignDate: map['campaignDate'] != null
          ? DateTime.parse(map['campaignDate'])
          : null,
      bannerImageUrl: map['bannerImageUrl'],
    );
  }
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
    );
  }
}

class Quiz {
  final String quizId;
  final String title;
  final String description;
  final bool isPostQuiz;
  final List<QuizQuestion> questions;

  const Quiz({
    required this.quizId,
    required this.title,
    required this.description,
    required this.isPostQuiz,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'title': title,
      'description': description,
      'isPostQuiz': isPostQuiz,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map, String id) {
    return Quiz(
      quizId: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isPostQuiz: map['isPostQuiz'] ?? false,
      questions: (map['questions'] as List<dynamic>?)
              ?.map((q) => QuizQuestion.fromMap(Map<String, dynamic>.from(q)))
              .toList() ??
          [],
    );
  }
}
