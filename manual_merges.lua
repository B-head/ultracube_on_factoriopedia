-- 自動判定 (icon 一致 + 名前推測) で merge できない recipe について、
-- 手動で recipe -> target item/fluid 名のマッピングを列挙する。
--
-- merge_recipes.lua の自動ロジックより優先される。
-- target prototype が存在しない場合はスキップされる。
-- shadow recipe (target 名) が無ければ作成し、ターゲット item/fluid と auto-merge させる。
-- cube-recipe 側は hidden_in_factoriopedia = true で隠される。

local merges = {
  -- cube-n-dimensional-widget の複数 variant のうち -0 を merge 元とする。
  -- -1 は触らず alt recipe として自動表示させる。
  ["cube-n-dimensional-widget-0"] = "cube-n-dimensional-widget",
  ["cube-basic-matter-unit-0"] = "cube-basic-matter-unit",
  ["cube-basic-contemplation-unit-0"] = "cube-basic-contemplation-unit",

  ["cube-construction-robot"] = "construction-robot",
  ["cube-logistic-robot"] = "cube-logistic-robot-0",
  ["cube-greenhouse-wood"] = "wood",
  ["cube-greenhouse-potato"] = "cube-potato",
  ["cube-deep-core-crushing"] = "cube-deep-powder",
  ["cube-sulfur"] = "sulfur",
  ["cube-sulfuric-acid"] = "sulfuric-acid",
}

-- cube-rare-metal-crushing は cube-refined-rare-metals item に merge したい。
-- 元の "cube-refined-rare-metals" 名 recipe (results = cube-rare-metals) と
-- name conflict するため、対応する rename 設定が有効なときだけ追加する。
-- rename は data-final-fixes.lua で行われる (rename_recipes.lua 参照)。
if settings.startup["ultracube-on-factoriopedia-rename-refined-rare-metals-recipe"].value then
  merges["cube-rare-metal-crushing"] = "cube-refined-rare-metals"
end

return merges
