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

function AutoDoorInstallMenu.doDoorMenu(playerNum, context, worldobjects, test)
    local door = AutoDoorInstallMenu.findDoor(worldobjects)
    if not door then return end
    local player = getSpecificPlayer(playerNum)
    if not player or player:isDead() then return end

    local md = door:getModData()
    if md.autoDoor then
        -- Already automated: manage submenu.
        local subMenu = ISContextMenu:getNew(context)
        context:addSubMenu(context:addOption(getText("IGUI_AutoDoor_Manage")), subMenu)
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
        local install = context:addOption(getText("IGUI_AutoDoor_Install"), playerNum,
            AutoDoorInstallMenu.onInstall, door)
        install.toolTip = remoteTooltip(player)
        if not hasRemote(player) then
            install.notAvailable = true
            install.onSelect = nil
        end
    end

    -- Debug mode only: one-click paired remote for testing.
    if isDebugEnabled() then
        context:addOption(getText("IGUI_AutoDoor_DebugSpawnRemote"), playerNum,
            AutoDoorInstallMenu.onDebugSpawnRemote, door)
    end
end

Events.OnFillWorldObjectContextMenu.Add(AutoDoorInstallMenu.doDoorMenu)
