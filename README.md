# Mistria Companion

Mistria Companion adds item information and quality-of-life tools to Fields of Mistria while reading directly from the game's current data.

## Features

- Shows every cooking or crafting recipe that consumes a hovered item.
- Lists villagers who like or love a hovered item.
- Adds a chest button that grabs one loved gift for each met villager who has not received a gift that day, prioritizing birthdays and available backpack space.
- Copies relevant Fields of Mistria Wiki links for items, villagers, calendar birthdays, quest objectives, Museum wings, and map markers.
- Shows villager names when hovering known NPC map markers.
- Displays today's birthdays below the mana meter.
- Announces legendary fish and very rare bug spawns.
- Marks active bugs at the nearest map hub, with ordinary bugs available on demand.
- Announces active dig spots when entering a location or mine floor and marks their general areas at the nearest map hubs.
- Lists bugs initially spawned on each newly entered mine floor.
- Pauses and resumes the in-game clock without pausing gameplay.

The mod uses the live item, recipe, NPC, fish, bug, calendar, and map data shipped with the installed game. It does not bundle game or wiki assets.

## Requirements

- Fields of Mistria for Windows
- [Mods of Mistria Installer (MOMI)](https://github.com/Garethp/Mods-of-Mistria-Installer) 0.15.5 or newer

## Installation

1. Download the release ZIP and extract it.
2. Copy the `MistriaCompanion` folder into the game's `mods` folder.
3. Start MOMI, select **Mistria Companion**, and choose **Install**.
4. Launch Fields of Mistria.

The installed layout should be:

```text
Fields of Mistria\
  mods\
    MistriaCompanion\
      manifest.json
      gml\
        MistriaCompanion.gml
```

Do not copy a DLL or add an extra folder level. MOMI detects the mod only when `manifest.json` is directly inside the mod folder.

If upgrading from Mistria Item Details, remove the old `MistriaItemDetails` folder before installing Mistria Companion. The internal mod ID remains unchanged for compatibility.

## Controls

| Key | Action |
| --- | --- |
| **F5** | Pause or resume the in-game clock. |
| **F6** | Replay legendary fish and very rare bug sightings from the current day. |
| **F7** | Copy the relevant Fields of Mistria Wiki URL while supported content is selected or hovered. |
| **F8** | Toggle the compact `F7 Wiki` hints for the current session. |
| **F9** | Toggle ordinary bug map markers in the current area. |

Paste copied wiki links into a browser with `Ctrl+V`.

When a regular chest is open, use the gift button above its inventory to collect
one loved gift per eligible villager from that chest. The picker prioritizes
today's birthdays, accounts for overlapping preferences and duplicate items, and
makes a capacity-efficient selection for the available backpack space. It does
not mark a villager as gifted until the gift is actually given.

## Spawn information

Legendary fish and very rare bugs are announced only after they actually spawn in a map you visit. Active very rare bugs are always shown at their nearest map hub rather than their exact world position. Press **F9** to also show or hide every other active bug in the current area for the rest of the session.

Active dig spots are counted once after each location or mine floor finishes loading. Opening the corresponding map groups the spots at their nearest map hubs; hover a dig marker to see how many active spots are in that general area.

On entering a newly generated mine floor, a compact `Mine bugs:` notification lists the bugs initially present. Duplicate species include a count.

## Known limitations

- The game runtime cannot open web links directly, so F7 copies links to the clipboard.
- Dig markers show approximate areas and do not reveal exact coordinates or predict what a spot contains.
- Quest Details wiki detection depends on the active objective data exposed by the game and may not recognize every objective layout.
- Mine bug summaries include only bugs present when the floor finishes loading; bugs revealed later from rocks or other interactions are not included.

## License

Mistria Companion is available under the [MIT License](LICENSE).
