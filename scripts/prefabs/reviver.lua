local assets =
{
    Asset("ANIM", "anim/bloodpump.zip"),
}

local function beat(inst)
    inst.AnimState:PlayAnimation("idle")
    if inst.glowfx ~= nil then
        inst.glowfx.AnimState:PlayAnimation("glow_idle")
    end
    inst.SoundEmitter:PlaySound("dontstarve/ghost/bloodpump")
    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, beat)
end

local function startbeat(inst)
    if inst.beat_fx ~= nil then
        inst.beat_fx:Remove()
        inst.beat_fx = nil
    end
    if inst.reviver_beat_fx ~= nil then
        inst.beat_fx = SpawnPrefab(inst.reviver_beat_fx)
        inst.beat_fx.entity:SetParent(inst.entity)
        inst.beat_fx.entity:AddFollower()
        inst.beat_fx.Follower:FollowSymbol(inst.GUID, "bloodpump02", -5, -30, 0)
    end
    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, beat)
end

local function ondropped(inst)
    if inst.beattask ~= nil then
        inst.beattask:Cancel()
    end
    inst.beattask = inst:DoTaskInTime(0, startbeat)
end

local function onpickup(inst)
    if inst.beattask ~= nil then
        inst.beattask:Cancel()
        inst.beattask = nil
    end
    if inst.beat_fx ~= nil then
        inst.beat_fx:Remove()
        inst.beat_fx = nil
    end
end

local function ConvertToGlow(inst)
    inst.Physics:SetActive(false)

    inst.AnimState:PlayAnimation("glow_idle")
    inst.AnimState:SetLightOverride(.3)
    inst.AnimState:SetFinalOffset(1)

    inst:AddTag("FX")

    inst:RemoveComponent("inventoryitem")
    inst:RemoveComponent("inspectable")
    inst:RemoveComponent("tradable")
    inst:RemoveComponent("hauntable")

    onpickup(inst) --V2C: durrhhhh it does wot i need yo

    inst.persists = false

    inst.reviver_beat_fx = nil
    inst.OnBuiltFn = nil
    inst.OnSave = nil
    inst.OnLoad = nil

    return inst
end

local function OnEntityReplicated(inst)
    local parent = inst.entity:GetParent()
    if parent ~= nil and parent.prefab == inst.prefab then
        parent.highlightchildren = { inst }
    end
end

------------------------------------------------------------
-- NOTE: update reviver skins when modifying this prefab! --
------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("bloodpump01")
    inst.AnimState:SetBuild("bloodpump")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnEntityReplicated

        return inst
    end

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(ondropped)
    inst.components.inventoryitem:SetOnPutInInventoryFn(onpickup)

    inst:AddComponent("inspectable")
    inst:AddComponent("tradable")

    MakeHauntableLaunch(inst)

    inst.beattask = nil
    ondropped(inst)

    inst.ConvertToGlow = ConvertToGlow

    return inst
end

return Prefab("reviver", fn, assets)
