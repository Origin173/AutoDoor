--[[
    AutoDoor remote control logic (client).
    Finds the paired auto door near the player (or their vehicle) and
    toggles it open/closed. The remote is the door opener: locked doors
    are opened without needing the original key (the lock is bypassed).
    Works from the driver's seat: the search is centred on the vehicle
    square.
]]

require "AutoDoor/AutoDoorDoorLib"

AutoDoorRemote = {}

-- Execute one "use the remote" action. Returns true when a door was toggled.
function AutoDoorRemote.trigger(player)
    if not player then return false end
    local remote = AutoDoor.getRemote(player)
    if not remote then return false end
    local remoteId = AutoDoor.getRemoteId(remote)
    if not remoteId then
        -- Remote never paired with any door yet.
        player:getEmitter():playSound("RadioButton")
        return false
    end
    local doors = AutoDoor.findPairedDoors(player, remoteId)
    if #doors == 0 then
        player:getEmitter():playSound("RadioButton")
        return false
    end
    local door = AutoDoor.getNearestDoor(player, doors)
    if not door then return false end

    -- The remote opens/closes the door: a locked door is unlocked first
    -- without requiring the original key.
    if door:isLockedByKey() then
        AutoDoor.unlockDoor(door)
    end

    local ok = AutoDoor.toggleDoor(player, door)
    if ok then
        getSoundManager():playUISound("UIActivateButton")
    end
    return ok
end

-- Right-click menu on the remote item (works on foot too).
function AutoDoorRemote.fillInventoryMenu(playerNum, context, items)
    if not items then return end
    -- items can contain InventoryItem objects or inventory "group" objects
    -- (which carry an .items list); find the first real item.
    local remote = nil
    for _, it in ipairs(items) do
        if instanceof(it, "InventoryItem") then
            remote = it
            break
        elseif it.items and #it.items > 0 and instanceof(it.items[1], "InventoryItem") then
            remote = it.items[1]
            break
        end
    end
    if not remote or remote:getFullType() ~= AutoDoor.ITEM_REMOTE then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local remoteId = AutoDoor.getRemoteId(remote)
    if not remoteId then return end
    local doors = AutoDoor.findPairedDoors(player, remoteId)
    if #doors == 0 then return end
    local door = AutoDoor.getNearestDoor(player, doors)
    if not door then return end

    local text = getText("IGUI_AutoDoor_ContextOpen")
    if door:IsOpen() then
        text = getText("IGUI_AutoDoor_ContextClose")
    end
    context:addOptionOnTop(text, playerNum, AutoDoorRemote.onContextToggle, door)
end

function AutoDoorRemote.onContextToggle(playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    -- Remote opens/closes the door regardless of the lock state.
    if door:isLockedByKey() then
        AutoDoor.unlockDoor(door)
    end
    AutoDoor.toggleDoor(player, door)
end

Events.OnFillInventoryObjectContextMenu.Add(AutoDoorRemote.fillInventoryMenu)
