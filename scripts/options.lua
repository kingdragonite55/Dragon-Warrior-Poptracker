-- Options toggles (on/off only, not progressive)
-- These control visibility rules in locations.json

local toggles = {
    { code = "shopsanity", label = "Shop Sanity" },
    { code = "searchsanity", label = "Search Sanity" },
    { code = "levelsanity", label = "Level Checks" },
    { code = "monstersanity", label = "Monster Sanity" },
}

for _, opt in ipairs(toggles) do
    local item = Tracker:FindObjectForCode(opt.code)
    if item then
        item.ItemInstanceName = opt.label
    end
end
