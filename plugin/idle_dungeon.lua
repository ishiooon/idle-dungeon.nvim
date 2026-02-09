-- このプラグインはユーザーコマンドを定義して入口を提供する。

local function idle()
  -- コマンド呼び出し時に都度requireすることで、再読み込み後の実装へ追従する。
  return require("idle_dungeon")
end

-- 利用者が操作できるコマンドを登録する。
vim.api.nvim_create_user_command("IdleDungeonStart", function()
  idle().start()
end, {})

vim.api.nvim_create_user_command("IdleDungeonStop", function()
  idle().stop()
end, {})

vim.api.nvim_create_user_command("IdleDungeonMenu", function()
  idle().open_menu()
end, {})

vim.api.nvim_create_user_command("IdleDungeonToggleTextMode", function()
  idle().toggle_text_mode()
end, {})

vim.api.nvim_create_user_command("IdleDungeonTakeover", function()
  idle().takeover_owner()
end, {})

-- Neovim終了時に停止処理を実行してロックを解放する。
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    idle().stop()
  end,
})
