/*
 * File: home.dart
 * Description: Main hub screen of the Quackle app. Hosts the bottom
 * navigation bar and manages the five primary content pages.
 *
 * Dependencies:
 * - User / MockDatabase (mock_data.dart)
 * - ThemeDatabase (theme_data.dart)
 * - AppFeedback (audio_helper.dart)
 * - AnimatedCoinBadge, Custom3DButton (components)
 * - WordleScreen, FlashcardPage, DictionaryPage, StorePage, ProfilePage
 *
 * Lifecycle:
 * - Created via Navigator.push from LoginPage or SplashScreen.
 * - Disposed when the user logs out and the route stack is cleared.
 *
 * Responsibilities:
 * - Manages the global state and navigation between the five primary app tabs.
 * - Coordinates state refreshes (e.g., coin updates) across different pages.
 * - Provides a persistent AppBar for global actions like coin display and settings.
 *
 * Author: 660510687 Kanittha Bootchumsaeng, 660510669 Phutawan Fongchan
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/coin_badge.dart';
import '../components/custom_3d_buttton.dart';
import '../models/mock_data.dart';
import '../theme/theme_data.dart';
import 'game_screen.dart';
import 'store.dart';
import 'dictionary.dart';
import 'profile.dart';
import 'flashcard.dart';
import '../services/audio_helper.dart';

/// Main scaffold hosting five tab pages via a [BottomNavigationBar].
///
/// Tabs (in order):
/// 0. Home – [WordleMainBody] with the PLAY button
/// 1. Flashcard – [FlashcardPage]
/// 2. Dictionary – [DictionaryPage]
/// 3. Store – [StorePage]
/// 4. Profile – [ProfilePage]
///
/// A [GlobalKey] is kept on [ProfilePage] so the AppBar settings button
/// can call [ProfilePageState.showSettings] directly.
///
/// Fields:
/// - [currentUser]: the active player session whose data is shared across all tabs
class HomePage extends StatefulWidget {
  final User currentUser;

  const HomePage({super.key, required this.currentUser});

  @override
  State<HomePage> createState() => _HomePageState();
}
/// The logic and state management for [HomePage].
///
/// Handles tab switching and maintains a [GlobalKey] to interact with
/// the profile settings directly from the AppBar.
///
/// Fields:
/// - [_selectedIndex]: the index of the currently active navigation tab
/// - [_profileKey]: key used to trigger the settings dialog within [ProfilePage]
class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final GlobalKey<ProfilePageState> _profileKey = GlobalKey<ProfilePageState>();

  /// Triggers a full rebuild so the coin badge and other reactive UI refreshes.
  void _refreshState() {
    setState(() {});
  }

  /// Lazily builds the list of tab pages, attaching [_profileKey] to [ProfilePage].
  List<Widget> get _pages => [
    WordleMainBody(
      currentUser: widget.currentUser,
      onRefresh: _refreshState,
    ),
    FlashcardPage(
      currentUser: widget.currentUser,
      onRefresh: _refreshState,
    ),
    DictionaryPage(currentUser: widget.currentUser),
    StorePage(
      currentUser: widget.currentUser,
      onShopAction: _refreshState,
    ),
    ProfilePage(
      key: _profileKey,
      currentUser: widget.currentUser,
      onProfileUpdate: _refreshState,
    ),
  ];

  /// Switches the active tab to [index].
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  /// Whether the Profile tab (index 4) is currently selected.
  bool get _onProfileTab => _selectedIndex == 4;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeDatabase.getTheme(widget.currentUser.currentThemeId);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/images/diedquackle.png', width: 80, height: 80),
          ],
        ),
        actions: [
          Center(
            child: AnimatedCoinBadge(coins: widget.currentUser.coins),
          ),

          if (_onProfileTab)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: IconButton(
                icon: Icon(
                  Icons.settings_rounded,
                  color: theme.textColor.withAlpha(191),
                  size: 26,
                ),
                tooltip: "Settings",
                onPressed: () {
                  AppFeedback.playClick(widget.currentUser);
                  AppFeedback.triggerHaptic(widget.currentUser);
                  _profileKey.currentState?.showSettings(theme);
                },
              ),
            ),

          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: theme.textColor.withAlpha(25),
            height: 1.0,
          ),
        ),
      ),

      body: _pages[_selectedIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
                color: theme.textColor.withAlpha(25), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.backgroundColor,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: (index) {
            AppFeedback.playClick(widget.currentUser);
            AppFeedback.triggerHaptic(widget.currentUser);
            _onItemTapped(index);
          },
          selectedItemColor: theme.correct,
          unselectedItemColor: theme.textColor.withAlpha(102),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded, size: 30), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.style_rounded, size: 30), label: 'Flashcard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_rounded, size: 30),
                label: 'Dictionary'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_rounded, size: 30),
                label: 'Store'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded, size: 30), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WordleMainBody
// ─────────────────────────────────────────────────────────────────────────────

/// The home tab body showing the mascot image and the PLAY button.
///
/// Navigates to [WordleScreen] on tap and calls [onRefresh] when the user
/// returns, so the coin badge and other state-dependent UI reflects any changes.
///
/// Fields:
/// - [currentUser]: the active player session
/// - [onRefresh]: callback to notify [HomePage] of state changes after gameplay
class WordleMainBody extends StatelessWidget {
  final User currentUser;
  final VoidCallback onRefresh;

  const WordleMainBody({
    super.key,
    required this.currentUser,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeDatabase.getTheme(currentUser.currentThemeId);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/welcomequackle.png',
            width: 480,
            height: 400,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),

          Custom3DButton(
            width: 260.0,
            text: 'PLAY',
            onPressed: () {
              AppFeedback.playKeyboardTap(currentUser);
              AppFeedback.playStartGame(currentUser);
              AppFeedback.triggerHaptic(currentUser);

              Future.delayed(const Duration(milliseconds: 50), () async {
                if (!context.mounted) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WordleScreen(currentUser: currentUser),
                  ),
                );

                onRefresh();
              });
            },
            backgroundColor: theme.correct,
            shadowColor: theme.correct.withAlpha(128),
          ),
        ],
      ),
    );
  }
}
