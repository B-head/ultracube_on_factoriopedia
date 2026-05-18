-- reachable な recipe について target item/fluid との Factoriopedia 統合を試みる。
--
-- 戦略:
--   manual_merges.lua に列挙されたもの -> 手動指定の target に shadow recipe で merge
--   単一 result + 名前一致           -> Factorio が自動統合 (何もしない)
--   単一 result + 名前不一致 + icon 互換 (継承 or 一致)
--                                    -> shadow recipe を作成し、cube-recipe は
--                                       hidden_in_factoriopedia=true で隠す。
--                                       shadow が target item と auto-merge し、
--                                       cube-recipe の content を item ページに表示する。
--   単一 result + 名前不一致 + icon 不一致
--                                    -> 独自ビジュアルなので何もしない
--   複数 result + 名前一致           -> main_product 設定 (dev 確認済みで item ページと merge)
--   複数 result + 名前一致無し      -> 何もしない (個別対応は manual_merges に列挙)
--
-- Shadow recipe:
--   - name = target item/fluid 名
--   - ingredients/results は cube-recipe から全コピー (catalyst パターン等の正確な表示)
--   - multi-result の場合は main_product = shadow_name を設定 (name-based merge 成立のため)
--   - hidden = false             (hidden=true だと Factoriopedia merge 対象外になるため。
--                                 結果 factory recipe selector に locked 状態で出るが許容)
--   - enabled = false            (locked 状態、研究/手動 craft で使えない)
-- cube-recipe 側:
--   - hidden_in_factoriopedia = true (Factoriopedia から消す。content は shadow 経由で見える)

local log = require("debug_log")

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
  local manual_merges = require("manual_merges")
  local item_index = build_item_index()
  local fluids = data.raw.fluid or {}

  local stats = {
    manual_shadow          = 0,
    manual_existing        = 0,
    manual_target_missing  = 0,
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

  local function plan_shadow(target_name, target_type, source_recipe)
    if not shadow_names_set[target_name] then
      shadow_plans[target_name] = {
        source = source_recipe,
        target_type = target_type,
      }
      shadow_names_set[target_name] = true
    end
  end

  for recipe_name in pairs(reachable.recipe) do
    local recipe = data.raw.recipe and data.raw.recipe[recipe_name]
    if recipe then
      -- manual_merges を最優先 (Ultracube が main_product や factoriopedia_alternative を
      -- 設定済みでも上書きする。user が明示的に指定したケースのため)
      if manual_merges[recipe_name] then
        local target_name = manual_merges[recipe_name]
        local target_type
        if item_index[target_name] then
          target_type = "item"
        elseif fluids[target_name] then
          target_type = "fluid"
        end
        if not target_type then
          stats.manual_target_missing = stats.manual_target_missing + 1
          log(string.format("[fp:merge] M ? %s manual target=%s not found",
            recipe_name, target_name))
        else
          recipe.hidden_in_factoriopedia = true
          local existing = data.raw.recipe[target_name]
          if existing then
            -- 既存 recipe を Factoriopedia に出して item ページとの auto-merge を担当させる。
            -- vanilla の ingredients/results が残っていると嘘の recipe 表示になるので、
            -- cube-recipe の content で上書きする (Ultracube が本来やるべき調整を肩代わり)。
            -- main_product は cube-recipe の値ではなく target_name を使う:
            -- cube-recipe では "" になっている場合があり、それを継承すると icon 継承が
            -- 無効化されて recipe 自身に icon フィールドが必要になってしまう。
            existing.hidden_in_factoriopedia = false
            existing.ingredients = recipe.ingredients and deepcopy(recipe.ingredients) or {}
            existing.results = recipe.results and deepcopy(recipe.results) or {}
            existing.energy_required = recipe.energy_required
            existing.category = recipe.category
            existing.main_product = target_name
            stats.manual_existing = stats.manual_existing + 1
            log(string.format("[fp:merge] M %s hidden (existing %s overridden, handles merge)",
              recipe_name, target_name))
          else
            plan_shadow(target_name, target_type, recipe)
            stats.manual_shadow = stats.manual_shadow + 1
            log(string.format("[fp:merge] M %s hidden (shadow %s)",
              recipe_name, target_name))
          end
        end
      elseif recipe.factoriopedia_alternative ~= nil then
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
                recipe.hidden_in_factoriopedia = true
                local existing = data.raw.recipe[rname]
                if existing then
                  -- 既存 recipe を unhide + cube-recipe の content で上書き (manual_merges と同様)
                  -- main_product は target 名 (rname) を使う (cube-recipe の "" 等を継承しないため)
                  existing.hidden_in_factoriopedia = false
                  existing.ingredients = recipe.ingredients and deepcopy(recipe.ingredients) or {}
                  existing.results = recipe.results and deepcopy(recipe.results) or {}
                  existing.energy_required = recipe.energy_required
                  existing.category = recipe.category
                  existing.main_product = rname
                  stats.existing_redirect = stats.existing_redirect + 1
                  log(string.format("[fp:merge] -> %s hidden (existing %s overridden, handles merge, %s)",
                    recipe_name, rname, reason))
                else
                  plan_shadow(rname, rtype, recipe)
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
    local shadow_results = src.results and deepcopy(src.results) or {}
    local shadow_def = {
      type = "recipe",
      name = shadow_name,
      category = src.category,
      ingredients = src.ingredients and deepcopy(src.ingredients) or {},
      results = shadow_results,
      energy_required = src.energy_required,
      enabled = false,
    }
    -- multi-result の場合は main_product を明示しないと name-based merge が成立しない
    if #shadow_results > 1 then
      shadow_def.main_product = shadow_name
    end
    data:extend({shadow_def})
    shadow_added = shadow_added + 1
  end

  log(string.format(
    "[fp:merge] summary: manual_shadow=%d manual_existing=%d manual_missing=%d name_match=%d shadow_added=%d existing_redirect=%d icon_diff=%d target_missing=%d multi_set=%d multi_no_match=%d alt_set=%d main_already=%d",
    stats.manual_shadow,
    stats.manual_existing,
    stats.manual_target_missing,
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
