
-- Baits and Lures

local LURES =
{
	["oceanfishinglure_spoon_red"]			= { build = "oceanfishing_lure_spoon", symbol = "red",		lure_data = TUNING.OCEANFISHING_LURE.SPOON_DAY, },
	["oceanfishinglure_spoon_green"]		= { build = "oceanfishing_lure_spoon", symbol = "green",	lure_data = TUNING.OCEANFISHING_LURE.SPOON_DUSK, },
	["oceanfishinglure_spoon_blue"]			= { build = "oceanfishing_lure_spoon", symbol = "blue",		lure_data = TUNING.OCEANFISHING_LURE.SPOON_NIGHT, },

	["oceanfishinglure_spinner_red"]		= { build = "oceanfishing_lure_spinner", symbol = "red",	lure_data = TUNING.OCEANFISHING_LURE.SPINNERBAIT_DAY, },
	["oceanfishinglure_spinner_green"]		= { build = "oceanfishing_lure_spinner", symbol = "green",	lure_data = TUNING.OCEANFISHING_LURE.SPINNERBAIT_DUSK, },
	["oceanfishinglure_spinner_blue"]		= { build = "oceanfishing_lure_spinner", symbol = "blue",	lure_data = TUNING.OCEANFISHING_LURE.SPINNERBAIT_NIGHT, },


	-- WIP lures, will probably use them in the future
	["oceanfishinglure_spoon_brown"]		= { build = "oceanfishing_lure_spoon", symbol = "brown",	lure_data = TUNING.OCEANFISHING_LURE.SPOON_WIP, },
	["oceanfishinglure_spoon_yellow"]		= { build = "oceanfishing_lure_spoon", symbol = "yellow",	lure_data = TUNING.OCEANFISHING_LURE.SPOON_WIP, },
	["oceanfishinglure_spoon_silver"]		= { build = "oceanfishing_lure_spoon", symbol = "silver",	lure_data = TUNING.OCEANFISHING_LURE.SPOON_WIP, },

	["oceanfishinglure_spinner_orange"]		= { build = "oceanfishing_lure_spinner", symbol = "orange", lure_data = TUNING.OCEANFISHING_LURE.SPINNERBAIT_WIP, },
	["oceanfishinglure_spinner_yellow"]		= { build = "oceanfishing_lure_spinner", symbol = "yellow", lure_data = TUNING.OCEANFISHING_LURE.SPINNERBAIT_WIP, },
	["oceanfishinglure_spinner_white"]		= { build = "oceanfishing_lure_spinner", symbol = "white",	lure_data = TUNING.OCEANFISHING_LURE.SPINNERBAIT_WIP, },

	-- other lures: 
	-- spoon = tinket_17
	-- berry = berries, berries_juicy
	-- seed = seeds, seed_<veggie>
}

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local function item_fn(data, name)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank(data.bank or data.build)
    inst.AnimState:SetBuild(data.build)
    inst.AnimState:PlayAnimation("idle_"..data.symbol)

    MakeInventoryFloatable(inst, "small", nil, 0.5)

	inst:AddTag("oceanfishing_lure")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

	inst:AddComponent("oceanfishingtackle")
	inst.components.oceanfishingtackle:SetupLure(data)

    inst:AddComponent("inventoryitem")

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    return inst
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local ret = { }

for name, v in pairs(LURES) do
	local assets =
	{
		Asset("ANIM", "anim/"..v.build..".zip"),
	}
	if v.bank ~= nil and v.build ~= v.bank then
		table.insert(assets, Asset("ANIM", "anim/"..v.bank..".zip"))
	end

    table.insert(ret, Prefab(name, function() return item_fn(v, name) end, assets))
end

return unpack(ret)

