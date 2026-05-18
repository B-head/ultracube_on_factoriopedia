-- 「Ultracube 進行ルートに乗っている tech」を分類するモジュール。
--
-- 判定アルゴリズム (2 pass + 1 fallback):
--   Pass 1: tech.unit.ingredients を見て、cube サイエンスパックのみで構成されていれば CUBE。
--           非 cube サイエンスパックを含めば OTHER。unit が無いものは保留。
--   Pass 2: 保留分 (research_trigger 持ちなど unit が無い tech) について、
--           prerequisites のいずれかが CUBE 分類なら CUBE に伝播 (固定点まで反復)。
--   Pass 3: それでも保留のものは OTHER。
--
-- 仕組みの背景は memory の reference_ultracube_progression.md 参照。

local log = require("debug_log")

local M = {}

local CUBE_SCIENCE_PACKS = {
  ["cube-basic-contemplation-unit"]      = true,
  ["cube-fundamental-comprehension-card"] = true,
  ["cube-abstract-interrogation-card"]   = true,
  ["cube-deep-introspection-card"]       = true,
  ["cube-synthetic-premonition-card"]    = true,
  ["cube-complete-annihilation-card"]    = true,
}

local function ingredient_name(ingredient)
  return ingredient[1] or ingredient.name
end

local function classify_by_ingredients(tech)
  if not tech.unit or not tech.unit.ingredients or #tech.unit.ingredients == 0 then
    return nil, nil
  end
  local non_cube = {}
  for _, ing in ipairs(tech.unit.ingredients) do
    local name = ingredient_name(ing)
    if not CUBE_SCIENCE_PACKS[name] then
      non_cube[#non_cube + 1] = name or "?"
    end
  end
  if #non_cube == 0 then
    return "CUBE", "cube-only"
  end
  return "OTHER", "non_cube=[" .. table.concat(non_cube, ",") .. "]"
end

local function no_unit_prefix(tech)
  return tech.research_trigger and "trigger+" or "no-unit+"
end

-- 全 technology を分類する。
-- 返り値: classification (name -> "CUBE" or "OTHER"), reasons (name -> string)
function M.classify_techs()
  local techs = data.raw.technology or {}
  local classification = {}
  local reasons = {}

  -- Pass 1
  for name, tech in pairs(techs) do
    local class, reason = classify_by_ingredients(tech)
    if class then
      classification[name] = class
      reasons[name] = reason
    end
  end

  -- Pass 2
  local changed = true
  while changed do
    changed = false
    for name, tech in pairs(techs) do
      if classification[name] == nil and tech.prerequisites then
        for _, prereq_name in ipairs(tech.prerequisites) do
          if classification[prereq_name] == "CUBE" then
            classification[name] = "CUBE"
            reasons[name] = no_unit_prefix(tech) .. "cube-prereq:" .. prereq_name
            changed = true
            break
          end
        end
      end
    end
  end

  -- Pass 3
  for name, tech in pairs(techs) do
    if classification[name] == nil then
      classification[name] = "OTHER"
      reasons[name] = no_unit_prefix(tech) .. "no-cube-prereq"
    end
  end

  return classification, reasons
end

-- CUBE 分類された tech 名のみの集合 (name -> true) を返す。
function M.cube_techs()
  local classification = M.classify_techs()
  local result = {}
  for name, class in pairs(classification) do
    if class == "CUBE" then
      result[name] = true
    end
  end
  return result
end

-- 分類結果をログ出力する。
function M.trace_ultracube()
  local techs = data.raw.technology
  if not techs then
    log("[fp:utc-tech] no technologies found")
    return
  end
  local classification, reasons = M.classify_techs()

  local n_total, n_cube, n_other = 0, 0, 0
  for name, _ in pairs(techs) do
    n_total = n_total + 1
    if classification[name] == "CUBE" then
      n_cube = n_cube + 1
    else
      n_other = n_other + 1
    end
    log(string.format("[fp:utc-tech] %s %s | %s",
      classification[name], name, reasons[name]))
  end
  log(string.format("[fp:utc-tech] summary total=%d cube=%d other=%d",
    n_total, n_cube, n_other))
end

return M
