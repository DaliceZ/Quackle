/*
 * File: game_screen.dart
 * Description: Core Wordle gameplay screen with grid, on-screen keyboard,
 * power-up bar, and end-game dialogs.
 *
 * Dependencies:
 * - User (mock_data.dart)
 * - ThemeDatabase / GameTheme (theme_data.dart)
 * - AppFeedback (audio_helper.dart)
 * - Custom3DKey (components)
 * - Custom3DButton (components)
 * - VictoryEffect (components)
 *
 * Lifecycle:
 * - Created via Navigator.push from WordleMainBody.
 * - Disposed when the player navigates back or via the end-game dialog.
 *
 * Responsibilities:
 * - Loads target words and valid words from JSON/text assets.
 * - Manages guess state, letter status, and row progression.
 * - Handles power-up logic (Hint, Cleaner, Extra Row).
 * - Updates user stats, coins, and rank on win/loss.
 *
 * Author: 660510649 Detnarin Karinchai, 660510685 Aissara Pathan, 660510687 Kanittha Bootchumsaeng
 * Course: 204311-Mobile Application Development Framework
 */

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/mock_data.dart';
import '../services/audio_helper.dart';
import '../theme/theme_data.dart';
import '../components/custom_keyboard_key.dart';
import '../components/custom_3d_buttton.dart';
import '../components/victory_effect.dart';

const Color defaultLightKeyColor = Color(0xFFD3D6DA);
const Color defaultDarkKeyColor = Color(0xFF4F4F4F);
const Color filledBorderColor = Color(0xFF878A8C);

/// Represents the visual/evaluation state of a single letter cell.
enum LetterStatus { initial, entered, correct, present, absent }

/// Main Wordle game screen.
///
/// Fields:
/// - [currentUser]: the active player whose inventory, stats, and coins are mutated
///
/// On init, randomly selects a target word from `assets/targetwords.json` and
/// loads `assets/validwords.txt` to validate guesses. The game supports up to
/// 6 rows (7 with the Extra Row power-up).
class WordleScreen extends StatefulWidget {
  final User currentUser;
  const WordleScreen({super.key, required this.currentUser});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

/// The logic and gameplay state for [WordleScreen].
///
/// Manages the guess grid, keyboard status mapping, and power-up execution.
///
/// Fields:
/// - [currentTheme]: the theme used for visual feedback, overriding specific color keys
/// - [maxRows]: the maximum number of guess rows allowed (6 or 7)
/// - [isExtraRowUsed]: whether the "Extra Row" power-up has been consumed
/// - [targetWord]: the hidden 5-letter word the player is trying to guess
/// - [targetWordTranslation]: the Thai translation of the current [targetWord]
/// - [targetWords]: a mapping of all possible target words to their Thai meanings
/// - [validWordsDict]: a collection of all valid 5-letter words for validation
/// - [isLoading]: whether the game is currently loading assets from the bundle
/// - [guesses]: the list of guesses entered by the player, indexed by row
/// - [gridStatus]: the visual status of each cell in the grid [row][column]
/// - [currentRow]: the index of the row currently being edited
/// - [keyStatus]: a mapping of keyboard letters to their highest known [LetterStatus]
/// - [isAnimating]: whether a row evaluation animation is in progress
class _WordleScreenState extends State<WordleScreen> {
  late GameTheme currentTheme;
  int maxRows = 6;
  bool isExtraRowUsed = false;
  String targetWord = "";
  String targetWordTranslation = "";
  Map<String, String> targetWords = {};
  Set<String> validWordsDict = {};
  bool isLoading = true;

  List<String> guesses = List.generate(6, (_) => "");
  List<List<LetterStatus>> gridStatus = List.generate(6, (_) => List.filled(5, LetterStatus.initial));
  int currentRow = 0;

  Map<String, LetterStatus> keyStatus = {};
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();
    GameTheme userTheme = ThemeDatabase.getTheme(widget.currentUser.currentThemeId);
    // Always use fixed wordle tile colors regardless of the UI theme
    currentTheme = GameTheme(
      id: userTheme.id,
      name: userTheme.name,
      price: userTheme.price,
      correct: const Color(0xFF58CC02),
      present: const Color(0xFFC9B458),
      absent: const Color(0xFF787C7E),
      backgroundColor: userTheme.backgroundColor,
      textColor: userTheme.textColor,
      brightness: userTheme.brightness,
    );

    _loadGameData();
  }

