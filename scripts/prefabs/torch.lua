local assets =
{
    Asset("ANIM", "anim/torch.zip"),
    Asset("ANIM", "anim/swap_torch.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "torchfire",
}

local function onequipfueldelta(inst)
    if inst.components.fueled.currentfuel < inst.components.fueled.maxfuel then
        inst.components.fueled:DoDelta(-inst.components.fueled.maxfuel*.01)
    end
end

local function onequip(inst, owner)
    --owner.components.combat.damage = TUNING.PICK_DAMAGE 
    inst.components.burnable:Ignite()
    owner.AnimState:OverrideSymbol("swap_object", "swap_torch", "swap_torch")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal") 

    inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_LP", "torch")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/torch_swing")
    inst.SoundEmitter:SetParameter("torch", "intensity", 1)

    if inst.fire == nil then
        inst.fire = SpawnPrefab("torchfire")
        local follower = inst.fire.entity:AddFollower()
        follower:FollowSymbol(owner.GUID, "swap_object", 0, -114, 0)
    end

    --take a percent of fuel next frame instead of this one, so we can remove the torch properly if it runs out at that point
    inst:DoTaskInTime(0, onequipfueldelta)
end

local function onunequip(inst, owner)
    if inst.fire ~= nil then
        inst.fire:Remove()
        inst.fire = nil
    end

    inst.components.burnable:Extinguish()
    owner.components.combat.damage = owner.components.combat.defaultdamage 
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal")
    inst.SoundEmitter:KillSound("torch")
    inst.SoundEmitter:PlaySound("dontstarve/common/fireOut")
end

local function onpocket(inst, owner)
    inst.components.burnable:Extinguish()
end

local function onattack(weapon, attacker, target)
    if target ~= nil and target.components.burnable ~= nil and math.random() < TUNING.TORCH_ATTACK_IGNITE_PERCENT * target.components.burnable.flammability then
        target.components.burnable:Ignite(nil, attacker)
    end
end

local function onupdatefueledraining(inst)
    local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
    inst.components.fueled.rate =
        owner ~= nil and
        owner.components.sheltered ~= nil and
        owner.components.sheltered.sheltered and
        1 or 1 + TUNING.TORCH_RAIN_RATE * TheWorld.state.precipitationrate
end

local function onisraining(inst, israining)
    if inst.components.fueled ~= nil then
        if israining then
            inst.components.fueled:SetUpdateFn(onupdatefueledraining)
        else
            inst.components.fueled:SetUpdateFn()
            inst.components.fueled.rate = 1
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

    inst.AnimState:SetBank("torch")
    inst.AnimState:SetBuild("torch")
    inst.AnimState:PlayAnimation("idle")

    --lighter (from lighter component) added to pristine state for optimization
    inst:AddTag("lighter")

    --waterproofer (from waterproofer component) added to pristine state for optimization
    inst:AddTag("waterproofer")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.TORCH_DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)

    -----------------------------------
    inst:AddComponent("lighter")
    -----------------------------------

    inst:AddComponent("inventoryitem")
    -----------------------------------

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnPocket(onpocket)
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    -----------------------------------

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

    -----------------------------------

    inst:AddComponent("inspectable")

    -----------------------------------

    inst:AddComponent("burnable")
    inst.components.burnable.canlight = false
    inst.components.burnable.fxprefab = nil
    --inst.components.burnable:AddFXOffset(Vector3(0, 1.5, -.01))

    -----------------------------------

    inst:AddComponent("fueled")
    inst.components.fueled:SetSectionCallback(
        function(section)
            if section == 0 then
                --when we burn out
                if inst.components.burnable ~= nil then
                    inst.components.burnable:Extinguish()
                end
                local equippable = inst.components.equippable
                if equippable ~= nil and equippable:IsEquipped() then
                    local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
                    if owner ~= nil then
                        local data =
                        {
                            prefab = inst.prefab,
                            equipslot = equippable.equipslot,
                            announce = "ANNOUNCE_TORCH_OUT"
                        }
                        inst:Remove()
                        owner:PushEvent("itemranout", data)
                        return
                    end
                end
                inst:Remove()
            end
        end)
    inst.components.fueled:InitializeFuelLevel(TUNING.TORCH_FUEL)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    inst:WatchWorldState("israining", onisraining)
    onisraining(inst, TheWorld.state.israining)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("torch", fn, assets, prefabs)
