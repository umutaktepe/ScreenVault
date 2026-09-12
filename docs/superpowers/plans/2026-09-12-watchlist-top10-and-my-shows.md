# Watchlist Top 10 ve "Tüm Dizilerim" Kütüphane Sayfası Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Anasayfa (Watchlist) karmaşasını önlemek için takip edilen dizileri en son izleme aktivitesine göre sıralayıp ilk 10 diziyle sınırlandırmak; hem bölüm başlığına hem de liste altına "Tümünü Gör" aksiyonu ekleyerek Grid/Liste görünüm geçişli, canlı aramalı, tür/yıl/durum filtrelemeli ve çok kriterli sıralama özellikli yeni "Tüm Dizilerim" kütüphane sayfasını hayata geçirmek.

**Architecture:** 
- `DatabaseService` üzerine `getLastWatchedDateForShow(showId)` ve `getRecentlyActiveFollowedShows({int limit = 10})` metodları eklenerek son izleme aktivitelerine dayalı deterministik sıralama sağlanır.
- `WatchlistScreen` üzerinde dizi listesi ilk 10 öğeyle sınırlandırılır, bölüm başlığına ("Dizilerim") "Tümünü Gör >" bağlantısı ve 10. dizinin altına şık bir "Tüm Dizilerimi Gör (+X Dizi)" buton kartı yerleştirilir.
- Yeni `MyShowsScreen` (`lib/presentation/screens/my_shows/my_shows_screen.dart`), afiş ızgarası (`ShowGridCard`, 3 sütunlu 2:3 en-boy oranlı afişler ve ilerleme çubuğu) ile dikey liste görünümü arasında geçiş imkanı, canlı arama çubuğu, hızlı durum çipleri ve Obsidian Cinema temalı `MyShowsFilterSheet` (türler, yıllar, 7 farklı sıralama kriteri) sunar.

**Tech Stack:** Flutter, Dart, Drift SQLite, Provider/StreamBuilder, ARTEMIS (Fiziksel Cihaz Doğrulaması: Xiaomi Redmi Note 13 Pro+ 5G).

## Global Constraints
- Flutter/Dart terminal komutlarında HER ZAMAN `BypassSandbox: true` kullanılmalıdır.
- Obsidian Cinema OLED teması (`#0E0F12`, `#1A1C23`, `#222631`, `#FED530`, `#22C55E`, `#94A3B8`) ve tasarım tokenlarına eksiksiz uyulmalıdır.
- Canlı UI ve regresyon testleri ARTEMIS MCP araçları ile fiziksel cihazda (`23090RA98G`) yürütülmelidir.
- Statik analizde (`flutter analyze`) 0 hata, 0 uyarı hedeflenmelidir.

---

### Task 1: DatabaseService - Son Aktivite Sıralama Mantığı & Testleri

**Files:**
- Create: `test/database/recent_shows_test.dart`
- Modify: `lib/data/database/database_service.dart:905-920`

**Interfaces:**
- Consumes: `_shows: Map<int, ShowModel>`, `_watchRecords: List<WatchRecordModel>`
- Produces: 
  - `DateTime? getLastWatchedDateForShow(int showId)`
  - `List<ShowModel> getRecentlyActiveFollowedShows({int? limit})`

- [ ] **Step 1: Write the failing test**

