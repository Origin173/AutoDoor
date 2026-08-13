--[[
    AutoDoor shared library.
    Door helper functions used by both the server-side building objects
    and the client-side remote control logic. Only relies on native APIs
    so it can be loaded on every side.
]]

AutoDoor = {}

AutoDoor.ITEM_REMOTE = "Base.RemoteDoorOpener"
AutoDoor.ITEM_KEY = "Base.AutoDoorKey"
AutoDoor.SEARCH_RADIUS = 12

-- Garage door styles: 3 tiles (left/middle/right), W-facing and N-facing sprites.
-- Open-state sprites are handled natively via the GarageDoor tile property.
AutoDoor.GARAGE_DOOR_STYLES = {
    {
        name = "IGUI_AutoDoor_GarageDoor_01",
        skill = "Woodwork",
        skillLevel = 6,
        materials = { "Base.Plank:8", "Base.Nails:8", "Base.Hinge:4", "Base.Screws:8", "Base.SmallSheetMetal:4" },
        health = 600,
        spriteW = { "walls_garage_01_48", "walls_garage_01_49", "walls_garage_01_50" },
        spriteN = { "walls_garage_01_51", "walls_garage_01_52", "walls_garage_01_53" },
    },
    {
        name = "IGUI_AutoDoor_GarageDoor_02",
        skill = "Woodwork",
        skillLevel = 6,
        materials = { "Base.Plank:8", "Base.Nails:8", "Base.Hinge:4", "Base.Screws:8", "Base.SmallSheetMetal:4" },
        health = 600,
        spriteW = { "walls_garage_02_0", "walls_garage_02_1", "walls_garage_02_2" },
        spriteN = { "walls_garage_02_3", "walls_garage_02_4", "walls_garage_02_5" },
    },
    {
        name = "IGUI_AutoDoor_GarageDoor_03",
        skill = "Woodwork",
        skillLevel = 6,
        materials = { "Base.Plank:8", "Base.Nails:8", "Base.Hinge:4", "Base.Screws:8", "Base.SmallSheetMetal:4" },
        health = 600,
        spriteW = { "walls_garage_02_32", "walls_garage_02_33", "walls_garage_02_34" },
        spriteN = { "walls_garage_02_35", "walls_garage_02_36", "walls_garage_02_37" },
    },
}

-- Fence gate styles: single tile, W-facing closed sprite + N-facing closed sprite.
-- The open sprites are resolved natively through the doorTrans tile property.
AutoDoor.FENCE_GATE_STYLES = {
    {
        name = "IGUI_AutoDoor_FenceGate_Wire",
        skill = "MetalWelding",
        skillLevel = 3,
        materials = { "Base.MetalPipe:3", "Base.Hinge:2", "Base.ScrapMetal:4", "Base.Screws:2" },
        health = 400,
        sprite = "fixtures_doors_fences_01_128",
        northSprite = "fixtures_doors_fences_01_129",
    },
    {
        name = "IGUI_AutoDoor_FenceGate_Pole",
        skill = "MetalWelding",
        skillLevel = 4,
        materials = { "Base.MetalPipe:6", "Base.Hinge:2", "Base.ScrapMetal:6", "Base.Screws:2" },
        health = 400,
        sprite = "fixtures_doors_fences_01_24",
        northSprite = "fixtures_doors_fences_01_25",
    },
    {
        name = "IGUI_AutoDoor_FenceGate_Wood",
        skill = "Woodwork",
        skillLevel = 3,
        materials = { "Base.Plank:4", "Base.Nails:4", "Base.Hinge:2", "Base.Doorknob:1" },
        health = 300,
        sprite = "fixtures_doors_fences_01_4",
        northSprite = "fixtures_doors_fences_01_5",
    },
}

-- Convert a material list {"Base.Plank:8", ...} into the modData format
-- used by ISBuildingObject:haveMaterial().
function AutoDoor.buildModData(materials)
    local modData = {}
    for _, entry in ipairs(materials) do
        local idx = entry:find(":")
        if idx then
            modData["need:" .. entry:sub(1, idx - 1)] = entry:sub(idx + 1)
        end
    end
    return modData
