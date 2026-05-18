-- 名前 conflict があるレシピを別名にリネームして、本 mod の shadow recipe による
-- merge を成立させるためのモジュール。
--
-- リネーム対象:
--   data.raw.recipe[old_name]                            recipe 本体
--   tech.effects (unlock-recipe / change-recipe-productivity)
--                                                        全 tech 横断で参照を書き換え
--
-- 注意: 旧名で recipe を参照する他 mod は壊れる。設定で無効化できるようにしてある。

local log = require("debug_log")

local M = {}

local function rewrite_tech_effects(old_name, new_name)
  for _, tech in pairs(data.raw.technology or {}) do
    if tech.effects then
      for _, effect in ipairs(tech.effects) do
        if (effect.type == "unlock-recipe"
            or effect.type == "change-recipe-productivity")
            and effect.recipe == old_name then
          effect.recipe = new_name
        end
      end
    end
  end
end

function M.rename(old_name, new_name)
  local recipe = data.raw.recipe and data.raw.recipe[old_name]
  if not recipe then
    log(string.format("[fp:rename] skip: %s not found", old_name))
    return false
  end
  if data.raw.recipe[new_name] then
    log(string.format("[fp:rename] skip: %s -> %s, new name already taken", old_name, new_name))
    return false
  end
  data.raw.recipe[old_name] = nil
  recipe.name = new_name
  -- 元の翻訳を引き継ぐ (locale ファイルは旧名で定義されているため)
  recipe.localised_name = recipe.localised_name or {"recipe-name." .. old_name}
  recipe.localised_description = recipe.localised_description or {"recipe-description." .. old_name}
  data.raw.recipe[new_name] = recipe
  rewrite_tech_effects(old_name, new_name)
  log(string.format("[fp:rename] %s -> %s", old_name, new_name))
  return true
end

return M
