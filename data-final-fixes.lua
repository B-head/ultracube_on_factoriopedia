-- Ultracube 進行ルートに乗っている tech を分類してログ出力 (調査用)
require("trace_technologies").trace_ultracube()

-- CUBE tech から波及して到達可能な prototype 集合を計算
local reachable_module = require("trace_reachable")
local reachable = reachable_module.compute()
reachable_module.trace(reachable)

-- Ultracube が hide した prototype のうち、reachable 集合に含まれるもののみ
-- hidden_in_factoriopedia を false に戻す。集合外は隠れたままにする。
local types = require("factoriopedia_inspect").types

local unhidden = 0
local kept_hidden = 0
for _, type_name in ipairs(types) do
  local category = reachable_module.category_of(type_name)
  local reachable_set = category and reachable[category]
  local protos = data.raw[type_name]
  if protos then
    for name, proto in pairs(protos) do
      if proto.hidden_in_factoriopedia then
        if reachable_set and reachable_set[name] then
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
log(string.format("[fp:unhide] summary unhidden=%d kept_hidden=%d", unhidden, kept_hidden))
