--[[
    AutoDoor loot distribution (server).
    Adds the Auto Door Magazine to mailboxes so the recipes can be
    learned from reading it.
]]

local function addToContainer(containerName, item, weight)
    if not ProceduralDistributions or not ProceduralDistributions.list then return end
    local dist = ProceduralDistributions.list[containerName]
    if not dist or not dist.items then return end
    for i = 1, #dist.items, 2 do
        if dist.items[i] == item then return end
    end
    table.insert(dist.items, item)
    table.insert(dist.items, weight)
end

addToContainer("postbox", "AutoDoorMagazine", 0.5)
