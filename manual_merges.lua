-- 自動判定 (icon 一致 + 名前推測) で merge できない recipe について、
-- 手動で recipe -> target item/fluid 名のマッピングを列挙する。
--
-- merge_recipes.lua の自動ロジックより優先される。
-- target prototype が存在しない場合はスキップされる。
-- shadow recipe (target 名) が無ければ作成し、ターゲット item/fluid と auto-merge させる。
-- cube-recipe 側は hidden_in_factoriopedia = true で隠される。

return {
  -- cube-n-dimensional-widget の複数 variant のうち -0 を merge 元とする。
  -- -1 は触らず alt recipe として自動表示させる。
  ["cube-n-dimensional-widget-0"] = "cube-n-dimensional-widget",

  -- cube-rare-metal-crushing は cube-refined-rare-metals item に merge したいが、
  -- Ultracube に既に "cube-refined-rare-metals" 名の recipe が存在し、その results は
  -- cube-rare-metals (リサイクル系 recipe で自分の名前と一致しない出力)。
  -- このため:
  --   - 既存 recipe は同名 item と auto-merge しない (results 不一致)
  --   - shadow も同名で作れない (name conflict)
  --   - 既存 recipe の content を上書きすると本来のリサイクル機能が壊れる
  -- Ultracube 側で recipe 名と results を整合させるべき (recipe 名を変えるか
  -- 結果に cube-refined-rare-metals を含めるか) で、こちらでは対応不能。
  -- ["cube-rare-metal-crushing"] = "cube-refined-rare-metals",

  ["cube-construction-robot"] = "construction-robot",
  ["cube-logistic-robot"] = "cube-logistic-robot-0",
  ["cube-greenhouse-wood"] = "wood",
  ["cube-greenhouse-potato"] = "cube-potato",
  ["cube-deep-core-crushing"] = "cube-deep-powder",
  ["cube-sulfur"] = "sulfur",
  ["cube-sulfuric-acid"] = "sulfuric-acid",
}
