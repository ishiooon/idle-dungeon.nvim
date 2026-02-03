-- このモジュールは各コンテンツ定義をまとめて提供する。
-- コンテンツ定義はcontent配下へ集約する。
local characters = require("idle_dungeon.content.characters")
local enemies = require("idle_dungeon.content.enemies")
local items = require("idle_dungeon.content.items")
local events = require("idle_dungeon.content.events")
local stage_intros = require("idle_dungeon.content.stage_intros")

local M = {
  characters = characters.characters,
  enemies = enemies.enemies,
  items = items.items,
  events = events.events,
  hidden_events = events.hidden_events,
  stage_intros = stage_intros.intros,
}

return M
