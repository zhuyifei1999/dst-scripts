local assets =
{
    --FE
    Asset("DYNAMIC_ANIM", "anim/dynamic/credits.zip"),
    Asset("DYNAMIC_ANIM", "anim/dynamic/credits2.zip"),
    Asset("DYNAMIC_ANIM", "anim/dynamic/credits3.zip"),
    Asset("DYNAMIC_ANIM", "anim/dynamic/credits4.zip"),
    Asset("DYNAMIC_ANIM", "anim/dynamic/credits5.zip"),
    Asset("DYNAMIC_ANIM", "anim/dynamic/credits6.zip"),
    Asset("DYNAMIC_ANIM", "anim/dynamic/credits7.zip"),
    Asset("DYNAMIC_ANIM", "anim/dynamic/credits8.zip"),

    Asset("IMAGE", "images/customisation.tex"),
    Asset("ATLAS", "images/customisation.xml"),

    Asset("DYNAMIC_ATLAS", "images/anr_silhouettes.xml"),
    Asset("ASSET_PKGREF", "images/anr_silhouettes.tex"),

    Asset("ATLAS", "images/frontscreen.xml"),
    Asset("IMAGE", "images/frontscreen.tex"),
        
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

    Asset("ATLAS", "images/new_host_picker.xml"),
    Asset("IMAGE", "images/new_host_picker.tex"),

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

    --testing 
    Asset("ATLAS", "images/inventoryimages.xml"),
    Asset("IMAGE", "images/inventoryimages.tex"),

    Asset("ANIM", "anim/mod_player_build.zip"),

    Asset("ANIM", "anim/frames_comp.zip"),
    Asset("ANIM", "anim/frame_bg.zip"),

    -- DISABLE SPECIAL RECIPES
    --Asset("ANIM", "anim/button_weeklyspecial.zip"),

    Asset("ANIM", "anim/swapshoppe.zip"),

    -- DISABLE SPECIAL RECIPES
    --Asset("ANIM", "anim/swapshoppe_special_build.zip"),
    --Asset("ANIM", "anim/swapshoppe_special_lightfx.zip"),
    --Asset("ANIM", "anim/swapshoppe_special_transitionfx.zip"),

    Asset("ANIM", "anim/swapshoppe_bg.zip"),
    Asset("ANIM", "anim/joystick.zip"),
    Asset("ANIM", "anim/button.zip"),
    Asset("ANIM", "anim/shoppe_frames.zip"),
    Asset("ANIM", "anim/skin_collector.zip"),
    Asset("ANIM", "anim/textbox.zip"),

    Asset("ANIM", "anim/chest_bg.zip"),

    Asset("ANIM", "anim/puff_spawning.zip"),
    Asset("ANIM", "anim/sporecloud.zip"),

    Asset("DYNAMIC_ATLAS", "images/thankyou_item_popup.xml"),
    Asset("ASSET_PKGREF", "images/thankyou_item_popup.tex"),
    Asset("DYNAMIC_ATLAS", "images/thankyou_item_event.xml"),
    Asset("ASSET_PKGREF", "images/thankyou_item_event.tex"),
    Asset("DYNAMIC_ATLAS", "images/thankyou_item_popup_rog.xml"),
    Asset("ASSET_PKGREF", "images/thankyou_item_popup_rog.tex"),

    --Credits screen
    Asset("SOUND", "sound/gramaphone.fsb"),

    --FE Music
    Asset("PKGREF", "sound/music_frontend.fsb"),
    Asset("PKGREF", "sound/music_frontend_winters_feast.fsb"),
    Asset("PKGREF", "sound/music_frontend_yotg.fsb"),

    Asset("PKGREF", "movies/intro.ogv"),
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
            table.insert(assets, Asset("DYNAMIC_ATLAS", "bigportraits/"..character..".xml"))
            table.insert(assets, Asset("ASSET_PKGREF", "bigportraits/"..character..".tex"))
        end
        table.insert(assets, Asset("DYNAMIC_ATLAS", "bigportraits/"..char..".xml"))
        table.insert(assets, Asset("ASSET_PKGREF", "bigportraits/"..char..".tex"))

        --table.insert(assets, Asset("IMAGE", "images/selectscreen_portraits/"..char..".tex")) -- Not currently used, but likely to come back
        --table.insert(assets, Asset("IMAGE", "images/selectscreen_portraits/"..char.."_silho.tex")) -- Not currently used, but likely to come back
    end
end

for i, v in pairs(DST_CHARACTERLIST) do
    if v ~= "" then
        table.insert(assets, Asset("ANIM", "anim/"..v..".zip"))
    end
end

for i, v in pairs(MAINSCREEN_TOOL_LIST) do
    if v ~= "" then
        table.insert(assets, Asset("ANIM", "anim/"..v..".zip"))
    end
end

for i, v in pairs(MAINSCREEN_TORSO_LIST) do
    if v ~= "" then
        table.insert(assets, Asset("ANIM", "anim/"..v..".zip"))
    end
end

for i, v in pairs(MAINSCREEN_HAT_LIST) do
    if v ~= "" then
        table.insert(assets, Asset("ANIM", "anim/"..v..".zip"))
    end
end

local prefabs = {}

--Skins assets
for _, clothing_asset in pairs(require("clothing_assets")) do
    table.insert(assets, clothing_asset)
end
for _, skins_prefabs in pairs(PREFAB_SKINS) do
    for _, skin_prefab in pairs(skins_prefabs) do
        table.insert(prefabs, skin_prefab)
        if string.sub(skin_prefab, -5) ~= "_none" then
            local prefab = require("prefabs/"..skin_prefab)
            if type(prefab) == "table" then
                for k, v in pairs(prefab.assets) do
                    table.insert(assets, v)
                end
            else
                print("ERROR: The contents of prefabs/"..skin_prefab..".lua are corrupt. Try verifying your game's install.")
            end
        end
    end
end

--we don't actually instantiate this prefab. It's used for controlling asset loading
local function fn()
    return CreateEntity()
end

return Prefab("frontend", fn, assets, prefabs)