end

-- True if the door was created by this mod.
function AutoDoor.isAutoDoor(object)
    if not instanceof(object, "IsoDoor") then return false end
    local md = object:getModData()
    return md and md.autoDoor == true
end

-- Walk a garage door chain and return all its parts (native statics).
-- Returns a single-element list for regular doors.
function AutoDoor.getGarageDoorParts(door)
    if not door then return {} end
    if IsoDoor.getGarageDoorIndex(door) == -1 then
        return { door }
    end
    local cur = door
    local prev = IsoDoor.getGarageDoorPrev(cur)
    while prev do
        cur = prev
        prev = IsoDoor.getGarageDoorPrev(cur)
    end
    local parts = {}
    while cur do
        table.insert(parts, cur)
        cur = IsoDoor.getGarageDoorNext(cur)
    end
    return parts
end

-- The first (leftmost) part of a garage door chain.
function AutoDoor.getGarageDoorAnchor(door)
    local parts = AutoDoor.getGarageDoorParts(door)
    return parts[1] or door
end

-- Unlock every part of a door chain. Mirrors the vanilla ISLockDoor pattern.
function AutoDoor.unlockDoor(door)
    local parts = AutoDoor.getGarageDoorParts(door)
    for _, part in ipairs(parts) do
        if part:isLockedByKey() then
            part:setLockedByKey(false)
            part:syncIsoObject(false, 0, nil, nil)
        end
    end
end

-- Toggle a door open/closed. Garage doors are toggled through their anchor
-- part; the native code animates the whole chain.
function AutoDoor.toggleDoor(player, door)
    if not door then return false end
    if door:isDestroyed() then return false end
    local target = AutoDoor.getGarageDoorAnchor(door)
    if not target then return false end
    target:ToggleDoor(player)
    return true
end

-- Square used as the search origin: the vehicle square while seated,
-- otherwise the player square.
function AutoDoor.getAnchorSquare(player)
    local vehicle = player:getVehicle()
    if vehicle then
        local sq = vehicle:getSquare()
        if sq then return sq end
    end
    return player:getCurrentSquare()
end

-- Find auto doors within radius of the anchor square, optionally filtered
-- by the key id held by the remote/key item.
function AutoDoor.findPairedDoors(player, keyId, radius)
    local doors = {}
    local anchor = AutoDoor.getAnchorSquare(player)
    if not anchor then return doors end
    radius = radius or AutoDoor.SEARCH_RADIUS
    local z = anchor:getZ()
    for dx = -radius, radius do
        for dy = -radius, radius do
            local sq = getCell():getGridSquare(anchor:getX() + dx, anchor:getY() + dy, z)
            if sq then
                local objects = sq:getObjects()
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    if AutoDoor.isAutoDoor(obj) then
                        if keyId == -1 or obj:getKeyId() == keyId then
                            table.insert(doors, obj)
                        end
                    end
                end
            end
        end
    end
    return doors
end

-- Nearest door in the list.
function AutoDoor.getNearestDoor(player, doors)
    local best, bestDist = nil, nil
    for _, door in ipairs(doors) do
        local sq = door:getSquare()
        local dist = player:getCurrentSquare():DistTo(sq)
        if bestDist == nil or dist < bestDist then
            best, bestDist = door, dist
        end
    end
    return best
end

-- Generate the remote + key for a newly built door and hand them to the player.
function AutoDoor.grantAccessories(player, keyId)
    if not player then return end
    local remote = instanceItem(AutoDoor.ITEM_REMOTE)
    remote:setKeyId(keyId)
    if not player:getInventory():AddItem(remote) then
        player:getCurrentSquare():AddWorldInventoryItem(remote, 0.5, 0.5, 0.0)
    end
    local key = instanceItem(AutoDoor.ITEM_KEY)
    key:setKeyId(keyId)
    if not player:getInventory():AddItem(key) then
        player:getCurrentSquare():AddWorldInventoryItem(key, 0.5, 0.5, 0.0)
    end
end
