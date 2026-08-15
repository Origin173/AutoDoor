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

-- Finds the placed motor world item on a square (the one right-clicked).
local function findMotorWorldItemAt(x, y, z)
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return nil end
    local world = sq:getWorldObjects()
    for i = 0, world:size() - 1 do
        local w = world:get(i)
        if w and w.getItem then
            local inv = w:getItem()
            if inv and inv.getModData and inv:getModData().autoDoorMotor then
                return w
            end
        end
    end
    return nil
end

-- Adds an item to the player inventory and syncs it to clients.
local function giveItem(player, item)
    if not item then return end
    player:getInventory():AddItem(item)
    if isServer() then
        sendItemChangeToClients(item)
    end
end

-- Removes a world item (the motor) from the world square.
local function removeWorldItem(worldItem)
    if not worldItem then return end
    local sq = worldItem:getSquare()
    if sq then
        sq:RemoveWorldObject(worldItem)
    end
end

-- Returns a fresh battery inventory item with the given charge fraction (0..1).
local function makeBattery(delta)
    local bat = instanceItem(AutoDoor.ITEM_BATTERY)
    if not bat then return nil end
    if delta and delta > 0 then
        -- Battery uses Delta (remaining power 0..1); UsedDelta is the consumed part.
        bat:setUsedDelta(1.0 - delta)
    else
        bat:setUsedDelta(1.0) -- fully drained
    end
    return bat
end

local function playSound(player, sound)
    if player then sendServerCommand(player, "AutoDoor", "Sound", { sound = sound }) end
end

local function removeFromPlayer(player, item)
    if not item then return end
    player:getInventory():Remove(item)
    sendRemoveItemFromContainer(player:getInventory(), item)
end

-- Drops the motor item on the square, offset toward the door post (corner).
local function placeMotor(player, motor, door, sq)
    local anchor = AutoDoor.getDoorAnchor(door)
    local md = motor:getModData()
    md.autoDoorMotor = true
    md.doorX, md.doorY, md.doorZ = anchor:getX(), anchor:getY(), anchor:getZ()
    local dx, dy = sq:getX() - anchor:getX(), sq:getY() - anchor:getY()
    -- Push the motor toward the corner of the tile that faces the door post,
    -- so it sits beside the frame instead of in the middle of the doorway.
    local ox, oy = 0.5, 0.5
    if dx ~= 0 and dy ~= 0 then
        -- diagonal neighbour: hug the corner closest to the door post
        ox = dx > 0 and 0.25 or 0.75
        oy = dy > 0 and 0.25 or 0.75
    elseif dx ~= 0 then
        ox = dx > 0 and 0.3 or 0.7
    elseif dy ~= 0 then
        oy = dy > 0 and 0.3 or 0.7
    end
    local worldItem = sq:AddWorldInventoryItem(motor, ox, oy, 0, false)
    if worldItem then
        -- B42: setIgnoreRemoveSandbox / transmitCompleteItemToClients live on the
        -- inner world item returned by getWorldItem(), not on the
        -- IsoWorldInventoryObject itself (see the vanilla ISDropWorldItemAction).
        -- transmitCompleteItemToClients also syncs the motor's ModData
        -- (autoDoorMotor flag, doorX/Y/Z) to clients.
        local groundItem = worldItem:getWorldItem()
        if groundItem then
            groundItem:setIgnoreRemoveSandbox(true)
            groundItem:transmitCompleteItemToClients()
        end
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

    -- Commands that operate on the door directly.
    if command == "Install" or command == "Repair"
        or command == "ReplaceBattery" or command == "Uninstall" then
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
        return
    end

    -- Commands that operate on the placed motor world item directly.
    if command == "UninstallMotor" or command == "RemoveBattery"
        or command == "InstallBattery" then
        local worldItem = findMotorWorldItemAt(args.x, args.y, args.z)
        if not worldItem then return end
        local door = AutoDoor.getDoorFromMotor(worldItem)
        if not door then
            -- Orphaned motor (already unpaired): only allow picking it up.
            if command == "UninstallMotor" then
                local invItem = worldItem:getItem()
                if invItem then
                    local mmd = invItem:getModData()
                    mmd.autoDoorMotor = nil
                    mmd.doorX, mmd.doorY, mmd.doorZ = nil, nil, nil
                    giveItem(player, invItem)
                    removeWorldItem(worldItem)
                    playSound(player, "UIActivateButton")
                end
            end
            return
        end

        if command == "UninstallMotor" then
            -- Give the motor back to the player and, if charged, a battery too.
            local charge = AutoDoor.getMotorCharge(door)
            local invItem = worldItem:getItem()
            if invItem then
                local mmd = invItem:getModData()
                mmd.autoDoorMotor = nil
                mmd.doorX, mmd.doorY, mmd.doorZ = nil, nil, nil
                giveItem(player, invItem)
            end
            removeWorldItem(worldItem)
            AutoDoor.unpairDoor(door)
            if charge > 0 then
                local bat = makeBattery(charge / AutoDoor.MOTOR_MAX_CHARGE)
                giveItem(player, bat)
            end
            playSound(player, "UIActivateButton")
        elseif command == "RemoveBattery" then
            -- Return a battery reflecting the current charge; the motor keeps
            -- its place and pairing but is discharged.
            local charge = AutoDoor.getMotorCharge(door)
            if charge <= 0 then return end
            local bat = makeBattery(charge / AutoDoor.MOTOR_MAX_CHARGE)
            giveItem(player, bat)
            AutoDoor.dischargeBattery(door)
            playSound(player, "UIActivateButton")
        elseif command == "InstallBattery" then
            local battery = AutoDoor.getBattery(player)
            if not battery then return end
            removeFromPlayer(player, battery)
            AutoDoor.refillBattery(door)
            playSound(player, "UIActivateButton")
        end
        return
    end
end

Events.OnClientCommand.Add(OnClientCommand)
