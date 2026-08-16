-- Server: spawns the magazine in the same containers, with the same weights,
-- as the vanilla recipe magazines, so the recipes can be learned.

-- B42 note: the generic recipe-magazine containers live in
-- ProceduralDistributions.list (referenced by name from Distributions.lua),
-- while the postbox moved out of ProceduralDistributions into the inline
-- Distributions table (exposed to mods as SuburbsDistributions).

local function addToContainer(dist, item, weight)
    if not dist or not dist.items then return end
    for i = 1, #dist.items, 2 do
        if dist.items[i] == item then return end
    end
    table.insert(dist.items, item)
    table.insert(dist.items, weight)
end

-- Weights match the vanilla recipe magazines (MechanicMag1 etc.) in each
-- container: 2.0 in bookstores, 1.0 in dedicated magazine/libraries, 0.1 on
-- generic shelves.
local proceduralContainers = {
    BookstoreMisc = 2.0,
    CrateMagazines = 1.0,
    LibraryMagazines = 1.0,
    MagazineRackMixed = 1.0,
    PostOfficeMagazines = 1.0,
    ShelfGeneric = 0.1,
    UniversityLibraryMagazines = 1.0,
}

if ProceduralDistributions and ProceduralDistributions.list then
    for name, weight in pairs(proceduralContainers) do
        addToContainer(ProceduralDistributions.list[name], "AutoDoorMagazine", weight)
    end
end

-- Mailboxes: vanilla recipe magazines are 0.1 (SmithingMag is rarer at 0.01).
if SuburbsDistributions and SuburbsDistributions.all
    and SuburbsDistributions.all.postbox then
    addToContainer(SuburbsDistributions.all.postbox, "AutoDoorMagazine", 0.1)
end
