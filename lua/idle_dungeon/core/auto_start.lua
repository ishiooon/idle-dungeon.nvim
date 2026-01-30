-- このモジュールは自動開始の判定を純粋関数で提供する。

local M = {}

local function resolve(user_config, config, saved_state)
  local user_setting = user_config and user_config.ui and user_config.ui.auto_start
  if user_setting ~= nil then
    return user_setting
  end
  local saved_setting = saved_state and saved_state.ui and saved_state.ui.auto_start
  if saved_setting ~= nil then
    return saved_setting
  end
  local config_setting = config and config.ui and config.ui.auto_start
  if config_setting ~= nil then
    return config_setting
  end
  return true
end

M.resolve = resolve

return M
