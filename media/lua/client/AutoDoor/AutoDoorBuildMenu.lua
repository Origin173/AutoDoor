--[[
    AutoDoor build menu (client).
    Right-click on the ground -> "Build Auto Door" -> garage doors / fence
    gates. Only shown when the player is on foot, holds a hammer and meets
    the skill requirement. The building object classes live on the server
    side; in singleplayer everything is loaded so this works as-is. On a
    multiplayer client the classes are absent and the menu is hidden.
]]

require "AutoDoor/AutoDoorDoorLib"
-- The building object classes and buildUtil live in media/lua/server.
-- In B42 a client can load server-side Lua via require (vanilla precedent:
-- ISAnimalContextMenu requires BuildingObjects/ISAnimalPickMateCursor).
-- Loading them here makes the build menu work on a pure MP client too.
-- Guarded with pcall: if the load ever fails only the build menu is hidden,
-- the remote control functionality keeps working.
pcall(function()
    require "BuildingObjects/ISBuildUtil"
    require "AutoDoor/AutoDoorBuildingObjects"
end)

AutoDoorBuildMenu = {}

function AutoDoorBuildMenu.canBuild()
    return ISAutoGarageDoor ~= nil and ISAutoFenceGate ~= nil
end

local function predicateNotBroken(item)
    return not item:isBroken()
end

local function hasMaterials(playerObj, materials)
    for _, entry in ipairs(materials) do
        local idx = entry:find(":")
        local fullType = entry:sub(1, idx - 1)
        local need = tonumber(entry:sub(idx + 1))
        local count = playerObj:getInventory():getCountTypeEvalRecurse(fullType, buildUtil.predicateMaterial)
        if count < need then
            return false
        end
    end
    return true
end

local function styleTooltip(playerObj, style)
    local tooltip = ISToolTip:new(playerObj)
    tooltip:initialise()
    tooltip:setName(getText(style.name))
    tooltip.description = {}
    local skill = getText("IGUI_PerkName_" .. style.skill)
    table.insert(tooltip.description, skill .. " " .. tostring(style.skillLevel))
    for _, entry in ipairs(style.materials) do
        local idx = entry:find(":")
        local fullType = entry:sub(1, idx - 1)
        local need = tonumber(entry:sub(idx + 1))
        local itemName = getText("ItemName_" .. fullType:sub(fullType:find(":") + 1))
        table.insert(tooltip.description, itemName .. " x" .. tostring(need))
    end
    return tooltip
end

local function addStyleOption(parentMenu, playerNum, playerObj, style, buildFunc, styleIndex)
    local option = parentMenu:addOption(getText(style.name), playerNum, buildFunc, styleIndex)
    option.toolTip = styleTooltip(playerObj, style)
    if not hasMaterials(playerObj, style.materials) then
        option.notAvailable = true
        option.onSelect = nil
    end
    return option
end

function AutoDoorBuildMenu.onBuildGarageDoor(playerNum, styleIndex)
    local o = ISAutoGarageDoor:new(styleIndex)
    o.player = playerNum
    getCell():setDrag(o, playerNum)
end

function AutoDoorBuildMenu.onBuildFenceGate(playerNum, styleIndex)
    local o = ISAutoFenceGate:new(styleIndex)
    o.player = playerNum
    getCell():setDrag(o, playerNum)
end

local function buildGarageSubMenu(parentMenu, playerNum, playerObj)
    local subMenu = ISContextMenu:getNew(parentMenu)
    parentMenu:addSubMenu(parentMenu:addOption(getText("IGUI_AutoDoor_GarageDoor")), subMenu)
    for i, style in ipairs(AutoDoor.GARAGE_DOOR_STYLES) do
        if playerObj:getPerkLevel(Perks[style.skill]) >= style.skillLevel then
            addStyleOption(subMenu, playerNum, playerObj, style, AutoDoorBuildMenu.onBuildGarageDoor, i)
        end
    end
end

local function buildFenceSubMenu(parentMenu, playerNum, playerObj)
    local subMenu = ISContextMenu:getNew(parentMenu)
    parentMenu:addSubMenu(parentMenu:addOption(getText("IGUI_AutoDoor_FenceGate")), subMenu)
    for i, style in ipairs(AutoDoor.FENCE_GATE_STYLES) do
        if playerObj:getPerkLevel(Perks[style.skill]) >= style.skillLevel then
            addStyleOption(subMenu, playerNum, playerObj, style, AutoDoorBuildMenu.onBuildFenceGate, i)
        end
    end
end

function AutoDoorBuildMenu.doBuildMenu(playerNum, context, worldobjects, test)
    if not AutoDoorBuildMenu.canBuild() then return end
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj or playerObj:getVehicle() then return end
    if playerObj:getPerkLevel(Perks.Woodwork) < 3 and playerObj:getPerkLevel(Perks.MetalWelding) < 3 then
        return
    end
    local hammer = playerObj:getInventory():getFirstTagEvalRecurse(ItemTag.HAMMER, predicateNotBroken)
    if not hammer then return end

    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(context:addOption(getText("IGUI_AutoDoor_BuildMenu")), subMenu)
    buildGarageSubMenu(subMenu, playerNum, playerObj)
    buildFenceSubMenu(subMenu, playerNum, playerObj)
end

Events.OnFillWorldObjectContextMenu.Add(AutoDoorBuildMenu.doBuildMenu)
