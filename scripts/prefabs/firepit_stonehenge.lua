local assets =
{
	Asset("DYNAMIC_ANIM", "anim/dynamic/firepit_stonehenge.zip"),
}

local base_prefab = "firepit"

local tags = {"FIREPIT", "CRAFTABLE"}

-- TODO: maybe set a init_placer function?
local function init_fn(inst)
    
    inst.AnimState:SetSkin("firepit_stonehenge", "firepit")

    -- This is called when the skinned object is a placer and not an actual skinned item
    if not inst.components.burnable then return end

    for k,v in pairs(inst.components.burnable.fxchildren) do 
    	local x,y,z = v.Transform:GetWorldPosition()
    	v.Transform:SetPosition(x, y+.2, z)
    end
end

local ui_preview =
{
	build = "firepit_stonehenge",
	bank = "firepit",
}

return CreatePrefabSkin("firepit_stonehenge",
{
	base_prefab = base_prefab, 
	assets = assets,
	tags = tags,
	init_fn = init_fn,
	ui_preview = ui_preview,
	item_type = "ITEM_SKIN_LOYAL",
	rarity = "Loyal",
	
	skip_giftable_gen = true,
})