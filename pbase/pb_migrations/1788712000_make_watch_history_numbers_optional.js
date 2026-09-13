/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const col = app.findCollectionByNameOrId("watch_history");
  if (!col) return;

  const seasonNumberField = col.fields.getByName("seasonNumber");
  if (seasonNumberField) {
    seasonNumberField.required = false;
  }

  const episodeNumberField = col.fields.getByName("episodeNumber");
  if (episodeNumberField) {
    episodeNumberField.required = false;
  }

  app.save(col);
}, (app) => {
  // down migration
});
