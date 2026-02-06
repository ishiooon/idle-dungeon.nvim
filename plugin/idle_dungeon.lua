-- このプラグインはユーザーコマンドを定義して入口を提供する。

local idle = require("idle_dungeon")

-- 利用者が操作できるコマンドを登録する。
vim.api.nvim_create_user_command("IdleDungeonStart", function()
  idle.start()
end, {})

vim.api.nvim_create_user_command("IdleDungeonStop", function()
  idle.stop()
end, {})

vim.api.nvim_create_user_command("IdleDungeonMenu", function()
  idle.open_menu()
end, {})

vim.api.nvim_create_user_command("IdleDungeonToggleTextMode", function()
  idle.toggle_text_mode()
end, {})

vim.api.nvim_create_user_command("IdleDungeonTakeover", function()
  idle.takeover_owner()
end, {})

-- Neovim終了時に停止処理を実行してロックを解放する。
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    idle.stop()
  end,
})
