-- entry point for all lua code of the pack
ENABLE_DEBUG_LOG = true

local variant = Tracker.ActiveVariantUID
IS_ITEMS_ONLY = variant:find("itemsonly")

print("-- Dragon Warrior Tracker --")
print("Loaded variant: ", variant)
if ENABLE_DEBUG_LOG then print("Debug logging is enabled!") end

-- Load Utilities
ScriptHost:LoadScript("scripts/utils.lua")
ScriptHost:LoadScript("scripts/autotracking/option_mapping.lua")
ScriptHost:LoadScript("scripts/options.lua")

-- Load Logic
ScriptHost:LoadScript("scripts/logic/logic.lua")


-- Load Items
Tracker:AddItems("items/items.json")


-- Maps
if not IS_ITEMS_ONLY then
  Tracker:AddMaps("maps/maps.json")
ScriptHost:LoadScript("scripts/locations.lua")

end

-- Layouts
Tracker:AddLayouts("layouts/items.json")
Tracker:AddLayouts("layouts/tracker.json")
Tracker:AddLayouts("layouts/broadcast.json")

-- Start with "no gear" items lit
Tracker:FindObjectForCode("equipment_weapon").Active = true
Tracker:FindObjectForCode("equipment_armor").Active = true
Tracker:FindObjectForCode("equipment_shield").Active = true


-- Autotracking (if supported)
if PopVersion and PopVersion >= "0.18.0" then
  ScriptHost:LoadScript("scripts/autotracking.lua")
end







