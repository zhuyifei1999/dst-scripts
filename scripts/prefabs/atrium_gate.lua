local assets =
{
	Asset("ANIM", "anim/atrium_gate.zip"),
    Asset("MINIMAP_IMAGE", "atrium_gate_active"),
}

local prefabs = 
{
	"atrium_key",
}

local function ShowFx(inst)
    if inst._staffstar == nil then
        inst._staffstar = SpawnPrefab("stafflight")
        inst._staffstar.entity:SetParent(inst.entity)
        inst._staffstar.Transform:SetScale(1.92, 1.92, 1.92)
        inst._staffstar.AnimState:SetMultColour(.95, .1, .65, 1)

        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end
end

local function HideFx(inst)
    if inst._staffstar ~= nil then
        inst._staffstar:Remove()
        inst._staffstar = nil

        inst.AnimState:ClearBloomEffectHandle()
    end
end

local function ItemTradeTest(inst, item)
    if item == nil then
        return false
    elseif item.prefab ~= "atrium_key" then
        return false, "NOTATRIUMKEY"
    end
    return true
end

local function OnKeyGiven(inst)
    --Disable trading, enable picking.
    inst.components.trader:Disable()
    inst.components.pickable:SetUp("atrium_key", 1000000)
    inst.components.pickable:Pause()
    inst.components.pickable.caninteractwith = true

	TheWorld:PushEvent("atriumpowered", true)
end

local function OnKeyTaken(inst, picker, loot)
    --Disable picking, enable trading.
    inst.components.trader:Enable()
    inst.components.pickable.caninteractwith = false

	TheWorld:PushEvent("atriumpowered", false)
end

local function OnPoweredFn(inst, ispowered)
    inst.AnimState:PlayAnimation(ispowered and "idle_active" or "idle", ispowered)

    TheWorld:PushEvent("ms_locknightmarephase", ispowered and "wild" or nil)
    
    inst.MiniMapEntity:SetIcon(ispowered and "atrium_gate_active.png" or "atrium_gate.png")
    
    if ispowered then
        --ShowFx(inst)
	else
	    --HideFx(inst)
	end
end

local function getstatus(inst)
    return inst.components.pickable.caninteractwith and "ON" or "OFF"
end

local function OnLoad(inst, data)
    if inst.components.pickable.caninteractwith then
        inst:DoTaskInTime(0, OnKeyGiven)
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("atrium_gate")
    inst.AnimState:SetBuild("atrium_gate")
    inst.AnimState:PlayAnimation("idle")

    inst.MiniMapEntity:SetIcon("atrium_gate.png")

	inst:AddTag("gemsocket") -- for "Socket" action string
	inst:AddTag("stargate")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("pickable")
    inst.components.pickable.caninteractwith = false
    inst.components.pickable.onpickedfn = OnKeyTaken

    --inst:AddTag("intense") -- add this when the fight starts, and stop it when the fight ends

    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(ItemTradeTest)
    inst.components.trader.deleteitemonaccept = true
    inst.components.trader.onaccept = OnKeyGiven

    MakeHauntableWork(inst)

    inst.OnLoad = OnLoad

	inst:ListenForEvent("atriumpowered", function(_, ispowered) OnPoweredFn(inst, ispowered) end, TheWorld)

    return inst
end

return Prefab("atrium_gate", fn, assets, prefabs)
