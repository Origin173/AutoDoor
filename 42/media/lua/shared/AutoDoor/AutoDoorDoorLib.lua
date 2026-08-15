-- Shared door helpers (detection, pairing, motor power). Loaded on every side.
AutoDoor = {}

AutoDoor.ITEM_REMOTE = "Base.RemoteDoorOpener"
AutoDoor.ITEM_MOTOR = "Base.AutoDoorMotor" -- receiver + motor unit installed on the door
AutoDoor.ITEM_BATTERY = "Base.Battery"
AutoDoor.ITEM_MAGAZINE = "Base.AutoDoorMagazine" -- reading it unlocks the recipes
AutoDoor.MOTOR_MAX_CHARGE = 100
AutoDoor.MOTOR_CHARGE_PER_USE = 0.5
AutoDoor.SEARCH_RADIUS = 12
AutoDoor.FENCE_GATE_PREFIX = "fixtures_doors_fences_01_" -- all vanilla fence gates share this sprite prefix

-- getText fallback; a nil text would crash tooltip/menu rendering.
function AutoDoor.text(key, fallback)
    local t = getText(key)
    if t == nil or t == "" or t == key then
        return fallback
    end
    return t
end

-- Vanilla garage doors carry the "GarageDoor" tile property.
function AutoDoor.isGarageDoor(object)
    if not instanceof(object, "IsoDoor") then return false end
    local props = object:getProperties()
    return props ~= nil and props:has("GarageDoor")
end

