local assets =
{
	Asset("ANIM", "anim/trap.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local sounds =
{
    close = "dontstarve/common/trap_close",
    rustle = "dontstarve/common/trap_rustle",
}

local function onharvested(inst)
    if inst.components.finiteuses then
	    inst.components.finiteuses:Use(1)
    end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.MiniMapEntity:SetIcon("rabbittrap.png")

    inst.AnimState:SetBank("trap")
    inst.AnimState:SetBuild("trap")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("trap")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    inst.sounds = sounds

    inst:AddComponent("inventoryitem")
    inst:AddComponent("inspectable")

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.TRAP_USES)
    inst.components.finiteuses:SetUses(TUNING.TRAP_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("trap")
    inst.components.trap.targettag = "canbetrapped"
    inst.components.trap:SetOnHarvestFn(onharvested)

    MakeHauntableLaunch(inst)

    inst:SetStateGraph("SGtrap")

    return inst
end

return Prefab("common/inventory/trap", fn, assets)