-- Client door context menu: install, re-pair, replace battery, uninstall.
require "AutoDoor/AutoDoorDoorLib"

AutoDoorInstallMenu = {}

function AutoDoorInstallMenu.findDoor(worldobjects)
    if not worldobjects then return nil end
    for _, obj in ipairs(worldobjects) do
        if AutoDoor.isAutomatableDoor(obj) then
            return obj
        end
    end
    return nil
end

-- The server consumes the battery, places the motor next to the door and pairs it.
function AutoDoorInstallMenu.onInstall(playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local remote = AutoDoor.getRemote(player)
    if not remote then return end
    AutoDoor.ensureRemoteId(player, remote) -- pairing id is generated and synced client-side
    sendClientCommand(player, "AutoDoor", "Install", { x = door:getX(), y = door:getY(), z = door:getZ() })
end

-- Re-pairs the door with a different remote (no motor needed).
function AutoDoorInstallMenu.onRePair(playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local remote = AutoDoor.getRemote(player)
    if not remote then return end
    AutoDoor.ensureRemoteId(player, remote)
    sendClientCommand(player, "AutoDoor", "Repair", { x = door:getX(), y = door:getY(), z = door:getZ() })
end

-- Consumes one battery and refills the motor to full charge.
function AutoDoorInstallMenu.onReplaceBattery(playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    sendClientCommand(player, "AutoDoor", "ReplaceBattery", { x = door:getX(), y = door:getY(), z = door:getZ() })
end

function AutoDoorInstallMenu.onUnpair(playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    sendClientCommand(player, "AutoDoor", "Uninstall", { x = door:getX(), y = door:getY(), z = door:getZ() })
end

local function hasRemote(playerObj)
    return AutoDoor.getRemote(playerObj) ~= nil
end

local function hasBattery(playerObj)
    return AutoDoor.getBattery(playerObj) ~= nil
end

local function hasInstallItems(playerObj)
    return hasRemote(playerObj)
        and AutoDoor.getMotor(playerObj) ~= nil
        and hasBattery(playerObj)
end

local function makeTooltip(playerObj, key, fallback)
    local tooltip = ISToolTip:new(playerObj)
    tooltip:initialise()
    tooltip:setName(AutoDoor.text(key, fallback))
    -- description must stay "" (an empty table crashes the tooltip renderer)
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

-- The remote never bypasses locks, so only unlocked doors can be paired.
local function canInstallOn(door)
    return not door:isLockedByKey()
end

-- Debug only: skips the recipe and hands out an already-paired remote.
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

-- Our options go inside the vanilla "Door" submenu when it exists.
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

    local menu = AutoDoorInstallMenu.findDoorSubMenu(context) or context

    local md = door:getModData()
    if md.autoDoor then
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
            install.notAvailable = true
            install.onSelect = nil
            install.toolTip = lockedTooltip(player)
        end
    end

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

-- Server-confirmed UI sound (install/remove actions run server-side).
local function onServerCommand(module, command, args)
    if module ~= "AutoDoor" or command ~= "Sound" then return end
    if args and args.sound then
        getSoundManager():playUISound(args.sound)
    end
end

Events.OnFillWorldObjectContextMenu.Add(AutoDoorInstallMenu.doDoorMenu)
Events.OnServerCommand.Add(onServerCommand)
