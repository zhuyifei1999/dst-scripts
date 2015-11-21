local assets =
{
    Asset("ANIM", "anim/ruins_bat.zip"),
    Asset("ANIM", "anim/swap_ruins_bat.zip"),
}

local prefabs =
{
    "shadowtentacle",
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_ruins_bat", "swap_ruins_bat")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local summonchance = 0.2

local function onattack(inst, owner, target)
    if math.random() < summonchance then
        local pt = target:GetPosition()
        local st_pt =  FindWalkableOffset(pt or owner:GetPosition(), math.random()*2*PI, 2, 3)
        if st_pt then
            inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_1")
            inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_2")            
            st_pt = st_pt + pt
            local st = SpawnPrefab("shadowtentacle")
            --print(st_pt:Get())
            st.Transform:SetPosition(st_pt:Get())
            st.components.combat:SetTarget(target)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("ruins_bat")
    inst.AnimState:SetBank("ruins_bat")
    inst.AnimState:SetBuild("ruins_bat")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.RUINS_BAT_DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)

    -------

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.RUINS_BAT_USES)
    inst.components.finiteuses:SetUses(TUNING.RUINS_BAT_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = 1.1

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("common/inventory/ruins_bat", fn, assets, prefabs)