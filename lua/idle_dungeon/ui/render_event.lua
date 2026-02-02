-- このモジュールはイベント表示に関わる情報取得をまとめる。
-- 階層計算はgame/floor/progressへ集約する。
local content = require("idle_dungeon.content")
local floor_progress = require("idle_dungeon.game.floor.progress")

local M = {}

local function find_event_by_id(event_id)
  for _, event in ipairs(content.events) do
    if event.id == event_id then
      return event
    end
  end
  for _, event in ipairs(content.stage_intros or {}) do
    if event.id == event_id then
      return event
    end
  end
  return nil
end

local function resolve_event_message(event, lang)
  if not event then
    return ""
  end
  if type(event.message) == "table" then
    return event.message[lang] or event.message.en or event.message.ja or ""
  end
  return event.message or ""
end

local function resolve_event_title(event, lang)
  if not event then
    return ""
  end
  if type(event.title) == "table" then
    return event.title[lang] or event.title.en or event.title.ja or ""
  end
  return event.title or ""
end

local function resolve_event_art(event, lang)
  if not event then
    return {}
  end
  local art = event.art
  if type(art) == "table" then
    if art[lang] then
      return art[lang]
    end
    if art.en or art.ja then
      return art[lang] or art.en or art.ja or {}
    end
    if #art > 0 then
      return art
    end
  end
  if type(art) == "string" and art ~= "" then
    return { art }
  end
  return {}
end

local function find_next_event_distance(progress, config)
  local candidates = {}
  for _, event in ipairs(content.events) do
    local stage_ok = not event.stage_id or event.stage_id == progress.stage_id
    if stage_ok then
      table.insert(candidates, event.distance)
    end
  end
  local current = progress.distance or 0
  local next_distance = nil
  for _, distance in ipairs(candidates) do
    if distance > current and (not next_distance or distance < next_distance) then
      next_distance = distance
    end
  end
  if not next_distance then
    return nil
  end
  -- 進行表示と合わせるため距離差分を階層数へ換算する。
  local floor_length = floor_progress.resolve_floor_length(config or {})
  return math.floor(math.max(next_distance - current, 0) / floor_length)
end

M.find_event_by_id = find_event_by_id
M.resolve_event_message = resolve_event_message
M.resolve_event_title = resolve_event_title
M.resolve_event_art = resolve_event_art
M.find_next_event_distance = find_next_event_distance

return M
