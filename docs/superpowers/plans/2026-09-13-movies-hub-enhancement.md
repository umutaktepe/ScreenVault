# Movies Hub & Watchlist Film Deneyimi Geliştirme Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Anasayfa (Watchlist) film sekmesini dizi sekmesi seviyesinde zenginleştirmek; en üstte "Spotlight / Sıradaki Film" öne çıkan hero kartı, durum filtreleri ("Tümü", "İzlenecekler", "İzlenenler"), hızlı izlendi butonlu zengin `WatchlistMovieTile` kartları, tam teşekküllü `MovieDetailScreen` detay sayfası ve 3'lü grid/liste geçişli `MyMoviesScreen` kütüphane ekranını hayata geçirmek.

**Architecture:** 
- `DatabaseService` üzerinde film sorgulama ve vitrin yardımcıları (`getMovieById`, `getFollowedOrWatchedMovies`, `getSpotlightMovie`) eklenerek son izleme ve eklenme sıralamaları reactive `showsStream` üzerinden sağlanır.
- `WatchlistScreen` film sekmesi modüler bileşenlerle yeniden yapılandırılır:
  1. En üstte `MovieSpotlightCard` (izleme listesindeki sıradaki filmi veya son izleneni öne çıkaran geniş vitrin kartı).
  2. "Filmlerim" bölüm başlığı, sayaç rozeti (`10 / X`) ve `MyMoviesScreen` sayfasına yönlendiren "Tümünü Gör >" bağlantısı.
  3. Durum filtre chipleri: "Tümü", "İzlenecekler", "İzlenenler".
  4. Top 10 film listesi için `WatchlistMovieTile` (poster, TMDB puanı, süre, vizyon yılı, türler ve sağda tek dokunuşla çalışan `CheckmarkToggleButton`).
  5. 10'dan fazla film olduğunda "Tüm Filmlerimi Gör (+X Film)" kart butonu.
