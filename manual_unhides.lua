-- 自動判定 (reachable 集合 + parameter フラグ) で unhide されない prototype を、
-- 手動で Factoriopedia に再表示させたいときに列挙する。
--
-- data-final-fixes.lua の unhide 条件に追加判定される。
-- 値は true でも説明文でも何でも良い (nil でなければ判定される)。
-- proto.hidden = true なものは触らない方針のため、ここに書いても無視される。
--
-- 名前は prototype type を問わず一致するもの全てに作用する。
-- (item と entity で同名のものがある場合は両方 unhide される)

return {
  ["discharge-defense-remote"] = true,
  ["artillery-targeting-remote"] = true,
  ["red-wire"] = true,
  ["green-wire"] = true,
  ["copper-wire"] = true,
  ["spidertron-remote"] = true,
  ["entity-ghost"] = true,
  ["item-on-ground"] = true,
  ["item-request-proxy"] = true,
  ["tile-ghost"] = true,
}
