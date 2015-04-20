local assets =
{
  --FE

    Asset("ANIM", "anim/credits.zip"),
    Asset("ANIM", "anim/credits2.zip"),

    Asset("ATLAS", "bigportraits/locked.xml"),
    Asset("IMAGE", "bigportraits/locked.tex"),
    
    Asset("IMAGE", "images/customisation.tex" ),
    Asset("ATLAS", "images/customisation.xml" ),
    
	Asset("ATLAS", "images/selectscreen_portraits.xml"),
	Asset("IMAGE", "images/selectscreen_portraits.tex"),

    Asset("ANIM", "anim/portrait_frame.zip"),

    Asset("ANIM", "anim/build_status.zip"),
	Asset("ANIM", "anim/corner_dude.zip"),
    Asset("ANIM", "anim/savetile.zip"),    
    Asset("ANIM", "anim/savetile_small.zip"),
    
    Asset("ATLAS", "images/avatars.xml"),
    Asset("IMAGE", "images/avatars.tex"),

    Asset("ATLAS", "images/lobbyscreen.xml"),
    Asset("IMAGE", "images/lobbyscreen.tex"),

    Asset("ATLAS", "images/bg_logo.xml"),
    Asset("IMAGE", "images/bg_logo.tex"),

    Asset("ATLAS", "images/bg_rog_logo_1.xml"),
    Asset("IMAGE", "images/bg_rog_logo_1.tex"),

    Asset("ATLAS", "images/bg_rog_logo_2.xml"),
    Asset("IMAGE", "images/bg_rog_logo_2.tex"),

    Asset("ATLAS", "images/bg_rog_logo_3.xml"),
    Asset("IMAGE", "images/bg_rog_logo_3.tex"),

    Asset("ATLAS", "images/bg_rog_logo_4.xml"),
    Asset("IMAGE", "images/bg_rog_logo_4.tex"),

    Asset("ATLAS", "images/historyscreen.xml"),
    Asset("IMAGE", "images/historyscreen.tex"),
    
	--character portraits
	Asset("ATLAS", "images/saveslot_portraits.xml"),
    Asset("IMAGE", "images/saveslot_portraits.tex"),

    -- update spinner
    Asset("ANIM", "anim/researchlab.zip"),
}

if PLATFORM == "PS4" then
    table.insert(assets, Asset("ATLAS", "images/ps4.xml"))
    table.insert(assets, Asset("IMAGE", "images/ps4.tex"))
    table.insert(assets, Asset("ATLAS", "images/ps4_controllers.xml"))
    table.insert(assets, Asset("IMAGE", "images/ps4_controllers.tex"))
    table.insert(assets, Asset("ANIM", "anim/animated_title.zip"))
    table.insert(assets, Asset("ANIM", "anim/title_fire.zip"))
end


-- Add all the characters by name
local charlist = GetActiveCharacterList and GetActiveCharacterList() or DST_CHARACTERLIST
for i,char in ipairs(charlist) do
	table.insert(assets, Asset("ATLAS", "bigportraits/"..char..".xml"))
	table.insert(assets, Asset("IMAGE", "bigportraits/"..char..".tex"))
	--table.insert(assets, Asset("IMAGE", "images/selectscreen_portraits/"..char..".tex"))
	--table.insert(assets, Asset("IMAGE", "images/selectscreen_portraits/"..char.."_silho.tex"))
end

-- Pick some random stuff to show on the puppets on the main screen (and only load the assets that we need)
local attempts = 0
while MAINSCREEN_CHAR_1 == MAINSCREEN_CHAR_2 and attempts < 10 do
    MAINSCREEN_CHAR_1 = DST_CHARACTERLIST[math.random(#DST_CHARACTERLIST)]
    MAINSCREEN_CHAR_2 = DST_CHARACTERLIST[math.random(#DST_CHARACTERLIST)]
    attempts = attempts + 1
end
-- table.insert(assets, Asset("ANIM", "anim/"..MAINSCREEN_CHAR_1..".zip"))
-- table.insert(assets, Asset("ANIM", "anim/"..MAINSCREEN_CHAR_2..".zip"))

attempts = 0
while MAINSCREEN_TOOL_1 == MAINSCREEN_TOOL_2 and attempts < 10 do
    MAINSCREEN_TOOL_1 = MAINSCREEN_TOOL_LIST[math.random(#MAINSCREEN_TOOL_LIST)]
    MAINSCREEN_TOOL_2 = MAINSCREEN_TOOL_LIST[math.random(#MAINSCREEN_TOOL_LIST)]
    attempts = attempts + 1
end
-- table.insert(assets, Asset("ANIM", "anim/"..MAINSCREEN_TOOL_1..".zip"))
-- table.insert(assets, Asset("ANIM", "anim/"..MAINSCREEN_TOOL_2..".zip"))

attempts = 0
while MAINSCREEN_TORSO_1 == MAINSCREEN_TORSO_2 and attempts < 10 do
    MAINSCREEN_TORSO_1 = MAINSCREEN_TORSO_LIST[math.random(#MAINSCREEN_TORSO_LIST)]
    MAINSCREEN_TORSO_2 = MAINSCREEN_TORSO_LIST[math.random(#MAINSCREEN_TORSO_LIST)]
    attempts = attempts + 1
end
-- if MAINSCREEN_TORSO_1 ~= "" then table.insert(assets, Asset("ANIM", "anim/"..MAINSCREEN_TORSO_1..".zip")) end
-- if MAINSCREEN_TORSO_2 ~= "" then table.insert(assets, Asset("ANIM", "anim/"..MAINSCREEN_TORSO_2..".zip")) end

attempts = 0
while MAINSCREEN_HAT_1 == MAINSCREEN_HAT_2 and attempts < 10 do
    MAINSCREEN_HAT_1 = MAINSCREEN_HAT_LIST[math.random(#MAINSCREEN_HAT_LIST)]
    MAINSCREEN_HAT_2 = MAINSCREEN_HAT_LIST[math.random(#MAINSCREEN_HAT_LIST)]
    attempts = attempts + 1
end
-- if MAINSCREEN_HAT_1 ~= "" then table.insert(assets, Asset("ANIM", "anim/"..MAINSCREEN_HAT_1..".zip")) end
-- if MAINSCREEN_HAT_2 ~= "" then table.insert(assets, Asset("ANIM", "anim/"..MAINSCREEN_HAT_2..".zip")) end 

for i,v in pairs(DST_CHARACTERLIST) do
    if v ~= "" then
        table.insert(assets, Asset("ANIM", "anim/"..v..".zip"))
    end
end

for i,v in pairs(MAINSCREEN_TOOL_LIST) do
    if v ~= "" then
    table.insert(assets, Asset("ANIM", "anim/"..v..".zip"))
    end
end

for i,v in pairs(MAINSCREEN_TORSO_LIST) do
    if v ~= "" then
    table.insert(assets, Asset("ANIM", "anim/"..v..".zip"))
    end
end

for i,v in pairs(MAINSCREEN_HAT_LIST) do
    if v ~= "" then
    table.insert(assets, Asset("ANIM", "anim/"..v..".zip"))
    end
end

--we don't actually instantiate this prefab. It's used for controlling asset loading
local function fn(Sim)
    return CreateEntity()
end

return Prefab( "UI/interface/frontend", fn, assets) 
