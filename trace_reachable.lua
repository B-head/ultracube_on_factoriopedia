-- CUBE tech を起点にして、Ultracube 進行ルートで「触れる」prototype 集合を計算する。
--
-- 波及ルール:
--   tech.effects (unlock-recipe)  -> recipe
--   recipe.ingredients / .results -> item, fluid
--   item.place_result              -> entity
--   item.place_as_tile.result      -> tile
--   item.burnt_result              -> item
--   resource.minable -> 出力が reached item に含まれる -> entity (resource)
--
-- 固定点まで反復して BFS 的に拡張する。

local M = {}

local function name_of(entry)
  -- ingredient/result: {type=..., name=..., amount=...} または {"name", count}
  return entry.name or entry[1]
end

local function type_of(entry)
  return entry.type or "item"
end

local function add(set, name)
  if not name or set[name] then return false end
  set[name] = true
  return true
end

-- item 名から prototype を引くインデックスを構築 (item サブタイプ横断)
local function build_item_index()
  local idx = {}
  for t in pairs(defines.prototypes.item) do
    if data.raw[t] then
      for n, p in pairs(data.raw[t]) do
        idx[n] = p
      end
    end
  end
  return idx
end

-- 結果セットを計算する。返り値: {category -> {name -> true}}
function M.compute()
  local cube_techs = require("trace_technologies").cube_techs()
  local item_index = build_item_index()

  local reachable = {
    technology = {}, recipe = {}, item = {}, fluid = {},
    entity = {}, tile = {},
  }

  -- Seed: CUBE tech とその unlock-recipe
  for name in pairs(cube_techs) do
    reachable.technology[name] = true
    local tech = data.raw.technology[name]
    if tech and tech.effects then
      for _, effect in ipairs(tech.effects) do
        if effect.type == "unlock-recipe" and effect.recipe then
          reachable.recipe[effect.recipe] = true
        end
      end
    end
  end

  -- 反復拡張
  local changed = true
  while changed do
    changed = false

    -- recipe -> item / fluid (ingredients + results)
    for rname in pairs(reachable.recipe) do
      local recipe = data.raw.recipe and data.raw.recipe[rname]
      if recipe then
        local function process(pile)
          if not pile then return end
          for _, e in ipairs(pile) do
            local n = name_of(e)
            local t = type_of(e)
            if t == "fluid" then
              if add(reachable.fluid, n) then changed = true end
            elseif t == "item" then
              if add(reachable.item, n) then changed = true end
            end
          end
        end
        process(recipe.ingredients)
        process(recipe.results)
      end
    end

    -- item -> entity / tile / item
    for iname in pairs(reachable.item) do
      local item = item_index[iname]
      if item then
        if item.place_result then
          if add(reachable.entity, item.place_result) then changed = true end
        end
        if item.place_as_tile and item.place_as_tile.result then
          if add(reachable.tile, item.place_as_tile.result) then changed = true end
        end
        if item.burnt_result then
          if add(reachable.item, item.burnt_result) then changed = true end
        end
      end
    end

    -- resource -> entity: 採掘出力に reached item が含まれていれば resource を追加
    for rname, resource in pairs(data.raw.resource or {}) do
      if not reachable.entity[rname] and resource.minable then
        local outputs = {}
        if resource.minable.result then
          outputs[#outputs + 1] = resource.minable.result
        end
        if resource.minable.results then
          for _, r in ipairs(resource.minable.results) do
            outputs[#outputs + 1] = name_of(r)
          end
        end
        for _, oname in ipairs(outputs) do
          if reachable.item[oname] then
            if add(reachable.entity, rname) then changed = true end
            break
          end
        end
      end
    end
  end

  return reachable
end

-- prototype 型名から reachable のカテゴリ名へのマッピング。
-- 該当しない型 (ammo-category 等) は nil を返す。
function M.category_of(type_name)
  if defines.prototypes.item[type_name] then return "item" end
  if defines.prototypes.entity[type_name] then return "entity" end
  if type_name == "fluid" then return "fluid" end
  if type_name == "recipe" then return "recipe" end
  if type_name == "tile" then return "tile" end
  if type_name == "technology" then return "technology" end
  return nil
end

function M.trace(reachable)
  reachable = reachable or M.compute()
  local categories = {"technology", "recipe", "item", "fluid", "entity", "tile"}

  -- カテゴリごとの件数サマリを最初に
  local summary = {}
  for _, c in ipairs(categories) do
    local count = 0
    for _ in pairs(reachable[c]) do count = count + 1 end
    summary[#summary + 1] = c .. "=" .. count
  end
  log("[fp:reach] summary " .. table.concat(summary, " "))

  -- 各 prototype の名前を一覧
  for _, category in ipairs(categories) do
    for name in pairs(reachable[category]) do
      log(string.format("[fp:reach] %s :: %s", category, name))
    end
  end
end

return M
