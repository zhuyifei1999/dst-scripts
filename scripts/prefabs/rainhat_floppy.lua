-- AUTOGENERATED CODE BY export_accountitems.lua

local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/rainhat_floppy.zip"),
}

return CreatePrefabSkin("rainhat_floppy",
{
	base_prefab = "rainhat",
	type = "item",
	assets = assets,
	build_name = "rainhat_floppy",
	rarity = "Elegant",
	init_fn = function(inst) rainhat_init_fn(inst, "rainhat_floppy") end,
	release_group = 28,
})
