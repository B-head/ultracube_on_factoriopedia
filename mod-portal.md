[Ultracube](https://mods.factorio.com/mod/Ultracube) hides most of Factoriopedia
because it rewrites large parts of the base game. This mod brings the
encyclopedia back — but only for things that actually belong to the Ultracube
progression route. Unused vanilla recipes, items, and entities stay hidden so
the encyclopedia is not flooded with noise.

It also cleans up the duplicate pages Ultracube tends to leave behind: when a
recipe and its result item are listed as separate Factoriopedia entries even
though they belong together, this mod merges them into a single page.

## What you get

- Factoriopedia entries restored for recipes, items, fluids, machines, and
  technologies that you can actually research and craft along the Ultracube
  route.
- Recipe pages folded into their item/fluid pages when they match, so each
  thing shows up in one place.
- Internal dummy items (the ones Ultracube keeps fully hidden on purpose) are
  left alone.

## Settings

**Rename refined rare metals conversion recipe** (startup, on by default).
Ultracube has a recipe whose name collides with the refined rare metals item,
preventing a clean Factoriopedia merge. The setting renames that recipe to
`cube-refined-rare-metals-conversion` and ships a save migration. Turn it off
only if another mod references the recipe by its original name.

## Compatibility

Requires Ultracube 0.7.0+ and base 2.0.8+. This mod only touches
`hidden_in_factoriopedia` flags, recipe `main_product` hints, and the one
optional recipe rename — no gameplay numbers, no balance changes.

## Uninstalling

Removing this mod will show a warning that several recipes will be deleted.
Those are dummy recipes created purely to drive Factoriopedia's page merging —
they cannot be researched or crafted and have no gameplay effect. You can
disable the mod and continue an existing save normally.
