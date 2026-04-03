local assets =
{
    --Asset("ANIM", "anim/wx78_lightbeam.zip"),
}

local LIGHT_R, LIGHT_G, LIGHT_B = 235 / 255, 121 / 255, 12 / 255
local function LightFx_SetLightRadius(inst, light_radius)
    local radius = math.sqrt(light_radius * 0.08) * inst.i
    inst.Light:SetRadius( radius )
end

local function CreateLight(i, light_rad)
    i = i + 2

    local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddLight()

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.Light:SetIntensity(.90)
    inst.Light:SetColour(LIGHT_R, LIGHT_G, LIGHT_B)
    inst.Light:SetFalloff( 0.5 )
    inst.Light:Enable(true)

    inst.i = i

    inst:AddTag("FX")
	inst:AddTag("NOCLICK")
    inst:AddTag("staysthroughvirtualrooms")

    inst.SetLightRadius = LightFx_SetLightRadius
    inst:SetLightRadius(light_rad)

    return inst
end

local function LightBeam_OnRemoveEntity(inst)
    for i, v in ipairs(inst.light_fx) do
        v:Remove()
    end
end

local PREDICT_FROM_LAST_WALK_DELAY = 2
local function LightBeam_GetTargetRotation(inst)
    -- Master
    if TheWorld.ismastersim then
        local rot = inst.owner.Transform:GetRotation()
        inst.light_rotation:set(math.ceil(rot))
        return rot
    -- (Attempted) Prediction
    elseif inst.owner.components.playercontroller ~= nil and inst.owner.components.playercontroller:CanLocomote() then
        local pt = inst.owner.components.playercontroller and inst.owner.components.playercontroller:GetRemotePredictPositionExternal()
        if pt then
            local x0, y0, z0 = inst.owner.Transform:GetWorldPosition()
            local distancetotargetsq = distsq(pt.x, pt.z, x0, z0)
	        local stopdistancesq = inst.sg and inst.sg:HasStateTag("floating") and 0.0001 or 0.05

            if inst.owner.components.playercontroller.client_last_predict_walk.tick ~= nil then
                if not inst._is_predict_walking then
                    inst.started_walking_pos = inst:GetPosition()
                end
                inst._is_predict_walking = true
            elseif inst._is_predict_walking then
                inst._is_predict_walking = nil
                inst.last_predict_walk_time = GetTime()
            end

            -- Predict our rotation if we are, or were just walking.
            --  and if we actually moved distance
            local linger_was_predict_walking = inst.last_predict_walk_time == nil or (GetTime() - inst.last_predict_walk_time <= PREDICT_FROM_LAST_WALK_DELAY)
            if inst._is_predict_walking or linger_was_predict_walking then
                if (distancetotargetsq > stopdistancesq)
                    or (linger_was_predict_walking and (inst.started_walking_pos == nil or distsq(inst.started_walking_pos.x, inst.started_walking_pos.z, x0, z0) > stopdistancesq)) then
                    return inst.owner.Transform:GetRotation()
                end
            end
        end
    end
    -- No prediction
    return inst.light_rotation:value()
end

local function LightBeam_OnUpdate(inst, dt)
    local x, y, z = inst.owner.Transform:GetWorldPosition()
    local rot1 = (LightBeam_GetTargetRotation(inst) + 90) * DEGREES
    local rot2 = inst.lightbeam_rotation

    local diff = ReduceAngleRad(rot2 - rot1)

	rot2 = rot1 + diff * 0.75

    inst.lightbeam_rotation = rot2
    for i, fx in ipairs(inst.light_fx) do
        fx.Transform:SetPosition(x + math.sin(rot2) * fx.x_offset, 0, z + math.cos(rot2) * fx.x_offset)
    end
end

local function LightBeam_UpdateLights(inst)
    local light_radius = inst.light_radius:value()
    local num_lights = math.ceil(math.sqrt(light_radius * 2 + 32))
    local space_between = 0.5 * math.pow(light_radius, 0.8)

    if num_lights > #inst.light_fx then
        for i = #inst.light_fx + 1, num_lights do
            local fx = CreateLight(i, light_radius)
            table.insert(inst.light_fx, fx)
        end
    elseif num_lights < #inst.light_fx then
        for i = #inst.light_fx, num_lights + 1, -1 do
            local fx = table.remove(inst.light_fx)
            fx:Remove()
        end
    end

    for i, fx in ipairs(inst.light_fx) do
        fx.x_offset = 0.1 + i + space_between * i
        fx:SetLightRadius(light_radius)
    end
end

local function SpawnLightsForOwner(inst, owner)
    inst.owner = owner
    inst.light_fx = {}
    inst.lightbeam_rotation = (inst.owner.Transform:GetRotation() + 90) * DEGREES

    LightBeam_UpdateLights(inst)
    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(LightBeam_OnUpdate)
    inst.OnRemoveEntity = LightBeam_OnRemoveEntity
end

local function OnEntityReplicated(inst)
    local owner = inst.entity:GetParent()
    if owner ~= nil then
        SpawnLightsForOwner(inst, owner)
    end
end

local function AttachToOwner(inst, owner)
    inst.entity:SetParent(owner.entity)
    SpawnLightsForOwner(inst, owner)
end

local function LightBeam_SetLightradius(inst, light_radius)
    inst.light_radius:set(light_radius)
    LightBeam_UpdateLights(inst)
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    -- inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    --[[
    inst.AnimState:SetBank("wx78_lightbeam")
    inst.AnimState:SetBuild("wx78_lightbeam")
    inst.AnimState:PlayAnimation("turn_on")
    inst.AnimState:PushAnimation("idle", true)
    inst.AnimState:SetLightOverride(1)
    ]]

    inst:AddTag("FX")
	inst:AddTag("NOCLICK")

    inst.light_rotation = net_shortint(inst.GUID, "wx78_lightbeam.light_rotation", "onlightrotationdirty")
    inst.light_radius = net_smallbyte(inst.GUID, "wx78_lightbeam.light_radius", "onlightradiusdirty")
    inst.light_rotation:set(0)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnEntityReplicated
        inst:ListenForEvent("onlightradiusdirty", LightBeam_UpdateLights)
        return inst
    end

    inst.persists = false
    inst.lightbeam_rotation = 0

    inst.AttachToOwner = AttachToOwner
    inst.SetLightRadius = LightBeam_SetLightradius

    return inst
end

return Prefab("wx78_lightbeam", fn)