```dart
// test/database/recent_shows_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/show_model.dart';
import 'package:screenvault/data/models/watch_record_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();

  setUp(() async {
    await db.clearActiveUserData();
  });

  test('getRecentlyActiveFollowedShows sorts shows by most recent watch activity', () async {
    final show1 = ShowModel(id: 1, name: 'Show A', isFollowed: true, totalEpisodes: 10);
    final show2 = ShowModel(id: 2, name: 'Show B', isFollowed: true, totalEpisodes: 10);
    final show3 = ShowModel(id: 3, name: 'Show C', isFollowed: true, totalEpisodes: 10);
    final showUnfollowed = ShowModel(id: 4, name: 'Show D', isFollowed: false);

    await db.upsertShow(show1);
    await db.upsertShow(show2);
    await db.upsertShow(show3);
    await db.upsertShow(showUnfollowed);

    // Show 2 watched 2 hours ago
    await db.insertWatchRecord(WatchRecordModel(
      id: 101,
      showId: 2,
      seasonNumber: 1,
      episodeNumber: 1,
      watchedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ));

    // Show 1 watched 10 minutes ago (most recent)
    await db.insertWatchRecord(WatchRecordModel(
      id: 102,
      showId: 1,
      seasonNumber: 1,
      episodeNumber: 1,
      watchedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ));

    final recent = db.getRecentlyActiveFollowedShows(limit: 2);
    expect(recent.length, 2);
    expect(recent[0].id, 1, reason: 'Show 1 watched most recently');
    expect(recent[1].id, 2, reason: 'Show 2 watched second most recently');
  });

  test('getRecentlyActiveFollowedShows places unwatched shows after watched ones and respects limit', () async {
    final showWatched = ShowModel(id: 10, name: 'Watched', isFollowed: true);
    final showUnwatched1 = ShowModel(id: 20, name: 'Unwatched 1', isFollowed: true, updatedAt: DateTime(2025, 1, 1));
    final showUnwatched2 = ShowModel(id: 30, name: 'Unwatched 2', isFollowed: true, updatedAt: DateTime(2025, 2, 1));

    await db.upsertShow(showWatched);
    await db.upsertShow(showUnwatched1);
    await db.upsertShow(showUnwatched2);

    await db.insertWatchRecord(WatchRecordModel(
      id: 201,
      showId: 10,
      seasonNumber: 1,
      episodeNumber: 1,
      watchedAt: DateTime.now(),
    ));

    final recent = db.getRecentlyActiveFollowedShows();
    expect(recent.map((s) => s.id).toList(), [10, 30, 20]);

    final limited = db.getRecentlyActiveFollowedShows(limit: 2);
    expect(limited.length, 2);
    expect(limited.map((s) => s.id).toList(), [10, 30]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run command via bash:
```bash
flutter test test/database/recent_shows_test.dart
```
Expected: FAIL with compilation error: "The method 'getRecentlyActiveFollowedShows' isn't defined for the class 'DatabaseService'".

- [ ] **Step 3: Implement getRecentlyActiveFollowedShows in DatabaseService**

In `lib/data/database/database_service.dart`:
```dart
  DateTime? getLastWatchedDateForShow(int showId) {
    DateTime? latest;
    final show = _shows[showId];
    final tvdbId = show?.tvdbId;
    for (final r in _watchRecords) {
      if (r.showId == showId || (tvdbId != null && tvdbId > 0 && r.tvdbId == tvdbId)) {
        if (latest == null || r.watchedAt.isAfter(latest)) {
          latest = r.watchedAt;
        }
      }
    }
    return latest;
  }

  List<ShowModel> getRecentlyActiveFollowedShows({int? limit}) {
    final followed = getFollowedShows();
    followed.sort((a, b) {
      final aDate = getLastWatchedDateForShow(a.id);
      final bDate = getLastWatchedDateForShow(b.id);
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      if (aDate != null) return -1;
      if (bDate != null) return 1;

      // Fallback: updatedAt or createdAt or id desc
      final aUpdated = a.updatedAt ?? a.createdAt;
      final bUpdated = b.updatedAt ?? b.createdAt;
      if (aUpdated != null && bUpdated != null) {
        return bUpdated.compareTo(aUpdated);
      }
      if (aUpdated != null) return -1;
      if (bUpdated != null) return 1;

      return b.id.compareTo(a.id);
    });

    if (limit != null && limit > 0 && followed.length > limit) {
      return followed.sublist(0, limit);
    }
    return followed;
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run command:
```bash
flutter test test/database/recent_shows_test.dart
```
Expected: PASS with all tests green.

- [ ] **Step 5: Commit changes**

```bash
git add lib/data/database/database_service.dart test/database/recent_shows_test.dart
git commit -m "feat(database): add getLastWatchedDateForShow and getRecentlyActiveFollowedShows"
```

---

### Task 2: WatchlistScreen - İlk 10 Dizi Sınırı, Başlık "Tümünü Gör >" ve Alt Buton Kartı

**Files:**
- Modify: `lib/presentation/screens/watchlist/watchlist_screen.dart:160-220`

**Interfaces:**
- Consumes: `DatabaseService.getRecentlyActiveFollowedShows(limit: 10)`, `DatabaseService.getFollowedShows()`
- Produces: 
  - Section Header ("Dizilerim" + Sayaç + "Tümünü Gör >")
  - List bounded to 10 shows
  - Bottom action tile `_buildShowMoreButton(context, totalCount, remainingCount)` navigating to `MyShowsScreen`

- [ ] **Step 1: Write widget test for Watchlist top 10 & navigation buttons**

Create `test/presentation/watchlist_top10_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/show_model.dart';
import 'package:screenvault/presentation/screens/watchlist/watchlist_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();

  testWidgets('Watchlist shows only top 10 items and displays Show More button when > 10', (tester) async {
    await db.clearActiveUserData();
    for (int i = 1; i <= 15; i++) {
      await db.upsertShow(ShowModel(
        id: i,
        name: 'Show $i',
        isFollowed: true,
        totalEpisodes: 10,
        watchedEpisodesCount: i <= 5 ? 2 : 0,
      ));
    }

    await tester.pumpWidget(const MaterialApp(home: WatchlistScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Dizilerim'), findsOneWidget);
    expect(find.text('Tümünü Gör >'), findsOneWidget);
    expect(find.textContaining('Tüm Dizilerimi Gör'), findsOneWidget);
    expect(find.textContaining('+5 dizi daha'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run widget test to verify it fails**

Run: `flutter test test/presentation/watchlist_top10_test.dart`
Expected: FAIL (text "Dizilerim" or "Tümünü Gör >" not found).

- [ ] **Step 3: Update WatchlistScreen implementation**

In `lib/presentation/screens/watchlist/watchlist_screen.dart`:
1. Add section header row right above the filter chips or list:
   - "Dizilerim" (bold 18px), item counter badge (`10 / ${allFollowed.length}`).
   - Right side: `InkWell` with "Tümünü Gör >" (Canary Yellow, font 13px, w700).
   - Tapping pushes `MaterialPageRoute(builder: (context) => const MyShowsScreen())`.
2. Limit the vertical list:
   - Calculate `allFollowed = _dbService.getRecentlyActiveFollowedShows();`
   - Filter by category (`In Progress` / `Completed` / `All`).
   - `final displayedShows = allFollowed.take(10).toList();`
   - Render `displayedShows` in `SliverList`.
3. If `allFollowed.length > 10`:
   - Append a `SliverToBoxAdapter` with `_buildShowMoreButton(context, allFollowed.length, allFollowed.length - 10)`:
     ```dart
     Widget _buildShowMoreButton(BuildContext context, int totalCount, int remainingCount) {
       return Padding(
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
         child: InkWell(
           onTap: () => Navigator.of(context).push(
             MaterialPageRoute(builder: (context) => const MyShowsScreen()),
           ),
           borderRadius: BorderRadius.circular(16),
           child: Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
             decoration: BoxDecoration(
               color: AppColors.cardSurface,
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: AppColors.borderStroke),
             ),
             child: Row(
               children: [
                 Container(
                   padding: const EdgeInsets.all(10),
                   decoration: BoxDecoration(
                     color: AppColors.primaryAccent.withValues(alpha: 0.15),
                     shape: BoxShape.circle,
                   ),
                   child: const Icon(Icons.grid_view_rounded, color: AppColors.primaryAccent, size: 20),
                 ),
                 const SizedBox(width: 14),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text(
                         'Tüm Dizilerimi Gör',
                         style: TextStyle(
                           color: AppColors.textPrimary,
                           fontSize: 15,
                           fontWeight: FontWeight.w700,
                         ),
                       ),
                       const SizedBox(height: 2),
                       Text(
                         '+$remainingCount dizi daha kütüphanenizde',
                         style: const TextStyle(
                           color: AppColors.secondarySlate,
                           fontSize: 12,
                         ),
                       ),
                     ],
                   ),
                 ),
                 const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.secondarySlate, size: 16),
               ],
             ),
           ),
         ),
       );
     }
     ```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/watchlist_top10_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/screens/watchlist/watchlist_screen.dart test/presentation/watchlist_top10_test.dart
git commit -m "feat(watchlist): limit followed shows to top 10 with show more entrypoints"
```

