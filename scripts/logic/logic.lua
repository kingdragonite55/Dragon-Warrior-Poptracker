-- This keeps it from having to load things in order ie less crashing
Tracker.AllowDeferredLogicUpdate = true

-- Define basic logic helpers for use in locations.json access_rules

function has(code)
  return Tracker:ProviderCountForCode(code) > 0
end


-- === Key Items ===

hasprincess = function()
    return is_location_checked("@Main/Swamp Cave/Rescue Princess Gwaelin")
       and not is_location_checked("@Main/Tantagel Castle/Returned Gwaelin to Castle")
end

function rainbow_shrine()
	if has("staff_of_rain") and has("stones_of_sunlight") and has("magic_key") then
		if not has("searchsanity") then
			return true
		else
			return has("erdricks_token") and has("fairy_flute")
		end
	end
end



-- Progressive Gear 
function WeaponLevel()
    return Tracker:ProviderCountForCode("weapon") or 0
end

function ArmorLevel()
    return Tracker:ProviderCountForCode("armor") or 0
end

function ShieldLevel()
    return Tracker:ProviderCountForCode("shield") or 0
end

-- Options 
-- Tracker toggle visibility stubs
function Shopsanity()
    return Tracker:ProviderCountForCode("shopsanity") > 0
end

function Levelsanity()
    return Tracker:ProviderCountForCode("levelsanity") > 0
end

function Searchsanity()
    return Tracker:ProviderCountForCode("searchsanity") > 0
end

function Monstersanity()
    return Tracker:ProviderCountForCode("monstersanity") > 0
end