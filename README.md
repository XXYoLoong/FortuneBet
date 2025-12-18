# FortuneBet (鸿运押宝)

[中文 (Chinese)](README_CN.md) | **English**

<div align="center">
  <img src="entry/src/main/resources/base/media/startIcon.jpg" alt="FortuneBet Icon" width="120" height="120">
  <br>
  <h3>A Thrilling HarmonyOS Betting Simulation Game built with ArkTS</h3>
</div>


---

## 📖 Overview

**FortuneBet** (鸿运押宝) is a standalone casual simulation betting game developed for HarmonyOS using ArkTS and ArkUI. Players can experience the thrill of high-stakes betting in a risk-free virtual environment. Test your strategy and luck by placing bets on various multipliers ranging from safe low-odds to risky high-rewards!

This project demonstrates a complete application architecture on HarmonyOS, including secure local data persistence (Preferences), complex UI state management, animations, and business logic separation.

## ✨ Key Features

* **🎲 Thrilling Gameplay:** Experience the excitement of betting with a tiered multiplier system. Choose between high-frequency low multipliers (e.g., 2x, 4x) for steady gains or chase the jackpot with low-frequency high multipliers (e.g., 50x, 100x).
* **💰 Currency System:** Start with free virtual coins to enjoy the game immediately.
* **🎁 Daily Relief Bonus:** Never run out of fun! If your balance hits zero, or upon your first login daily, the system automatically grants a relief bonus of 30 coins.
* **💾 Local Data Persistence:** All user data, balances, settings, and detailed game history are securely saved locally using HarmonyOS `Preferences`. No internet connection is required.
* **📈 Asset Trend Chart:** Track your performance visually with a dynamic trend chart in the Profile section, showing your balance snapshots over the last 10 rounds.
* **🏆 Milestones System:** Unlock achievements badges as your cumulative total winnings grow.
* **⚙️ Robust Profile & Settings:**
    * Customize nickname, profile quote, and game avatar.
    * Secure local password change functionality.
    * Access game rules, version info, and licenses easily.
* **🎨 Immersive UI:** A dark-themed interface with engaging animations, such as the unique "About Us" entrance sequence.

## 📱 Screenshots

<div align="center" style="display: flex; justify-content: center; gap: 10px;">
  <img src="entry/src/main/resources/base/media/GamePage.png" alt="Game Page" width="200">
  <img src="entry/src/main/resources/base/media/GamePage2.png" alt="Game Page 2" width="200">
  <img src="entry/src/main/resources/base/media/HistoryPage.png" alt="History Chart" width="200">
  <img src="entry/src/main/resources/base/media/MilestonePage.png" alt="Milestone Page" width="200">
  <img src="entry/src/main/resources/base/media/MinePage.png" alt="Mine Page" width="200">
</div>


## 🛠️ Getting Started

### Prerequisitesa

* **DevEco Studio:** Version 6.0 or higher (Compatible with API 12+).
* **HarmonyOS SDK:** API Version 9 or higher.

### Installation & Run

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/XXYoLoong/FortuneBet.git
    ```
2.  **Open in DevEco Studio:**
    Launch DevEco Studio, navigate to **File -> Open**, and select the project root directory.
3.  **Sync Project:**
    Wait for DevEco Studio to download necessary dependencies and sync the project configuration (Gradle sync).
4.  **Build and Run:**
    Connect a HarmonyOS physical device or start a local emulator. Click the **Run** button (▶️) in the toolbar to deploy the app.

## 🎮 Game Rules

1.  **Betting Phase:** Each game round lasts for **60 seconds**. During this countdown, you can analyze the odds and place bets on one or more multiplier options.
2.  **Multipliers & Probabilities:**
    * **High Risk, High Reward:** E.g., 100x (0.1% chance), 50x (0.3% chance).
    * **Low Risk, Low Reward:** E.g., 2x (10.0% chance), 4x (25.0% chance).
3.  **Settlement:** When the countdown ends, the system selects a winning multiplier based on weighted probabilities.
    * **Win:** If you placed a bet on the winning multiplier, you receive: `Bet Amount * Multiplier`.
    * **Lose:** Bets placed on non-winning multipliers are deducted from your balance.
4.  **Relief Fund:** If your balance drops to 0, re-enter the game or log in the next day to receive the 30-coin relief bonus.

## 📂 Project Structure (Key Files)

```
entry/src/main/ets/
├── common/
│   ├── constants.ts       // Game rules, multipliers configuration, global constants
│   └── types.ts           // TypeScript interfaces (GameRound, UserProfile, etc.)
├── pages/
│   ├── Index.ets          // Application entry point, authentication check, main Tabs layout
│   ├── game/              // Game UI and core interaction logic components
│   ├── history/           // Game history list component with real-time updates
│   ├── milestone/         // Achievements and milestones tracking component
│   └── profile/           // User profile hub, settings menu, asset trend chart, about pages
└── services/
    ├── AuthService.ts     // Handles login, registration, and password management
    ├── GameService.ts     // Manages the core game loop, betting state, and settlement logic
    ├── HistoryService.ts  // Retrieves and manages past game records
    ├── StorageService.ts  // Centralized local data persistence layer using Preferences
    └── ServiceLocator.ts  // Service initialization and dependency injection
```

## 📄 License

```
Copyright 2025 Jiacheng Ni

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## 👤 About the Author

* *"既见游龙，为何不拜"* (Since you see the wandering dragon, why not bow?)
* GitHub: [https://github.com/XXYoLoong](https://github.com/XXYoLoong)