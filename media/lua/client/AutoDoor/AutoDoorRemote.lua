--[[
    AutoDoor remote control logic (client).
    Finds the paired auto door near the player (or their vehicle), unlocks
    it if the player carries the matching key, then toggles it open/closed.
]]

require "AutoDoor/AutoDoorDoorLib"

AutoDoorRemote = {}

-- Execute one "use the remote" action. Returns true when a door was toggled.
function AutoDoorRemote.trigger(player)
    if not player then return false end
    local remote = player:getInventory():getFirstTypeRecurse(AutoDoor.ITEM_REMOTE)
    if not remote then return false end
    local keyId = remote:getKeyId()
    local doors = AutoDoor.findPairedDoors(player, keyId)
    if #doors == 0 then
        player:getEmitter():playSound("RemoteClick")
        return false
    end
    local door = AutoDoor.getNearestDoor(player, doors)
    if not door then return false end

    -- Locked: unlock with the matching key if the player carries one.
    if door:isLockedByKey() then
        if player:getInventory():haveThisKeyId(door:getKeyId()) then
            AutoDoor.unlockDoor(door)
        else
            player:getEmitter():playSound("DoorIsLocked")
            getSoundManager():playUISound("UIActivateButton")
            return false
        end
    end

    local ok = AutoDoor.toggleDoor(player, door)
    if ok then
        getSoundManager():playUISound("UIActivateButton")
    end
    return ok
end

-- Right-click menu on the remote item (works on foot too).
function AutoDoorRemote.fillInventoryMenu(playerNum, context, items)
    if not items or #items == 0 then return end
    local remote = items[1]
    if not remote or remote:getFullType() ~= AutoDoor.ITEM_REMOTE then return end
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local keyId = remote:getKeyId()
    local doors = AutoDoor.findPairedDoors(player, keyId)
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
    if door:isLockedByKey() then
        if player:getInventory():haveThisKeyId(door:getKeyId()) then
            AutoDoor.unlockDoor(door)
        else
            player:getEmitter():playSound("DoorIsLocked")
            return
        end
    end
    AutoDoor.toggleDoor(player, door)
end

Events.OnFillInventoryObjectContextMenu.Add(AutoDoorRemote.fillInventoryMenu)
