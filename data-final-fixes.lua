-- 名前 conflict があるレシピのオプショナルなリネーム。
-- reachable 計算 / merge より前に行う必要がある (tech effects の参照を書き換えるため)。
if settings.startup["ultracube-on-factoriopedia-rename-refined-rare-metals-recipe"].value then
  require("rename_recipes").rename(
    "cube-refined-rare-metals", "cube-refined-rare-metals-conversion")
end

-- Ultracube 進行ルートに乗っている tech を分類してログ出力 (調査用)
require("trace_technologies").trace_ultracube()

-- CUBE tech から波及して到達可能な prototype 集合を計算
local reachable_module = require("trace_reachable")
local reachable = reachable_module.compute()
reachable_module.trace(reachable)

-- Ultracube が hide した prototype のうち、reachable 集合に含まれるもののみ
-- hidden_in_factoriopedia を false に戻す。集合外は隠れたままにする。
-- 注: proto.hidden = true なものは触らない。hidden と hidden_in_factoriopedia は
-- 独立フラグで、hidden=true でも hidden_in_factoriopedia=false だと Factoriopedia
-- 一覧に出てしまう。Ultracube のダミーアイテム (cube-qubits 等、recipe ingredient
-- としてのみ存在し実体無し) は hidden=true で完全に隠す意図なのでそれを尊重する。
local types = require("factoriopedia_inspect").types
local manual_unhides = require("manual_unhides")

local unhidden = 0
local manual_unhidden = 0
local kept_hidden = 0
local kept_hidden_flag = 0
for _, type_name in ipairs(types) do
  local category = reachable_module.category_of(type_name)
  local reachable_set = category and reachable[category]
  local protos = data.raw[type_name]
  if protos then
    for name, proto in pairs(protos) do
      if proto.hidden_in_factoriopedia then
        if manual_unhides[name] ~= nil then
          proto.hidden_in_factoriopedia = false
          log(string.format("[fp:unhide] %s :: %s (existing %s overridden, handles unhide)", type_name, name, name))
          manual_unhidden = manual_unhidden + 1
        elseif proto.hidden then
          kept_hidden_flag = kept_hidden_flag + 1
        elseif (reachable_set and reachable_set[name]) or proto.parameter then
          proto.hidden_in_factoriopedia = false
          log(string.format("[fp:unhide] %s :: %s", type_name, name))
          unhidden = unhidden + 1
        else
          kept_hidden = kept_hidden + 1
        end
      end
    end
  end
end
log(string.format("[fp:unhide] summary unhidden=%d manual_unhidden=%d kept_hidden=%d kept_hidden_flag=%d",
  unhidden, manual_unhidden, kept_hidden, kept_hidden_flag))

-- reachable な recipe を target item/fluid と統合 (重複エントリ解消)
require("merge_recipes").apply(reachable)
