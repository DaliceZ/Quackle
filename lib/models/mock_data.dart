/*
 * File: mock_data.dart
 * Description: Defines the User data model and the MockDatabase class used
 * as an in-memory user store with SharedPreferences persistence.
 *
 * Dependencies:
 * - SharedPreferences
 *
 * Responsibilities:
 * - Models all player state (coins, stats, inventory, settings).
 * - Provides saveData() / loadData() for local persistence.
 * - Provides MockDatabase.login() to authenticate users.
 *
 * Author: 660510649 Detnarin Karinchai
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single player account and all associated game state.
///
/// Fields:
/// - [username]: display name and persistence key prefix
/// - [password]: plain-text credential used only for mock authentication
/// - [coins]: in-game currency balance
/// - [wordsFound]: total unique words the player has guessed correctly
/// - [foundWordsList]: ordered list of all discovered words
/// - [currentThemeId]: ID of the currently equipped [GameTheme]
/// - [ownedThemeIds]: IDs of all purchased themes
/// - [gamesPlayed] / [gamesWon]: lifetime match statistics
/// - [currentStreak] / [maxStreak]: consecutive-win tracking
/// - [guessDistribution]: count of wins per guess-row (indices 0–5)
/// - [isSoundEnabled] / [isVibrationEnabled]: accessibility toggles
/// - [avatarEmoji]: asset path of the currently equipped avatar image
/// - [ownedAvatars]: asset paths of all purchased avatar images
/// - [hintCount] / [cleanerCount] / [extraRowCount]: power-up inventory
/// - [selectedRankTitle]: the rank title currently displayed on the profile
/// - [unlockedRanks]: all rank titles the player has earned
///
/// Usage:
/// - Created by [MockDatabase] and passed through the widget tree
/// - Call [saveData] after any mutation; call [loadData] on login
class User {
  String username;
  final String password;
  int coins;
  int wordsFound;
  List<String> foundWordsList;
  String currentThemeId;
  List<String> ownedThemeIds;

  int gamesPlayed;
  int gamesWon;
  int currentStreak;
  int maxStreak;
  List<int> guessDistribution;
  bool isSoundEnabled;
  bool isVibrationEnabled;
  String avatarEmoji;
  List<String> ownedAvatars;
  int hintCount;
  int cleanerCount;
  int extraRowCount;
  String selectedRankTitle;
  List<String> unlockedRanks;

  User({
    required this.username,
    required this.password,
    this.coins = 0,
    this.wordsFound = 0,
    List<String>? foundWordsList,
    this.currentThemeId = 'classic',
    List<String>? ownedThemeIds,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.hintCount = 0,
    this.cleanerCount = 0,
    this.extraRowCount = 0,
    List<int>? guessDistribution,
    this.isSoundEnabled = true,
    this.isVibrationEnabled = true,
    this.avatarEmoji = 'assets/emoji/duck.png',
    List<String>? ownedAvatars,
    this.selectedRankTitle = "🌱 Novice",
    List<String>? unlockedRanks,
  })  : foundWordsList = foundWordsList ?? [],
        ownedThemeIds = ownedThemeIds ?? ['classic'],
        guessDistribution = guessDistribution ?? [0, 0, 0, 0, 0, 0],
        ownedAvatars = ownedAvatars ?? ['assets/emoji/duck.png', 'assets/emoji/chicken.png'],
        unlockedRanks = unlockedRanks ?? ["🌱 Novice"];

  /// Persists all user fields to [SharedPreferences] under keys prefixed by [username].
  ///
  /// Should be called after any mutation to coins, inventory, stats, or settings.
  /// Logs progress to the console for debugging.
  Future<void> saveData() async {
    print('💾 [QUACKLE LOG] เริ่มบันทึกข้อมูลของ User: $username ...');
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('${username}_coins', coins);
    await prefs.setInt('${username}_words_count', wordsFound);
    await prefs.setStringList('${username}_found_list', foundWordsList);
    await prefs.setString('${username}_theme', currentThemeId);
    await prefs.setStringList('${username}_owned_themes', ownedThemeIds);
    await prefs.setInt('${username}_gamesPlayed', gamesPlayed);
    await prefs.setInt('${username}_gamesWon', gamesWon);
    await prefs.setInt('${username}_currentStreak', currentStreak);
    await prefs.setInt('${username}_maxStreak', maxStreak);
    await prefs.setString('${username}_guessDist', guessDistribution.join(','));
    await prefs.setBool('${username}_isSound', isSoundEnabled);
    await prefs.setBool('${username}_isVibrate', isVibrationEnabled);
    await prefs.setString('${username}_avatar', avatarEmoji);
    await prefs.setStringList('${username}_owned_avatars', ownedAvatars);
    await prefs.setString('${username}_selectedRank', selectedRankTitle);
    await prefs.setStringList('${username}_unlockedRanks', unlockedRanks);

    print('✅ [QUACKLE LOG] บันทึกข้อมูลของ $username สำเร็จ! (Coins: $coins, Words: $wordsFound)');
  }

  /// Loads all previously saved fields from [SharedPreferences] into this instance.
  ///
  /// Called automatically by [MockDatabase.login] after finding a matching user.
  /// Missing keys fall back to current field values. New avatars and ranks found
  /// in storage are merged into the existing lists without duplicates.
  Future<void> loadData() async {
    print('📂 [QUACKLE LOG] กำลังโหลดข้อมูลของ User: $username ...');
    final prefs = await SharedPreferences.getInstance();

    coins = prefs.getInt('${username}_coins') ?? coins;
    wordsFound = prefs.getInt('${username}_words_count') ?? wordsFound;
    foundWordsList = prefs.getStringList('${username}_found_list') ?? foundWordsList;
    currentThemeId = prefs.getString('${username}_theme') ?? currentThemeId;
    ownedThemeIds = prefs.getStringList('${username}_owned_themes') ?? ownedThemeIds;
    gamesPlayed = prefs.getInt('${username}_gamesPlayed') ?? gamesPlayed;
    gamesWon = prefs.getInt('${username}_gamesWon') ?? gamesWon;
    currentStreak = prefs.getInt('${username}_currentStreak') ?? currentStreak;
    maxStreak = prefs.getInt('${username}_maxStreak') ?? maxStreak;

    String? distStr = prefs.getString('${username}_guessDist');
    if (distStr != null && distStr.isNotEmpty) {
      guessDistribution = distStr.split(',').map((e) => int.parse(e)).toList();
    }

    isSoundEnabled = prefs.getBool('${username}_isSound') ?? true;
    isVibrationEnabled = prefs.getBool('${username}_isVibrate') ?? true;
    avatarEmoji = prefs.getString('${username}_avatar') ?? avatarEmoji;
    selectedRankTitle = prefs.getString('${username}_selectedRank') ?? selectedRankTitle;

    final savedAvatars = prefs.getStringList('${username}_owned_avatars') ?? [];
    for (final a in savedAvatars) {
      if (!ownedAvatars.contains(a)) ownedAvatars.add(a);
    }

    final savedRanks = prefs.getStringList('${username}_unlockedRanks') ?? [];
    for (final r in savedRanks) {
      if (!unlockedRanks.contains(r)) unlockedRanks.add(r);
    }

    print('✅ [QUACKLE LOG] โหลดข้อมูล $username สำเร็จ! (Avatar: $avatarEmoji, Theme: $currentThemeId)');
  }
}

/// Static in-memory user store used in place of a real backend.
///
/// Provides a fixed list of seed [User] accounts for development and demo
/// purposes, and a [login] method that authenticates by username/password.
class MockDatabase {
  static List<User> users = [

    // ═══════════════════════════════════════════════════════
    // 💎  user: god / pass: god  —  "FULL DEMO USER"
    // ═══════════════════════════════════════════════════════
    User(
      username: 'god',
      password: 'god',
      coins: 1000000,
      wordsFound: 99,
      foundWordsList: [
        'ABATE','ABYSS','ADORN','AFIRE','ALERT','ANGER','ANNOY','ARENA','ARRAY','AUDIT',
        'AVOID','AWAKE','AWARD','BELCH','BETEL','BIDDY','BLITZ','BLUER','BOBBY','BOOBY',
        'BORNE','BRAKE','BRASH','BRIAR','BRINE','BROKE','BROOD','BRUSH','BUDDY','CAGEY',
        'CANAL','CHAIN','CHARD','CHILI','CHOKE','CHUCK','CHURN','CLAMP','CLANG','CLEAR',
        'CLOCK','CLOUT','CLOVE','CONCH','COVER','CRAMP','CRANK','CREED','CRUMP','DADDY',
        'DALLY','DEBUT','DEPOT','DODGY','DONUT','DRAPE','EASEL','EJECT','ELUDE','ENACT',
        'ENEMA','ENTRY','EQUIP','ERODE','ETHOS','FANCY','FIGHT','FLUTE','FOLLY','FROST',
        'FUNKY','GLADE','GLEAN','GLOAT','GLORY','GOING','GONER','GRANT','GRASP','GRASS',
        'GRAVY','GROAN','GROUT','GUILE','GULLY','GUMBO','GUSTY','HARRY','HARSH','HENCE',
        'HITCH','HONEY','HOVEL','HUMUS','HUNCH','HYENA','IDEAL','INDEX','KNAVE',
      ],
      currentThemeId: 'legendary',
      ownedThemeIds: [
        'classic','pastel','dark','neon','midnight','sunset',
        'sakura','ice','ocean','candy','matrix','galaxy','legendary',
      ],
      gamesPlayed: 250,
      gamesWon: 99,
      currentStreak: 99,
      maxStreak: 99,
      guessDistribution: [10, 30, 80, 40, 20, 20],
      avatarEmoji: 'assets/emoji/Butterfly.png',
      ownedAvatars: [
        'assets/emoji/Duck.png', 'assets/emoji/Chicken.png', 'assets/emoji/Frog.png',
        'assets/emoji/pig_face.png', 'assets/emoji/maple_leaf.png', 'assets/emoji/Bubbles.png',
        'assets/emoji/Penguin.png', 'assets/emoji/Panda.png', 'assets/emoji/teddy_bear.png',
        'assets/emoji/Butterfly.png', 'assets/emoji/Jellyfish.png', 'assets/emoji/Peacock.png',
        'assets/emoji/Whale.png', 'assets/emoji/Sauropod.png', 'assets/emoji/Alien.png',
        'assets/emoji/t-rex.png', 'assets/emoji/Fire.png', 'assets/emoji/video_game.png',
        'assets/emoji/Rainbow.png', 'assets/emoji/glowing_star.png', 'assets/emoji/Unicorn.png',
        'assets/emoji/Phoenix.png', 'assets/emoji/trident_emblem.png',
      ],
      hintCount: 99,
      cleanerCount: 99,
      extraRowCount: 99,
      isSoundEnabled: true,
      isVibrationEnabled: true,
      selectedRankTitle: "🧙‍♂️ Master",
      unlockedRanks: [
        "🌱 Novice","📖 Bookworm","🎓 Scholar","🧙‍♂️ Master",
      ],
    ),
    // ═══════════════════════════════════════════════════════
    // 1️⃣  user: newbie / pass: 1  —  "BRAND NEW PLAYER"
    // ═══════════════════════════════════════════════════════
    User(
      username: 'newbie',
      password: '1',
      coins: 0,
      wordsFound: 0,
      foundWordsList: [],
      currentThemeId: 'classic',
      ownedThemeIds: ['classic'],
      gamesPlayed: 0,
      gamesWon: 0,
      currentStreak: 0,
      maxStreak: 0,
      guessDistribution: [0, 0, 0, 0, 0, 0],
      avatarEmoji: 'assets/emoji/Chicken.png',
      ownedAvatars: ['assets/emoji/Duck.png', 'assets/emoji/Chicken.png'],
      hintCount: 0,
      cleanerCount: 0,
      extraRowCount: 0,
      selectedRankTitle: "🌱 Novice",
      unlockedRanks: ["🌱 Novice"],
    ),

    // ═══════════════════════════════════════════════════════
    // 2️⃣  user: flash / pass: 2  —  "FLASHCARD TRIGGER"
    // ═══════════════════════════════════════════════════════
    User(
      username: 'flash',
      password: '2',
      coins: 5000,
      wordsFound: 14,
      foundWordsList: [
        'ABODE','BONGO','EGRET','FLUNK','GRAFT',
        'KRILL','LURCH','MELEE','REBEL','ROACH',
        'SHORE','SPIKY','TABBY','WOOER',
      ],
      currentThemeId: 'pastel',
      ownedThemeIds: ['classic','pastel'],
      gamesPlayed: 17,
      gamesWon: 14,
      currentStreak: 4,
      maxStreak: 7,
      guessDistribution: [0, 1, 4, 5, 3, 1],
      avatarEmoji: 'assets/emoji/Duck.png',
      ownedAvatars: ['assets/emoji/Duck.png', 'assets/emoji/Chicken.png', 'assets/emoji/Frog.png'],
      hintCount: 50,
      cleanerCount: 50,
      extraRowCount: 50,
      selectedRankTitle: "📖 Bookworm",
      unlockedRanks: ["🌱 Novice","📖 Bookworm"],
    ),

    // ═══════════════════════════════════════════════════════
    // 3️⃣  user: ranker / pass: 3  —  "ALMOST SCHOLAR"
    // ═══════════════════════════════════════════════════════
    User(
      username: 'ranker',
      password: '3',
      coins: 500,
      wordsFound: 29,
      foundWordsList: [
        'ALONE','BLANK','BONUS','BUTCH','CHOSE','CLASS','COURT','DOUGH','ETHER','EVICT',
        'FLANK','FLUTE','FOGGY','GNOME','HEAVY','IDLER','IMBUE','LLAMA','PENAL','SATIN',
        'SCOLD','SHOCK','SNARL','SOOTY','STAIN','SWASH','SWORN','VILLA','VOTER'
      ],
      currentThemeId: 'dark',
      ownedThemeIds: ['classic','dark'],
      gamesPlayed: 35,
      gamesWon: 29,
      currentStreak: 8,
      maxStreak: 12,
      guessDistribution: [1, 5, 10, 8, 3, 2],
      avatarEmoji: 'assets/emoji/Penguin.png',
      ownedAvatars: ['assets/emoji/Duck.png', 'assets/emoji/Chicken.png', 'assets/emoji/Penguin.png'],
      hintCount: 50,
      cleanerCount: 50,
      extraRowCount: 50,
      selectedRankTitle: "📖 Bookworm",
      unlockedRanks: ["🌱 Novice","📖 Bookworm"],
    ),

    // ═══════════════════════════════════════════════════════
    // 4️  user: richboy / pass: 4  —  "RICH SHOPPER"
    // ═══════════════════════════════════════════════════════
    User(
      username: 'richboy',
      password: '4',
      coins: 1000000,
      wordsFound: 20,
      foundWordsList: [
        'AGING','BAWDY','BLAME','BLURB','BLUSH','BOSOM','BRINK','BRISK','BUILT','CANNY',
        'CAROL','CROWN','DELVE','ELIDE','FLINT','GAUGE','HEADY','HINGE','HUTCH','KARMA'
      ],
      currentThemeId: 'classic',
      ownedThemeIds: ['classic'],
      gamesPlayed: 25,
      gamesWon: 20,
      currentStreak: 5,
      maxStreak: 10,
      guessDistribution: [0, 2, 5, 8, 3, 2],
      avatarEmoji: 'assets/emoji/Duck.png',
      ownedAvatars: ['assets/emoji/Duck.png', 'assets/emoji/Chicken.png'],
      hintCount: 0,
      cleanerCount: 0,
      extraRowCount: 0,
      selectedRankTitle: "📖 Bookworm",
      unlockedRanks: ["🌱 Novice","📖 Bookworm"],
    ),
  ];

  /// Authenticates a user by [username] and [password], then loads their saved data.
  ///
  /// Returns the matching [User] with persisted data loaded, or `null` if no
  /// account matches the provided credentials.
  static Future<User?> login(String username, String password) async {
    try {
      User user = users.firstWhere(
        (u) => u.username == username && u.password == password,
      );
      await user.loadData();
      return user;
    } catch (e) {
      return null;
    }
  }
}
