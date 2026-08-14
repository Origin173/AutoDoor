-- Server: install / re-pair / replace battery / uninstall commands.
require "AutoDoor/AutoDoorDoorLib"

local function findDoorAt(x, y, z)
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return nil end
    for i = 0, sq:getObjects():size() - 1 do
        local obj = sq:getObjects():get(i)
        if AutoDoor.isAutomatableDoor(obj) then return obj end
    end
    return nil
end

local function playSound(player, sound)
    if player then sendServerCommand(player, "AutoDoor", "Sound", { sound = sound }) end
end

local function removeFromPlayer(player, item)
    if not item then return end
    player:getInventory():Remove(item)
    sendRemoveItemFromContainer(player:getInventory(), item)
end

-- Drops the motor item on the square, offset toward the door.
local function placeMotor(player, motor, door, sq)
    local anchor = AutoDoor.getDoorAnchor(door)
    local md = motor:getModData()
    md.autoDoorMotor = true
    md.doorX, md.doorY, md.doorZ = anchor:getX(), anchor:getY(), anchor:getZ()
    local dx, dy = sq:getX() - anchor:getX(), sq:getY() - anchor:getY()
    local ox, oy = 0.5, 0.5
    if dx ~= 0 then ox = dx > 0 and 0.35 or 0.65 end
    if dy ~= 0 then oy = dy > 0 and 0.35 or 0.65 end
    local worldItem = sq:AddWorldInventoryItem(motor, ox, oy, 0, false)
    if worldItem and worldItem:getWorldItem() then
        worldItem:getWorldItem():setIgnoreRemoveSandbox(true)
        worldItem:getWorldItem():transmitCompleteItemToClients()
    end
    removeFromPlayer(player, motor)
    return worldItem ~= nil
end

local function setMotorSquare(door, sq)
    local parts = AutoDoor.getDoorParts(door)
    for _, part in ipairs(parts) do
        local md = part:getModData()
        md.motorX, md.motorY, md.motorZ = sq:getX(), sq:getY(), sq:getZ()
        part:transmitModData()
    end
end

local function OnClientCommand(module, command, player, args)
    if module ~= "AutoDoor" then return end
    if not player or not args or args.x == nil then return end
    local door = findDoorAt(args.x, args.y, args.z)
    if not door then return end

    if command == "Install" then
        if AutoDoor.isAutoDoor(door) or door:isLockedByKey() then return end
        local remote = AutoDoor.getRemote(player)
        local motor = AutoDoor.getMotor(player)
        local battery = AutoDoor.getBattery(player)
        if not remote or not motor or not battery then return end
        if not AutoDoor.getRemoteId(remote) then return end -- client syncs the pairing id first
        local sq = AutoDoor.findMotorSquare(door)
        if not sq then
            playSound(player, "RadioButton")
            return
        end
        if placeMotor(player, motor, door, sq) then
            if AutoDoor.pairDoor(player, door, remote) then
                setMotorSquare(door, sq)
                removeFromPlayer(player, battery)
                playSound(player, "UIActivateButton")
            end
        end
    elseif command == "Repair" then
        if not AutoDoor.isAutoDoor(door) then return end
        local remote = AutoDoor.getRemote(player)
        if not remote or not AutoDoor.getRemoteId(remote) then return end
        if AutoDoor.pairDoor(player, door, remote) then
            playSound(player, "UIActivateButton")
        end
    elseif command == "ReplaceBattery" then
        if not AutoDoor.isAutoDoor(door) then return end
        local battery = AutoDoor.getBattery(player)
        if not battery then return end
        removeFromPlayer(player, battery)
        AutoDoor.refillBattery(door)
        playSound(player, "UIActivateButton")
    elseif command == "Uninstall" then
        if not AutoDoor.isAutoDoor(door) then return end
        AutoDoor.unpairDoor(door)
        playSound(player, "UIActivateButton")
    end
end

Events.OnClientCommand.Add(OnClientCommand)
