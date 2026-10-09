/*
 * File: flashcard.dart
 * Description: UI screen for reviewing and quizzing on unlocked vocabulary.
 * Requires at least 15 discovered words to unlock.
 *
 * Dependencies:
 * - User (mock_data.dart)
 * - ThemeDatabase / GameTheme (theme_data.dart)
 * - AppFeedback (audio_helper.dart)
 * - AppTextStyles (text_styles.dart)
 * - Custom3DButton (components)
 * - VictoryEffect (components)
 * - assets/targetwords.json (word → Thai meaning map)
 *
 * Lifecycle:
 * - Created via the Flashcard tab in HomePage.
 * - Disposed when the user navigates away from the tab.
 *
 * Responsibilities:
 * - Manages the transition between Study (flip-card) and Quiz (multiple-choice) modes.
 * - Handles the asynchronous loading and parsing of vocabulary translations.
 * - Logic for generating quiz distractors and validating player answers.
 * - Updates user currency and saves progress upon quiz completion.
 *
 * Author: 660510649 Detnarin Karinchai, 660510685 Aissara Pathan
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import '../models/mock_data.dart';
import '../services/audio_helper.dart';
import '../theme/theme_data.dart';
import '../theme/text_styles.dart';
import '../components/custom_3d_buttton.dart';
import '../components/victory_effect.dart';

/// Vocabulary review screen with Study (flip-card) and Quiz (multiple-choice) modes.
///
/// Fields:
/// - [currentUser]: the active player whose word list and coins are read/mutated
/// - [onRefresh]: callback invoked after a quiz completes so [HomePage] updates
///   the coin badge
///
/// The screen is locked until [User.wordsFound] reaches 15. Once unlocked,
/// words are loaded from `assets/targetwords.json` and shuffled for variety.
class FlashcardPage extends StatefulWidget {
  final User currentUser;
  final VoidCallback onRefresh;

  const FlashcardPage({super.key, required this.currentUser, required this.onRefresh});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

/// The logic and UI state management for [FlashcardPage].
///
/// Orchestrates the animation controllers for card flipping and tracks the
/// scoring state for the multiple-choice quiz session.
class _FlashcardPageState extends State<FlashcardPage> with SingleTickerProviderStateMixin {
  bool isLoading = true;

  Map<String, String> wordMeanings = {};
  List<String> unlockedWords = [];

  bool isQuizMode = false;

  // --- Study Mode state ---
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool isFront = true;
  int studyIndex = 0;

  // --- Quiz Mode state ---
  int quizIndex = 0;
  int correctAnswersCount = 0;
  List<String> currentOptions = [];
  String? selectedAnswer;
  bool isAnswering = false;

  bool showVictory = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);

    _loadTranslations();
  }

  /// Loads Thai translations from `assets/targetwords.json` for all unlocked words.
  ///
  /// Side effects:
  /// - Populates [wordMeanings] and [unlockedWords]
  /// - Calls [_generateOptions] when done so the quiz is ready immediately
  /// - Sets [isLoading] to `false` when complete
  Future<void> _loadTranslations() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/targetwords.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      unlockedWords = List.from(widget.currentUser.foundWordsList);

      for (var word in unlockedWords) {
        String lowerWord = word.toLowerCase();
        if (data.containsKey(lowerWord) && data[lowerWord]['th'] != null) {
          wordMeanings[word] = data[lowerWord]['th'];
        } else {
          wordMeanings[word] = "ไม่มีคำแปล";
        }
      }

      setState(() {
        isLoading = false;
        if (unlockedWords.isNotEmpty) {
          unlockedWords.shuffle();
          _generateOptions();
        }
      });
    } catch (e) {
      print("Error loading targetwords.json: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  // ==========================================
  // 📖 STUDY MODE
  // ==========================================

  /// Flips the current study card to show or hide the translation.
  ///
  /// Side effects:
  /// - Plays a flip sound effect.
  /// - Triggers physical haptic feedback.
  void _flipCard() {
    if (_flipController.isAnimating) return;
    AppFeedback.playFlip(widget.currentUser);
    AppFeedback.triggerHaptic(widget.currentUser);

    if (isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    isFront = !isFront;
  }

  /// Advances to the next study card and resets the flip state.
  void _nextStudyCard() {
    if (studyIndex < unlockedWords.length - 1) {
      AppFeedback.playClick(widget.currentUser);
      setState(() {
        studyIndex++;
        _resetCard();
      });
    }
  }

  /// Returns to the previous study card and resets the flip state.
  void _prevStudyCard() {
    if (studyIndex > 0) {
      AppFeedback.playClick(widget.currentUser);
      setState(() {
        studyIndex--;
        _resetCard();
      });
    }
  }

  /// Resets the flip animation so the card always shows the front (word) side.
  void _resetCard() {
    if (!isFront) {
      _flipController.value = 0;
      isFront = true;
    }
  }

  // ==========================================
  // 🎮 QUIZ MODE
  // ==========================================

  /// Generates four answer options including the correct translation.
  ///
  /// Side effects:
  /// - Shuffles the distractor list to ensure random placement.
  /// - Resets [selectedAnswer] and [isAnswering] for the new question.
  void _generateOptions() {
    String currentWord = unlockedWords[quizIndex];
    String correctMeaning = wordMeanings[currentWord] ?? "ไม่มีคำแปล";

    List<String> allMeanings = wordMeanings.values.where((m) => m != "ไม่มีคำแปล").toList();
    allMeanings.remove(correctMeaning);
    allMeanings.shuffle();

    currentOptions = [correctMeaning];
    currentOptions.addAll(allMeanings.take(3));
    currentOptions.shuffle();

    selectedAnswer = null;
    isAnswering = false;
    showVictory = false;
  }

  /// Evaluates the [answer] against the correct meaning and advances the quiz.
  ///
  /// This method handles the asynchronous delay between questions.
  ///
  /// Side effects:
  /// - Increments [correctAnswersCount] on success.
  /// - Updates [User.coins] and saves to local storage on completion.
  /// - Displays an [AlertDialog] when the quiz ends.
  Future<void> _checkAnswer(String answer) async {
    if (isAnswering) return;

    setState(() {
      isAnswering = true;
      selectedAnswer = answer;
    });

    String currentWord = unlockedWords[quizIndex];
    String correctMeaning = wordMeanings[currentWord] ?? "";

    if (answer == correctMeaning) {
      correctAnswersCount++;
      AppFeedback.playCorrect(widget.currentUser);
      setState(() => showVictory = true);
    } else {
      AppFeedback.playWrong(widget.currentUser);
      AppFeedback.triggerHaptic(widget.currentUser);
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    if (quizIndex < unlockedWords.length - 1) {
      setState(() {
        quizIndex++;
        _generateOptions();
      });
    } else {
      int rewardCoins = correctAnswersCount;

      setState(() {
        widget.currentUser.coins += rewardCoins;
      });
      widget.currentUser.saveData();
      widget.onRefresh();

      _showQuizCompleteDialog(rewardCoins);
    }
  }

  /// Shows the end-of-round dialog with score and coin reward information.
  void _showQuizCompleteDialog(int rewardCoins) {
    final theme = ThemeDatabase.getTheme(widget.currentUser.currentThemeId);
    AppFeedback.playWin(widget.currentUser);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Image.asset(
              'assets/images/wowquackle.png',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              "ROUND COMPLETE!",
              style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Score: $correctAnswersCount / ${unlockedWords.length}",
              style: TextStyle(color: theme.correct, fontSize: 22, fontWeight: FontWeight.w900)
            ),
            const SizedBox(height: 15),
            Text(
              rewardCoins > 0 ? "Great job! Here is your reward." : "Keep practicing! You can do it.",
              style: TextStyle(color: theme.textColor.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("💰", style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    "+$rewardCoins Coins",
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.brown, fontSize: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.correct,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                AppFeedback.playClick(widget.currentUser);
                AppFeedback.triggerHaptic(widget.currentUser);
                Navigator.pop(context);

                setState(() {
                  unlockedWords.shuffle();
                  quizIndex = 0;
                  correctAnswersCount = 0;
                  _generateOptions();
                });
              },
              child: const Text("Play Again", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // 🖥️ UI BUILDER
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final theme = ThemeDatabase.getTheme(widget.currentUser.currentThemeId);

    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.correct));
    }

    if (widget.currentUser.wordsFound < 15) {
      int wordsNeeded = 15 - widget.currentUser.wordsFound;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 100, color: theme.textColor.withOpacity(0.3)),
              const SizedBox(height: 20),
              Text("LOCKED", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.textColor)),
              const SizedBox(height: 15),
              Text("Find $wordsNeeded more words to unlock\nStudy & Quiz Modes!", textAlign: TextAlign.center, style: TextStyle(color: theme.textColor.withOpacity(0.7), fontSize: 18)),
            ],
          ),
        ),
      );
    }

    if (unlockedWords.isEmpty) {
      return Center(child: Text("No words available.", style: TextStyle(color: theme.textColor)));
    }

    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    "FLASHCARDS",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.textColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: theme.textColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildModeTab("📖 STUDY", false, theme)),
                      Expanded(child: _buildModeTab("🎮 QUIZ", true, theme)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: isQuizMode ? _buildQuizMode(theme) : _buildStudyMode(theme),
                ),
              ],
            ),
          ),
        ),

        if (showVictory) const VictoryEffect(),
      ],
    );
  }

  Widget _buildModeTab(String title, bool isQuiz, GameTheme theme) {
    bool isSelected = isQuizMode == isQuiz;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          AppFeedback.playClick(widget.currentUser);
          setState(() => isQuizMode = isQuiz);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? theme.correct : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected ? [BoxShadow(color: theme.correct.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textColor.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStudyMode(GameTheme theme) {
    String currentWord = unlockedWords[studyIndex];
    String currentMeaning = wordMeanings[currentWord] ?? "";

    return Column(
      children: [
        Text(
          "Card ${studyIndex + 1} of ${unlockedWords.length}",
          style: TextStyle(color: theme.textColor.withOpacity(0.6), fontSize: 14),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: GestureDetector(
            onTap: _flipCard,
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value * pi;
                bool showFront = angle < (pi / 2);
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  alignment: Alignment.center,
                  child: showFront
                      ? _buildCardSide(currentWord.toUpperCase(), true, theme)
                      : Transform(
                          transform: Matrix4.identity()..rotateY(pi),
                          alignment: Alignment.center,
                          child: _buildCardSide(currentMeaning, false, theme),
                        ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 40,
              color: studyIndex > 0 ? theme.correct : theme.textColor.withOpacity(0.2),
              icon: const Icon(Icons.arrow_circle_left_rounded),
              onPressed: studyIndex > 0 ? _prevStudyCard : null,
            ),
            IconButton(
              iconSize: 40,
              color: studyIndex < unlockedWords.length - 1 ? theme.correct : theme.textColor.withOpacity(0.2),
              icon: const Icon(Icons.arrow_circle_right_rounded),
              onPressed: studyIndex < unlockedWords.length - 1 ? _nextStudyCard : null,
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCardSide(String text, bool isFrontSide, GameTheme theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.textColor.withOpacity(0.1), width: 2),
        boxShadow: isFrontSide ? [] : [
          BoxShadow(color: theme.correct.withOpacity(0.15), blurRadius: 30, spreadRadius: 5)
        ],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFrontSide ? theme.textColor.withOpacity(0.1) : theme.correct.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFrontSide ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: isFrontSide ? theme.textColor.withOpacity(0.5) : theme.correct,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isFrontSide ? "WHAT DOES THIS MEAN?" : "TRANSLATION",
              style: TextStyle(
                color: isFrontSide ? theme.textColor.withOpacity(0.4) : theme.correct.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: AppTextStyles.smartStyle(
                  text,
                  fontSize: isFrontSide ? 42 : 40,
                  fontWeight: isFrontSide ? FontWeight.w900 : FontWeight.w600,
                  color: isFrontSide ? theme.textColor : theme.correct,
                  letterSpacing: isFrontSide ? 4 : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizMode(GameTheme theme) {
    bool isDark = theme.brightness == Brightness.dark;
    String currentWord = unlockedWords[quizIndex];
    String correctMeaning = wordMeanings[currentWord] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (quizIndex + 1) / unlockedWords.length,
            backgroundColor: theme.textColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(theme.correct),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [theme.correct, theme.correct.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: theme.correct.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 25),
              ),
              const SizedBox(height: 8),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("What does this word mean?", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  currentWord.toUpperCase(),
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: currentOptions.map((option) {
                ButtonState buttonState = ButtonState.normal;
                Color currentTextColor = theme.textColor;
                Color currentBgColor = isDark ? Colors.grey.shade800 : Colors.white;
                Color currentShadowColor = isDark ? Colors.grey.shade900 : Colors.grey.shade300;

                String displayText = option;

                if (isAnswering) {
                  if (option == correctMeaning) {
                    buttonState = ButtonState.correct;
                    currentTextColor = Colors.white;
                    displayText = "$option";
                  } else if (option == selectedAnswer) {
                    buttonState = ButtonState.incorrect;
                    currentTextColor = Colors.white;
                    displayText = "$option";
                  } else {
                    currentTextColor = theme.textColor.withOpacity(0.3);
                    currentShadowColor = Colors.transparent;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Custom3DButton(
                      text: displayText,
                      state: buttonState,
                      backgroundColor: currentBgColor,
                      shadowColor: currentShadowColor,
                      textColor: currentTextColor,
                      style: AppTextStyles.smartStyle(displayText, fontWeight: FontWeight.w500),
                      onPressed: () => _checkAnswer(option),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
