--[[
    AutoDoor install menu (client).
    Right-click a vanilla garage door, fence gate or player-built door:
      - not automated : "Install Auto Door Opener" — installs the signal
        receiver + motor unit (consumes one motor item and one battery)
        and pairs it with a remote control from your inventory.
      - automated     : "Auto Door Opener" submenu with re-pair with a
        different remote / replace battery / remove the opener.
    The door itself is never replaced: it keeps its original look, size,
    sprites and native open/close animation.
]]

require "AutoDoor/AutoDoorDoorLib"

AutoDoorInstallMenu = {}

-- First automatable door among the clicked objects.
function AutoDoorInstallMenu.findDoor(worldobjects)
    if not worldobjects then return nil end
    for _, obj in ipairs(worldobjects) do
        if AutoDoor.isAutomatableDoor(obj) then
            return obj
        end
    end
    return nil
end

-- Fresh install: consumes one motor unit and one battery (the motor's
-- first battery), then pairs the door with the remote.
function AutoDoorInstallMenu.onInstall(playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local remote = AutoDoor.getRemote(player)
    local motor = AutoDoor.getMotor(player)
    local battery = AutoDoor.getBattery(player)
    if not remote or not motor or not battery then return end
    if AutoDoor.pairDoor(player, door, remote) then
        motor:getContainer():Remove(motor)
        battery:getContainer():Remove(battery)
        getSoundManager():playUISound("UIActivateButton")
    end
end

-- Re-pair an automated door with a different remote (no motor needed).
function AutoDoorInstallMenu.onRePair(playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local remote = AutoDoor.getRemote(player)
    if not remote then return end
    if AutoDoor.pairDoor(player, door, remote) then
        getSoundManager():playUISound("UIActivateButton")
    end
end

-- Replace the motor's battery (consumes one Battery item).
function AutoDoorInstallMenu.onReplaceBattery(playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local battery = AutoDoor.getBattery(player)
    if not battery then return end
    battery:getContainer():Remove(battery)
    AutoDoor.refillBattery(door)
    getSoundManager():playUISound("UIActivateButton")
end

function AutoDoorInstallMenu.onUnpair(playerNum, door)
    AutoDoor.unpairDoor(door)
    getSoundManager():playUISound("UIActivateButton")
end

local function hasRemote(playerObj)
    return AutoDoor.getRemote(playerObj) ~= nil
end

local function hasBattery(playerObj)
    return AutoDoor.getBattery(playerObj) ~= nil
end

-- Everything a fresh install needs: remote + motor + battery.
local function hasInstallItems(playerObj)
    return hasRemote(playerObj)
        and AutoDoor.getMotor(playerObj) ~= nil
        and hasBattery(playerObj)
end

local function makeTooltip(playerObj, key, fallback)
    local tooltip = ISToolTip:new(playerObj)
    tooltip:initialise()
    tooltip:setName(AutoDoor.text(key, fallback))
    -- description stays at its default "" (empty string): an empty TABLE
    -- would crash the tooltip renderer (ISToolTip.layoutContents only
    -- guards against "").
    return tooltip
end

local function installTooltip(playerObj)
    if hasInstallItems(playerObj) then return nil end
    return makeTooltip(playerObj, "IGUI_AutoDoor_NeedItems",
        "Requires in inventory: a remote, an auto door motor and a battery")
end

local function batteryTooltip(playerObj)
    if hasBattery(playerObj) then return nil end
    return makeTooltip(playerObj, "IGUI_AutoDoor_NeedBattery", "A battery is required in your inventory")
end

local function lockedTooltip(playerObj)
    return makeTooltip(playerObj, "IGUI_AutoDoor_CannotInstallLocked",
        "Cannot install on a locked door (unlock it first)")
end

-- The opener can only be installed on an unlocked door: the remote
-- simply automates the open/close action and never bypasses locks.
local function canInstallOn(door)
    return not door:isLockedByKey()
end

-- Debug helper (only visible with the -debug launch option):
-- installs the opener (motor + battery consumed) and hands the player
-- the already-paired remote plus the magazine, skipping the recipe.
function AutoDoorInstallMenu.onDebugSpawnRemote(playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local remote = instanceItem(AutoDoor.ITEM_REMOTE)
    local motor = instanceItem(AutoDoor.ITEM_MOTOR)
    local battery = instanceItem(AutoDoor.ITEM_BATTERY)
    local magazine = instanceItem(AutoDoor.ITEM_MAGAZINE)
    if AutoDoor.pairDoor(player, door, remote) then
        player:getInventory():AddItem(remote)
        if magazine then
            player:getInventory():AddItem(magazine)
        end
        getSoundManager():playUISound("UIActivateButton")
    end
end

-- The vanilla "Door" submenu (with Open/Lock) is created by the engine
-- before OnFillWorldObjectContextMenu fires. Find it so our options sit
-- right next to "Open Door", inside 门 > . Falls back to nil (top level).
function AutoDoorInstallMenu.findDoorSubMenu(context)
    if not context or not context.options then return nil end
    local doorTitles = {
        getText("ContextMenu_Door_option"),
        getText("ContextMenu_Door"),
    }
    for _, opt in ipairs(context.options) do
        if opt and opt.subOption ~= nil and opt.name then
            for _, title in ipairs(doorTitles) do
                if opt.name == title then
                    local subMenu = context:getSubMenu(opt.subOption)
                    if subMenu then return subMenu end
                end
            end
        end
    end
    return nil
end

function AutoDoorInstallMenu.doDoorMenu(playerNum, context, worldobjects, test)
    local door = AutoDoorInstallMenu.findDoor(worldobjects)
    if not door then return end
    local player = getSpecificPlayer(playerNum)
    if not player or player:isDead() then return end

    -- Our options go inside the vanilla "Door" submenu, next to
    -- Open/Lock; fall back to the top level if it is not there.
    local menu = AutoDoorInstallMenu.findDoorSubMenu(context) or context

    local md = door:getModData()
    if md.autoDoor then
        -- Already automated: manage submenu.
        local subMenu = ISContextMenu:getNew(menu)
        menu:addSubMenu(menu:addOption(AutoDoor.text("IGUI_AutoDoor_Manage", "Auto Door Opener")), subMenu)
        local rePair = subMenu:addOption(AutoDoor.text("IGUI_AutoDoor_RepairPair", "Re-pair With Remote"), playerNum,
            AutoDoorInstallMenu.onRePair, door)
        if not hasRemote(player) then
            rePair.notAvailable = true
            rePair.onSelect = nil
            rePair.toolTip = makeTooltip(player, "IGUI_AutoDoor_NeedRemote",
                "A remote control is required in your inventory")
        end
        local battery = subMenu:addOption(AutoDoor.text("IGUI_AutoDoor_ReplaceBattery", "Replace Battery"), playerNum,
            AutoDoorInstallMenu.onReplaceBattery, door)
        battery.toolTip = batteryTooltip(player)
        if not hasBattery(player) then
            battery.notAvailable = true
            battery.onSelect = nil
        end
        subMenu:addOption(AutoDoor.text("IGUI_AutoDoor_Uninstall", "Remove Auto Door Opener"), playerNum,
            AutoDoorInstallMenu.onUnpair, door)
    else
        local install = menu:addOption(AutoDoor.text("IGUI_AutoDoor_Install", "Install Auto Door Opener"), playerNum,
            AutoDoorInstallMenu.onInstall, door)
        install.toolTip = installTooltip(player)
        if not hasInstallItems(player) then
            install.notAvailable = true
            install.onSelect = nil
        elseif not canInstallOn(door) then
            -- Locked doors cannot be paired: the remote never bypasses locks.
            install.notAvailable = true
            install.onSelect = nil
            install.toolTip = lockedTooltip(player)
        end
    end

    -- Debug mode only: one-click paired remote for testing.
    local debugOn = false
    if isDebugEnabled then
        local ok, res = pcall(isDebugEnabled)
        if ok and res then debugOn = true end
    end
    if not debugOn and getCore and getCore():getDebug() then debugOn = true end
    if debugOn then
        menu:addOption(AutoDoor.text("IGUI_AutoDoor_DebugSpawnRemote", "Debug: Spawn Paired Remote"), playerNum,
            AutoDoorInstallMenu.onDebugSpawnRemote, door)
    end
end

Events.OnFillWorldObjectContextMenu.Add(AutoDoorInstallMenu.doDoorMenu)
