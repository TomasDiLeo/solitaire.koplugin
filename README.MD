# 🃏 Solitaire for KOReader

**Solitaire** is a KOReader plugin that brings the classic Klondike card game to your e-reader. Take a break from reading and enjoy a relaxing game of Solitaire, optimized for e-ink displays!

![KOReader](https://img.shields.io/badge/KOReader-Plugin-blue)
![Lua](https://img.shields.io/badge/Language-Lua-purple)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

### 🎮 Core Mechanics

| Feature | Description |
|---------|-------------|
| **Classic Klondike** | Traditional Solitaire rules you know and love |
| **Touch Optimized** | Designed for e-ink touchscreens |
| **Grayscale Design** | Clear distinction between red and black suits |
| **Score Tracking** | Earn points for every move |
| **Move Counter** | Track how efficient your game is |

### 🎯 Game Helpers

| Feature | Description |
|---------|-------------|
| 💡 **Hint System** | Get suggestions when you're stuck |
| ⚡ **Auto-Complete** | Automatically move cards to foundations |
| 🎯 **Quick Move** | Long-press to send cards to foundations |
| 🔄 **New Game** | Start fresh anytime |

### ♠️ Card Design

| Element | Design Choice |
|---------|---------------|
| **Black Suits** (♠ ♣) | Solid black color |
| **Red Suits** (♥ ♦) | Gray color (e-ink friendly) |
| **Face Down** | Dotted pattern |
| **Selected Cards** | Bold border highlight |

---

## 📥 Installation

### Method 1: Direct Download

1. Download the `solitaire.koplugin` folder
2. Copy it to your KOReader plugins directory:
   - **Kindle**: `/koreader/plugins/`
   - **Kobo**: `/.adds/koreader/plugins/`
   - **Android**: `/sdcard/koreader/plugins/`
   - **Desktop**: `~/.config/koreader/plugins/`
3. Restart KOReader

### Method 2: Git Clone

```bash
cd /path/to/koreader/plugins/
git clone https://github.com/Lalocaballero/solitaire.koplugin.git
```

---

## 📁 Plugin Structure

```
solitaire.koplugin/
├── _meta.lua        # Plugin metadata
├── main.lua         # Entry point & menu registration
├── game.lua         # Game logic & rules
└── solitaireui.lua  # User interface & rendering
```

---

## 🎯 Usage

### Accessing the Plugin

1. Open KOReader
2. Go to **Menu** → **Tools** → **Solitaire**

### Button Bar

| Button | Action |
|--------|--------|
| **New Game** | Shuffle and deal a new game |
| **Hint** | Highlight a suggested move (2 seconds) |
| **Auto** | Move all possible cards to foundations |
| **Close** | Exit the game |

---

## 🎮 Controls

### Touch Actions

| Action | Effect |
|--------|--------|
| **Tap stock pile** | Draw a card to waste |
| **Tap empty stock** | Recycle waste pile back to stock |
| **Tap a card** | Select it (shows highlight) |
| **Tap destination** | Move selected card(s) there |
| **Tap elsewhere** | Deselect current selection |
| **Long-press card** | Auto-move to foundation if valid |

### Card Selection

| Selection | What Moves |
|-----------|------------|
| Waste card | Single card |
| Tableau card | That card + all cards below it |
| Foundation card | Single card (can move back to tableau) |

---

## 📜 Rules

### Objective

Move all 52 cards to the four foundation piles, sorted by suit from Ace to King.

### Tableau Rules

| Rule | Description |
|------|-------------|
| **Build Down** | Place cards in descending order (K, Q, J, 10...) |
| **Alternate Colors** | Red on black, black on red |
| **Move Stacks** | Can move multiple face-up cards together |
| **Empty Columns** | Only Kings can fill empty tableau spots |

### Foundation Rules

| Rule | Description |
|------|-------------|
| **Build Up** | Place cards in ascending order (A, 2, 3... K) |
| **Same Suit** | Each foundation is one suit only |
| **Start with Ace** | Must begin each foundation with an Ace |

### Stock & Waste

| Rule | Description |
|------|-------------|
| **Draw** | Tap stock to draw one card to waste |
| **Recycle** | When stock is empty, tap to recycle waste |
| **Play from Waste** | Top waste card is always playable |

---

## 📊 Scoring System

### Earning Points

| Action | Points |
|--------|--------|
| Card to foundation | +10 |
| Card to tableau | +5 |
| Flip tableau card | +5 |

### Penalties

| Action | Points |
|--------|--------|
| Card from foundation to tableau | -15 |
| Recycle waste pile | -20 |

---

## 🛠️ Customization

### Card Dimensions

Edit `solitaireui.lua` in the `init()` function:

```lua
-- Card size (fraction of screen width)
self.card_width = math.floor(self.screen_width / 9)

-- Card height ratio
self.card_height = math.floor(self.card_width * 1.4)

-- Stack overlap (how much cards show when stacked)
self.stack_offset = math.floor(self.card_height * 0.35)
```

### Font Sizes

```lua
-- Rank font (A, 2, 3... K)
self.rank_font = Font:getFace("cfont", math.floor(self.card_width * 0.25))

-- Center suit symbol
self.suit_center_font = Font:getFace("cfont", math.floor(self.card_width * 0.35))
```

### Suit Position

In `drawCard()` function:

```lua
-- Adjust vertical position of center suit
-- Increase 0.25 to move higher, decrease to move lower
local center_y = y + self.card_height - sh - (self.card_height * 0.25)
```

---

## 🔧 Development

### Requirements

| Requirement | Version |
|-------------|---------|
| KOReader | v2021.01 or later |
| Lua | 5.1 / LuaJIT |

### Key Files

| File | Purpose |
|------|---------|
| `game.lua` | Card logic, valid moves, win detection |
| `solitaireui.lua` | Drawing, touch handling, UI updates |

### Adding Features

To add undo functionality, you would:
1. Store move history in `game.lua`
2. Add undo button in `solitaireui.lua`
3. Implement `Game:undo()` method

---

## 🚀 Roadmap

### Planned Features

- [X] Undo/redo functionality
- [X] Save and resume game
- [ ] Draw-3 variant option
- [ ] Game statistics tracking
- [ ] Best scores leaderboard
- [ ] Timer mode
- [ ] More card games (Spider, FreeCell)

---

## 🤝 Contributing

Contributions are welcome! Here's how:

1. Fork the repository
2. Create a feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Commit your changes
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. Push to the branch
   ```bash
   git push origin feature/amazing-feature
   ```
5. Open a Pull Request

### Ideas for Contributions

- [ ] Undo system
- [ ] Save/load game state
- [ ] Draw-3 mode toggle
- [ ] Win animation
- [ ] Statistics tracking
- [ ] Card themes
- [ ] Landscape orientation support
- [ ] Localization / translations

---

## 📝 License

This project is licensed under the MIT License.

```
MIT License

Copyright (c) 2024

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

| | |
|---|---|
| [KOReader](https://github.com/koreader/koreader) | The amazing open-source ebook reader |
| KOReader Community | Documentation and plugin examples |
| Classic Windows Solitaire | Inspiration for the game |

---

## 📬 Contact

| Channel | Link |
|---------|------|
| **Issues** | [GitHub Issues](https://github.com/Lalocaballero/solitaire.koplugin/issues) |
| **Discussions** | [GitHub Discussions](https://github.com/Lalocaballero/solitaire.koplugin/discussions) |

---

## 📸 Screenshots

### Plugin Location & Game

<table>
  <tr>
    <th>Game Board</th>
  </tr>
  <tr>
    <td><img src="screenshots/game_board.png" width="300" alt="Game Board"></td>
  </tr>
  <tr>
    <td><i>Classic Klondike layout</i></td>
  </tr>
</table>

### Winning

<table>
  <tr>
    <th>Victory!</th>
  </tr>
  <tr>
    <td><img src="screenshots/win.png" width="300" alt="Win Screen"></td>
  </tr>
  <tr>
    <td><i>Congratulations message with stats</i></td>
  </tr>
</table>

---

<p align="center">
  <b>Take a break and play! 🃏✨</b>
  <br><br>
  <i>Perfect for those moments when you need a pause from reading.</i>
  <br><br>
  ⭐ Star this repo if you find it useful! ⭐
  <br><br>
  <a href="https://www.buymeacoffee.com/lalocaballero">
    <img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow?style=flat&logo=buy-me-a-coffee" alt="Buy Me A Coffee">
  </a>
</p>
