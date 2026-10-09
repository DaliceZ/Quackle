/*
 * File: store.dart
 * Description: UI screen for the in-game shop, allowing players to purchase
 * visual themes and power-up items using their coin balance.
 *
 * Dependencies:
 * - User (mock_data.dart)
 * - ThemeDatabase / GameTheme (theme_data.dart)
 * - AppFeedback (audio_helper.dart)
 *
 * Lifecycle:
 * - Created via the Store tab in HomePage.
 * - Disposed when the user navigates away from the tab.
 *
 * Responsibilities:
 * - Displays a categorized marketplace for themes and consumable power-ups.
 * - Validates user coin balance before processing transactions.
 * - Manages the equipping and real-time application of purchased themes.
 * - Triggers purchase feedback (audio/haptic) and updates persistent user data.
 *
 * Author: 660510649 Detnarin Karinchai, 660510669 Phutawan Fongchan, 660510687 Kanittha Bootchumsaeng
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';
import '../models/mock_data.dart';
import '../theme/theme_data.dart';
import '../services/audio_helper.dart';

/// Two-tab shop screen offering [GameTheme] skins and consumable power-ups.
///
/// Fields:
/// - [currentUser]: the active player whose coins and inventory are mutated
/// - [onShopAction]: callback invoked after any successful purchase so the
///   parent [HomePage] can refresh its coin badge and theme
class StorePage extends StatefulWidget {
  final User currentUser;
  final VoidCallback onShopAction;

  const StorePage({
    super.key,
    required this.currentUser,
    required this.onShopAction,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

/// The logic and state management for [StorePage].
///
/// Handles transaction validation, theme switching, and inventory updates
/// for the player.
///
/// Fields:
/// - [powerUps]: catalogue of purchasable power-up items with display metadata and pricing
class _StorePageState extends State<StorePage> {
  /// Catalogue of purchasable power-up items with display metadata and pricing.
  final List<Map<String, dynamic>> powerUps = [
    {
      "id": "hint",
      "name": "Hint Reveal",
      "description": "Reveals one correct letter in its position.",
      "price": 50,
      "icon": Icons.lightbulb_outline,
      "color": Colors.orangeAccent
    },
    {
      "id": "cleaner",
      "name": "Keyboard Cleaner",
      "description": "Removes 3 wrong letters from the keyboard.",
      "price": 30,
      "icon": Icons.auto_fix_high,
      "color": Colors.blueAccent
    },
    {
      "id": "extra_life",
      "name": "Extra Row",
      "description": "Gives you a 7th row if you fail on the 6th.",
      "price": 100,
      "icon": Icons.add_circle_outline,
      "color": Colors.greenAccent
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentAppTheme = ThemeDatabase.getTheme(widget.currentUser.currentThemeId);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: currentAppTheme.correct,
            unselectedLabelColor: currentAppTheme.textColor.withOpacity(0.5),
            indicatorColor: currentAppTheme.correct,
            tabs: const [
              Tab(text: "THEMES", icon: Icon(Icons.palette_outlined)),
              Tab(text: "POWER-UPS", icon: Icon(Icons.bolt_outlined)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildThemeList(currentAppTheme),
                _buildItemList(currentAppTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable list of all [GameTheme] entries.
  Widget _buildThemeList(GameTheme currentAppTheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ThemeDatabase.themes.length,
      itemBuilder: (context, index) {
        final theme = ThemeDatabase.themes[index];
        final bool isOwned = widget.currentUser.ownedThemeIds.contains(theme.id);
        final bool isEquipped = widget.currentUser.currentThemeId == theme.id;

        return Card(
          color: currentAppTheme.brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: isEquipped ? BorderSide(color: currentAppTheme.correct, width: 2) : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => _handleThemeTap(theme),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildThemePreview(theme),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(theme.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: currentAppTheme.textColor)),
                        Text(isEquipped ? "Currently Active" : (isOwned ? "Owned" : "Premium Theme"),
                            style: TextStyle(color: isEquipped ? currentAppTheme.correct : Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  _buildPriceTag(theme.price, isOwned, isEquipped, currentAppTheme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the scrollable list of purchasable power-up items.
  Widget _buildItemList(GameTheme currentAppTheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: powerUps.length,
      itemBuilder: (context, index) {
        final item = powerUps[index];
        final String id = item['id'];

        int ownedCount = 0;
        if (id == 'hint') ownedCount = widget.currentUser.hintCount;
        else if (id == 'cleaner') ownedCount = widget.currentUser.cleanerCount;
        else if (id == 'extra_life') ownedCount = widget.currentUser.extraRowCount;

        return Card(
          color: currentAppTheme.brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: currentAppTheme.correct.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "📦 INVENTORY",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: currentAppTheme.correct,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      "Owned: $ownedCount",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: currentAppTheme.correct,
                      ),
                    ),
                  ],
                ),
              ),

              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: (item['color'] as Color).withOpacity(0.2),
                  child: Icon(item['icon'], color: item['color']),
                ),
                title: Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, color: currentAppTheme.textColor)),
                subtitle: Text(item['description'], style: TextStyle(fontSize: 12, color: currentAppTheme.textColor.withOpacity(0.6))),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _confirmPurchase(item, true),
                  child: Text("💰 ${item['price']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Equips an owned theme or opens the purchase dialog for unowned themes.
  void _handleThemeTap(GameTheme theme) {
    AppFeedback.playClick(widget.currentUser);
    if (widget.currentUser.ownedThemeIds.contains(theme.id)) {
      if (widget.currentUser.currentThemeId != theme.id) {
        setState(() => widget.currentUser.currentThemeId = theme.id);
        widget.currentUser.saveData();
        widget.onShopAction();
        _showSnackBar("Theme applied: ${theme.name}");
      }
    } else {
      _confirmPurchase(theme, false);
    }
  }

  /// Shows a confirmation [AlertDialog] before completing a purchase.
  ///
  /// [isPowerUp] determines whether [item] is treated as a [Map] (power-up)
  /// or a [GameTheme] (skin).
  void _confirmPurchase(dynamic item, bool isPowerUp) {
    final currentTheme = ThemeDatabase.getTheme(widget.currentUser.currentThemeId);
    AppFeedback.playClick(widget.currentUser);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentTheme.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isPowerUp ? "Buy Power-up" : "Unlock Theme", style: TextStyle(color: currentTheme.textColor, fontWeight: FontWeight.bold)),
        content: Text("Confirm purchase of '${isPowerUp ? item['name'] : item.name}' for ${isPowerUp ? item['price'] : item.price} coins?",
            style: TextStyle(color: currentTheme.textColor.withOpacity(0.8))),
        actions: [
          TextButton(
            onPressed: () {
              AppFeedback.playClick(widget.currentUser);
              Navigator.pop(context);
            },
            child: Text("Cancel", style: TextStyle(color: currentTheme.textColor.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: currentTheme.correct, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              if (isPowerUp) {
                _processItemPurchase(item);
              } else {
                _processThemePurchase(item);
              }
            },
            child: const Text("Purchase", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Deducts coins and adds the theme to the player's collection.
  ///
  /// Side effects:
  /// - Mutates [User.coins] and [User.ownedThemeIds].
  /// - Plays a cash sound effect on success.
  ///
  /// Failure Modes:
  /// - Displays an error SnackBar if the player has insufficient coins.
  void _processThemePurchase(GameTheme theme) {
    if (widget.currentUser.coins >= theme.price) {
      AppFeedback.playCash(widget.currentUser);
      setState(() {
        widget.currentUser.coins -= theme.price;
        widget.currentUser.ownedThemeIds.add(theme.id);
        widget.currentUser.currentThemeId = theme.id;
      });
      widget.currentUser.saveData();
      widget.onShopAction();
      _showSnackBar("Purchase successful! 🎨");
    } else {
      AppFeedback.triggerHaptic(widget.currentUser);
      _showSnackBar("Not enough coins.", isError: true);
    }
  }

  /// Deducts coins and increments the appropriate power-up counter.
  ///
  /// Side effects:
  /// - Mutates [User.coins] and specific inventory counts.
  /// - Plays a cash sound effect on success.
  ///
  /// Failure Modes:
  /// - Displays an error SnackBar if the player has insufficient coins.
  void _processItemPurchase(Map<String, dynamic> item) {
    if (widget.currentUser.coins >= item['price']) {
      AppFeedback.playCash(widget.currentUser);

      setState(() {
        widget.currentUser.coins -= (item['price'] as int);

        if (item['id'] == 'hint') {
          widget.currentUser.hintCount++;
        } else if (item['id'] == 'cleaner') {
          widget.currentUser.cleanerCount++;
        } else if (item['id'] == 'extra_life') {
          widget.currentUser.extraRowCount++;
        }
      });

      widget.currentUser.saveData();
      widget.onShopAction();

      _showSnackBar("Purchase successful! You received ${item['name']} 🎁");
    } else {
      AppFeedback.triggerHaptic(widget.currentUser);
      _showSnackBar("Not enough coins.", isError: true);
    }
  }

  /// Builds a small row of three color dots previewing a theme's tile colors.
  Widget _buildThemePreview(GameTheme theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          _colorDot(theme.correct), const SizedBox(width: 4),
          _colorDot(theme.present), const SizedBox(width: 4),
          _colorDot(theme.absent),
        ],
      ),
    );
  }

  /// Returns a circular container representing a single color.
  Widget _colorDot(Color color) => Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  /// Builds the price/status tag shown on the right side of each theme card.
  Widget _buildPriceTag(int price, bool isOwned, bool isEquipped, GameTheme theme) {
    if (isEquipped) return Icon(Icons.check_circle, color: theme.correct, size: 28);
    if (isOwned) return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(20)), child: const Text("USE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Text("💰 $price", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)),
    );
  }

  /// Displays a floating [SnackBar] message.
  ///
  /// Uses green for success messages and red for errors.
  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.redAccent : Colors.green, behavior: SnackBarBehavior.floating));
  }
}
