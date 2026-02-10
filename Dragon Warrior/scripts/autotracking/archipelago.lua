-- Dragon Warrior PopTracker - Archipelago autotracking
-- (Panel + map checks + equipment dock)

local ITEM_MAPPING     = require "autotracking.item_mapping"
local LOCATION_MAPPING = require "autotracking.location_mapping"
local OPTION_MAPPING   = require "autotracking.option_mapping"

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

-- Shopsanity panel uses plain item codes (bamboo_pole, chain_mail, etc.).
-- Some packs also have equipment_* aliases; setting both doesn't hurt.
local function MarkPanelItemAcquired(code)
    if not code or code == "" then return end
    MarkOne(code)
    if not code:match("^equipment_") then
        MarkOne("equipment_" .. code)
    end
end

local function ToItemCodeFromPurchaseLeaf(leaf)
    -- leaf like: "Purchase Copper Sword"
    local item = leaf and leaf:match("^Purchase%s+(.+)$") or nil
    if not item then return nil end

    item = item:lower()
    item = item:gsub("['’]", "")        -- drop apostrophes
    item = item:gsub("[^%w]+", "_")     -- spaces/punct -> _
    item = item:gsub("_+", "_")         -- collapse runs
    item = item:gsub("^_", ""):gsub("_$", "")
    return item
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
    if player_number ~= Archipelago.PlayerNumber then return end
    CUR_INDEX = index

    local mapped = ITEM_MAPPING[item_id]
    if mapped then
        SetItem(mapped[1], mapped[2])
    end

    -- Equipment dock stages
    local alt_code = EQUIPMENT_UPGRADES[item_name]
    if alt_code then
        local dock_item = Tracker:FindObjectForCode(alt_code)
        if dock_item then
            dock_item.CurrentStage = (dock_item.CurrentStage or 0) + 1
            dock_item.Active = true
        end
    end
end

function onLocationHandler(index, location_id, location_name)
    if index < 0 then return end

    -- Resolve to tracker location code/path
    local location_path = LOCATION_MAPPING[tonumber(location_id)]

    -- Some clients hand us a name instead of an id; try to match by leaf name.
    if not location_path and type(location_id) == "string" then
        for _, v in pairs(LOCATION_MAPPING) do
            local clean_name = v:match("([^/]+)$")
            if clean_name == location_id then
                location_path = v
                break
            end
        end
    end

    -- Shopsanity Panel:
    -- Trigger off the leaf segment of the resolved path (best) or the provided name.
    do
        local leaf = nil
        if type(location_path) == "string" then
            leaf = location_path:match("([^/]+)$")
        end
        if not leaf or leaf == "" then
            leaf = location_name or (type(location_id) == "string" and location_id) or ""
        end

        local code = ToItemCodeFromPurchaseLeaf(leaf)
        if code then
            MarkPanelItemAcquired(code)
        end
    end

    -- Monstersanity + Dragonlord panel (UI grids)
    do
        local leaf = nil
        if type(location_path) == "string" then
            leaf = location_path:match("([^/]+)$")
        end
        if not leaf or leaf == "" then
            leaf = location_name or (type(location_id) == "string" and location_id) or ""
        end

        local mon = leaf:match("^Defeated%s+(.+)$")
        if mon and mon ~= "Dragonlord" then
            local code = mon:lower()
            code = code:gsub("['’]", "")
            code = code:gsub("[^%w]+", "_")
            code = code:gsub("_+", "_")
            code = code:gsub("^_", ""):gsub("_$", "")

            local obj = Tracker:FindObjectForCode(code)
            if obj then obj.Active = true end
        end
    end



    if not location_path then return end

    -- Harp turn-in logic: flip image when staff location is completed
    if location_id == 0x0D0304 or tonumber(location_id) == 0x0D0304 then
        local harp = Tracker:FindObjectForCode("silver_harp")
        if harp and harp.CurrentStage ~= 2 then
            harp.CurrentStage = 2
            harp.Active = true
        end
    end

    -- Normal location marking (map dots / chest counts)
    local obj = Tracker:FindObjectForCode(location_path)
    if obj then
        obj.AvailableChestCount = 0
        local parent = obj.Parent
        if parent then parent:UpdateVisibility() end
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
