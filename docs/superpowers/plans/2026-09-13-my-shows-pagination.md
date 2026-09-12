# MyShows Screen 20-Item Infinite Scroll & End-of-List Indicator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement 20-item infinite scroll pagination on `MyShowsScreen` with automatic loading on scroll threshold and a minimalist cinema-styled end-of-list indicator.

**Architecture:** `MyShowsScreen` maintains a dynamic `_displayedCount` initialized to 20. A `ScrollController` listener checks if the user scrolled within 300px of `maxScrollExtent` and increments `_displayedCount` by 20. When search or filters change, `_displayedCount` resets to 20. When all items in the filtered list are displayed, a minimalist divider with film/check icon and item count is rendered at the bottom.

**Tech Stack:** Flutter, Dart, Drift SQLite, ARTEMIS Mobile Automation.

**Spec:** User interview via `/grill-me` (20 items initial batch, automatic infinite scroll with 300px threshold, auto-reset on search/filter, minimalist divider line with icon at end of list).

## Global Constraints
- All Flutter and Dart commands must be run with `BypassSandbox: true`.
- Zero compiler errors, zero analyzer warnings (`flutter analyze`).
- Theme colors and tokens must match Obsidian Cinema (`AppColors.cardSurface`, `AppColors.borderStroke`, `AppColors.secondarySlate`, `AppColors.textPrimary`).
- Full test coverage for pagination behavior and end-of-list indicator.

---

### Task 1: Add Pagination State & Auto-Loading ScrollController to MyShowsScreen

**Files:**
- Modify: `lib/presentation/screens/my_shows/my_shows_screen.dart:20-150`
- Test: `test/presentation/my_shows_screen_test.dart:1-120`

**Interfaces:**
- Consumes: `_dbService.getFollowedShows()`, `_filterAndSortShows()`
- Produces: `_displayedCount` clamped to `filteredShows.length`, slice of `filteredShows.take(_displayedCount).toList()`, `_resetPagination()`

- [ ] **Step 1: Write failing pagination test in `test/presentation/my_shows_screen_test.dart`**

```dart
  testWidgets('MyShowsScreen paginates items in batches of 20 and loads more on scroll', (tester) async {
    for (int i = 1; i <= 35; i++) {
      await db.upsertShow(ShowModel(
        id: i,
        name: 'Dizi $i',
        isFollowed: true,
        totalEpisodes: 10,
        watchedEpisodesCount: 2,
      ));
    }

    await tester.pumpWidget(const MaterialApp(home: MyShowsScreen()));
    await tester.pumpAndSettle();

    // Only first 20 items should be rendered initially
    expect(find.text('Dizi 1'), findsOneWidget);
    expect(find.text('Dizi 20'), findsOneWidget);
    expect(find.text('Dizi 25'), findsNothing);

    // Scroll down towards bottom
    final scrollable = find.byType(CustomScrollView);
    await tester.drag(scrollable, const Offset(0, -1200));
    await tester.pumpAndSettle();

    // Now remaining items should be loaded
    expect(find.text('Dizi 25'), findsOneWidget);
    expect(find.text('Dizi 35'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/presentation/my_shows_screen_test.dart`
Expected: FAIL (because all 35 shows are currently rendered without pagination)

- [ ] **Step 3: Implement pagination state and ScrollController listener**

In `lib/presentation/screens/my_shows/my_shows_screen.dart`:
```dart
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  int _displayedCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      final text = _searchController.text.trim();
      if (text != _searchQuery) {
        setState(() {
          _searchQuery = text;
          _displayedCount = _pageSize;
        });
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 300) {
      if (_displayedCount < _totalFilteredCount) {
        setState(() {
          _displayedCount = (_displayedCount + _pageSize).clamp(0, _totalFilteredCount);
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
```
In `CustomScrollView`:
Attach `controller: _scrollController`.
Use `final paginatedShows = filteredShows.take(_displayedCount).toList();` for `SliverGrid` and `SliverList`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/my_shows_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/my_shows/my_shows_screen.dart test/presentation/my_shows_screen_test.dart
git commit -m "feat(my_shows): implement 20-item infinite scroll pagination with auto-load"
```

---

### Task 2: Implement Minimalist End-of-List Indicator Component

**Files:**
- Modify: `lib/presentation/screens/my_shows/my_shows_screen.dart:450-550`
- Test: `test/presentation/my_shows_screen_test.dart:120-180`

**Interfaces:**
- Consumes: `filteredShows.length`, `_displayedCount >= filteredShows.length`
- Produces: `_buildEndOfListIndicator(int totalCount)` widget sliver

- [ ] **Step 1: Write failing test for End-of-List indicator**

```dart
  testWidgets('MyShowsScreen shows minimalist end-of-list indicator when all items are loaded', (tester) async {
    for (int i = 1; i <= 5; i++) {
      await db.upsertShow(ShowModel(
        id: i,
        name: 'Dizi $i',
        isFollowed: true,
      ));
    }

    await tester.pumpWidget(const MaterialApp(home: MyShowsScreen()));
    await tester.pumpAndSettle();

    // Since total <= 20, all items are loaded and end-of-list indicator is shown
    expect(find.textContaining('Tüm 5 dizi listelendi'), findsOneWidget);
    expect(find.byIcon(Icons.movie_filter_outlined), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify failure**

Run: `flutter test test/presentation/my_shows_screen_test.dart`
Expected: FAIL with "Nothing found matching 'Tüm 5 dizi listelendi'"

- [ ] **Step 3: Implement `_buildEndOfListIndicator` widget in `MyShowsScreen`**

In `lib/presentation/screens/my_shows/my_shows_screen.dart`:
```dart
  Widget _buildEndOfListIndicator(int totalCount) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Row(
          children: [
            Expanded(
              child: Divider(
                color: AppColors.borderStroke.withValues(alpha: 0.6),
                thickness: 0.8,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.movie_filter_outlined,
                    size: 14,
                    color: AppColors.secondarySlate,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tüm $totalCount dizi listelendi',
                    style: const TextStyle(
                      color: AppColors.secondarySlate,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Divider(
                color: AppColors.borderStroke.withValues(alpha: 0.6),
                thickness: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
```
Add `if (paginatedShows.isNotEmpty && _displayedCount >= filteredShows.length) _buildEndOfListIndicator(filteredShows.length)` at the bottom of `CustomScrollView.slivers`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/my_shows_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/screens/my_shows/my_shows_screen.dart test/presentation/my_shows_screen_test.dart
git commit -m "feat(my_shows): add minimalist end-of-list indicator with divider and icon"
```

---

### Task 3: Physical Device Verification with ARTEMIS

**Files:**
- Test on Device: `Xiaomi Redmi Note 13 Pro+ 5G` (`NBFMGQORPFXK854L`)

- [ ] **Step 1: Static analysis and full suite check**

Run: `flutter analyze` & `flutter test` (BypassSandbox: true)
Expected: 0 errors, all tests pass.

- [ ] **Step 2: Build and deploy debug APK to device**

Run:
```bash
flutter build apk --debug
adb -s NBFMGQORPFXK854L install -r build/app/outputs/flutter-apk/app-debug.apk
```

- [ ] **Step 3: Run ARTEMIS test to verify 20-item loading and end indicator**

Run:
ARTEMIS task to navigate to `MyShowsScreen`, observe initial 20 items, scroll down to bottom, and capture screenshot of the end-of-list indicator.
Expected: PASS with photographic verification.

- [ ] **Step 4: Commit and push**

```bash
git push origin feat/watchlist-top10-and-my-shows
```
