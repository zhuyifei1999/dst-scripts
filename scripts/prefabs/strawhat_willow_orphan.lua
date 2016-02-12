local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/hat_straw_strawhat_willow_orphan.zip"),
}

local base_prefab = "strawhat"

local tags = {"STRAWHAT", "CRAFTABLE"}

local function init_fn(inst)
    inst.AnimState:SetBank("hat_straw_strawhat_willow_orphan")
    inst.AnimState:SetBuild("hat_straw_strawhat_willow_orphan")
end

local ui_preview =
{
	build = "hat_straw_strawhat_willow_orphan",
	bank = "hat_straw_strawhat_willow_orphan",
}

return CreatePrefabSkin("strawhat_willow_orphan",
{
	base_prefab = base_prefab, 
	assets = assets,
	tags = tags,
	init_fn = init_fn,
	item_type = "ITEM_SKIN",
	ui_preview = ui_preview,
	
	skip_item_gen = true,
	skip_giftable_gen = true,
})