---

### Task 3: ShowGridCard - Afiş Izgarası Bileşeni

**Files:**
- Create: `lib/presentation/screens/my_shows/widgets/show_grid_card.dart`
- Create: `test/presentation/show_grid_card_test.dart`

**Interfaces:**
- Consumes: `ShowModel`, `VoidCallback onTap`
- Produces: 3-column responsive 2:3 aspect-ratio poster card with progress indicator, title, and status pill

- [ ] **Step 1: Write widget test for ShowGridCard**

```dart
// test/presentation/show_grid_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/models/show_model.dart';
import 'package:screenvault/presentation/screens/my_shows/widgets/show_grid_card.dart';

void main() {
  testWidgets('ShowGridCard renders show name, progress bar, and triggers onTap', (tester) async {
    bool tapped = false;
    final show = ShowModel(
      id: 1,
      name: 'Severance',
      firstAirDate: DateTime(2022, 2, 18),
      totalEpisodes: 10,
      watchedEpisodesCount: 6,
      posterPath: '/path.jpg',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ShowGridCard(
          show: show,
          onTap: () => tapped = true,
        ),
      ),
    ));

    expect(find.text('Severance'), findsOneWidget);
    expect(find.text('6/10'), findsOneWidget);

    await tester.tap(find.byType(ShowGridCard));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/show_grid_card_test.dart`
