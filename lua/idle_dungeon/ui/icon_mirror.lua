-- このモジュールはアイコン文字列を左右反転した表示用文字列へ変換する。

local util = require("idle_dungeon.util")

local M = {}

local MIRROR_PAIRS = {
  ["("] = ")",
  [")"] = "(",
  ["["] = "]",
  ["]"] = "[",
  ["{"] = "}",
  ["}"] = "{",
  ["<"] = ">",
  [">"] = "<",
  ["/"] = "\\",
  ["\\"] = "/",
  ["┌"] = "┐",
  ["┐"] = "┌",
  ["└"] = "┘",
  ["┘"] = "└",
  ["╭"] = "╮",
  ["╮"] = "╭",
  ["╰"] = "╯",
  ["╯"] = "╰",
  ["◀"] = "▶",
  ["▶"] = "◀",
  ["◁"] = "▷",
  ["▷"] = "◁",
  ["◂"] = "▸",
  ["▸"] = "◂",
  ["◃"] = "▹",
  ["▹"] = "◃",
  ["←"] = "→",
  ["→"] = "←",
}

-- 1文字を左右反転後の対応文字へ変換する。
local function mirror_char(ch)
  return MIRROR_PAIRS[ch] or ch
end

-- 文字順を反転しつつ、向きのある文字を対応文字へ置き換える。
local function horizontal(text)
  local chars = util.split_utf8(text or "")
  if #chars == 0 then
    return ""
  end
  local mirrored = {}
  for index = #chars, 1, -1 do
    table.insert(mirrored, mirror_char(chars[index]))
  end
  return table.concat(mirrored, "")
end

-- 単独グリフのように反転前後で見た目が変わらない場合だけ向き補助を付ける。
local function needs_pet_direction_hint(original, mirrored)
  if (original or "") ~= (mirrored or "") then
    return false
  end
  local chars = util.split_utf8(original or "")
  return #chars == 1 and (chars[1] or "") ~= ""
end

-- ペット表示用の左右反転文字列を返す。必要な場合は向き補助記号を末尾へ付ける。
local function horizontal_for_pet(text)
  local mirrored = horizontal(text)
  if mirrored == "" then
    return ""
  end
  if needs_pet_direction_hint(text, mirrored) then
    return mirrored .. ">"
  end
  return mirrored
end

M.horizontal = horizontal
M.horizontal_for_pet = horizontal_for_pet

return M
