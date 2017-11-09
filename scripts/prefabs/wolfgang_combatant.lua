-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_wolfgang_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_mighty_combatant.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_combatant.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wolfgang_skinny_combatant.zip"),
}

return CreatePrefabSkin("wolfgang_combatant",
{
	base_prefab = "wolfgang",
	type = "base",
	assets = assets,
	build_name = "wolfgang_combatant",
	rarity = "Event",
	skin_tags = { "LAVA", "BASE", "CHARACTER", "WOLFGANG", },
	skins = { ghost_skin = "ghost_wolfgang_build", mighty_skin = "wolfgang_mighty_combatant", normal_skin = "wolfgang_combatant", wimpy_skin = "wolfgang_skinny_combatant", },
	release_group = 32,
})
