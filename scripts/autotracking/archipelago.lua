-- Dragon Warrior PopTracker - Archipelago autotracking
-- (Panel + map checks + equipment dock)

local ITEM_MAPPING     = require "autotracking.item_mapping"
local LOCATION_MAPPING = require "autotracking.location_mapping"
local OPTION_MAPPING   = require "autotracking.option_mapping"
local TAB_MAPPING      = require "autotracking.tab_mapping"

CUR_INDEX = -1
AP_INDEX  = -1
SAVED_SLOT_DATA = {}

-- Equipment dock display logic
local EQUIPMENT_UPGRADES = {
    ["Progressive Weapon Upgrade"] = "equipment_weapon",
    ["Progressive Armor Upgrade"]  = "equipment_armor",
    ["Progressive Shield Upgrade"] = "equipment_shield"
}

-- Mark a tracker item as acquired in a way that works for toggle/progressive/consumable.
local function MarkOne(code)
    local obj = Tracker:FindObjectForCode(code)
    if not obj then return end

    if obj.Type == "toggle" then
        obj.Active = true
    elseif obj.Type == "progressive" then
        obj.CurrentStage = math.max(obj.CurrentStage or 0, 1)
        obj.Active = true
    elseif obj.Type == "consumable" then
        obj.AcquiredCount = math.max(obj.AcquiredCount or 0, 1)
    else
        obj.Active = true
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

    -- Clear dock display items directly
    local dock_codes = { "equipment_weapon", "equipment_armor", "equipment_shield" }
    for _, code in ipairs(dock_codes) do
        local obj = Tracker:FindObjectForCode(code)
        if obj then
            obj.CurrentStage = 0
            obj.Active = true
        end
    end

    -- Auto-toggle option buttons from SlotData.
    -- option_mapping.lua in this pack is "slotdata_key -> tracker_code OR {tracker_code,...}"
    local opts = slot_data or SAVED_SLOT_DATA or {}
	print("%s", dump(slot_data))

    for key, mapped in pairs(OPTION_MAPPING) do
        local isEnabled = (opts[key] == 1) or (opts[key] == 50) or (opts[key] == true)

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
	
	-- Get correct levelsanity check counts. Currently broken for some reason
	if slot_data["levelsanity_range"] then
		local levelsanity_range = tonumber(slot_data["levelsanity_range"])
		levelsanity_low = Tracker:FindObjectForCode("@Main/Levelsanity/Level 2-9")
		levelsanity_high = Tracker:FindObjectForCode("@Main/Levelsanity/Level 10+")
		levelsanity_low.AvailableChestCount = math.min(levelsanity_range, 8)
		levelsanity_high.AvailableChestCount = math.max(0, levelsanity_range - 9)
		-- levelsanity_high:UpdateVisibility()
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
    if not value then
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

function reset_all_locations()
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

function dump(o, depth)
    if depth == nil then
        depth = 0
    end
    if type(o) == 'table' then
        local tabs = ('\t'):rep(depth)
        local tabs2 = ('\t'):rep(depth + 1)
        local s = '{\n'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. tabs2 .. '[' .. k .. '] = ' .. dump(v, depth + 1) .. ',\n'
        end
        return s .. tabs .. '}'
    else
        return tostring(o)
    end
end

function onBounce(json)
	print(string.format("called onBounce: %s", dump(json)))
	if not json["data"] then
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
			current_map = new_map
			for tab in string.gmatch(current_map, "([^/]+)") do
                print(string.format("Switching to tab %s",tab))
                Tracker:UiHint("ActivateTab", tab)
            end
		end
	end
end

function onClearHandler(slot_data)
    SAVED_SLOT_DATA = slot_data or {}
    ClearItems(SAVED_SLOT_DATA)
    reset_all_locations()
end

function UpdateReceivedItems()
    if not Archipelago or not Archipelago.ReceivedItems then return end

    for _, item in pairs(Archipelago.ReceivedItems) do
        local idx = item.index
        if idx <= AP_INDEX then goto continue end
        if item.player ~= Archipelago.PlayerNumber then goto continue end
        AP_INDEX = idx

        local mapping = ITEM_MAPPING[item.item]
        if mapping then
            SetItem(mapping[1], mapping[2])
        end
        ::continue::
    end
end

function UpdateCheckedLocations()
    if not Archipelago or not Archipelago.CheckedLocations then return end

    for _, id in pairs(Archipelago.CheckedLocations) do
        local code = LOCATION_MAPPING[id]
        if code then
            local obj = Tracker:FindObjectForCode(code)
            if obj then obj.AvailableChestCount = 0 end
        end
    end
end

function ResetItems()
    ClearItems(Archipelago.SlotData or {})
    UpdateReceivedItems()
    UpdateCheckedLocations()
end

Archipelago:AddItemHandler("itemHandler", onItem)
Archipelago:AddLocationHandler("locationHandler", onLocationHandler)
Archipelago:AddClearHandler("clearHandler", onClearHandler)
Archipelago:AddBouncedHandler("bounceHandler", onBounce)
