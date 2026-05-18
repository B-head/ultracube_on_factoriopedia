-- reachable な recipe について target item/fluid との Factoriopedia 統合を試みる。
--
-- 戦略:
--   単一 result + 名前一致           -> Factorio が自動統合 (何もしない)
--   単一 result + 名前不一致 + icon 互換 (継承 or 一致)
--                                    -> shadow recipe を作成し、cube-recipe は
--                                       hidden_in_factoriopedia=true で隠す。
--                                       shadow が target item と auto-merge し、
--                                       cube-recipe の content を item ページに表示する。
--   単一 result + 名前不一致 + icon 不一致
--                                    -> 独自ビジュアルなので何もしない
--   複数 result + 名前一致           -> main_product 設定 (dev 確認済み)
--   複数 result + 名前一致無し      -> 何もしない
--
-- Shadow recipe:
--   - name = target item/fluid 名
--   - ingredients/results は cube-recipe からコピー (item ページに recipe 詳細が表示される)
--   - hidden = false             (hidden=true だと Factoriopedia merge 対象外になるため。
--                                 結果 factory recipe selector に locked 状態で出るが許容)
--   - enabled = false            (locked 状態、研究/手動 craft で使えない)
-- cube-recipe 側:
--   - hidden_in_factoriopedia = true (Factoriopedia から消す。content は shadow 経由で見える)
--   - factoriopedia_alternative は設定しない (設定すると alt recipe として再登場してしまう)

local M = {}

local function name_of(entry)
  return entry.name or entry[1]
end

local function type_of(entry)
  return entry.type or "item"
end

local function deepcopy(t)
  if type(t) ~= "table" then return t end
  local copy = {}
  for k, v in pairs(t) do
    copy[k] = deepcopy(v)
  end
  return copy
end

local function normalize_icons(proto)
  if proto.icons then
    return serpent.line(proto.icons, {sortkeys = true, comment = false})
  elseif proto.icon then
    local layer = {icon = proto.icon, icon_size = proto.icon_size}
    return serpent.line({layer}, {sortkeys = true, comment = false})
  end
  return nil
end

local function build_item_index()
  local idx = {}
  for t in pairs(defines.prototypes.item) do
    if data.raw[t] then
      for n, p in pairs(data.raw[t]) do
        idx[n] = p
      end
    end
  end
  return idx
end

function M.apply(reachable)
  if not reachable then
    reachable = require("trace_reachable").compute()
  end
  local item_index = build_item_index()
  local fluids = data.raw.fluid or {}

  local stats = {
    name_match_no_op       = 0,
    shadow_created         = 0,
    existing_redirect      = 0,
    icon_diff_kept         = 0,
    target_missing         = 0,
    multi_main_product_set = 0,
    multi_no_name_match    = 0,
    alt_already_set        = 0,
    main_product_already   = 0,
  }

  local shadow_plans = {}
  local shadow_names_set = {}

  for recipe_name in pairs(reachable.recipe) do
    local recipe = data.raw.recipe and data.raw.recipe[recipe_name]
    if recipe then
      if recipe.factoriopedia_alternative ~= nil then
        stats.alt_already_set = stats.alt_already_set + 1
      elseif recipe.main_product ~= nil then
        stats.main_product_already = stats.main_product_already + 1
      else
        local results = recipe.results or {}
        if #results == 1 then
          local r = results[1]
          local rname = name_of(r)
          local rtype = type_of(r)
          if rname == recipe_name then
            stats.name_match_no_op = stats.name_match_no_op + 1
          else
            local target = (rtype == "fluid") and fluids[rname] or item_index[rname]
            if not target then
              stats.target_missing = stats.target_missing + 1
              log(string.format("[fp:merge] ? %s target=%s not found", recipe_name, tostring(rname)))
            else
              local can_merge = false
              local reason = nil
              if recipe.icon == nil and recipe.icons == nil then
                can_merge = true
                reason = "B inherits"
              elseif normalize_icons(recipe) == normalize_icons(target) then
                can_merge = true
                reason = "C icon match"
              else
                reason = "C icon diff"
              end
              if not can_merge then
                stats.icon_diff_kept = stats.icon_diff_kept + 1
                log(string.format("[fp:merge] - %s kept (icon differs from %s)", recipe_name, rname))
              else
                -- cube-recipe を Factoriopedia から消す。content は shadow が引き継ぐ。
                recipe.hidden_in_factoriopedia = true
                if data.raw.recipe[rname] then
                  stats.existing_redirect = stats.existing_redirect + 1
                  log(string.format("[fp:merge] -> %s hidden (existing %s handles merge, %s)",
                    recipe_name, rname, reason))
                else
                  if not shadow_names_set[rname] then
                    shadow_plans[rname] = {source = recipe, target_type = rtype}
                    shadow_names_set[rname] = true
                  end
                  stats.shadow_created = stats.shadow_created + 1
                  log(string.format("[fp:merge] -> %s hidden (shadow %s, %s)",
                    recipe_name, rname, reason))
                end
              end
            end
          end
        elseif #results > 1 then
          local matched = false
          for _, r in ipairs(results) do
            if name_of(r) == recipe_name then
              matched = true
              break
            end
          end
          if matched then
            recipe.main_product = recipe_name
            stats.multi_main_product_set = stats.multi_main_product_set + 1
            log(string.format("[fp:merge] D %s main_product=%s", recipe_name, recipe_name))
          else
            stats.multi_no_name_match = stats.multi_no_name_match + 1
          end
        end
      end
    end
  end

  local shadow_added = 0
  for shadow_name, plan in pairs(shadow_plans) do
    local src = plan.source
    -- hidden = true だと Factoriopedia の merge ロジックから除外されるため、
    -- enabled = false (locked) のみで factory craft 不可にする。
    -- machine の recipe selector には locked 状態で表示される。
    data:extend({{
      type = "recipe",
      name = shadow_name,
      category = src.category,
      ingredients = src.ingredients and deepcopy(src.ingredients) or {},
      results = src.results and deepcopy(src.results) or {},
      energy_required = src.energy_required,
      enabled = false,
    }})
    shadow_added = shadow_added + 1
  end

  log(string.format(
    "[fp:merge] summary: name_match=%d shadow_added=%d existing_redirect=%d icon_diff=%d target_missing=%d multi_set=%d multi_no_match=%d alt_set=%d main_already=%d",
    stats.name_match_no_op,
    shadow_added,
    stats.existing_redirect,
    stats.icon_diff_kept,
    stats.target_missing,
    stats.multi_main_product_set,
    stats.multi_no_name_match,
    stats.alt_already_set,
    stats.main_product_already))
end

return M
