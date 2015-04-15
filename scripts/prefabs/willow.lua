local MakePlayerCharacter = require("prefabs/player_common")

local assets =
{
    Asset("ANIM", "anim/willow.zip"),
	Asset("SOUND", "sound/willow.fsb"),

	Asset("ANIM", "anim/ghost_willow_build.zip"),
}

local prefabs =
{
    "willowfire",
    "lighter",
}

local start_inv =
{
    "lighter",
}

local function sanityfn(inst)
	local x,y,z = inst.Transform:GetWorldPosition()	
	local delta = 0
	local max_rad = 10
	local ents = TheSim:FindEntities(x,y,z, max_rad, {"fire"})
    for k,v in pairs(ents) do
    	if v.components.burnable and v.components.burnable.burning then
    		local sz = TUNING.SANITYAURA_TINY
    		local rad = v.components.burnable:GetLargestLightRadius() or 1
    		sz = sz * ( math.min(max_rad, rad) / max_rad )
			local distsq = inst:GetDistanceSqToInst(v)
			delta = delta + sz/math.max(1, distsq)
    	end
    end

    return delta
end

local function common_postinit(inst)
    inst:AddTag("ghostwithhat")
    inst:AddTag("pyromaniac")
end

-- local function startfirebug(inst)
--     inst.components.firebug:Enable()
-- end

-- local function stopfirebug(inst)
--     inst.components.firebug:Disable()
-- end

local function master_postinit(inst)
    inst.components.health.fire_damage_scale = TUNING.WILLOW_FIRE_DAMAGE

    inst.components.sanity:SetMax(TUNING.WILLOW_SANITY)
    inst.components.sanity.custom_rate_fn = sanityfn
    inst.components.sanity.rate_modifier = TUNING.WILLOW_SANITY_MODIFIER

    -- inst:AddComponent("firebug")
    -- inst.components.firebug.prefab = "willowfire"
    -- inst.components.firebug.sanity_threshold = TUNING.WILLOW_LIGHTFIRE_SANITY_THRESH

    -- inst:ListenForEvent("ms_respawnedfromghost", startfirebug)
    -- inst:ListenForEvent("ms_becameghost", stopfirebug)
    -- inst:ListenForEvent("death", stopfirebug)

    -- startfirebug(inst)
end

return MakePlayerCharacter("willow", prefabs, assets, common_postinit, master_postinit, start_inv)