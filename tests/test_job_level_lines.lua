-- このテストはジョブごとのレベル一覧が生成されることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local content = require("idle_dungeon.content")
local menu_locale = require("idle_dungeon.menu.locale")

local state = { job_levels = {} }
for _, job in ipairs(content.jobs or {}) do
  state.job_levels[job.id] = { level = 3 }
end

local lines = menu_locale.build_job_level_lines(state, "ja", content.jobs or {})
for _, job in ipairs(content.jobs or {}) do
  local found = false
  for _, line in ipairs(lines or {}) do
    if line:find(job.name, 1, true) and line:find("Lv3", 1, true) then
      found = true
      break
    end
  end
  assert_true(found, "ジョブレベル表示にジョブ名が含まれる: " .. (job.id or ""))
end

local lines_en = menu_locale.build_job_level_lines(state, "en", content.jobs or {})
local found_en = false
for _, line in ipairs(lines_en or {}) do
  if line:find("Swordsman", 1, true) and line:find("Lv3", 1, true) then
    found_en = true
    break
  end
end
assert_true(found_en, "英語設定ではジョブレベル表示に英語ジョブ名が含まれる")

print("OK")
