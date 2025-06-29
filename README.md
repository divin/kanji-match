# Kanji Match 🎴✨

Kanji Match is an educational game designed to help you master visually similar Japanese kanji. By focusing on kanji that are often confused due to their appearance, the game helps reinforce subtle distinctions and deepen your recognition skills. Kanji Match uses the WaniKani API to fetch your personalized kanji data, so an active WaniKani subscription is required.

## ✨ Features

- 🉐 **Focus on Visually Similar Kanji:** Practice distinguishing kanji that look alike, reducing common mistakes in reading and writing.
- 🔗 **WaniKani Integration:** Connects to your WaniKani account to use your current kanji progress and review schedule.
- ⏰ **Spaced Repetition System (SRS):** Review kanji in groups based on when they are due for optimal memory retention.
- 🀄 **Matching Gameplay:** Match kanji characters with their correct meanings.
- 📊 **Session Tracking:** Detailed statistics including correct/incorrect matches, streaks, session time, and more.
- 🔥 **Streak System:** Get rewarded for consecutive correct answers with increasing audio pitch and visual feedback.
- 🏁 **Session Overview:** At the end of each session (or if you exit early), see a summary of your performance.
- 🔊 **Audio-Visual Feedback:** Enjoy sound effects and confetti for correct answers and streaks.

## 📝 Requirements

- **WaniKani Subscription:** You must have an active WaniKani account and API key to use this game.
- **LÖVE (Love2D):** Only required if you want to run the game from source or for development. Pre-built binaries are available for end users.

> **Note:** Kanji Match was written using LÖVE2D 12, but should be compatible with LÖVE2D 11.x as well.

## 🎮 How to Play

1. **Connect to WaniKani:** Enter your WaniKani API key when prompted.
2. **Start a Review Session:** The game will present you with groups of visually similar kanji that are due for review.
3. **Match Cards:** Click on cards to match each kanji with its correct meaning.
4. **Track Your Progress:** Watch your streak and stats update as you play.
5. **Complete or Exit:** Finish all groups to complete the session, or exit early at any time. Your progress will be saved and summarized.

## 🕹️ Controls

- **Mouse:** Click cards to select and match them.
- **Exit Button:** Click the exit button in the corner to end your session early.
- **Keyboard (Overview Screen):** Press `SPACE`, `ENTER`, or click anywhere to return to the main menu after a session.

## 📈 Stats Tracked

- Groups Completed
- Total Kanji Reviewed
- Correct Matches
- Incorrect Matches
- Accuracy Percentage
- Best Streak
- Session Time

## 🚀 Download & Running the Game

You can download pre-built binaries for **Linux**, **macOS**, and **Windows** from the following pages:

- **[GitHub Releases](https://github.com/divin/kanji-match/releases):** Always get the latest version here.
  - **Windows:** Download the `.exe` installer or the `.zip` portable version.
  - **macOS:** Download the `.app.zip` for a drag-and-drop app, or `.dmg` for disk image install.
  - **Linux:** Download the `.AppImage` for a single-file app, or `.tar.gz` for manual extraction.
  - **All Platforms (advanced/source):** Download the `.love` file to run with LÖVE2D, or the source code archives.

- **[itch.io Page](https://divingavran.itch.io/kanji-match):** Alternative download and community page.

Simply download the appropriate file for your platform and run it—no additional installation required.

> **macOS Users:**  
> This app is **not code-signed**. After the initial start, you may need to allow the app to run via **System Settings → Privacy & Security**. If you see a warning that the app cannot be opened because it is from an unidentified developer, open System Settings, scroll to the bottom of the Privacy & Security pane, and click "Allow Anyway" next to the Kanji Match app. Then try launching the app again. This is required because the app is unsigned.

If you prefer to run from source:

1. Install [LÖVE](https://love2d.org/).
2. Clone this repository.
3. Run the game with:
   ```bash
   love .
   ```

## 🛠️ Development

If you want to contribute or modify the game:

1. Make sure you have [LÖVE](https://love2d.org/) and Lua installed.
2. Clone this repository.
3. All source code is in the `src/` directory.
4. You can run the game directly with:
   ```bash
   love .
   ```
5. To package your own binaries, follow the [LÖVE distribution instructions](https://love2d.org/wiki/Game_Distribution).

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.

---

Enjoy mastering visually similar kanji with Kanji Match!
