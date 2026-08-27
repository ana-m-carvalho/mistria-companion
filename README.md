# Mistria Item Details

Mistria Item Details adds recipe and gift-preference details to the game's existing item tooltip. Hover an inventory item to see:

- every cooking or crafting recipe that consumes it;
- villagers who like it; and
- villagers who love it.

The data is read from Fields of Mistria's live item, recipe, and NPC tables. This follows the categories documented by [the Fields of Mistria Wiki](https://fieldsofmistria.wiki.gg/) while avoiding a copied, version-sensitive wiki database. New items and balance changes made by game updates are therefore reflected automatically.

## Install with MOMI

- Fields of Mistria for Windows
- [Mods of Mistria Installer (MOMI)](https://github.com/Garethp/Mods-of-Mistria-Installer) version 0.15.5 or newer

1. In the Fields of Mistria game folder, open `mods`.
2. Copy the entire `MistriaItemDetails` folder from this repository into `mods`.
3. Start MOMI. Check **Mistria Item Details**, then select **Install**.
4. Start the game and hover an inventory item.

Press **F7** while an item tooltip is visible, a villager is selected in the Relationships menu, a villager birthday is hovered in the calendar, a quest item is hovered in Quest Details, or a Museum wing is hovered to copy the relevant Fields of Mistria Wiki URL. Paste it into a browser with `Ctrl+V`.

A short **F7: Copy wiki link** hint appears when a new eligible item or NPC is selected.
Press **F8** to toggle those hints for the current game session. This keybind is intentionally not shown in-game yet.

Hover a known NPC marker on the map to reveal that NPC's name.

On an NPC's birthday, a `Birthday: Name` label appears beneath the mana display. It is hidden on days with no birthdays.

When a legendary fish or very rare bug actually spawns in a map you visit, the mod announces its name and location. Press **F6** to replay those sightings from the current day. Active very rare bugs also appear on the map at their nearest map hub and disappear when the bug is gone.

When entering a mine floor, a brief `Mine bugs:` notification lists every bug initially spawned there. Duplicate bugs are shown with a count.

Press **F5** to pause or resume the in-game clock.

The resulting layout must be:

```text
Fields of Mistria\
  mods\
    MistriaItemDetails\
      manifest.json
      gml\
        MistriaItemDetails.gml
```

Do not copy a DLL or nest the `MistriaItemDetails` folder inside another folder. MOMI only detects a mod when `manifest.json` is directly inside a mod folder.