- `MovieDetailScreen` ile filmlere tıklandığında geniş backdrop, poster, TMDB puanı, süre, vizyon tarihi, özet (synopsis), "İzleme Listesi" ve "İzlendi" durum butonları sunulur. `DiscoverScreen` üzerindeki film tıklamaları da bu ekrana bağlanır.
- `MyMoviesScreen` kütüphane ekranı (`MyShowsScreen` standartlarında) 3 sütunlu `MovieGridCard` afiş ızgarası ve dikey liste görünümü, canlı arama çubuğu, sayfalama (20'lik gruplar) ve `MyMoviesFilterSheet` (sıralama ve tür filtreleri) içerir.

**Tech Stack:** Flutter, Dart, Drift SQLite, Provider/StreamBuilder, Obsidian Cinema OLED Tasarım Sistemi (`#0E0F12`, `#1A1C23`, `#222631`, `#FED530`, `#22C55E`, `#94A3B8`).

**Spec:** Kullanıcı ile `/grill-me` mülakatında mutabık kalınan mimari ve tasarım kararları.

## Global Constraints
- Flutter/Dart terminal komutlarında HER ZAMAN `BypassSandbox: true` kullanılmalıdır (`/home/umutaktepe/flutter/bin`).
- Obsidian Cinema OLED tema tokenlarına (`AppColors`, `AppTypography`) tam uyum sağlanmalıdır.
- Test güdümlü geliştirme (TDD) uygulanmalı: her task önce başarısız test ile başlamalı, ardından minimal kod yazılarak test geçirilmelidir.
- `flutter analyze` ile 0 hata ve 0 lint uyarısı hedeflenmelidir.

---

### Task 1: DatabaseService - Film Sorgu ve Vitrin (Spotlight) Yardımcıları

**Files:**
- Create: `test/database/movie_service_helpers_test.dart`
- Modify: `lib/data/database/database_service.dart:1945-2000`

**Interfaces:**
- Consumes: `_movies: Map<int, MovieModel>`
- Produces:
  - `MovieModel? getMovieById(int id)`
  - `List<MovieModel> getFollowedOrWatchedMovies()`
  - `MovieModel? getSpotlightMovie()`

- [ ] **Step 1: Write the failing test**

```dart
// test/database/movie_service_helpers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/movie_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();

  setUp(() async {
    await db.clearActiveUserData();
  });

  test('getMovieById returns null when not found and correct model when present', () async {
    expect(db.getMovieById(9999), isNull);

    final movie = const MovieModel(
      id: 101,
      title: 'Inception',
      runtimeMinutes: 148,
      isFollowed: true,
    );
    await db.upsertMovie(movie);

    final retrieved = db.getMovieById(101);
    expect(retrieved, isNotNull);
    expect(retrieved!.title, 'Inception');
  });

  test('getFollowedOrWatchedMovies returns only followed or watched movies', () async {
    await db.upsertMovie(const MovieModel(id: 1, title: 'Followed Movie', isFollowed: true, isWatched: false));
    await db.upsertMovie(const MovieModel(id: 2, title: 'Watched Movie', isFollowed: false, isWatched: true));
    await db.upsertMovie(const MovieModel(id: 3, title: 'Ignored Movie', isFollowed: false, isWatched: false));

    final list = db.getFollowedOrWatchedMovies();
    final ids = list.map((m) => m.id).toSet();
    expect(ids, containsAll([1, 2]));
    expect(ids, isNot(contains(3)));
  });

  test('getSpotlightMovie prioritizes unwatched followed movie, falls back to latest watched', () async {
    final watchedMovie = MovieModel(
      id: 10,
      title: 'Past Watched',
      isFollowed: true,
      isWatched: true,
      watchedAt: DateTime(2025, 1, 1),
    );
    final watchlistMovie = const MovieModel(
      id: 20,
      title: 'Next To Watch',
      isFollowed: true,
      isWatched: false,
    );

    await db.upsertMovie(watchedMovie);
    expect(db.getSpotlightMovie()?.id, 10);

    await db.upsertMovie(watchlistMovie);
    expect(db.getSpotlightMovie()?.id, 20, reason: 'Watchlist movie should take priority over watched movie');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/database/movie_service_helpers_test.dart`
Expected: FAIL with compilation errors (methods undefined).

- [ ] **Step 3: Implement minimal code in DatabaseService**

```dart
// In screenvault/lib/data/database/database_service.dart around line 1947:
  MovieModel? getMovieById(int id) => _movies[id];

  List<MovieModel> getFollowedOrWatchedMovies() {
    return _movies.values.where((m) => m.isFollowed || m.isWatched).toList();
  }

  MovieModel? getSpotlightMovie() {
    final candidates = getFollowedOrWatchedMovies();
    if (candidates.isEmpty) return null;

    // 1. Priority: followed and not watched (watchlist)
    final unwatchedFollowed = candidates.where((m) => m.isFollowed && !m.isWatched).toList();
    if (unwatchedFollowed.isNotEmpty) {
      return unwatchedFollowed.last;
    }

    // 2. Fallback: most recently watched
    final watched = candidates.where((m) => m.isWatched).toList();
    if (watched.isNotEmpty) {
      watched.sort((a, b) {
        final dateA = a.watchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.watchedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
      return watched.first;
    }

    return candidates.first;
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/database/movie_service_helpers_test.dart`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/data/database/database_service.dart test/database/movie_service_helpers_test.dart
git commit -m "feat: add movie query and spotlight helper methods to DatabaseService"
```

---

### Task 2: Watchlist Movie Tile Component (`WatchlistMovieTile`)

**Files:**
- Create: `lib/presentation/screens/watchlist/widgets/watchlist_movie_tile.dart`
- Create: `test/presentation/watchlist_movie_tile_test.dart`

**Interfaces:**
- Consumes: `MovieModel`, `DatabaseService`, `CheckmarkToggleButton`, `CustomPosterImage`
- Produces: `WatchlistMovieTile(movie: movie, onTap: () => ...)`

- [ ] **Step 1: Write the failing test**

```dart
// test/presentation/watchlist_movie_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/movie_model.dart';
import 'package:screenvault/presentation/common/checkmark_toggle_button.dart';
import 'package:screenvault/presentation/screens/watchlist/widgets/watchlist_movie_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();

  setUp(() async {
    await db.clearActiveUserData();
  });

  testWidgets('WatchlistMovieTile renders title, runtime, rating, and toggles watched', (tester) async {
    bool tapped = false;
    final movie = MovieModel(
      id: 50,
      title: 'Interstellar',
      releaseDate: DateTime(2014, 11, 7),
      runtimeMinutes: 169,
      genres: const ['Sci-Fi', 'Drama'],
      voteAverage: 8.7,
      isFollowed: true,
      isWatched: false,
    );
    await db.upsertMovie(movie);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WatchlistMovieTile(
          movie: movie,
          onTap: () => tapped = true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Interstellar'), findsOneWidget);
    expect(find.textContaining('2014'), findsOneWidget);
    expect(find.textContaining('169 dk'), findsOneWidget);
    expect(find.textContaining('8.7'), findsOneWidget);
    expect(find.text('İzlenecek'), findsOneWidget);

    // Tap card
    await tester.tap(find.text('Interstellar'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);

    // Tap CheckmarkToggleButton to toggle watched
    final checkmark = find.byType(CheckmarkToggleButton);
    expect(checkmark, findsOneWidget);
    await tester.tap(checkmark);
    await tester.pumpAndSettle();

    final updated = db.getMovieById(50);
    expect(updated?.isWatched, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/watchlist_movie_tile_test.dart`
Expected: FAIL (file does not exist).

- [ ] **Step 3: Implement `WatchlistMovieTile`**

Create `lib/presentation/screens/watchlist/widgets/watchlist_movie_tile.dart`:
- Display `CustomPosterImage` with border radius 10.
- Show movie title with `AppTypography.headline3`.
- Subtitle with `${movie.releaseDate?.year ?? ''} • ${movie.runtimeMinutes} dk • ⭐ ${movie.voteAverage.toStringAsFixed(1)}`.
- Genre pill / status pill (`İzlendi ✓` in emerald or `İzlenecek` in gold).
- Right-aligned `CheckmarkToggleButton(isWatched: movie.isWatched, onToggle: (watched) => _dbService.toggleMovieWatched(movie.id, isWatched: watched))`
- Wrap in `InkWell` for `onTap`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/watchlist_movie_tile_test.dart`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/screens/watchlist/widgets/watchlist_movie_tile.dart test/presentation/watchlist_movie_tile_test.dart
git commit -m "feat: implement WatchlistMovieTile with quick checkmark toggle and rich metadata"
```

---

### Task 3: Movie Spotlight Hero Card (`MovieSpotlightCard`)

**Files:**
- Create: `lib/presentation/screens/watchlist/widgets/movie_spotlight_card.dart`
- Create: `test/presentation/movie_spotlight_card_test.dart`

**Interfaces:**
- Consumes: `MovieModel`, `DatabaseService`, `CheckmarkToggleButton`
- Produces: `MovieSpotlightCard(movie: movie, onTap: () => ...)`

- [ ] **Step 1: Write the failing test**

```dart
// test/presentation/movie_spotlight_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/movie_model.dart';
import 'package:screenvault/presentation/screens/watchlist/widgets/movie_spotlight_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();

  setUp(() async {
    await db.clearActiveUserData();
  });

  testWidgets('MovieSpotlightCard displays hero information and handles tap', (tester) async {
    bool tapped = false;
    final movie = MovieModel(
      id: 99,
      title: 'Dune: Part Two',
      runtimeMinutes: 166,
      genres: const ['Sci-Fi', 'Adventure'],
      voteAverage: 8.5,
      isFollowed: true,
      isWatched: false,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MovieSpotlightCard(
          movie: movie,
          onTap: () => tapped = true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('SPOTLIGHT'), findsOneWidget);
    expect(find.text('Dune: Part Two'), findsOneWidget);
    expect(find.textContaining('166 dk'), findsOneWidget);

    await tester.tap(find.text('Dune: Part Two'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/movie_spotlight_card_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `MovieSpotlightCard`**

Create `lib/presentation/screens/watchlist/widgets/movie_spotlight_card.dart`:
- Match `UpNextCard` visual quality:
  - Gradient backdrop overlay, rounded corners (18px), subtle border stroke.
  - Top header: "SPOTLIGHT" label with gold badge, "Next Movie" / "Sıradaki Film" or "Son İzlenen".
  - Large title, runtime, genres, star rating.
  - Integrated `CheckmarkToggleButton` on the card to toggle watched state with instant visual feedback.
  - InkWell tap triggering `onTap`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/movie_spotlight_card_test.dart`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/screens/watchlist/widgets/movie_spotlight_card.dart test/presentation/movie_spotlight_card_test.dart
git commit -m "feat: implement MovieSpotlightCard hero showcase component"
```

---

### Task 4: Movie Detail Screen (`MovieDetailScreen`)

**Files:**
- Create: `lib/presentation/screens/movie_detail/movie_detail_screen.dart`
- Modify: `lib/presentation/screens/discover/discover_screen.dart:147-156`
- Create: `test/presentation/movie_detail_screen_test.dart`

**Interfaces:**
- Consumes: `MovieModel`, `DatabaseService`, `AppColors`, `AppTypography`
- Produces: `MovieDetailScreen(movie: movie)`

- [ ] **Step 1: Write the failing test**

```dart
// test/presentation/movie_detail_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/movie_model.dart';
import 'package:screenvault/presentation/screens/movie_detail/movie_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();

  setUp(() async {
    await db.clearActiveUserData();
  });

  testWidgets('MovieDetailScreen displays overview, toggle watchlist, and toggle watched', (tester) async {
    final movie = MovieModel(
      id: 200,
      title: 'Oppenheimer',
      overview: 'The story of J. Robert Oppenheimer.',
      runtimeMinutes: 180,
      releaseDate: DateTime(2023, 7, 21),
      genres: const ['Biography', 'Drama', 'History'],
      voteAverage: 8.9,
      isFollowed: true,
      isWatched: false,
    );
    await db.upsertMovie(movie);

    await tester.pumpWidget(MaterialApp(
      home: MovieDetailScreen(movie: movie),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Oppenheimer'), findsOneWidget);
    expect(find.text('The story of J. Robert Oppenheimer.'), findsOneWidget);
    expect(find.textContaining('180 dk'), findsOneWidget);
    expect(find.textContaining('8.9'), findsOneWidget);

    // Toggle watched
    final watchedButton = find.text('İzlendi Olarak İşaretle');
    expect(watchedButton, findsOneWidget);
    await tester.tap(watchedButton);
    await tester.pumpAndSettle();

    final updated = db.getMovieById(200);
    expect(updated?.isWatched, isTrue);
    expect(find.text('İzlendi ✓'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/movie_detail_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `MovieDetailScreen` and wire up `DiscoverScreen`**

1. Create `lib/presentation/screens/movie_detail/movie_detail_screen.dart`:
   - Backdrop image with gradient fade into `AppColors.canvasBase`.
   - Back button and action pills.
   - Poster, Title, release year, runtime, genres, TMDB rating.
   - Action buttons:
     - Watchlist Button ("Listemde" / "İzleme Listesine Ekle")
     - Watched Button ("İzlendi ✓" / "İzlendi Olarak İşaretle") with watch date feedback.
   - Synopsis / Overview card.
   - StreamBuilder to listen to live state updates from `_dbService.showsStream`.
2. In `lib/presentation/screens/discover/discover_screen.dart:147-156`:
   - Replace SnackBar with `Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: item)))`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/movie_detail_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/screens/movie_detail/movie_detail_screen.dart lib/presentation/screens/discover/discover_screen.dart test/presentation/movie_detail_screen_test.dart
git commit -m "feat: implement MovieDetailScreen and connect DiscoverScreen movie navigation"
```

---

### Task 5: My Movies Library Screen (`MyMoviesScreen`), Grid Card & Filter Sheet

**Files:**
- Create: `lib/presentation/screens/my_movies/widgets/movie_grid_card.dart`
- Create: `lib/presentation/screens/my_movies/widgets/my_movies_filter_sheet.dart`
- Create: `lib/presentation/screens/my_movies/my_movies_screen.dart`
- Create: `test/presentation/my_movies_screen_test.dart`

**Interfaces:**
- Consumes: `MovieModel`, `DatabaseService`, `WatchlistMovieTile`, `AppColors`
- Produces: `MyMoviesScreen()`

- [ ] **Step 1: Write the failing test**

```dart
// test/presentation/my_movies_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/movie_model.dart';
import 'package:screenvault/presentation/screens/my_movies/my_movies_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();

  setUp(() async {
    await db.clearActiveUserData();
  });

  testWidgets('MyMoviesScreen renders grid and list view with search filter', (tester) async {
    for (int i = 1; i <= 25; i++) {
      await db.upsertMovie(MovieModel(
        id: i,
        title: 'Movie $i',
        isFollowed: true,
        isWatched: i <= 10,
        runtimeMinutes: 100 + i,
        genres: const ['Action'],
      ));
    }

    await tester.pumpWidget(const MaterialApp(
      home: MyMoviesScreen(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Tüm Filmlerim'), findsOneWidget);
    expect(find.textContaining('25 Film'), findsOneWidget);

    // Search filter
    await tester.enterText(find.byType(TextField), 'Movie 12');
    await tester.pumpAndSettle();
    expect(find.text('Movie 12'), findsOneWidget);
    expect(find.text('Movie 13'), findsNothing);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    // Toggle between Grid and List view
    final listToggleIcon = find.byIcon(Icons.view_agenda_rounded);
    expect(listToggleIcon, findsOneWidget);
    await tester.tap(listToggleIcon);
    await tester.pumpAndSettle();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/my_movies_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `MovieGridCard`, `MyMoviesFilterSheet`, and `MyMoviesScreen`**

1. `MovieGridCard`: 3-column grid card with 2:3 aspect ratio, poster, rating badge, watched checkmark, and title.
2. `MyMoviesFilterSheet`: Multi-criteria sorting (Recently added/active, Title, TMDB Rating, Release Date, Runtime) and genre chips.
3. `MyMoviesScreen`:
   - Top App Bar with back button, "Tüm Filmlerim" title, count badge, and Grid/List toggle button.
   - Search bar (by title, genres).
   - Quick status chips ("Tümü", "İzlenecekler", "İzlenenler").
   - Filter & Sort button opening `MyMoviesFilterSheet`.
   - Infinite scroll pagination (20 per page).

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/my_movies_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/screens/my_movies/ test/presentation/my_movies_screen_test.dart
git commit -m "feat: implement MyMoviesScreen library with grid/list toggle, search, and filter sheet"
```

---

### Task 6: Integrate Enhanced Movies Tab in `WatchlistScreen`

**Files:**
- Modify: `lib/presentation/screens/watchlist/watchlist_screen.dart:320-360`
- Create: `test/presentation/watchlist_movies_tab_test.dart`

**Interfaces:**
- Consumes: `MovieSpotlightCard`, `WatchlistMovieTile`, `MyMoviesScreen`, `MovieDetailScreen`, `DatabaseService`

- [ ] **Step 1: Write the failing test**

```dart
// test/presentation/watchlist_movies_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/movie_model.dart';
import 'package:screenvault/presentation/screens/watchlist/watchlist_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();

  setUp(() async {
    await db.clearActiveUserData();
  });

  testWidgets('Watchlist Movies tab displays spotlight, section header, filter chips, and top 10 limit', (tester) async {
    for (int i = 1; i <= 15; i++) {
      await db.upsertMovie(MovieModel(
        id: i,
        title: 'Film $i',
        isFollowed: true,
        isWatched: i <= 5,
        runtimeMinutes: 110,
        genres: const ['Drama'],
      ));
    }

    await tester.pumpWidget(const MaterialApp(home: WatchlistScreen()));
    await tester.pumpAndSettle();

    // Switch to Movies tab
    await tester.tap(find.text('Movies'));
    await tester.pumpAndSettle();

    expect(find.text('SPOTLIGHT'), findsOneWidget);
    expect(find.text('Filmlerim'), findsOneWidget);
    expect(find.text('Tümünü Gör >'), findsOneWidget);

    // Filter chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.text('Watched'), findsOneWidget);

    // Scroll down to check Show More button
    for (int i = 0; i < 4; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('Tüm Filmlerimi Gör'), findsOneWidget);
    expect(find.textContaining('+5 film daha'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/watchlist_movies_tab_test.dart`
Expected: FAIL.

- [ ] **Step 3: Modify `WatchlistScreen` Movies tab**

Update `WatchlistScreen` when `_selectedSegment == 1`:
- Render `MovieSpotlightCard` if `_dbService.getSpotlightMovie()` exists.
- Render Section Header: "Filmlerim", counter `shownCount / totalCount`, and "Tümünü Gör >" (pushes `MyMoviesScreen`).
- Filter Chips: "All", "Watchlist", "Watched" (`_movieFilterCategory`).
- Top 10 movies list using `WatchlistMovieTile` with `onTap` pushing `MovieDetailScreen`.
- Trailing `_buildMovieShowMoreButton` pushing `MyMoviesScreen` when `totalCount > 10`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/watchlist_movies_tab_test.dart`
Expected: PASS

- [ ] **Step 5: Run full test suite & static analysis**

Run: `flutter test`
Run: `flutter analyze`
Expected: All tests pass, 0 errors, 0 warnings.

- [ ] **Step 6: Commit changes**

```bash
git add lib/presentation/screens/watchlist/watchlist_screen.dart test/presentation/watchlist_movies_tab_test.dart
git commit -m "feat: complete integration of enhanced Movies hub in WatchlistScreen"
```

---

### Task 7: Physical Device Verification via ARTEMIS

**Target Device:** Xiaomi Redmi Note 13 Pro+ 5G (`23090RA98G`, Serial: `NBFMGQORPFXK854L`).

- [ ] **Step 1: Check device connection with ADB**
Run: `adb -s NBFMGQORPFXK854L get-state`

- [ ] **Step 2: Build and run the app on device**
Run: `flutter run -d NBFMGQORPFXK854L`

- [ ] **Step 3: Verify with ARTEMIS MCP tools**
Call `mobile_get_device_state` with screenshot to capture proof of:
1. Movies tab on WatchlistScreen with Spotlight card, filter chips, and rich tiles.
2. Tapping a movie tile to open `MovieDetailScreen`.
3. Tapping "Tümünü Gör >" to navigate to `MyMoviesScreen` and toggling grid/list.
