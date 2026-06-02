-- Dragon Warrior PopTracker - Archipelago autotracking
-- (Panel + map checks + equipment dock)

local ITEM_MAPPING     = require "autotracking.item_mapping"
local LOCATION_MAPPING = require "autotracking.location_mapping"
local OPTION_MAPPING   = require "autotracking.option_mapping"
local TAB_MAPPING      = require "autotracking.tab_mapping"

CUR_INDEX = -1
AP_INDEX  = -1

function ResetLocations()
	if IS_ITEMS_ONLY then
		return
	end
    for _, v in pairs(LOCATION_MAPPING) do
        local code = (type(v) == "table") and v[1] or v
        local obj = Tracker:FindObjectForCode(code)
        if obj then
            if code:sub(1, 1) == "@" then
                obj.AvailableChestCount = obj.ChestCount
            else
                obj.Active = false
            end
        end
    end
end

local function ClearItem(code, type)
    local item = Tracker:FindObjectForCode(code)
    if not item then return end
    if type == "toggle" then
        item.Active = false
    elseif type == "consumable" then
        item.AcquiredCount = 0
    elseif type == "progressive" then
        item.CurrentStage = 0
        item.Active = false
    end
end

function ClearItems(slot_data)
    AP_INDEX  = -1
    CUR_INDEX = -1

    for _, v in pairs(ITEM_MAPPING) do
        ClearItem(v[1], v[2])
    end
end

function SetOptions(slot_data)
	print("%s", dump_table(slot_data))

	-- Set -sanity toggles 
    for key, mapped in pairs(OPTION_MAPPING) do
        local isEnabled = (slot_data[key] == 1)

        if type(mapped) == "table" then
            for _, code in ipairs(mapped) do
                local obj = Tracker:FindObjectForCode(code)
                if obj and obj.Type == "toggle" then obj.Active = isEnabled end
            end
        else
            local obj = Tracker:FindObjectForCode(mapped)
            if obj and obj.Type == "toggle" then obj.Active = isEnabled end
        end
    end
	
	-- Get correct levelsanity check counts
	if slot_data["levelsanity_range"] and not IS_ITEMS_ONLY then
		local levelsanity_range = slot_data["levelsanity_range"]
		local levelsanity_low = Tracker:FindObjectForCode("@Main/Levelsanity/Level 2-9")
		levelsanity_high = Tracker:FindObjectForCode("@Main/Levelsanity/Level 10+")
		levelsanity_low.AvailableChestCount = math.min(levelsanity_range - 1, 8)
		levelsanity_high.AvailableChestCount = math.max(0, levelsanity_range - 9)
		levelsanity_high = (levelsanity_high.AvailableChestCount ~= 0)
	end
end

local function SetItem(code, type)
    local item = Tracker:FindObjectForCode(code)
    if not item then return end

    if type == "toggle" then
        item.Active = true
    elseif type == "progressive" then
        item.CurrentStage = (item.CurrentStage or 0) + 1
        item.Active = true
    elseif type == "consumable" then
        item.AcquiredCount = (item.AcquiredCount or 0) + 1
    end
end

function onItem(index, item_id, item_name, player_number)
    if index <= CUR_INDEX then return end
    local is_local = player_number == Archipelago.PlayerNumber
    CUR_INDEX = index

    local mapped = ITEM_MAPPING[item_id]
    if mapped then
        SetItem(mapped[1], mapped[2])
    end
	
	-- Erdrick's Sword handling
	if item_id == 0xFF then
		local sword = Tracker:FindObjectForCode("equipment_weapon")
		sword.CurrentStage = 7
	end
	
	-- Erdrick's Armor handling
	if item_id == 0xFE then
		local armor = Tracker:FindObjectForCode("equipment_armor")
		armor.CurrentStage = 7
	end
end

-- Taken from the Pokemon B/W poptracker (thanks palex)
function onLocationHandler(location_id, location_name)
    local value = LOCATION_MAPPING[location_id]
    if IS_ITEMS_ONLY or not value then
        return
    end
    for _, code in pairs(value) do
        local object = Tracker:FindObjectForCode(code)
        if object then
            if code:sub(1, 1) == "@" then
                object.AvailableChestCount = object.AvailableChestCount - 1
            elseif object.Type == "progressive" then
                object.CurrentStage = object.CurrentStage + 1
            else
                object.Active = true
            end
        elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
            print(string.format("onLocation: could not find object for code %s", code))
        end
    end
end

function onBounce(json)
	print(string.format("called onBounce: %s", dump_table(json)))
	if IS_ITEMS_ONLY or not json["data"] then
		return
	end
	
	local autoswitch = Tracker:FindObjectForCode("auto_switch")
	if json["data"]["current_map"] and autoswitch.Active then
		current_map = current_map or 0
		local new_map = json["data"]["current_map"]
		new_map = TAB_MAPPING[new_map]
		if current_map == new_map then
			return
		elseif new_map ~= "" then
			for tab in string.gmatch(new_map, "([^/]+)") do
                print(string.format("Switching to tab %s",tab))
                Tracker:UiHint("ActivateTab", tab)
            end
			current_map = new_map
		end
	end
end

function onClearHandler(slot_data)
    ResetLocations()
    ClearItems()
	SetOptions(slot_data)
end

Archipelago:AddItemHandler("itemHandler", onItem)
Archipelago:AddLocationHandler("locationHandler", onLocationHandler)
Archipelago:AddClearHandler("clearHandler", onClearHandler)
Archipelago:AddBouncedHandler("bounceHandler", onBounce)