Expected: FAIL (ShowGridCard not found).

- [ ] **Step 3: Implement ShowGridCard**

Implement `lib/presentation/screens/my_shows/widgets/show_grid_card.dart`:
- Rounded 12px card with `AppColors.cardSurface` and border `AppColors.borderStroke`.
- 2:3 Aspect ratio container with cached image or placeholder cinema icon.
- Progress bar stacked at the bottom of the poster image (Canary Yellow if in progress, Emerald Green if completed).
- Below poster: show name (max 1 line, overflow ellipsis, 13px w600), year / episode count (`6/10` or `100%`).
- Tap feedback with `InkWell`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/show_grid_card_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/screens/my_shows/widgets/show_grid_card.dart test/presentation/show_grid_card_test.dart
git commit -m "feat(my_shows): implement ShowGridCard component with progress overlay"
```

---

### Task 4: MyShowsFilterSheet - Gelişmiş Filtreleme ve Sıralama Modalı

**Files:**
- Create: `lib/presentation/screens/my_shows/widgets/my_shows_filter_sheet.dart`
- Create: `test/presentation/my_shows_filter_sheet_test.dart`

**Interfaces:**
- Consumes:
  - `availableGenres: List<String>`
  - `availableYears: List<int>`
  - Current filter values: `selectedGenres`, `selectedYear`, `sortOption`
- Produces:
  - Returns `MyShowsFilterResult` on "Uygula" tap: `selectedGenres`, `selectedYear`, `sortOption`.
  - Supports "Filtreleri Sıfırla".

- [ ] **Step 1: Write test for MyShowsFilterSheet**

```dart
// test/presentation/my_shows_filter_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/presentation/screens/my_shows/widgets/my_shows_filter_sheet.dart';

