/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  // 1. tracked_shows
  const trackedShows = new Collection({
    name: "tracked_shows",
    type: "base",
    listRule: "@request.auth.id != '' && user = @request.auth.id",
    viewRule: "@request.auth.id != '' && user = @request.auth.id",
    createRule: "@request.auth.id != '' && user = @request.auth.id",
    updateRule: "@request.auth.id != '' && user = @request.auth.id",
    deleteRule: "@request.auth.id != '' && user = @request.auth.id",
  });
  trackedShows.fields.add(
    new RelationField({ name: "user", required: true, collectionId: "_pb_users_auth_", cascadeDelete: true, maxSelect: 1 }),
    new NumberField({ name: "showId", required: true }),
    new NumberField({ name: "tvdbId", required: false }),
    new NumberField({ name: "tmdbId", required: false }),
    new TextField({ name: "title", required: true }),
    new TextField({ name: "posterPath", required: false }),
    new TextField({ name: "status", required: false }),
    new BoolField({ name: "isFavorite", required: false }),
  );
  app.save(trackedShows);

  // 2. watch_history
  const watchHistory = new Collection({
    name: "watch_history",
    type: "base",
    listRule: "@request.auth.id != '' && user = @request.auth.id",
    viewRule: "@request.auth.id != '' && user = @request.auth.id",
    createRule: "@request.auth.id != '' && user = @request.auth.id",
    updateRule: "@request.auth.id != '' && user = @request.auth.id",
    deleteRule: "@request.auth.id != '' && user = @request.auth.id",
  });
  watchHistory.fields.add(
    new RelationField({ name: "user", required: true, collectionId: "_pb_users_auth_", cascadeDelete: true, maxSelect: 1 }),
    new NumberField({ name: "showId", required: true }),
    new NumberField({ name: "tvdbId", required: false }),
    new NumberField({ name: "tmdbId", required: false }),
    new NumberField({ name: "seasonNumber", required: true }),
    new NumberField({ name: "episodeNumber", required: true }),
    new TextField({ name: "episodeTitle", required: false }),
    new NumberField({ name: "runtimeMinutes", required: false }),
    new BoolField({ name: "isWatched", required: false }),
    new NumberField({ name: "rewatchCount", required: false }),
    new DateField({ name: "watchedAt", required: false }),
  );
  app.save(watchHistory);

  // 3. movie_watch_history
  const movieWatchHistory = new Collection({
    name: "movie_watch_history",
    type: "base",
    listRule: "@request.auth.id != '' && user = @request.auth.id",
    viewRule: "@request.auth.id != '' && user = @request.auth.id",
    createRule: "@request.auth.id != '' && user = @request.auth.id",
    updateRule: "@request.auth.id != '' && user = @request.auth.id",
    deleteRule: "@request.auth.id != '' && user = @request.auth.id",
  });
  movieWatchHistory.fields.add(
    new RelationField({ name: "user", required: true, collectionId: "_pb_users_auth_", cascadeDelete: true, maxSelect: 1 }),
    new NumberField({ name: "movieId", required: true }),
    new NumberField({ name: "tmdbId", required: false }),
    new TextField({ name: "title", required: true }),
    new TextField({ name: "posterPath", required: false }),
    new NumberField({ name: "runtimeMinutes", required: false }),
    new BoolField({ name: "isWatched", required: false }),
    new DateField({ name: "watchedAt", required: false }),
  );
  app.save(movieWatchHistory);

  // 4. comments
  const comments = new Collection({
    name: "comments",
    type: "base",
    listRule: "@request.auth.id != ''",
    viewRule: "@request.auth.id != ''",
    createRule: "@request.auth.id != '' && user = @request.auth.id",
    updateRule: "@request.auth.id != '' && user = @request.auth.id",
    deleteRule: "@request.auth.id != '' && user = @request.auth.id",
  });
  comments.fields.add(
    new RelationField({ name: "user", required: true, collectionId: "_pb_users_auth_", cascadeDelete: true, maxSelect: 1 }),
    new TextField({ name: "userName", required: true }),
    new TextField({ name: "userAvatar", required: false }),
    new TextField({ name: "showTitle", required: true }),
    new TextField({ name: "episodeCode", required: false }),
    new NumberField({ name: "showId", required: true }),
    new NumberField({ name: "seasonNumber", required: false }),
    new NumberField({ name: "episodeNumber", required: false }),
    new TextField({ name: "content", required: true }),
    new BoolField({ name: "isSpoiler", required: false }),
    new TextField({ name: "emotion", required: false }),
    new NumberField({ name: "likesCount", required: false }),
  );
  app.save(comments);

  // 5. episode_reactions
  const episodeReactions = new Collection({
    name: "episode_reactions",
    type: "base",
    listRule: "@request.auth.id != ''",
    viewRule: "@request.auth.id != ''",
    createRule: "@request.auth.id != '' && user = @request.auth.id",
    updateRule: "@request.auth.id != '' && user = @request.auth.id",
    deleteRule: "@request.auth.id != '' && user = @request.auth.id",
  });
  episodeReactions.fields.add(
    new RelationField({ name: "user", required: true, collectionId: "_pb_users_auth_", cascadeDelete: true, maxSelect: 1 }),
    new NumberField({ name: "showId", required: true }),
    new NumberField({ name: "seasonNumber", required: true }),
    new NumberField({ name: "episodeNumber", required: true }),
    new TextField({ name: "emotion", required: false }),
    new TextField({ name: "mvpCharacter", required: false }),
  );
  app.save(episodeReactions);
}, (app) => {
  const names = ["episode_reactions", "comments", "movie_watch_history", "watch_history", "tracked_shows"];
  for (const name of names) {
    try {
      const c = app.findCollectionByNameOrId(name);
      app.delete(c);
    } catch (_) {}
  }
});