  /// Loads target words (JSON) and valid words (TXT) concurrently, then picks a random target.
  ///
  /// Side effects:
  /// - Populates [targetWords], [validWordsDict], [targetWord], [targetWordTranslation]
  /// - Sets [isLoading] to `false` when complete
  /// - Falls back to "WORLD / โลก" if the asset is empty
  Future<void> _loadGameData() async {
    try {
      final results = await Future.wait([
        rootBundle.loadString('assets/targetwords.json'),
        rootBundle.loadString('assets/validwords.txt'),
      ]);
      final Map<String, dynamic> targetsJson = json.decode(results[0]);
      final List<String> targets = targetsJson.keys.map((w) => w.trim().toUpperCase()).where((w) => w.length == 5).toList();
      targetsJson.forEach((key, value) => targetWords[key.toUpperCase()] = value['th']);
      List<String> valids = results[1].split('\n').map((w) => w.trim().toUpperCase()).where((w) => w.length == 5).toList();

      setState(() {
        if (targets.isNotEmpty) {
          targetWord = targets[Random().nextInt(targets.length)];
          targetWordTranslation = targetWords[targetWord] ?? "";
        } else {
          targetWord = "WORLD";
          targetWordTranslation = "โลก";
        }
        validWordsDict = valids.toSet()..addAll(targets);
        isLoading = false;
        print("Target: $targetWord ($targetWordTranslation)");
      });
    } catch (e) {
      setState(() { targetWord = "ERROR"; isLoading = false; });
    }
  }

  /// Resets all game state and picks a new random target word.
  void _resetGame() {
    setState(() {
      final List<String> keys = targetWords.keys.toList();
      if (keys.isNotEmpty) {
        targetWord = keys[Random().nextInt(keys.length)];
        targetWordTranslation = targetWords[targetWord] ?? "";
      }
      guesses = List.filled(6, "");
      currentRow = 0;
      gridStatus = List.generate(6, (_) => List.filled(5, LetterStatus.initial));
      keyStatus = {};
      isAnimating = false;
      maxRows = 6;
      isExtraRowUsed = false;
    });
  }

  // --- Power-ups Logic ---

  /// Reveals the next unfilled letter in the current row using the target word.
  ///
  /// Does nothing if [User.hintCount] is `0` or the row is already full.
  /// Side effects: decrements [User.hintCount] and calls [User.saveData].
  void _useHint() {
    if (widget.currentUser.hintCount <= 0 || guesses[currentRow].length >= 5) return;
    setState(() {
      widget.currentUser.hintCount--;
      int emptyIndex = guesses[currentRow].length;
      String correctLetter = targetWord[emptyIndex];
      guesses[currentRow] += correctLetter;
      gridStatus[currentRow][emptyIndex] = LetterStatus.entered;
    });
    widget.currentUser.saveData();
    AppFeedback.playClick(widget.currentUser);
  }

  /// Marks 3 random unused letters as absent on the keyboard.
  ///
  /// Does nothing if [User.cleanerCount] is `0`.
  /// Side effects: decrements [User.cleanerCount] and calls [User.saveData].
  void _useCleaner() {
    if (widget.currentUser.cleanerCount <= 0) return;
    setState(() {
      widget.currentUser.cleanerCount--;
      List<String> alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split('');
      List<String> wrongLetters = alphabet
          .where((letter) => !targetWord.contains(letter) && keyStatus[letter] == null)
          .toList()..shuffle();
      for (int i = 0; i < min(3, wrongLetters.length); i++) {
        keyStatus[wrongLetters[i]] = LetterStatus.absent;
      }
    });
    widget.currentUser.saveData();
    AppFeedback.playClick(widget.currentUser);
  }

  /// Adds a 7th guess row if the player has Extra Row charges remaining.
  ///
  /// Can only be used once per game ([isExtraRowUsed] guard).
  /// Side effects: decrements [User.extraRowCount] and calls [User.saveData].
  void _useExtraRow() {
    if (widget.currentUser.extraRowCount <= 0 || isExtraRowUsed) return;
    setState(() {
      widget.currentUser.extraRowCount--;
      isExtraRowUsed = true;
      maxRows = 7;
      guesses.add("");
      gridStatus.add(List.filled(5, LetterStatus.initial));
    });
    widget.currentUser.saveData();
    AppFeedback.playClick(widget.currentUser);
  }