void main() {
  testWidgets('MyShowsFilterSheet allows selecting sort option, genres, and applying', (tester) async {
    MyShowsFilterResult? result;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showModalBottomSheet<MyShowsFilterResult>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const MyShowsFilterSheet(
                  availableGenres: ['Drama', 'Sci-Fi', 'Comedy'],
                  availableYears: [2024, 2023, 2022],
                  currentSort: ShowSortOption.recentlyActive,
                  currentGenres: {'Drama'},
                  currentYear: 2024,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Filtrele ve Sırala'), findsOneWidget);
    expect(find.text('Sıralama Ölçütü'), findsOneWidget);
    expect(find.text('Türler'), findsOneWidget);

    // Tap Sci-Fi chip
    await tester.tap(find.text('Sci-Fi'));
    await tester.pumpAndSettle();

    // Tap Uygula
    await tester.tap(find.text('Uygula'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.genres.contains('Sci-Fi'), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/my_shows_filter_sheet_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement MyShowsFilterSheet**

In `lib/presentation/screens/my_shows/widgets/my_shows_filter_sheet.dart`:
- Define `enum ShowSortOption`:
  - `recentlyActive` ('En Son İzlenen')
  - `nameAsc` ('İsim (A-Z)')
  - `nameDesc` ('İsim (Z-A)')
  - `ratingDesc` ('TMDB Puanı (Yüksek)')
  - `yearDesc` ('Yıl (Yeni-Eski)')
  - `yearAsc` ('Yıl (Eski-Yeni)')
  - `progressDesc` ('İlerleme Durumu (%)')
- Class `MyShowsFilterResult`:
  - `final ShowSortOption sortOption;`
  - `final Set<String> genres;`
  - `final int? year;`
- Modal UI:
  - Drag handle + Title Row with "Filtrele ve Sırala" + "Sıfırla" text button.
  - Radio/Choice chips for `ShowSortOption`.
  - Filter chips wrap for `availableGenres`.
  - Dropdown / chip row for `availableYears`.
  - Bottom sticky Canary Yellow "Uygula" button.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/my_shows_filter_sheet_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/screens/my_shows/widgets/my_shows_filter_sheet.dart test/presentation/my_shows_filter_sheet_test.dart
git commit -m "feat(my_shows): implement advanced filter and sort bottom sheet modal"
```

---

### Task 5: MyShowsScreen - "Tüm Dizilerim" Kütüphane Sayfası

**Files:**
- Create: `lib/presentation/screens/my_shows/my_shows_screen.dart`
- Create: `test/presentation/my_shows_screen_test.dart`
- Modify: `lib/presentation/screens/watchlist/watchlist_screen.dart` (ensure navigation routes to `MyShowsScreen`)

**Interfaces:**
- Consumes:
  - `DatabaseService.showsStream`
  - `DatabaseService.getFollowedShows()`
  - `ShowGridCard`, `WatchlistItemTile`, `MyShowsFilterSheet`
- Produces:
  - Full dedicated library screen with live search, status chips, grid/list toggle, advanced filters, empty states.

- [ ] **Step 1: Write widget test for MyShowsScreen**

```dart
// test/presentation/my_shows_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenvault/data/database/database_service.dart';
import 'package:screenvault/data/models/show_model.dart';
import 'package:screenvault/presentation/screens/my_shows/my_shows_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService();

  testWidgets('MyShowsScreen searches shows and toggles grid/list view', (tester) async {
    await db.clearActiveUserData();
    await db.upsertShow(ShowModel(
      id: 1,
      name: 'Breaking Bad',
      isFollowed: true,
      genres: ['Drama', 'Crime'],
      firstAirDate: DateTime(2008, 1, 20),
    ));
    await db.upsertShow(ShowModel(
      id: 2,
      name: 'Better Call Saul',
      isFollowed: true,
      genres: ['Drama'],
      firstAirDate: DateTime(2015, 2, 8),
    ));

    await tester.pumpWidget(const MaterialApp(home: MyShowsScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tüm Dizilerim'), findsOneWidget);
    expect(find.text('Breaking Bad'), findsOneWidget);
    expect(find.text('Better Call Saul'), findsOneWidget);

    // Search 'Better'
    await tester.enterText(find.byType(TextField), 'Better');
    await tester.pumpAndSettle();

    expect(find.text('Better Call Saul'), findsOneWidget);
    expect(find.text('Breaking Bad'), findsNothing);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Breaking Bad'), findsOneWidget);

    // Toggle view mode icon
    final viewToggleIcon = find.byIcon(Icons.view_list_rounded);
    expect(viewToggleIcon, findsOneWidget);
    await tester.tap(viewToggleIcon);
    await tester.pumpAndSettle();

    // Now icon changes to grid_view_rounded
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/my_shows_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement MyShowsScreen**

In `lib/presentation/screens/my_shows/my_shows_screen.dart`:
- Build `CustomScrollView` with:
  - App Bar:
    - Back button.
    - Title: "Tüm Dizilerim" + show count badge `(X)`.
    - Action 1: Grid/List view toggle icon (`Icons.grid_view_rounded` <-> `Icons.view_list_rounded`).
    - Action 2: Filter/Sort action button with active badge dot (`Icons.tune_rounded`).
  - Sticky search bar with Cupertino/Obsidian styling.
  - Horizontal quick status filter chips: `Tümü`, `Devam Eden`, `Tamamlanan`, `Başlanmayan`.
  - Reactive show list computation:
    1. Filter by `isFollowed == true`.
    2. Filter by search query (case-insensitive on name & originalName).
    3. Filter by quick status (progress).
    4. Filter by selected genres (intersection).
    5. Filter by selected release year.
    6. Sort according to `ShowSortOption`.
  - Body:
    - If `_isGridView`: `SliverPadding` with `SliverGrid(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.58, ...), ...)`.
    - If `!_isGridView`: `SliverList` with `WatchlistItemTile`.
    - If filtered list is empty: cinematic empty state with "Filtreleri Temizle" button.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/my_shows_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit changes**

```bash
git add lib/presentation/screens/my_shows/my_shows_screen.dart test/presentation/my_shows_screen_test.dart
git commit -m "feat(my_shows): implement full MyShowsScreen with search, filters, and grid/list view"
```

---

### Task 6: Statik Analiz & ARTEMIS Fiziksel Cihaz Doğrulaması

**Files:**
- All touched files

**Verification:**
- Static analysis: `flutter analyze`
- ARTEMIS Physical Device Testing on Xiaomi Redmi Note 13 Pro+ 5G (`23090RA98G`, Serial: `NBFMGQORPFXK854L`):
  - Launch app.
  - Verify Watchlist shows top 10 limit with "Dizilerim" header and "Tümünü Gör >" button.
  - Verify "Tüm Dizilerimi Gör" bottom card.
  - Tap button to navigate to `MyShowsScreen`.
  - Verify 3-column Grid View posters.
  - Toggle to List View.
  - Test live search input.
  - Open Filter/Sort sheet, select a sort order or genre, apply and verify.

- [ ] **Step 1: Run static analysis**

Run: `flutter analyze`
Expected: 0 issues found.

- [ ] **Step 2: Run all unit & widget tests**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 3: Run ARTEMIS automated test on physical device**

Execute `artemis` MCP tool `mobile_run_task`:
- Target: `23090RA98G`
- Goal: "Screen Vault uygulamasını aç, anasayfada (Watchlist) 'Dizilerim' başlığını ve 'Tümünü Gör' butonunu doğrula. 'Tümünü Gör' butonuna tıkla, açılan 'Tüm Dizilerim' ekranında afiş ızgarasını (Grid View) kontrol et. Sağ üstteki görünüm butonuna basarak Liste görünümüne geç ve arama kutusuna dizi ismi yazarak filtrelemeyi doğrula."
- Verify trace and screenshots.

- [ ] **Step 4: Final commit & Walkthrough documentation**

```bash
git add -A
git commit -m "feat: complete top 10 watchlist limit and My Shows library screen"
```
