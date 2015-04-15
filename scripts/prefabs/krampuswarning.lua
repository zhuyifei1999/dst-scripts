local function PlayWarningSound(proxy, level)
    local inst = CreateEntity()

    --[[Non-networked entity]]

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    -- The proxy is spawned in a player's position
    -- The sound needs to be moved away by my distance from the relevant player, so if I am near that player I hear it at about the same volume, if I am farther away
    -- I hear it less loud, even if according to the other player it's in my direction (only because it's less relevant to me - since it's a random position (and just ambient warning) there really is no valid logic)
    local theta = math.random() * 2 * PI
    local radius = 15
    local x, y, z
    if ThePlayer ~= nil then
        x, y, z = ThePlayer.Transform:GetWorldPosition()
        local px, py, pz = proxy.Transform:GetWorldPosition()
        radius = radius + math.sqrt(distsq(x, z, px, pz))
    else
        x, y, z = proxy.Transform:GetWorldPosition()
    end

    inst.Transform:SetPosition(x + radius * math.cos(theta), 0, z - radius * math.sin(theta))
    inst.SoundEmitter:PlaySound("dontstarve/creatures/krampus/beenbad_lvl"..tostring(level))

    inst:Remove()
end

local function krampus(level)
    local inst = CreateEntity()

    inst.entity:AddTransform()
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

local function krampus_1()
	return krampus(1)
end

local function krampus_2()
	return krampus(2)
end

local function krampus_3()
	return krampus(3)
end

return Prefab("common/fx/krampuswarning_lvl1", krampus_1),
	   Prefab("common/fx/krampuswarning_lvl2", krampus_2),
	   Prefab("common/fx/krampuswarning_lvl3", krampus_3)