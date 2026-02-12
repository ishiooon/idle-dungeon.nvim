-- このモジュールは選択メニューの行デザインを統一する補助関数を提供する。

local M = {}

-- 変化量を符号付きの短い表記へ変換する。
local function format_signed(value)
  local safe = tonumber(value) or 0
  if safe > 0 then
    return string.format("+%d", safe)
  end
  return tostring(safe)
end

-- 現在値と変更後値から主要ステータスの差分を算出する。
local function build_actor_delta(current_actor, next_actor)
  local left = current_actor or {}
  local right = next_actor or {}
  return {
    hp = (right.max_hp or 0) - (left.max_hp or 0),
    atk = (right.atk or 0) - (left.atk or 0),
    def = (right.def or 0) - (left.def or 0),
    speed = (right.speed or 0) - (left.speed or 0),
  }
end

-- 差分情報を1行で比較しやすい短文へ整形する。
local function format_actor_delta(delta)
  local safe = delta or {}
  return string.format(
    "Δ HP%s ATK%s DEF%s SPD%s",
    format_signed(safe.hp),
    format_signed(safe.atk),
    format_signed(safe.def),
    format_signed(safe.speed)
  )
end

-- アクティブスキルの要点を一覧用の短文へ整形する。
local function format_active_skill_summary(skill)
  local rate = math.floor(((skill and skill.rate) or 0) * 100 + 0.5)
  local power = (skill and skill.power) or 1
  local accuracy = (skill and skill.accuracy) or 0
  return string.format("Rate%d%% Powx%.2f Acc%+d", rate, power, accuracy)
end

-- パッシブスキルの補正値を一覧用の短文へ整形する。
local function format_passive_skill_summary(skill)
  local mul = (skill and skill.bonus_mul) or {}
  local summary = string.format("ATKx%.2f DEFx%.2f ACCx%.2f", mul.atk or 1, mul.def or 1, mul.accuracy or 1)
  local pet_slots = tonumber(skill and skill.pet_slots) or 0
  if pet_slots > 0 then
    return string.format("%s Pet+%d", summary, pet_slots)
  end
  return summary
end

-- スキル種別に応じて一覧表示用の要点を返す。
local function format_skill_summary(skill)
  if skill and skill.kind == "active" then
    return format_active_skill_summary(skill)
  end
  return format_passive_skill_summary(skill)
end

M.format_signed = format_signed
M.build_actor_delta = build_actor_delta
M.format_actor_delta = format_actor_delta
M.format_skill_summary = format_skill_summary

return M
