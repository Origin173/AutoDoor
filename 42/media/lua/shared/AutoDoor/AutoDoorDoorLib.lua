--[[
    AutoDoor shared library.
    Door helpers used by the client-side install menu and the remote
    control logic. Only relies on native APIs so it can be loaded on
    every side (shared).

    Design: the mod never replaces door objects. A vanilla garage door
    or fence gate keeps its original object, sprites, size and native
    open/close animation. "Installing" only tags the door with ModData
    (autoDoor + remoteKeyId) and pairs it with a remote control id.
]]

AutoDoor = {}

AutoDoor.ITEM_REMOTE = "Base.RemoteDoorOpener"
AutoDoor.SEARCH_RADIUS = 12
-- All vanilla fence gates live under this sprite prefix
-- (fixtures_doors_fences_01_0 .. _131).
AutoDoor.FENCE_GATE_PREFIX = "fixtures_doors_fences_01_"

-- ------------------------------------------------------------
-- Door type detection (vanilla doors only)
-- ------------------------------------------------------------

-- Garage doors carry the "GarageDoor" tile property (1..6:
-- closed left/middle/right + open variants). This is the same check
-- vanilla itself uses (ISZoneDisplay.lua).
function AutoDoor.isGarageDoor(object)
    if not instanceof(object, "IsoDoor") then return false end
    local props = object:getProperties()
    return props ~= nil and props:has("GarageDoor")
end

-- Fence gates are IsoDoors whose sprite belongs to the
-- fixtures_doors_fences_01_ tileset (single gates and double gates).
function AutoDoor.isFenceGate(object)
    if not instanceof(object, "IsoDoor") then return false end
    local sprite = object:getSprite()
    if not sprite then return false end
    local name = sprite:getName()
    return name ~= nil and name:sub(1, #AutoDoor.FENCE_GATE_PREFIX) == AutoDoor.FENCE_GATE_PREFIX
end

function AutoDoor.isAutomatableDoor(object)
    return AutoDoor.isGarageDoor(object) or AutoDoor.isFenceGate(object)
end

-- True when the door has been automated by this mod
-- (installed opener, or a door built by the old version of the mod).
function AutoDoor.isAutoDoor(object)
    if not instanceof(object, "IsoDoor") then return false end
    local md = object:getModData()
    return md ~= nil and (md.autoDoor == true or md.remoteKeyId ~= nil)
end

-- ------------------------------------------------------------
-- Door units / chains
-- ------------------------------------------------------------

-- All parts of one door unit, native chain handling:
--   - garage doors: IsoDoor.getGarageDoorPrev/Next
--   - double doors: IsoDoor.getDoubleDoorObject (slots 1..4)
-- A regular door is its own unit.
function AutoDoor.getDoorParts(door)
    local parts = {}
    local seen = {}
    local function add(obj)
        if obj and not seen[obj:getId()] then
            seen[obj:getId()] = true
            table.insert(parts, obj)
        end
    end
    if not door then return parts end
    add(door)
    if AutoDoor.isGarageDoor(door) and IsoDoor.getGarageDoorIndex(door) ~= -1 then
        local cur = door
        local prev = IsoDoor.getGarageDoorPrev(cur)
        while prev do
            cur = prev
            prev = IsoDoor.getGarageDoorPrev(cur)
        end
        while cur do
            add(cur)
            cur = IsoDoor.getGarageDoorNext(cur)
        end
    end
    for i = 1, 4 do
        add(IsoDoor.getDoubleDoorObject(door, i))
    end
    return parts
end

-- Anchor (first) part of a door unit, used to toggle the whole chain.
function AutoDoor.getDoorAnchor(door)
    local parts = AutoDoor.getDoorParts(door)
    return parts[1] or door
end

-- ------------------------------------------------------------
-- Remote identity
-- ------------------------------------------------------------

-- The pairing id of a remote. New remotes store it in their ModData
-- (set on first pairing); remotes from the old version of the mod
-- used the item keyId field instead.
function AutoDoor.getRemoteId(remote)
    if not remote then return nil end
    local id = remote:getModData().autoDoorRemoteId
    if id and id > 0 then return id end
    local legacy = remote:getKeyId()
    if legacy and legacy > 0 then return legacy end
    return nil
end

-- The first remote control in the player's inventory (anywhere,
-- including containers inside the inventory).
function AutoDoor.getRemote(player)
    if not player then return nil end
    return player:getInventory():getFirstTypeRecurse(AutoDoor.ITEM_REMOTE)
end

-- Give the remote a fresh unique id the first time it is paired.
-- The item change is synced with the vanilla syncItemModData helper
-- so it survives in multiplayer as well.
function AutoDoor.ensureRemoteId(player, remote)
    local id = AutoDoor.getRemoteId(remote)
    if id then return id end
    id = ZombRand(100000, 999999)
    remote:getModData().autoDoorRemoteId = id
    if isClient() and syncItemModData then
        syncItemModData(player, remote)
    end
    return id
end

-- ------------------------------------------------------------
-- Pairing / unpairing
-- ------------------------------------------------------------

-- Install the opener on a door and pair it with a remote.
-- One remote can be paired with any number of doors; the door keeps
-- its original key (a locked door still needs its original key to be
-- unlocked automatically). The ModData change is transmitted with the
-- vanilla transmitModData helper.
function AutoDoor.pairDoor(player, door, remote)
    if not door or not remote then return false end
    local id = AutoDoor.ensureRemoteId(player, remote)
    local parts = AutoDoor.getDoorParts(door)
    for _, part in ipairs(parts) do
        local md = part:getModData()
        md.autoDoor = true
        md.remoteKeyId = id
        part:transmitModData()
    end
    return true
end

-- Remove the opener: the door goes back to a plain vanilla door.
function AutoDoor.unpairDoor(door)
    if not door then return end
    local parts = AutoDoor.getDoorParts(door)
    for _, part in ipairs(parts) do
        local md = part:getModData()
        md.autoDoor = nil
        md.remoteKeyId = nil
        part:transmitModData()
    end
end

-- True when the door is paired with the given remote id.
function AutoDoor.doorMatchesRemote(door, remoteId)
    if not remoteId then return false end
    local md = door:getModData()
    if not md then return false end
    if md.remoteKeyId ~= nil then
        return md.remoteKeyId == remoteId
    end
    -- Doors built by the old version of this mod are paired through
    -- the door's own keyId.
    return md.autoDoor == true and door:getKeyId() == remoteId
end

-- ------------------------------------------------------------
-- Remote control
-- ------------------------------------------------------------

-- Unlock every part of a door unit (mirrors the vanilla ISLockDoor
-- sync pattern).
function AutoDoor.unlockDoor(door)
    local parts = AutoDoor.getDoorParts(door)
    for _, part in ipairs(parts) do
        if part:isLockedByKey() then
            part:setLockedByKey(false)
            part:syncIsoObject(false, 0, nil, nil)
        end
    end
end

-- Toggle a door open/closed. Chains are toggled through their anchor
-- part; the native code animates and syncs the whole unit.
function AutoDoor.toggleDoor(player, door)
    if not door then return false end
    if door:isDestroyed() then return false end
    local target = AutoDoor.getDoorAnchor(door)
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

-- Find auto doors paired with the given remote id within radius of the
-- anchor square (the vehicle position while the player is seated).
function AutoDoor.findPairedDoors(player, remoteId, radius)
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
                    if AutoDoor.isAutoDoor(obj) and AutoDoor.doorMatchesRemote(obj, remoteId) then
                        table.insert(doors, obj)
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
