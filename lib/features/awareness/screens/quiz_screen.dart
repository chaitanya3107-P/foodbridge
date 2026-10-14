import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/awareness_model.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _hasSubmittedCurrent = false;
  int _correctCount = 0;
  final Map<int, int> _userAnswers = {};

  void _submitAnswer(int correctIndex) {
    if (_selectedOptionIndex == null) return;
    setState(() {
      _hasSubmittedCurrent = true;
      _userAnswers[_currentIndex] = _selectedOptionIndex!;
      if (_selectedOptionIndex == correctIndex) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion(int totalQuestions) {
    if (_currentIndex < totalQuestions - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _hasSubmittedCurrent = false;
      });
    } else {
      setState(() {
        _currentIndex = totalQuestions; // Complete
      });
    }
  }

  void _retakeQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedOptionIndex = null;
      _hasSubmittedCurrent = false;
      _correctCount = 0;
      _userAnswers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food-Waste Prevention Quiz'),
      ),
      body: SafeArea(
        child: quizAsync.when(
          data: (quiz) {
            final questions = quiz.questions;
            final total = questions.length;

            if (_currentIndex >= total) {
              return _buildResultsView(total, questions);
            }

            final currentQ = questions[_currentIndex];
            final progress = (_currentIndex + 1) / total;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentIndex + 1} of $total',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryGreen),
                      ),
                      Text(
                        'Score: $_correctCount',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE2EBE5),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),

                  const SizedBox(height: 20),

                  // Question Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCCD9D1)),
                    ),
                    child: Text(
                      currentQ.question,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3228),
                        height: 1.35,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Options
                  ...currentQ.options.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final optionText = entry.value;

                    final isSelected = _selectedOptionIndex == idx;
                    final isCorrect = idx == currentQ.correctIndex;

                    Color bg = Colors.white;
                    Color border = const Color(0xFFCCD9D1);
                    IconData icon = Icons.radio_button_off_rounded;
                    Color iconColor = Colors.grey;

                    if (_hasSubmittedCurrent) {
                      if (isCorrect) {
                        bg = const Color(0xFFE8F5E9);
                        border = const Color(0xFF2E7D32);
                        icon = Icons.check_circle_rounded;
                        iconColor = const Color(0xFF2E7D32);
                      } else if (isSelected) {
                        bg = const Color(0xFFFFEBEE);
                        border = AppTheme.alertRed;
                        icon = Icons.cancel_rounded;
                        iconColor = AppTheme.alertRed;
                      }
                    } else if (isSelected) {
                      bg = AppTheme.primaryContainer.withOpacity(0.5);
                      border = AppTheme.primaryGreen;
                      icon = Icons.radio_button_checked_rounded;
                      iconColor = AppTheme.primaryGreen;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: InkWell(
                        onTap: _hasSubmittedCurrent
                            ? null
                            : () => setState(() => _selectedOptionIndex = idx),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border, width: isSelected || (_hasSubmittedCurrent && isCorrect) ? 1.8 : 1.0),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, color: iconColor, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: const Color(0xFF1E3228),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 14),

                  // Explanation feedback box upon submit
                  if (_hasSubmittedCurrent) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedOptionIndex == currentQ.correctIndex
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedOptionIndex == currentQ.correctIndex
                              ? const Color(0xFF81C784)
                              : const Color(0xFFFFB74D),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _selectedOptionIndex == currentQ.correctIndex
                                    ? Icons.check_circle_rounded
                                    : Icons.info_rounded,
                                size: 18,
                                color: _selectedOptionIndex == currentQ.correctIndex
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFE65100),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedOptionIndex == currentQ.correctIndex
                                    ? 'Correct Answer!'
                                    : 'Review Explanation:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _selectedOptionIndex == currentQ.correctIndex
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFE65100),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentQ.explanation,
                            style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  if (!_hasSubmittedCurrent)
                    AppButton(
                      label: 'Check Answer',
                      icon: Icons.check_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: _selectedOptionIndex != null
                          ? () => _submitAnswer(currentQ.correctIndex)
                          : null,
                    )
                  else
                    AppButton(
                      label: _currentIndex < total - 1 ? 'Next Question →' : 'View Results & Certificate',
                      icon: Icons.arrow_forward_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: () => _nextQuestion(total),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildResultsView(int total, List<QuizQuestion> questions) {
    final scorePercent = ((_correctCount / total) * 100).round();
    final isPassed = scorePercent >= 70;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isPassed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPassed ? Icons.workspace_premium_rounded : Icons.replay_rounded,
              color: isPassed ? AppTheme.primaryGreen : Colors.deepOrange,
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPassed ? 'Assessment Completed!' : 'Keep Practicing!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E3228)),
          ),
          const SizedBox(height: 6),
          Text(
            isPassed
                ? 'Great job! You have demonstrated strong competency in surplus food safety and waste prevention.'
                : 'Review the explanations below and retake the quiz to master food donation safety.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4A5D54)),
          ),
          const SizedBox(height: 20),

          // Score Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2EBE5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('$_correctCount / $total', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primaryGreen)),
                    const SizedBox(height: 4),
                    const Text('Correct Answers', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
                Container(height: 40, width: 1, color: const Color(0xFFE2EBE5)),
                Column(
                  children: [
                    Text('$scorePercent%', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: isPassed ? const Color(0xFF2E7D32) : Colors.deepOrange)),
                    const SizedBox(height: 4),
                    const Text('Final Score', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          AppButton(
            label: 'Retake Quiz',
            icon: Icons.replay_rounded,
            variant: AppButtonVariant.primary,
            onPressed: _retakeQuiz,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Return to Awareness Centre',
            variant: AppButtonVariant.outline,
            onPressed: () => Navigator.pop(context),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
