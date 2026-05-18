-- ログ出力の本番/開発切り替え。
-- FMTK debug adapter が attach されている時は __DebugAdapter が定義されるので、
-- そのときだけ Factorio の global log() を返す。
-- リリース時は no-op を返し、factorio-current.log を [fp:*] でノイズらせない。
--
-- 使い方:
--   local log = require("debug_log")
--   log("...")   -- 既存の log() 呼び出しはそのまま動く
if __DebugAdapter then
  return log
end
return function() end
