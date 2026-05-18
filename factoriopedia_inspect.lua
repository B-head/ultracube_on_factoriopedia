-- Ultracube が hidden_in_factoriopedia=true を立てる prototype カテゴリと、調査用ロガー。
-- Ultracube/data-updates.lua の隠蔽処理と同じスコープに揃えてある:
--   defines.prototypes.item / defines.prototypes.entity の全サブタイプ +
--   fluid / recipe / ammo-category。
-- defines.prototypes は data ステージで利用可能なため、モジュールロード時に展開する。

local log = require("debug_log")

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

local function tri(v)
  if v == nil then return "-" end
  return tostring(v)
end

-- stage_tag: ログ行を区別するためのラベル (例: "data", "final")
function M.dump(stage_tag)
  local total = 0
  for _, type_name in ipairs(M.types) do
    local protos = data.raw[type_name]
    if protos then
      for name, proto in pairs(protos) do
        log(string.format(
          "[fp:%s] %s :: %s | hidden=%s hidden_in_factoriopedia=%s enabled=%s",
          stage_tag, type_name, name,
          tri(proto.hidden),
          tri(proto.hidden_in_factoriopedia),
          tri(proto.enabled)
        ))
        total = total + 1
      end
    end
  end
  log(string.format("[fp:%s] total prototypes: %d", stage_tag, total))
end

return M
