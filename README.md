# Ultracube on Factoriopedia

A Factorio 2.0 mod that restores Factoriopedia entries for prototypes reachable
on the [Ultracube](https://mods.factorio.com/mod/Ultracube) progression route.

For the player-facing description (what the mod does, settings, compatibility,
uninstalling), see [mod-portal.md](mod-portal.md). This README covers the
implementation.

## How it works

- **Selective un-hide.** Classifies every technology as Ultracube-route (`CUBE`)
  or not by looking at science pack ingredients and prerequisite chains. From
  the `CUBE` set it walks `tech.effects → recipe → ingredients/results →
  item/fluid → place_result/place_as_tile → entity/tile`, plus initially-enabled
  recipes and resource entities whose drops are reachable. Anything in that
  reachable set has `hidden_in_factoriopedia` cleared; everything else stays
  hidden. Prototypes flagged `hidden = true` (Ultracube's internal dummies) are
  left alone.
- **Recipe/item page merge.** A single-result recipe whose name differs from
  its result is paired with that item or fluid via a "shadow recipe" so
  Factorio's name-based merge kicks in. Multi-result recipes get a
  `main_product` hint when one of the results matches the recipe name.
- **Manual overrides.** [`manual_unhides.lua`](manual_unhides.lua) and
  [`manual_merges.lua`](manual_merges.lua) patch cases the automatic logic
  cannot resolve.

## Source layout

- [`data-final-fixes.lua`](data-final-fixes.lua) — entry point and pipeline
  driver: optional rename → tech classification → reachability → un-hide loop →
  recipe merge. Runs in the final-fixes stage so Ultracube has already applied
  its hides before this mod looks at them.
- [`trace_technologies.lua`](trace_technologies.lua) — `CUBE` / `OTHER`
  classification.
- [`trace_reachable.lua`](trace_reachable.lua) — BFS over recipes / items /
  fluids / entities / tiles.
- [`merge_recipes.lua`](merge_recipes.lua) — shadow recipe / existing-recipe
  override logic.
- [`rename_recipes.lua`](rename_recipes.lua), [`migrations/`](migrations/) —
  optional recipe rename and its save migration.
- [`debug_log.lua`](debug_log.lua) — no-op outside the FMTK debug adapter so
  release builds stay quiet.

## Debugging

The mod logs under `[fp:utc-tech]`, `[fp:reach]`, `[fp:unhide]`, `[fp:merge]`,
and `[fp:rename]` prefixes when run under the FMTK debug adapter. Each module
emits a summary line at the end, so the easiest way to investigate odd
behaviour is to launch with the debug adapter, reproduce, and `grep` the
Factorio log.

## License

MIT — see [LICENSE](LICENSE).
