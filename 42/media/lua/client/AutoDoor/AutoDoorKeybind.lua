-- B42 keybind: entries in the global keyBinding table show up in Options > Key Bindings (default Period key).
require "AutoDoor/AutoDoorControl"

local BIND_CATEGORY = "[AutoDoor]"
local BIND_NAME = "Open Door With Remote"

local function registerKeyBind()
    if not keyBinding then return end
    for _, kb in ipairs(keyBinding) do
        if kb.value == BIND_NAME then return end
    end
    table.insert(keyBinding, { value = BIND_CATEGORY })
    table.insert(keyBinding, { value = BIND_NAME, key = Keyboard.KEY_PERIOD })
end

local function onKeyStartPressed(key)
    if not getCore():isKey(BIND_NAME, key) then return end
    if not getPlayer() or getPlayer():isDead() then return end
    -- Ignore while typing or when a UI consumes the key.
    if UIManager.getSpeedControls() and UIManager.getSpeedControls():isKeyConsumed(key) then
        return
    end
    AutoDoorControl.trigger(getPlayer())
end

registerKeyBind()
Events.OnKeyStartPressed.Add(onKeyStartPressed)
