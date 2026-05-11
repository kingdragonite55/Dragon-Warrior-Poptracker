-- This keeps it from having to load things in order ie less crashing
Tracker.AllowDeferredLogicUpdate = true

-- Define basic logic helpers for use in locations.json access_rules

function has(code)
  return Tracker:ProviderCountForCode(code) > 0
end


-- === Key Items ===

function fairy_flute()
    return Tracker:ProviderCountForCode("fairy_flute") > 0
end

function rainbow_drop()
    return Tracker:ProviderCountForCode("rainbow_drop") > 0
end

function gwaelins_love()
    return Tracker:ProviderCountForCode("gwaelins_love") > 0
end

function erdricks_tablet()
    return Tracker:ProviderCountForCode("erdricks_tablet") > 0
end

hasprincess = function()
    return is_location_checked("@Main/Swamp Cave/Rescue Princess Gwaelin")
       and not is_location_checked("@Main/Tantagel Castle/Returned Gwaelin to Castle")
end

function ball_of_light()
    return Tracker:ProviderCountForCode("ball_of_light") > 0
end

function erdricks_token()
  return has("erdricks_token") or has("erdricks_token_checked")
end

function stones_of_sunlight()
  return has("stones_of_sunlight") or has("stones_of_sunlight_checked")
end

function silver_harp()
  local obj = Tracker:FindObjectForCode("silver_harp")
  return obj and obj.CurrentStage > 0
end


function staff_of_rain()
  return has("staff_of_rain") or has("staff_of_rain_checked")
end

function rainbow_shrine()
  return staff_of_rain() and stones_of_sunlight() and erdricks_token()
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