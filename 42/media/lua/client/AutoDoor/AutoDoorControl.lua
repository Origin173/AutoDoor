-- Client remote logic: toggles paired doors near the player or their vehicle.
require "AutoDoor/AutoDoorDoorLib"

AutoDoorControl = {}

-- Returns true when a door was toggled.
function AutoDoorControl.trigger(player)
    if not player then return false end
    local remote = AutoDoor.getRemote(player)
    if not remote then return false end
    local remoteId = AutoDoor.getRemoteId(remote)
    if not remoteId then
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

    -- Locked doors refuse to open; the remote automates open/close only.
    if door:isLockedByKey() then
        player:getEmitter():playSound("DoorIsLocked")
        return false
    end

    -- The motor needs battery power to move the door.
    if not AutoDoor.canOperate(door) then
        player:getEmitter():playSound("RadioButton")
        return false
    end

    local ok = AutoDoor.toggleDoor(player, door)
    if ok then
        AutoDoor.consumeMotorPower(door)
        getSoundManager():playUISound("UIActivateButton")
    end
    return ok
end

-- Right-click menu on the remote item (works on foot too).
function AutoDoorControl.fillInventoryMenu(playerNum, context, items)
    if not items then return end
    -- items may hold inventory group objects (with an .items list)
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

    local text = AutoDoor.text("IGUI_AutoDoor_ContextOpen", "Open Door")
    if door:IsOpen() then
        text = AutoDoor.text("IGUI_AutoDoor_ContextClose", "Close Door")
    end
    context:addOptionOnTop(text, playerNum, AutoDoorControl.onContextToggle, door)
end

function AutoDoorControl.onContextToggle(playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    if door:isLockedByKey() then
        player:getEmitter():playSound("DoorIsLocked")
        return
    end
    if not AutoDoor.canOperate(door) then
        player:getEmitter():playSound("RadioButton")
        return
    end
    if AutoDoor.toggleDoor(player, door) then
        AutoDoor.consumeMotorPower(door)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(AutoDoorControl.fillInventoryMenu)
