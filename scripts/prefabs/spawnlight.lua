local assets =
{
    Asset("ANIM", "anim/cave_exit_lightsource.zip"),
}

local START_RAD = 4
local TOTAL_TIME = 8
local UPDATE_PERIOD = 1 / 30

local function update(inst)
    if not inst.rad then
        inst.rad = START_RAD
    end
    if TheWorld.state.isday then
        inst.rad = inst.rad - UPDATE_PERIOD * START_RAD / TOTAL_TIME
        inst.Light:SetRadius(inst.rad)
        if not inst.off and inst.rad / START_RAD < .1 then
            inst.AnimState:PlayAnimation("off")
            inst.off = true
        end
        if inst.rad <= 0 then
            inst:Remove()
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Light:SetFalloff(0.3)
    inst.Light:SetIntensity(.9)
    inst.Light:SetRadius(START_RAD)
    inst.Light:SetColour(180/255, 195/255, 150/255)
    inst.Light:Enable(true)

    inst.AnimState:SetBank("cavelight")
    inst.AnimState:SetBuild("cave_exit_lightsource")
    inst.AnimState:PlayAnimation("on", false)
    inst.AnimState:PushAnimation("idle_loop", true)
    inst.AnimState:SetMultColour(255/255, 177/255, 32/255, 0)

    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:DoPeriodicTask(UPDATE_PERIOD, update, 2)
    inst.persists = false

    return inst
end

return Prefab("spawnlight", fn, assets)