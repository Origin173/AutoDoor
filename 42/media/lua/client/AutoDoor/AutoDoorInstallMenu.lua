--[[
    AutoDoor install menu (client).
    Right-click a vanilla garage door or fence gate:
      - not automated : "Install Auto Door Opener" — pairs the door with
        a remote control from your inventory (greyed out without one).
      - automated     : "Auto Door Opener" submenu with re-pair with a
        different remote / remove the opener.
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

function AutoDoorInstallMenu.onInstall(playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local remote = AutoDoor.getRemote(player)
    if not remote then return end
    if AutoDoor.pairDoor(player, door, remote) then
        getSoundManager():playUISound("UIActivateButton")
    end
end

function AutoDoorInstallMenu.onUnpair(playerNum, door)
    AutoDoor.unpairDoor(door)
    getSoundManager():playUISound("UIActivateButton")
end

local function hasRemote(playerObj)
    return AutoDoor.getRemote(playerObj) ~= nil
end

local function remoteTooltip(playerObj)
    if hasRemote(playerObj) then return nil end
    local tooltip = ISToolTip:new(playerObj)
    tooltip:initialise()
    tooltip:setName(getText("IGUI_AutoDoor_NeedRemote"))
    tooltip.description = {}
    return tooltip
end

local function lockedTooltip(playerObj)
    local tooltip = ISToolTip:new(playerObj)
    tooltip:initialise()
    tooltip:setName(getText("IGUI_AutoDoor_CannotInstallLocked"))
    tooltip.description = {}
    return tooltip
end

-- The opener can only be installed on an unlocked door: the remote
-- simply automates the open/close action and never bypasses locks.
local function canInstallOn(door)
    return not door:isLockedByKey()
end

-- Debug helper (only visible with the -debug launch option):
-- spawns a remote already paired with this door, skipping the recipe.
function AutoDoorInstallMenu.onDebugSpawnRemote(playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then return end
    local remote = instanceItem(AutoDoor.ITEM_REMOTE)
    if AutoDoor.pairDoor(player, door, remote) then
        player:getInventory():AddItem(remote)
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
        menu:addSubMenu(menu:addOption(getText("IGUI_AutoDoor_Manage")), subMenu)
        local rePair = subMenu:addOption(getText("IGUI_AutoDoor_RepairPair"), playerNum,
            AutoDoorInstallMenu.onInstall, door)
        rePair.toolTip = remoteTooltip(player)
        if not hasRemote(player) then
            rePair.notAvailable = true
            rePair.onSelect = nil
        end
        subMenu:addOption(getText("IGUI_AutoDoor_Uninstall"), playerNum,
            AutoDoorInstallMenu.onUnpair, door)
    else
        local install = menu:addOption(getText("IGUI_AutoDoor_Install"), playerNum,
            AutoDoorInstallMenu.onInstall, door)
        install.toolTip = remoteTooltip(player)
        if not hasRemote(player) then
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
        menu:addOption(getText("IGUI_AutoDoor_DebugSpawnRemote"), playerNum,
            AutoDoorInstallMenu.onDebugSpawnRemote, door)
    end
end

Events.OnFillWorldObjectContextMenu.Add(AutoDoorInstallMenu.doDoorMenu)
