--[[
    AutoDoor keybinding registration (client).
    B42 removed ISKeyBindings; mods register entries in the global keyBinding
    table so the binding shows up in Options > Keybindings and can be rebound
    (persisted in keysB42.ini). Default key: K (unused by vanilla).
    Events.OnKeyStartPressed fires on key-down (edge trigger).
]]

require "AutoDoor/AutoDoorRemote"

local BIND_CATEGORY = "[AutoDoor]"
local BIND_NAME = "Open Door With Remote"

-- Register the rebindable key once (appears in Options > Key Bindings).
local function registerKeyBind()
    if not keyBinding then return end
    for _, kb in ipairs(keyBinding) do
        if kb.value == BIND_NAME then return end
    end
    table.insert(keyBinding, { value = BIND_CATEGORY })
    table.insert(keyBinding, { value = BIND_NAME, key = Keyboard.KEY_K })
end

local function onKeyStartPressed(key)
    if not getCore():isKey(BIND_NAME, key) then return end
    if not getPlayer() or getPlayer():isDead() then return end
    -- Ignore while typing in a text field or with a UI grabbing the key.
    if UIManager.getSpeedControls() and UIManager.getSpeedControls():isKeyConsumed(key) then
        return
    end
    AutoDoorRemote.trigger(getPlayer())
end

registerKeyBind()
Events.OnKeyStartPressed.Add(onKeyStartPressed)
