-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_wendy_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/wendy_combatant.zip"),
}

return CreatePrefabSkin("wendy_combatant",
{
	base_prefab = "wendy",
	type = "base",
	assets = assets,
	build_name = "wendy_combatant",
	rarity = "Event",
	skins = { ghost_skin = "ghost_wendy_build", normal_skin = "wendy_combatant", },
	release_group = 32,
})