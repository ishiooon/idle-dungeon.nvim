-- このテストは閲覧専用状態から主導権を奪取できることを確認する。

local function assert_true(value, message)
  if not value then
    error(message or "assert_true failed")
  end
end

package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local calls = {
  acquire = 0,
  steal = 0,
}

package.loaded["idle_dungeon.storage.lock"] = {
  build_instance_id = function()
    return "test-instance"
  end,
  acquire_lock = function(_, _)
    calls.acquire = calls.acquire + 1
    return false
  end,
  steal_lock = function(_)
    calls.steal = calls.steal + 1
    return true
  end,
  release_lock = function()
    return true
  end,
}

package.loaded["idle_dungeon.storage.state"] = {
  load_state = function()
    return nil, nil
  end,
  load_state_if_newer = function()
    return nil, nil
  end,
  save_state = function(state)
    return state, nil
  end,
}

package.loaded["idle_dungeon.core.state"] = {
  normalize_state = function(state)
    return state
  end,
}

local session = require("idle_dungeon.core.session")
session.set_config({ storage = { lock_ttl_seconds = 30 } })
session.ensure_instance_id()
session.mark_read_only_notified()

local normal = session.acquire_owner()
assert_true(normal == false, "通常の所有権取得に失敗する場合を再現する")
assert_true(session.is_owner() == false, "通常取得に失敗した場合は所有者ではない")

local forced = session.acquire_owner(true)
assert_true(forced == true, "強制取得で所有権を奪取できる")
assert_true(session.is_owner() == true, "強制取得後は所有者になる")
assert_true(session.read_only_notified() == false, "強制取得成功時は閲覧専用通知フラグを解除する")
assert_true(calls.acquire == 1, "通常取得関数は1回だけ呼ばれる")
assert_true(calls.steal == 1, "強制取得関数が1回呼ばれる")

print("OK")
