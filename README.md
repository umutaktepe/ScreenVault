# ScreenVault 🎬

> **Obsidian Cinema & TV Tracker** — A modern, high-performance TV Time alternative designed with OLED aesthetics, local-first Drift SQLite storage, TMDB v3 integration, and seamless TV Time GDPR data migration.

---

## ✨ Features

- **🖤 OLED Obsidian Theme**: Tailored pure dark canvas (`#0E0F12`), high-contrast surface tiles (`#1A1C23`), Canary Yellow accents (`#FED530`), Emerald Green progress indicators (`#22C55E`), and `Inter` typography.
- **🛸 Floating Frosted Glass Dock**: 5-tab dynamic navigation dock (`FloatingFrostedNavBar`) with backdrop blur:
  1. **Watchlist**: 16:9 cinematic "Up Next" hero card, quick 40px `CheckmarkToggleButton`, and vertical tracking list with fine progress lines.
  2. **Calendar**: 7-day horizontal day strip and upcoming episode schedule.
  3. **Discover**: Multi-search TMDB v3 integration, Daily Trending carousel, and regional streaming provider filters.
  4. **Community**: TV Time friend activity feed, discussion threads, and tap-to-reveal blurred spoiler protection.
  5. **Profile**: 3-column gold digital LED lifetime counter (`[ 04 ] Months [ 09 ] Days [ 13 ] Hours`), genre breakdown donut chart, 28-day activity heatmap matrix, and rewatch rails.
- **📺 Episode Detail Screen**: 16:9 still image scrim, "I've Watched This" toggle with rewatch counter, 5-Emotion Meter (🤯, 😢, 😂, 🔥, 😡), MVP character voting, and spoiler comments.
- **⚡ TMDB v3 API Client**: Configured with token bucket rate-limiting (35-40 req/s), exponential backoff, and 429 Retry-After support.
- **📦 Drift Local-First SQLite Database**: Fully offline-capable local database schema with reactive query streams.
- **🔄 TV Time GDPR Migration & Exporter**: Ingests and exports TV Time GDPR archives (`gdpr-data.zip`), importing `seen_episode.csv`, `tracking_show.csv`, and `friend.csv` with accurate duration conversion (`runtimeSeconds ~/ 60`).

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (^3.44.0 or Dart ^3.12.0)
- TMDB API Key

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/umutaktepe/ScreenVault.git
   cd ScreenVault
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run tests**:
   ```bash
   flutter test
   ```

4. **Launch the application**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Code Quality

- **Test Suite**: 21 unit, migration, network, and widget tests passing cleanly.
- **Analysis**: 0 linter issues (`flutter analyze` clean).

---

## 📄 License

GNU General Public License v3.0 (GPL-3.0) — see [LICENSE](LICENSE) for details.
