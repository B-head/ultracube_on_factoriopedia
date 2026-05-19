-- Ultracube が hidden_in_factoriopedia=true を立てる prototype カテゴリ。
-- Ultracube/data-updates.lua の隠蔽処理と同じスコープに揃えてある:
--   defines.prototypes.item / defines.prototypes.entity の全サブタイプ +
--   fluid / recipe / ammo-category。
-- defines.prototypes は data ステージで利用可能なため、モジュールロード時に展開する。

local M = {}

local function build_types()
  local result = {}
  for t in pairs(defines.prototypes.item) do
    result[#result + 1] = t
  end
  for t in pairs(defines.prototypes.entity) do
    result[#result + 1] = t
  end
  result[#result + 1] = "fluid"
  result[#result + 1] = "recipe"
  result[#result + 1] = "ammo-category"
  return result
end

M.types = build_types()

return M
