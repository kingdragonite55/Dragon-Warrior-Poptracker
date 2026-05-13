-- This keeps it from having to load things in order ie less crashing
Tracker.AllowDeferredLogicUpdate = true

-- Define basic logic helpers for use in locations.json access_rules

function has(code)
	return Tracker:ProviderCountForCode(code) > 0
end

function has_equip_level(equipment, count)
	equipment = Tracker:FindObjectForCode(equipment)
	count = tonumber(count)
	return equipment.CurrentStage >= count
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

function erdricks_sword()
	if (Tracker:FindObjectForCode("equipment_weapon").CurrentStage == 7) or has("erdricks_sword") then
		return true
	end
end

function erdricks_armor()
	if (Tracker:FindObjectForCode("equipment_armor").CurrentStage == 7) or has("erdricks_armor") then
		return true
	end
end

function can_defeat_dragonlord()
	if has("shopsanity") then
		return equipment_helper(7, 7, 3)
	else
		if erdricks_sword() then
			return erdricks_armor() or not has("searchsanity")
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

function equipment_helper(weapon_count, armor_count, shield_count)
	if not has("shopsanity") then
		return true
	else
		return has_equip_level("equipment_weapon", weapon_count) and has_equip_level("equipment_armor", armor_count) and has_equip_level("equipment_shield", shield_count)
	end
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