local assets =
{
	Asset("ANIM", "anim/umbrella.zip"),
	Asset("ANIM", "anim/swap_umbrella.zip"),
}
  
local function UpdateSound(inst, israining)
    local soundShouldPlay = israining and inst.components.equippable:IsEquipped()
    if soundShouldPlay ~= inst.SoundEmitter:PlayingSound("umbrellarainsound") then
        if soundShouldPlay then
		    inst.SoundEmitter:PlaySound("dontstarve/rain/rain_on_umbrella", "umbrellarainsound") 
        else
		    inst.SoundEmitter:KillSound("umbrellarainsound")
		end
    end
end

local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_object", "swap_umbrella", "swap_umbrella")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    UpdateSound(inst, TheWorld.state.israining)
end

local function onunequip(inst, owner) 
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal") 
    UpdateSound(inst, TheWorld.state.israining)
end

local function fn(Sim)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst.AnimState:SetBank("umbrella")
    inst.AnimState:SetBuild("umbrella")
    inst.AnimState:PlayAnimation("idle")
    
    inst:AddTag("sharp")

    inst:AddComponent("dapperness")
    inst.components.dapperness.mitigates_rain = true
    -------
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.UMBRELLA_USES)
    inst.components.finiteuses:SetUses(TUNING.UMBRELLA_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove) 
    --inst.components.finiteuses:SetConsumption(ACTIONS.TERRAFORM, .125)
    -------

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.UMBRELLA_DAMAGE)
    
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)
    
    inst:WatchWorldState("israining", UpdateSound)
    
    return inst
end

return Prefab("common/inventory/umbrella", fn, assets)