  /// Shows a confirmation [AlertDialog] before consuming a power-up.
  void _showUseItemDialog(String title, String description, VoidCallback onConfirm) {
    AppFeedback.playClick(widget.currentUser);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Use $title?", style: TextStyle(color: currentTheme.textColor, fontWeight: FontWeight.bold)),
        content: Text(description, style: TextStyle(color: currentTheme.textColor.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: currentTheme.correct),
            onPressed: () { Navigator.pop(context); onConfirm(); },
            child: const Text("Use Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = currentTheme.brightness == Brightness.dark;

    Color keyColor = isDark ? defaultDarkKeyColor : defaultLightKeyColor;
    Color keyTextColor = isDark ? Colors.white : Colors.black;

    if (isLoading) {
      return Scaffold(
        backgroundColor: currentTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: currentTheme.textColor)),
      );
    }

    return WillPopScope(
      onWillPop: _showExitConfirmDialog,
      child: Scaffold(
        backgroundColor: currentTheme.backgroundColor,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: currentTheme.textColor),
            onPressed: () async {
              bool shouldExit = await _showExitConfirmDialog();
              if (shouldExit && mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text("QUACKLE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: currentTheme.textColor)),
          centerTitle: true,
          backgroundColor: currentTheme.backgroundColor,
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: _buildGrid(keyTextColor),
              ),
            ),

            _buildPowerUpBar(),

            Expanded(
              flex: 2,
              child: _buildKeyboard(keyColor, keyTextColor),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Sub-widgets ---

  /// Builds the 5×[maxRows] guess grid using [FlipTile] widgets.
  Widget _buildGrid(Color defaultTextColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxRows, (rowIndex) {
        return Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (colIndex) {
              String char = (guesses[rowIndex].length > colIndex) ? guesses[rowIndex][colIndex] : "";
              return FlipTile(
                char: char,
                status: gridStatus[rowIndex][colIndex],
                currentTheme: currentTheme,
                delayIndex: colIndex,
                currentUser: widget.currentUser,
              );
            }),
          ),
        );
      }),
    );
  }

  /// Builds the horizontal power-up bar with Hint, Cleaner, and Extra Row buttons.
  Widget _buildPowerUpBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _powerUpButton(
            icon: Icons.lightbulb_outline,
            count: widget.currentUser.hintCount,
            label: "Hint",
            onTap: () => _showUseItemDialog("Hint Reveal", "Reveals one correct letter.", _useHint),
            color: Colors.orange,
          ),
          _powerUpButton(
            icon: Icons.auto_fix_high,
            count: widget.currentUser.cleanerCount,
            label: "Cleaner",
            onTap: () => _showUseItemDialog("Keyboard Cleaner", "Removes 3 wrong letters.", _useCleaner),
            color: Colors.blue,
          ),
          _powerUpButton(
            icon: Icons.add_circle_outline,
            count: widget.currentUser.extraRowCount,
            label: "Extra Row",
            onTap: () => _showUseItemDialog("Extra Row", "Adds a 7th guess row.", _useExtraRow),
            color: Colors.green,
            isLocked: isExtraRowUsed,
          ),
        ],
      ),
    );
  }

  /// Builds a single power-up icon button with a count badge.
  ///
  /// Renders at reduced opacity when the item is unavailable ([isLocked] or count is 0).
  Widget _powerUpButton({required IconData icon, required int count, required String label, required VoidCallback onTap, required Color color, bool isLocked = false}) {
    bool hasItem = count > 0 && !isLocked;
    return GestureDetector(
      onTap: hasItem ? onTap : null,
      child: Opacity(
        opacity: hasItem ? 1.0 : 0.3,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text("$count", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: currentTheme.textColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  /// Builds the three-row QWERTY keyboard using [Custom3DKey] widgets.
  ///
  /// Key colors reflect the current [keyStatus] map so evaluated letters are
  /// shown in green, yellow, or grey.
  Widget _buildKeyboard(Color defaultKeyColor, Color defaultTextColor) {
    const keys = [
      ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
      ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
      ["ENTER", "Z", "X", "C", "V", "B", "N", "M", "DEL"]
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((char) {
              Color keyColor = defaultKeyColor;
              Color textColor = defaultTextColor;

              if (char != "ENTER" && char != "DEL") {
                LetterStatus? status = keyStatus[char];
                if (status != null) {
                  textColor = Colors.white;
                  switch (status) {
                    case LetterStatus.correct: keyColor = currentTheme.correct; break;
                    case LetterStatus.present: keyColor = currentTheme.present; break;
                    case LetterStatus.absent: keyColor = currentTheme.absent; break;
                    default: keyColor = defaultKeyColor; textColor = defaultTextColor;
                  }
                }
              }

              return Custom3DKey(
                char: char,
                keyColor: keyColor,
                textColor: textColor,
                flex: (char == "ENTER" || char == "DEL") ? 2 : 1,
                onTap: () => onKeyPressed(char),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  // --- Game Core Logic ---

  /// Handles a key press from the on-screen keyboard.
  ///
  /// - ENTER: validates and submits the current guess via [_checkWord]
  /// - DEL: removes the last character from the current row
  /// - Letter: appends the character if the row has fewer than 5 letters
  void onKeyPressed(String val) {
    if (currentRow >= maxRows || isLoading) return;

    setState(() {
      if (val == "ENTER") {
        AppFeedback.playKeyboardTap(widget.currentUser);
        _checkWord();
      } else if (val == "DEL") {
        AppFeedback.playKeyboardTap(widget.currentUser);
        if (guesses[currentRow].isNotEmpty) {
          guesses[currentRow] = guesses[currentRow].substring(0, guesses[currentRow].length - 1);
          gridStatus[currentRow][guesses[currentRow].length] = LetterStatus.initial;
        }
      } else {
        if (guesses[currentRow].length < 5) {
          AppFeedback.playKeyboardTap(widget.currentUser);
          int currentIndex = guesses[currentRow].length;
          guesses[currentRow] += val;
          gridStatus[currentRow][currentIndex] = LetterStatus.entered;
        }
      }
    });
  }

  /// Evaluates the current row's guess against [targetWord].
  ///
  /// Validates length and dictionary membership before scoring. Each letter
  /// is scored correct > present > absent using a two-pass algorithm to handle
  /// duplicate letters correctly. After a 1.6-second animation delay, updates
  /// [keyStatus] and checks for win/loss conditions.
  ///
  /// Side effects on win:
  /// - Increments [User.gamesPlayed], [User.gamesWon], [User.currentStreak],
  ///   [User.coins] (+10), [User.wordsFound], [User.guessDistribution]
  /// - May unlock a new rank title or the Flashcard feature
  /// - Calls [User.saveData] and shows the end-game dialog
  ///
  /// Side effects on loss:
  /// - Increments [User.gamesPlayed], resets [User.currentStreak] to 0
  Future<void> _checkWord() async {
    String guess = guesses[currentRow];
    if (guess.length != 5) {
      _showMessage("Not enough letters");
      if (widget.currentUser.isVibrationEnabled) HapticFeedback.heavyImpact();
      return;
    }
    if (!validWordsDict.contains(guess)) {
      _showMessage("Not in word list");
      if (widget.currentUser.isVibrationEnabled) HapticFeedback.heavyImpact();
      return;
    }
    if (isAnimating) return;

    setState(() { isAnimating = true; });

    List<String> targetChars = targetWord.split('');
    List<LetterStatus> rowStatus = List.filled(5, LetterStatus.absent);

    // First pass: mark correct positions
    for (int i = 0; i < 5; i++) {
      if (guess[i] == targetChars[i]) {
        rowStatus[i] = LetterStatus.correct;
        targetChars[i] = '';
      }
    }
    // Second pass: mark present letters
    for (int i = 0; i < 5; i++) {
      if (rowStatus[i] != LetterStatus.correct) {
        int indexInTarget = targetChars.indexOf(guess[i]);
        if (indexInTarget != -1) {
          rowStatus[i] = LetterStatus.present;
          targetChars[indexInTarget] = '';
        }
      }
    }

    setState(() {
      for (int i = 0; i < 5; i++) gridStatus[currentRow][i] = rowStatus[i];
      currentRow++;
    });

    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    setState(() {
      for (int i = 0; i < 5; i++) {
        String char = guess[i];
        LetterStatus currentStatus = rowStatus[i];
        if (keyStatus[char] != LetterStatus.correct) {
          if (currentStatus == LetterStatus.correct) keyStatus[char] = LetterStatus.correct;
          else if (keyStatus[char] != LetterStatus.present && currentStatus == LetterStatus.present) keyStatus[char] = LetterStatus.present;
          else if (keyStatus[char] == null && currentStatus == LetterStatus.absent) keyStatus[char] = LetterStatus.absent;
        }
      }
      isAnimating = false;
    });

    if (guess == targetWord) {
      AppFeedback.playWin(widget.currentUser);
      bool isUnlockedFlashcard = false;
      String? newlyUnlockedRank;

      setState(() {
        widget.currentUser.gamesPlayed++;
        widget.currentUser.gamesWon++;
        widget.currentUser.currentStreak++;
        if (widget.currentUser.currentStreak > widget.currentUser.maxStreak) {
          widget.currentUser.maxStreak = widget.currentUser.currentStreak;
        }
        widget.currentUser.coins += 10;
        widget.currentUser.wordsFound += 1;
        if (!widget.currentUser.foundWordsList.contains(targetWord)) widget.currentUser.foundWordsList.add(targetWord);
        widget.currentUser.guessDistribution[currentRow - 1]++;

        if (widget.currentUser.wordsFound == 15) isUnlockedFlashcard = true;

        if (widget.currentUser.wordsFound == 10) newlyUnlockedRank = "📖 Bookworm";
        if (widget.currentUser.wordsFound == 30) newlyUnlockedRank = "🎓 Scholar";
        if (widget.currentUser.wordsFound == 50) newlyUnlockedRank = "🧙‍♂️ Word Master";
        if (widget.currentUser.wordsFound == 100) newlyUnlockedRank = "👑 Legend";

        if (newlyUnlockedRank != null && !widget.currentUser.unlockedRanks.contains(newlyUnlockedRank)) {
          widget.currentUser.unlockedRanks.add(newlyUnlockedRank!);
          widget.currentUser.selectedRankTitle = newlyUnlockedRank!;
        }
      });
      widget.currentUser.saveData();

      _showEndGameDialog(true, targetWord, targetWordTranslation, justUnlocked: isUnlockedFlashcard, newlyUnlockedRank: newlyUnlockedRank);

    } else if (currentRow == maxRows) {
      AppFeedback.playLose(widget.currentUser);
      setState(() {
        widget.currentUser.gamesPlayed++;
        widget.currentUser.currentStreak = 0;
      });
      widget.currentUser.saveData();
      _showEndGameDialog(false, targetWord, targetWordTranslation);
    }
  }

  /// Displays a temporary floating toast message in the centre of the screen.
  ///
  /// The overlay entry auto-removes itself after 1.2 seconds.
  void _showMessage(String msg) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.35,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: currentTheme.textColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))
                ],
              ),
              child: Text(
                msg,
                style: TextStyle(
                  color: currentTheme.backgroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    bool isRemoved = false;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!isRemoved) {
        overlayEntry.remove();
        isRemoved = true;
      }
    });
  }

  /// Shows a confirmation dialog when the player attempts to leave mid-game.
  ///
  /// Returns `true` if the player confirms exit, `false` otherwise.
  /// Used by both the AppBar back button and the [WillPopScope] handler.
  Future<bool> _showExitConfirmDialog() async {
    AppFeedback.playClick(widget.currentUser);

    bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Image.asset(
              'assets/images/huhquackle.png',
              height: 70,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              "Quit Game?",
              style: TextStyle(
                  color: currentTheme.textColor,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text("Are you sure you want to leave?\nYour current progress will be lost.",
            style: TextStyle(color: currentTheme.textColor.withOpacity(0.8))),
        actions: [
            ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            onPressed: () {
              AppFeedback.playClick(widget.currentUser);
              Navigator.of(context).pop(true);
            },
            child: const Text("Quit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              AppFeedback.playClick(widget.currentUser);
              Navigator.of(context).pop(false);
            },
            child: Text("Cancel", style: TextStyle(color: currentTheme.textColor.withOpacity(0.5))),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  /// Displays the end-game result dialog with the target word, rewards, and action buttons.
  ///
  /// Parameters:
  /// - [won]: whether the player guessed correctly
  /// - [targetWord]: the hidden word revealed at the end
  /// - [meaning]: the Thai translation of the target word
  /// - [justUnlocked]: whether the Flashcard feature was unlocked this round
  /// - [newlyUnlockedRank]: a rank title string if a new rank was earned, or null
  void _showEndGameDialog(bool won, String targetWord, String meaning, {bool justUnlocked = false, String? newlyUnlockedRank}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        alignment: Alignment.center,
        children: [
          Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: currentTheme.backgroundColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: won ? currentTheme.correct.withOpacity(0.5) : Colors.redAccent.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: won ? currentTheme.correct.withOpacity(0.25) : Colors.redAccent.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(0),
                    child: Image.asset(
                      won ? 'assets/images/wowquackle.png' : 'assets/images/huhquackle.png',
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    won ? "EXCELLENT!" : "GAME OVER",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: won ? currentTheme.correct : Colors.redAccent,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    won ? "You guessed the word correctly." : "The hidden word was...",
                    style: TextStyle(color: currentTheme.textColor.withOpacity(0.6), fontSize: 14),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: currentTheme.textColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: currentTheme.textColor.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          targetWord.toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: currentTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meaning,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueAccent
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (won) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "+10 Coins",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: currentTheme.textColor
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (justUnlocked) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.style_rounded, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "FLASHCARD UNLOCKED!",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                ),
                                Text(
                                  "15 words milestone reached ✨",
                                  style: TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (newlyUnlockedRank != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "NEW TITLE UNLOCKED!",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                                ),
                                Text(
                                  newlyUnlockedRank,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Custom3DButton(
                          text: "MENU",
                          backgroundColor: Colors.grey.shade400,
                          shadowColor: Colors.grey.shade600,
                          onPressed: () {
                            AppFeedback.playClick(widget.currentUser);
                            AppFeedback.triggerHaptic(widget.currentUser);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Custom3DButton(
                          text: won ? "PLAY AGAIN" : "TRY AGAIN",
                          backgroundColor: won ? currentTheme.correct : Colors.blueAccent,
                          shadowColor: won ? Colors.green.shade700 : Colors.blue.shade700,
                          onPressed: () {
                            AppFeedback.playClick(widget.currentUser);
                            AppFeedback.triggerHaptic(widget.currentUser);
                            Navigator.pop(context);
                            _resetGame();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (won) const VictoryEffect(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FlipTile Component
// ─────────────────────────────────────────────────────────────────────────────

/// A single animated tile in the Wordle guess grid.
///
/// Flips on the X-axis when its [status] transitions from [LetterStatus.entered]
/// to a scored state, with each tile in the row delayed by [delayIndex] × 200 ms
/// to create a cascading reveal effect.
class FlipTile extends StatefulWidget {
  final String char;
  final LetterStatus status;
  final GameTheme currentTheme;
  final int delayIndex;
  final User currentUser;

  const FlipTile({
    super.key,
    required this.char,
    required this.status,
    required this.currentTheme,
    required this.delayIndex,
    required this.currentUser,
  });

  @override
  State<FlipTile> createState() => _FlipTileState();
}

/// The logic and animation state for [FlipTile].
///
/// Handles the [AnimationController] for the 3D flip effect.
class _FlipTileState extends State<FlipTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _animation = Tween<double>(begin: 0, end: pi).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack));
  }

  @override
  void didUpdateWidget(FlipTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == LetterStatus.initial) { _controller.reset(); return; }
    if (widget.status != oldWidget.status && widget.status != LetterStatus.initial && widget.status != LetterStatus.entered) {
      Future.delayed(Duration(milliseconds: widget.delayIndex * 200), () {
        if (mounted) { _controller.forward(from: 0.0); AppFeedback.playClick(widget.currentUser); AppFeedback.triggerHaptic(widget.currentUser); }
      });
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, child) {
      double angle = _animation.value;
      bool isFlipped = angle >= (pi / 2);
      double displayAngle = isFlipped ? angle - pi : angle;
      return Transform(transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(displayAngle), alignment: Alignment.center, child: _buildContent(isFlipped));
    });
  }

  /// Builds the visual tile box based on current flip angle and [LetterStatus].
  Widget _buildContent(bool isFlipped) {
    LetterStatus displayStatus = isFlipped ? widget.status : LetterStatus.entered;
    Color color = Colors.transparent;
    Color borderColor = widget.currentTheme.textColor.withOpacity(0.3);
    Color textColor = widget.currentTheme.textColor;
    if (displayStatus == LetterStatus.entered) {
      borderColor = filledBorderColor;
      if (widget.char.isEmpty) borderColor = widget.currentTheme.textColor.withOpacity(0.3);
    } else {
      textColor = Colors.white; borderColor = Colors.transparent;
      switch (displayStatus) {
        case LetterStatus.correct: color = widget.currentTheme.correct; break;
        case LetterStatus.present: color = widget.currentTheme.present; break;
        case LetterStatus.absent: color = widget.currentTheme.absent; break;
        default: break;
      }
    }
    if (widget.currentTheme.brightness == Brightness.dark && displayStatus == LetterStatus.initial) color = Colors.white.withOpacity(0.05);
    return Container(margin: const EdgeInsets.all(3), width: 50, height: 50, decoration: BoxDecoration(color: color, border: Border.all(color: borderColor, width: 2)), alignment: Alignment.center,
      child: Text(widget.char, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
    );
  }
}