-- Fence gates are IsoDoors using the fixtures_doors_fences_01_ tileset.
function AutoDoor.isFenceGate(object)
    if not instanceof(object, "IsoDoor") then return false end
    local sprite = object:getSprite()
    if not sprite then return false end
    local name = sprite:getName()
    return name ~= nil and name:sub(1, #AutoDoor.FENCE_GATE_PREFIX) == AutoDoor.FENCE_GATE_PREFIX
end

function AutoDoor.isAutomatableDoor(object)
    return AutoDoor.isGarageDoor(object) or AutoDoor.isFenceGate(object)
        or AutoDoor.isBuiltDoor(object)
end

-- Player-built doors (IsoThumpable) carry "need:" build markers in ModData.
function AutoDoor.isBuiltDoor(object)
    if not instanceof(object, "IsoThumpable") then return false end
    if not object:isDoor() then return false end
    local md = object:getModData()
    if not md then return false end
    for key, _ in pairs(md) do
        if type(key) == "string" and key:sub(1, 5) == "need:" then
            return true
        end
    end
    return false
end

function AutoDoor.isAutoDoor(object)
    if not (instanceof(object, "IsoDoor") or instanceof(object, "IsoThumpable")) then
        return false
    end
    local md = object:getModData()
    return md ~= nil and (md.autoDoor == true or md.remoteKeyId ~= nil)
end

-- Parts of one door unit, deduped by position + facing + sprite (world objects expose no ID API in Lua).
function AutoDoor.getDoorParts(door)
    local parts = {}
    local seen = {}
    local function keyOf(obj)
        local sprite = obj:getSprite()
        return tostring(obj:getX()) .. "," .. tostring(obj:getY()) .. "," .. tostring(obj:getZ())
            .. "|" .. tostring(obj:getNorth())
            .. "|" .. (sprite and sprite:getName() or "")
    end
    local function add(obj)
        if obj then
            local k = keyOf(obj)
            if not seen[k] then
                seen[k] = true
                table.insert(parts, obj)
            end
        end
    end
    if not door then return parts end
    add(door)
    -- Walk the whole garage unit via prev/next.
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
    -- Double-door chains are linked natively for IsoDoor only; built doors toggle per part.
    if instanceof(door, "IsoDoor") then
        for i = 1, 4 do
            add(IsoDoor.getDoubleDoorObject(door, i))
        end
    end
    return parts
end

-- Anchor (first) part of a door unit, used to toggle the whole chain.
function AutoDoor.getDoorAnchor(door)
    local parts = AutoDoor.getDoorParts(door)
    return parts[1] or door
end

-- The end part of a door unit (a stable "post" side). Used as the placement
-- anchor so the motor always lands next to the same end of the door, no matter
-- which part of the door the player right-clicked.
function AutoDoor.getDoorPost(door)
    if not door then return nil end
    local parts = AutoDoor.getDoorParts(door)
    return parts[#parts] or door
end

-- Pairing id stored on the remote's ModData.
function AutoDoor.getRemoteId(remote)
    if not remote then return nil end
    local id = remote:getModData().autoDoorId
    if id and id > 0 then return id end
    return nil
end

function AutoDoor.getRemote(player)
    if not player then return nil end
    return player:getInventory():getFirstTypeRecurse(AutoDoor.ITEM_REMOTE)
end

function AutoDoor.getMotor(player)
    if not player then return nil end
    return player:getInventory():getFirstTypeRecurse(AutoDoor.ITEM_MOTOR)
end

function AutoDoor.getBattery(player)
    if not player then return nil end
    return player:getInventory():getFirstTypeRecurse(AutoDoor.ITEM_BATTERY)
end

-- First pairing assigns a random id, synced so MP clients agree.
function AutoDoor.ensureRemoteId(player, remote)
    local id = AutoDoor.getRemoteId(remote)
    if id then return id end
    id = ZombRand(100000, 999999)
    remote:getModData().autoDoorId = id
    if isClient() and syncItemModData then
        syncItemModData(player, remote)
    end
    return id
end

-- Motor charge is only set on a fresh install; re-pairing keeps the current charge.
function AutoDoor.pairDoor(player, door, remote)
    if not door or not remote then return false end
    local id = AutoDoor.ensureRemoteId(player, remote)
    local parts = AutoDoor.getDoorParts(door)
    for _, part in ipairs(parts) do
        local md = part:getModData()
        md.autoDoor = true
        md.remoteKeyId = id
        if md.motorCharge == nil then
            md.motorCharge = AutoDoor.MOTOR_MAX_CHARGE
        end
        part:transmitModData()
    end
    return true
end

function AutoDoor.getMotorCharge(door)
    if not door then return 0 end
    local md = door:getModData()
    return md and md.motorCharge or 0
end

-- The motor unit placed on the ground next to the door (nil when picked up).
-- Returns the IsoWorldInventoryObject that wraps the motor InventoryItem.
function AutoDoor.getMotorItem(door)
    if not door then return nil end
    local md = door:getModData()
    if not md or not md.motorX then return nil end
    local sq = getCell():getGridSquare(md.motorX, md.motorY, md.motorZ)
    if not sq then return nil end
    local world = sq:getWorldObjects()
    for i = 0, world:size() - 1 do
        local worldItem = world:get(i)
        if worldItem and worldItem.getItem then
            local invItem = worldItem:getItem()
            if invItem and invItem.getModData and invItem:getModData().autoDoorMotor then
                return worldItem
            end
        end
    end
    return nil
end

-- Returns the underlying InventoryItem of the placed motor (nil when not found).
function AutoDoor.getMotorInventoryItem(door)
    local worldItem = AutoDoor.getMotorItem(door)
    if not worldItem then return nil end
    return worldItem:getItem()
end

-- Finds a placed motor world item directly from a world object (used by the
-- right-click menu on the motor itself).
function AutoDoor.getMotorFromWorldObject(worldObj)
    if not worldObj then return nil end
    if not instanceof(worldObj, "IsoWorldInventoryObject") then return nil end
    local invItem = worldObj:getItem()
    if invItem and invItem.getModData and invItem:getModData().autoDoorMotor then
        return worldObj
    end
    return nil
end

-- Returns the door that a placed motor is linked to (nil if unlinked/picked up).
function AutoDoor.getDoorFromMotor(worldObj)
    local motorInv = nil
    if instanceof(worldObj, "IsoWorldInventoryObject") then
        motorInv = worldObj:getItem()
    elseif instanceof(worldObj, "InventoryItem") then
        motorInv = worldObj
    end
    if not motorInv then return nil end
    local mmd = motorInv:getModData()
    if not mmd or not mmd.doorX then return nil end
    local sq = getCell():getGridSquare(mmd.doorX, mmd.doorY, mmd.doorZ)
    if not sq then return nil end
    for i = 0, sq:getObjects():size() - 1 do
        local obj = sq:getObjects():get(i)
        if AutoDoor.isAutoDoor(obj) then return obj end
    end
    return nil
end

-- True when the motor is charged and still sits next to the door.
function AutoDoor.canOperate(door)
    if not door then return false end
    if AutoDoor.getMotorCharge(door) <= 0 then return false end
    local md = door:getModData()
    if not md or not md.motorX then return true end -- legacy installs without a placed motor
    return AutoDoor.getMotorItem(door) ~= nil
end

-- First free square next to the door. We prefer the diagonal neighbours
-- (the door-post / pillar corners) so the motor sits beside the door frame
-- instead of blocking the doorway. Orthogonal neighbours and 2-tile offsets
-- are used as fallback only.
function AutoDoor.findMotorSquare(door)
    local anchor = AutoDoor.getDoorPost(door)
    if not anchor then return nil end
    local ax, ay, az = anchor:getX(), anchor:getY(), anchor:getZ()
    local order = {
        -- door-post / pillar corners first (diagonal, beside the frame)
        { ax - 1, ay - 1 }, { ax + 1, ay - 1 }, { ax - 1, ay + 1 }, { ax + 1, ay + 1 },
        -- then orthogonal neighbours (still beside the door, not in front)
        { ax - 1, ay }, { ax + 1, ay }, { ax, ay - 1 }, { ax, ay + 1 },
        -- wider fallback
        { ax - 2, ay - 1 }, { ax + 2, ay - 1 }, { ax - 2, ay + 1 }, { ax + 2, ay + 1 },
        { ax - 1, ay - 2 }, { ax + 1, ay - 2 }, { ax - 1, ay + 2 }, { ax + 1, ay + 2 },
        { ax - 2, ay }, { ax + 2, ay }, { ax, ay - 2 }, { ax, ay + 2 },
    }
    for _, c in ipairs(order) do
        local sq = getCell():getGridSquare(c[1], c[2], az)
        if sq and not sq:isSolid() and not sq:isSolidTrans() and sq:TreatAsSolidFloor() then
            return sq
        end
    end
    return nil
end

function AutoDoor.consumeMotorPower(door)
    if not door then return end
    local parts = AutoDoor.getDoorParts(door)
    for _, part in ipairs(parts) do
        local md = part:getModData()
        if md and md.motorCharge ~= nil then
            md.motorCharge = math.max(0, md.motorCharge - AutoDoor.MOTOR_CHARGE_PER_USE)
            part:transmitModData()
        end
    end
end

-- Replaces the battery: refills the motor to full charge.
function AutoDoor.refillBattery(door)
    if not door then return end
    local parts = AutoDoor.getDoorParts(door)
    for _, part in ipairs(parts) do
        local md = part:getModData()
        md.motorCharge = AutoDoor.MOTOR_MAX_CHARGE
        part:transmitModData()
    end
end

-- Removes the battery: discharges the motor to zero.
function AutoDoor.dischargeBattery(door)
    if not door then return end
    local parts = AutoDoor.getDoorParts(door)
    for _, part in ipairs(parts) do
        local md = part:getModData()
        md.motorCharge = 0
        part:transmitModData()
    end
end

-- Removes the opener; the door becomes a plain vanilla door again.
function AutoDoor.unpairDoor(door)
    if not door then return end
    -- Grab the motor BEFORE clearing the door's motor square info below,
    -- otherwise getMotorItem() can no longer find it.
    local motorWorldItem = AutoDoor.getMotorItem(door)
    local parts = AutoDoor.getDoorParts(door)
    for _, part in ipairs(parts) do
        local md = part:getModData()
        md.autoDoor = nil
        md.remoteKeyId = nil
        md.motorX, md.motorY, md.motorZ = nil, nil, nil
        part:transmitModData()
    end
    -- The motor stays on the ground, unlinked, so it can be picked up again.
    if motorWorldItem then
        -- Note: `obj:method and obj:method()` is a Lua syntax error; use a dot index for the guard.
        local inv = motorWorldItem.getItem and motorWorldItem:getItem()
        if inv then
            local mmd = inv:getModData()
            mmd.doorX, mmd.doorY, mmd.doorZ = nil, nil, nil
            mmd.autoDoorMotor = nil
            -- B42: transmitCompleteItemToClients is no longer exposed by
            -- IsoWorldInventoryObject; sync the inner InventoryItem's ModData instead.
            if inv.transmitModData then
                inv:transmitModData()
            end
        end
    end
end

function AutoDoor.doorMatchesRemote(door, remoteId)
    if not remoteId then return false end
    local md = door:getModData()
    if not md then return false end
    return md.remoteKeyId == remoteId
end

-- Unlocks every part of a door unit.
function AutoDoor.unlockDoor(door)
    local parts = AutoDoor.getDoorParts(door)
    for _, part in ipairs(parts) do
        if part:isLockedByKey() then
            part:setLockedByKey(false)
            part:syncIsoObject(false, 0, nil, nil)
        end
    end
end

-- Toggles through the anchor part so the whole chain animates as one unit.
function AutoDoor.toggleDoor(player, door)
    if not door then return false end
    if door:isDestroyed() then return false end
    local target = AutoDoor.getDoorAnchor(door)
    if not target then return false end
    target:ToggleDoor(player)
    return true
end

-- Search origin: the vehicle square while seated, otherwise the player square.
function AutoDoor.getAnchorSquare(player)
    local vehicle = player:getVehicle()
    if vehicle then
        local sq = vehicle:getSquare()
        if sq then return sq end
    end
    return player:getCurrentSquare()
end

-- Doors paired with the remote id within radius of the anchor square.
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
