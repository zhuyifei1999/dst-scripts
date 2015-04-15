local HOUND_SPAWN_DIST = 30

local function PlayWarningSound(proxy, level)
	-- the prefab is spawned in a player's position
	if ThePlayer == nil then
		return
	end

	-- The sound needs to be moved away by my distance from the relevant player, so if I am near that player I hear it at about the same volume, if I am farther away
	-- I hear it less loud, even if according to the other player it's in my direction (only because it's less relevant to me - since it's a random position (and just ambient warning) there really is no valid logic)
	local inst = CreateEntity()

    --[[Non-networked entity]]

	inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

	local radius = HOUND_SPAWN_DIST + (level - 1) * 10
	local theta = math.random() * 2 * PI
    local x, y, z = ThePlayer.Transform:GetWorldPosition()
	inst.Transform:SetPosition(x + radius * math.cos(theta), 0, z - radius * math.sin(theta))
	inst.SoundEmitter:PlaySound("dontstarve/creatures/hound/distant")

	inst:Remove()
end

local function houndwarning(level)
	local inst = CreateEntity()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        --Delay one frame so that we are positioned properly before starting the effect
        --or in case we are about to be removed
        inst:DoTaskInTime(0, PlayWarningSound, level)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst:DoTaskInTime(1, inst.Remove)

    return inst
end

local function houndwarning_1()
	return houndwarning(1)
end

local function houndwarning_2()
	return houndwarning(2)
end

local function houndwarning_3()
	return houndwarning(3)
end

local function houndwarning_4()
	return houndwarning(4)
end

return Prefab("common/fx/houndwarning_lvl1", houndwarning_1),
	   Prefab("common/fx/houndwarning_lvl2", houndwarning_2),
	   Prefab("common/fx/houndwarning_lvl3", houndwarning_3),
	   Prefab("common/fx/houndwarning_lvl4", houndwarning_4)
