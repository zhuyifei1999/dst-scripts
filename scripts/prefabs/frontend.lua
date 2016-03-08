local assets =
{
  --FE

    Asset("ANIM", "anim/credits.zip"),
    Asset("ANIM", "anim/credits2.zip"),
    
    Asset("IMAGE", "images/customisation.tex" ),
    Asset("ATLAS", "images/customisation.xml" ),
    
    -- Asset("ANIM", "anim/portrait_frame.zip"), -- Not currently used, but likely to come back

    Asset("ANIM", "anim/build_status.zip"), 

    -- Asset("ANIM", "anim/animated_title.zip"), -- Not currently used, but likely to come back
    -- Asset("ANIM", "anim/animated_title2.zip"), -- Not currently used, but likely to come back
    -- Asset("ANIM", "anim/title_fire.zip"), -- Not currently used, but likely to come back

    -- Used by TEMPLATES.Background
    -- Asset("ATLAS", "images/bg_color.xml"), -- Not currently used, but likely to come back
    -- Asset("IMAGE", "images/bg_color.tex"), -- Not currently used, but likely to come back

    Asset("ATLAS", "images/servericons.xml"),
    Asset("IMAGE", "images/servericons.tex"),

    Asset("ATLAS", "images/server_intentions.xml"),
    Asset("IMAGE", "images/server_intentions.tex"),

    Asset("FILE", "images/motd.xml"),

	--character portraits
	Asset("ATLAS", "images/saveslot_portraits.xml"),
    Asset("IMAGE", "images/saveslot_portraits.tex"),

    Asset("ATLAS", "bigportraits/unknownmod.xml"),
    Asset("IMAGE", "bigportraits/unknownmod.tex"),

    --V2C: originally in global, for old options and controls screens
    Asset("ATLAS", "images/bg_plain.xml"),
    Asset("IMAGE", "images/bg_plain.tex"),

    Asset("ATLAS", "images/skinsscreen.xml"),
    Asset("IMAGE", "images/skinsscreen.tex"),

    Asset("ATLAS", "images/tradescreen.xml"),
	Asset("IMAGE", "images/tradescreen.tex"),
	Asset("ATLAS", "images/tradescreen_overflow.xml"),
	Asset("IMAGE", "images/tradescreen_overflow.tex"),

    Asset("ANIM", "anim/mod_player_build.zip"),

    Asset("ANIM", "anim/frames_comp.zip"),
    Asset("ANIM", "anim/frame_skins.zip"),
    Asset("ANIM", "anim/frame_bg.zip"),

    Asset("ANIM", "anim/swapshoppe.zip"),
    Asset("ANIM", "anim/swapshoppe_bg.zip"),
    Asset("ANIM", "anim/joystick.zip"),
    Asset("ANIM", "anim/button.zip"),
    Asset("ANIM", "anim/shoppe_frames.zip"),
    Asset("ANIM", "anim/skin_collector.zip"),
    Asset("ANIM", "anim/textbox.zip"),

    Asset("ANIM", "anim/chest_bg.zip"),
}

if PLATFORM == "PS4" then
    table.insert(assets, Asset("ATLAS", "images/ps4.xml"))
    table.insert(assets, Asset("IMAGE", "images/ps4.tex"))
    table.insert(assets, Asset("ATLAS", "images/ps4_controllers.xml"))
    table.insert(assets, Asset("IMAGE", "images/ps4_controllers.tex"))
end


-- Add all the characters by name
local charlist = GetActiveCharacterList and GetActiveCharacterList() or DST_CHARACTERLIST
for i,char in ipairs(charlist) do
	if PREFAB_SKINS[char] then 
		for _,character in pairs(PREFAB_SKINS[char]) do
			table.insert(assets, Asset("ATLAS", "bigportraits/"..character..".xml"))
			table.insert(assets, Asset("IMAGE", "bigportraits/"..character..".tex"))
		end
		
		table.insert(assets, Asset("ATLAS", "bigportraits/"..char..".xml"))
		table.insert(assets, Asset("IMAGE", "bigportraits/"..char..".tex"))

		--table.insert(assets, Asset("IMAGE", "images/selectscreen_portraits/"..char..".tex")) -- Not currently used, but likely to come back
		--table.insert(assets, Asset("IMAGE", "images/selectscreen_portraits/"..char.."_silho.tex")) -- Not currently used, but likely to come back
	end
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

local prefabs = {}

--Skins assets
local clothing_assets = require("clothing_assets")
for _,clothing_asset in pairs( clothing_assets ) do
	table.insert( assets, clothing_asset )
end
for _,skins_prefabs in pairs(PREFAB_SKINS) do
	for _,skin_prefab in pairs(skins_prefabs) do
		table.insert( prefabs, skin_prefab )

		if not string.find(skin_prefab, "_none") then 
			local prefab = require("prefabs/"..skin_prefab)
			if type(prefab)=="table" then
				for k, v in pairs(prefab.assets) do 
					table.insert(assets, v)
				end
			else
				print("ERROR: The contents of prefabs/"..skin_prefab..".lua are corrupt. Try verifying your game's install." )
			end
		end
	end
end


--we don't actually instantiate this prefab. It's used for controlling asset loading
local function fn(Sim)
    return CreateEntity()
end

return Prefab( "frontend", fn, assets, prefabs) 
