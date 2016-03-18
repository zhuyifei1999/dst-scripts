local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/cookpot_survival.zip"),
}

local base_prefab = "cookpot"

local tags = {"CROCKPOT", "CRAFTABLE", "SURVIVOR"}

-- TODO: maybe set a init_placer function?
local function init_fn(inst)
    
    inst.AnimState:SetSkin("cookpot_survival", "cook_pot")
end

local ui_preview =
{
	build = "cookpot_survival",
	bank = "cook_pot",
}

return CreatePrefabSkin("cookpot_survival",
{
	base_prefab = base_prefab, 
	assets = assets,
	tags = tags,
	init_fn = init_fn,
	ui_preview = ui_preview,
	item_type = "ITEM_SKIN",
	rarity = "Elegant",
})