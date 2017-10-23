-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("ANIM", "anim/ghost_webber_build.zip"),
	Asset("DYNAMIC_ANIM", "anim/dynamic/webber_combatant.zip"),
}

return CreatePrefabSkin("webber_combatant",
{
	base_prefab = "webber",
	type = "base",
	assets = assets,
	build_name = "webber_combatant",
	rarity = "Event",
	skins = { ghost_skin = "ghost_webber_build", normal_skin = "webber_combatant", },
	release_group = 32,
})
