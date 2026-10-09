# 🦆 Quackle - EDICE (204311 Mobile Application Development Framework)

> A Wordle-inspired word-guessing game built with Flutter — featuring themes, power-ups, a flashcard system, and local persistence.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-%5E3.10.0-0175C2?style=flat-square&logo=dart)
![Version](https://img.shields.io/badge/Version-1.0.0%2B1-orange?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey?style=flat-square)
![License](https://img.shields.io/badge/Purpose-Educational-green?style=flat-square)

---

## 📖 Overview

Quackle is a mobile word game where players guess a hidden 5-letter English word within 6 attempts.
Each guess provides color-coded feedback, and correct guesses reward coins that can be spent in the in-game store.

> **Disclaimer:** This project was created for **educational purposes** as part of a Mobile Application Development course. It is not affiliated with or endorsed by The New York Times or Josh Wardle.

---

## ✨ Features

| Category               | Details                                                                |
| ---------------------- | ---------------------------------------------------------------------- |
| 🎮 **Core Gameplay**   | Guess a 5-letter word in 6 tries with color-coded tile feedback        |
| 🎨 **Theme Store**     | 14 purchasable visual themes (Classic, Dark, Neon, Galaxy, Legendary…) |
| ⚡ **Power-Ups**       | Hint Reveal, Keyboard Cleaner, Extra Row — purchasable with coins      |
| 📖 **Flashcard Mode**  | Study & Quiz modes unlocked after finding 15 words                     |
| 📚 **My Dictionary**   | Searchable log of all discovered words with Thai translations          |
| 🏆 **Rank System**     | Earn titles (Novice → Bookworm → Scholar → Master → Legend)            |
| 🐣 **Avatar Shop**     | Collect and equip emoji-style avatars                                  |
| 💾 **Persistence**     | All progress saved locally via `shared_preferences`                    |
| 🔊 **Sound & Haptics** | Toggle-able sound effects and vibration feedback                       |

---

## 🛠 Tech Stack

| Layer                  | Technology                    | Version       |
| ---------------------- | ----------------------------- | ------------- |
| **Framework**          | Flutter (Dart)                | SDK `^3.10.0` |
| **State Management**   | `setState` / `StatefulWidget` | —             |
| **Local Storage**      | `shared_preferences`          | `^2.3.2`      |
| **Audio**              | `audioplayers`                | `^6.1.0`      |
| **Fonts (Thai)**       | `google_fonts` (Kanit)        | `^6.2.1`      |
| **Fonts (Custom)**     | DINNextRounded LT W04         | bundled asset |
| **Icons**              | `cupertino_icons`             | `^1.0.8`      |
| **App Icon Generator** | `flutter_launcher_icons`      | `^0.13.1`     |

---

## 📁 Project Structure

```
lib/
├── main.dart                   # Entry point — orientation lock & app launch
├── app.dart                    # Root widget, routes, global theme
│
├── models/
│   └── mock_data.dart          # User model + MockDatabase (auth & persistence)
│
├── screens/
│   ├── splash_screen.dart      # Animated splash + session routing
│   ├── welcome_screen.dart     # Onboarding screen
│   ├── login.dart              # Authentication screen
│   ├── home.dart               # Main hub with bottom navigation
│   ├── game_screen.dart        # Core Wordle gameplay
│   ├── flashcard.dart          # Study & Quiz modes
│   ├── dictionary.dart         # Discovered word log
│   ├── store.dart              # Theme & power-up shop
│   └── profile.dart            # Stats, avatar, rank, settings
│
├── components/
│   ├── coin_badge.dart         # Animated coin display widget
│   ├── custom_3d_buttton.dart  # Reusable 3D press-down button
│   ├── custom_keyboard_key.dart# Individual keyboard key widget
│   └── victory_effect.dart     # Confetti particle animation
│
├── services/
│   └── audio_helper.dart       # Centralised sound & haptic utilities
│
└── theme/
    ├── theme_data.dart         # GameTheme model + ThemeDatabase catalog
    └── text_styles.dart        # Smart Thai/English font selection

assets/
├── emoji/                      # Avatar image assets
├── fonts/                      # Custom font files
├── images/                     # Mascot illustrations
├── sounds/                     # Sound effect files
├── targetwords.json            # Target word list with Thai translations
└── validwords.txt              # Valid guess dictionary
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.10.0`)
- Android Studio / Xcode (for device or emulator)
- Chrome (for web)

### Installation

1. **Clone the repository**

   ```bash
   # HTTPS
   git clone https://github.com/whoosh09/MobileProject_204311.git

   # SSH
   git clone git@github.com:whoosh09/MobileProject_204311.git

   cd MobileProject_204311
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate app icons** _(optional — icons are already committed)_

   ```bash
   dart run flutter_launcher_icons
   ```

4. **Run the app**

   ```bash
   # Mobile (recommended)
   flutter run

   # Web — fixed port required for shared_preferences to work correctly
   flutter run -d chrome --web-port=5000
   ```

5. **Generate documentation** _(optional)_

   ```bash
   dart doc
   # Output will be in the doc/ directory
   ```

---

## 🔐 Test Accounts

| Username  | Password | Coins     | Description                                           |
| --------- | -------- | --------- | ----------------------------------------------------- |
| `god`     | `god`    | 1,000,000 | Full demo — all themes, avatars & power-ups unlocked  |
| `newbie`  | `1`      | 0         | Brand-new player — zero progress                      |
| `flash`   | `2`      | 5,000     | One word away from unlocking Flashcard mode           |
| `ranker`  | `3`      | 500       | One word away from earning Scholar rank               |
| `richboy` | `4`      | 1,000,000 | Rich but nothing bought — ideal for testing the store |

---

## 🎮 How to Play

1. Log in with any test account
2. Tap **PLAY** on the home screen
3. Type a 5-letter English word using the on-screen keyboard and press **ENTER**
4. Read the tile feedback:
   - 🟩 **Green** — correct letter, correct position
   - 🟨 **Yellow** — correct letter, wrong position
   - ⬜ **Grey** — letter not in the word
5. Guess the word within 6 rows to earn **+10 coins**
6. Spend coins in the **Store** on themes and power-ups

### Power-Ups

| Power-Up            | Cost      | Effect                                    |
| ------------------- | --------- | ----------------------------------------- |
| 💡 Hint Reveal      | 50 coins  | Reveals the next correct letter           |
| 🔧 Keyboard Cleaner | 30 coins  | Removes 3 wrong letters from the keyboard |
| ➕ Extra Row        | 100 coins | Adds a 7th guess row                      |

---

## 📸 Screenshots

<img width="270" height="606" alt="Home" src="https://github.com/user-attachments/assets/c09eaf10-6a46-4de2-9fa8-1d3a22c033de" />
<img width="270" height="606" alt="FlashCardQuiz" src="https://github.com/user-attachments/assets/1580a532-69ed-4fbd-9252-a420a921e953" />
<img width="270" height="606" alt="FlashCardStudy" src="https://github.com/user-attachments/assets/8aed4eb8-085c-4dbd-80fb-7d8bf422959f" />
<img width="270" height="606" alt="Dictionary" src="https://github.com/user-attachments/assets/0f99ccc4-b5fa-401b-a2d2-43a1da6036d3" />
<img width="270" height="606" alt="ShopTheme" src="https://github.com/user-attachments/assets/9c2cb0cf-5e93-4334-8f68-5cc8d6785774" />
<img width="270" height="606" alt="ShopePowerUp" src="https://github.com/user-attachments/assets/3cc3f2f1-bfce-4f93-903b-2d51af257139" />
<img width="270" height="606" alt="Profile" src="https://github.com/user-attachments/assets/43f64f38-b216-4bef-9bd3-74fd4023c68d" />

---

## ⚖️ Credits

| Role                  | Credit                                                                |
| --------------------- | --------------------------------------------------------------------- |
| Original game concept | [Josh Wardle](https://twitter.com/powerlanguish)                      |
| Current rights holder | [The New York Times](https://www.nytimes.com/games/wordle/index.html) |
| Project author        | Quackle Team — Mobile Application Development Framework               |

---

_Created for educational purposes only. Not affiliated with The New York Times._
