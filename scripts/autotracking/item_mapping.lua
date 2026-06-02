ITEM_MAPPING = {

    [0xE20] = {"equipment_weapon", "progressive"},
    [0xE04] = {"equipment_armor", "progressive"},
    [0xE01] = {"equipment_shield", "progressive"},

    -- Key / progression items
    [0x5] = {"fairy_flute", "toggle"},
    [0x7] = {"erdricks_token", "toggle"},
    [0x8] = {"gwaelins_love", "toggle"},
    [0xA] = {"silver_harp", "toggle"},
    [0xC] = {"stones_of_sunlight", "toggle"},
    [0xD] = {"staff_of_rain", "toggle"},
    [0xE] = {"rainbow_drop", "toggle"},
    [0xD4] = {"magic_key", "toggle"},
    [0x12345] = {"ball_of_light", "toggle"},

    -- Equipment that is actually in the item pool (non-shopsanity modes)
    [0xFF] = {"erdricks_sword", "toggle"},
    [0xFE] = {"erdricks_armor", "toggle"},
    [0x4] = {"dragon_scale", "toggle"},
    [0x6] = {"fighters_ring", "toggle"},

    -- Cursed items
    [0x9] = {"cursed_belt", "toggle"},
    [0xB] = {"cursed_necklace", "toggle"},

}

return ITEM_MAPPING