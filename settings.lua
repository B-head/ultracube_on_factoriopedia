data:extend({
  -- Ultracube 側に「同名 item と results が一致しない」レシピがあると、本 mod の
  -- shadow recipe による merge ができない (name conflict + content 上書きで本来の
  -- 機能が壊れる)。該当レシピをリネームすることで shadow を作れるようにする。
  -- 他 mod が旧名でレシピを参照していると壊れる可能性があるため設定で無効化可能。
  {
    type = "bool-setting",
    name = "ultracube-on-factoriopedia-rename-refined-rare-metals-recipe",
    setting_type = "startup",
    default_value = true,
    order = "rename-a",
  },
})
