local assets =
{
    Asset("PKGREF", "sound/dontstarve.fev"),
	Asset("SOUNDPACKAGE", "sound/dontstarve_DLC001.fev"),
    Asset("FILE", "sound/DLC_music.fsb"),

    Asset("FILE", "sound/wilton.fsb"),         -- Legacy sound that can be used in mods
    Asset("FILE", "sound/winnie.fsb"),         -- Legacy sound that can be used in mods
    Asset("FILE", "sound/wallace.fsb"),        -- Legacy sound that can be used in mods
    Asset("FILE", "sound/woodrow.fsb"),        -- Legacy sound that can be used in mods
    Asset("FILE", "sound/stuff.fsb"),          -- Legacy sound that can be used in mods

    Asset("ATLAS", "images/global.xml"),
    Asset("IMAGE", "images/global.tex"),
    Asset("IMAGE", "images/visited.tex"),
    Asset("ANIM", "anim/scroll_arrow.zip"),

    Asset("ANIM", "anim/corner_dude.zip"),
	
	Asset("SHADER", "shaders/anim_bloom.ksh"),
    Asset("SHADER", "shaders/anim_bloom_ghost.ksh"),
	Asset("SHADER", "shaders/road.ksh"),

	Asset("IMAGE", "images/shadow.tex"),
	Asset("IMAGE", "images/erosion.tex"),
	Asset("IMAGE", "images/circle.tex"),
	Asset("IMAGE", "images/square.tex"),
	Asset("IMAGE", "images/trans.tex"),

    Asset("ATLAS", "images/fepanels.xml"),
    Asset("IMAGE", "images/fepanels.tex"),

    Asset("ATLAS", "images/options.xml"),
    Asset("IMAGE", "images/options.tex"),
    Asset("ATLAS", "images/options_bg.xml"),
    Asset("IMAGE", "images/options_bg.tex"),

	Asset("ATLAS", "images/frontend.xml"),
	Asset("IMAGE", "images/frontend.tex"),

    Asset("ATLAS", "images/frontscreen.xml"),
    Asset("IMAGE", "images/frontscreen.tex"),

    Asset("ATLAS", "images/fg_trees.xml"),
    Asset("IMAGE", "images/fg_trees.tex"),

    --V2C: moved to frontend
    --Asset("ATLAS", "images/bg_plain.xml"),
    --Asset("IMAGE", "images/bg_plain.tex"),

    Asset("ATLAS", "images/bg_spiral.xml"),
    Asset("IMAGE", "images/bg_spiral.tex"),
    Asset("DYNAMIC_ATLAS", "images/bg_spiral_fill1.xml"),
    Asset("ASSET_PKGREF", "images/bg_spiral_fill1.tex"),
    Asset("DYNAMIC_ATLAS", "images/bg_spiral_fill2.xml"),
    Asset("ASSET_PKGREF", "images/bg_spiral_fill2.tex"),
    Asset("DYNAMIC_ATLAS", "images/bg_spiral_fill3.xml"),
    Asset("ASSET_PKGREF", "images/bg_spiral_fill3.tex"),
    Asset("DYNAMIC_ATLAS", "images/bg_spiral_fill4.xml"),
    Asset("ASSET_PKGREF", "images/bg_spiral_fill4.tex"),
    Asset("DYNAMIC_ATLAS", "images/bg_spiral_fill5.xml"),
    Asset("ASSET_PKGREF", "images/bg_spiral_fill5.tex"),
    Asset("DYNAMIC_ATLAS", "images/bg_spiral_fill6.xml"),
    Asset("ASSET_PKGREF", "images/bg_spiral_fill6.tex"),
    Asset("DYNAMIC_ATLAS", "images/bg_spiral_fill7.xml"),
    Asset("ASSET_PKGREF", "images/bg_spiral_fill7.tex"),
    Asset("DYNAMIC_ATLAS", "images/bg_spiral_fill8.xml"),
    Asset("ASSET_PKGREF", "images/bg_spiral_fill8.tex"),
    Asset("ATLAS", "images/bg_vignette.xml"),
    Asset("IMAGE", "images/bg_vignette.tex"),

    Asset("ATLAS", "images/lobbyscreen.xml"),
    Asset("Image", "images/lobbyscreen.tex"),

    Asset("ATLAS", "images/fepanel_fills.xml"),
    Asset("IMAGE", "images/fepanel_fills.tex"),

    Asset("ATLAS", "images/thankyou_item_popup.xml"),
    Asset("IMAGE", "images/thankyou_item_popup.tex"),
    Asset("ATLAS", "images/thankyou_item_popup_rog.xml"),
    Asset("IMAGE", "images/thankyou_item_popup_rog.tex"),

    Asset("ATLAS", "images/bg_animated_portal.xml"),
    Asset("IMAGE", "images/bg_animated_portal.tex"),

    Asset("ATLAS", "images/fg_animated_portal.xml"),
    Asset("IMAGE", "images/fg_animated_portal.tex"),

    Asset("ANIM", "anim/portal_scene2.zip"),
    Asset("ANIM", "anim/portal_scene_steamfxbg.zip"),
    Asset("ANIM", "anim/portal_scene2_inside.zip"),
    Asset("ANIM", "anim/portal_scene_steamfxeast.zip"),
    Asset("ANIM", "anim/portal_scene_steamfxwest.zip"),
    Asset("ANIM", "anim/portal_scene_steamfxsouth.zip"),
    Asset("ANIM", "anim/cloud_build.zip"),
	
	--Asset("IMAGE", "images/river_bed.tex"),
	--Asset("IMAGE", "images/water_river.tex"),
	Asset("IMAGE", "images/pathnoise.tex"),
	Asset("IMAGE", "images/mini_pathnoise.tex"),
	Asset("IMAGE", "images/roadnoise.tex"),
	Asset("IMAGE", "images/roadedge.tex"),
	Asset("IMAGE", "images/roadcorner.tex"),
	Asset("IMAGE", "images/roadendcap.tex"),
	
	Asset("ATLAS", "images/fx.xml"),
	Asset("IMAGE", "images/fx.tex"),

	Asset("IMAGE", "images/colour_cubes/identity_colourcube.tex"),

	Asset("SHADER", "shaders/anim.ksh"),
    Asset("SHADER", "shaders/anim_fade.ksh"),
	Asset("SHADER", "shaders/anim_bloom.ksh"),
	Asset("SHADER", "shaders/blurh.ksh"),
	Asset("SHADER", "shaders/blurv.ksh"),
	Asset("SHADER", "shaders/creep.ksh"),
	Asset("SHADER", "shaders/debug_line.ksh"),
	Asset("SHADER", "shaders/debug_tri.ksh"),
	Asset("SHADER", "shaders/render_depth.ksh"),
	Asset("SHADER", "shaders/font.ksh"),
	Asset("SHADER", "shaders/font_packed.ksh"),
	Asset("SHADER", "shaders/font_packed_outline.ksh"),
	Asset("SHADER", "shaders/ground.ksh"),
    Asset("SHADER", "shaders/ground_overlay.ksh"),
	Asset("SHADER", "shaders/ground_lights.ksh"),
    Asset("SHADER", "shaders/ceiling.ksh"),
    -- Asset("SHADER", "shaders/triplanar.ksh"),
    Asset("SHADER", "shaders/triplanar_bg.ksh"),
    Asset("SHADER", "shaders/triplanar_alpha_wall.ksh"),
    Asset("SHADER", "shaders/triplanar_alpha_ceiling.ksh"),
	Asset("SHADER", "shaders/lighting.ksh"),
	Asset("SHADER", "shaders/minimap.ksh"),
	Asset("SHADER", "shaders/minimapfs.ksh"),
	Asset("SHADER", "shaders/particle.ksh"),
	Asset("SHADER", "shaders/vfx_particle.ksh"),
	Asset("SHADER", "shaders/vfx_particle_add.ksh"),
	Asset("SHADER", "shaders/vfx_particle_reveal.ksh"),
	Asset("SHADER", "shaders/road.ksh"),
	Asset("SHADER", "shaders/river.ksh"),
	Asset("SHADER", "shaders/splat.ksh"),
	Asset("SHADER", "shaders/texture.ksh"),
	Asset("SHADER", "shaders/ui.ksh"),
	Asset("SHADER", "shaders/ui_anim.ksh"),
    Asset("SHADER", "shaders/combine_colour_cubes.ksh"),
	Asset("SHADER", "shaders/postprocess.ksh"),
	Asset("SHADER", "shaders/postprocessbloom.ksh"),
	Asset("SHADER", "shaders/postprocessdistort.ksh"),
	Asset("SHADER", "shaders/postprocessbloomdistort.ksh"),

	Asset("SHADER", "shaders/waves.ksh"),
	Asset("SHADER", "shaders/overheat.ksh"),

    Asset("SHADER", "shaders/anim.ksh"),
    Asset("SHADER", "shaders/anim_bloom.ksh"),
    Asset("SHADER", "shaders/anim_fade.ksh"),
    Asset("SHADER", "shaders/anim_haunted.ksh"),
    Asset("SHADER", "shaders/anim_fade_haunted.ksh"),
    Asset("SHADER", "shaders/anim_bloom_haunted.ksh"),
    Asset("SHADER", "shaders/minimapblend.ksh"),

    --common UI elements that we will always need
    Asset("ATLAS", "images/ui.xml"),
    Asset("IMAGE", "images/ui.tex"),
    Asset("ATLAS", "images/textboxes.xml"),
    Asset("IMAGE", "images/textboxes.tex"),
    Asset("ATLAS", "images/serverbrowser.xml"),
    Asset("IMAGE", "images/serverbrowser.tex"),
    Asset("ATLAS", "images/scoreboard.xml"),
    Asset("IMAGE", "images/scoreboard.tex"),
    Asset("ANIM", "anim/generating_world.zip"),
    Asset("ANIM", "anim/generating_cave.zip"),
    Asset("ANIM", "anim/creepy_hands.zip"),    
    Asset("ANIM", "anim/saving_indicator.zip"),

    Asset("ANIM", "anim/skingift_popup.zip"),
    Asset("ATLAS", "images/giftpopup.xml"),
    Asset("IMAGE", "images/giftpopup.tex"),
    
    --oft-used panel bgs
    Asset("ATLAS", "images/globalpanels2.xml"),
    Asset("IMAGE", "images/globalpanels2.tex"),

    Asset("ATLAS", "images/button_icons.xml"),
    Asset("IMAGE", "images/button_icons.tex"),

    Asset("ATLAS", "images/avatars.xml"),
    Asset("IMAGE", "images/avatars.tex"),

    Asset("DYNAMIC_ANIM", "anim/dynamic/body_default1.zip"),
    Asset("DYNAMIC_ANIM", "anim/dynamic/hand_default1.zip"),
    Asset("DYNAMIC_ANIM", "anim/dynamic/legs_default1.zip"),
    Asset("DYNAMIC_ANIM", "anim/dynamic/feet_default1.zip"),

    Asset("DYNAMIC_ANIM", "anim/dynamic/previous_skin.zip"),
    Asset("DYNAMIC_ANIM", "anim/dynamic/random_skin.zip"),
}

require "fonts"
for i, font in ipairs( FONTS ) do
	table.insert( assets, Asset( "FONT", font.filename ) )
end

return Prefab("global", function() end, assets)
