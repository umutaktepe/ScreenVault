/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collections = ["comments", "episode_reactions", "watch_history", "movie_watch_history", "tracked_shows"];

  for (const name of collections) {
    const col = app.findCollectionByNameOrId(name);
    if (!col) continue;

    let hasCreated = false;
    let hasUpdated = false;
    for (const f of col.fields) {
      if (f.name === "created") hasCreated = true;
      if (f.name === "updated") hasUpdated = true;
    }

    if (!hasCreated) {
      col.fields.add(new AutodateField({
        name: "created",
        onCreate: true,
        onUpdate: false,
      }));
    }

    if (!hasUpdated) {
      col.fields.add(new AutodateField({
        name: "updated",
        onCreate: true,
        onUpdate: true,
      }));
    }

    if (name === "comments" || name === "episode_reactions") {
      col.listRule = "";
      col.viewRule = "";
    }

    app.save(col);
  }
}, (app) => {
  // down migration
});
