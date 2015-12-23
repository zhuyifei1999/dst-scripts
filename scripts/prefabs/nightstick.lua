local assets =
{
    Asset("ANIM", "anim/nightstick.zip"),
    Asset("ANIM", "anim/swap_nightstick.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "nightstickfire",
}

local function onpocket(inst)
    inst.components.burnable:Extinguish()
end

local function onequip(inst, owner) 
    inst.components.burnable:Ignite()
    owner.AnimState:OverrideSymbol("swap_object", "swap_nightstick", "swap_nightstick")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/morningstar", "torch")
    --inst.SoundEmitter:SetParameter("torch", "intensity", 1)

    inst.fire = SpawnPrefab("nightstickfire")
    local follower = inst.fire.entity:AddFollower()
    follower:FollowSymbol(owner.GUID, "swap_object", 0, -110, 1)

    --take a percent of fuel next frame instead of this one, so we can remove the torch properly if it runs out at that point
    inst:DoTaskInTime(0, function()
        if inst.components.fueled.currentfuel < inst.components.fueled.maxfuel then
            inst.components.fueled:DoDelta(-inst.components.fueled.maxfuel*.01)
        end
    end)
end

local function onunequip(inst,owner)
    inst.fire:Remove()
    inst.fire = nil

    inst.components.burnable:Extinguish()
    owner.components.combat.damage = owner.components.combat.defaultdamage
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    inst.SoundEmitter:KillSound("torch")
end

local function sectioncallback(newsection, oldsection, inst)
    if newsection == 0 then
        --when we burn out
        if inst.components.burnable then
            inst.components.burnable:Extinguish()
        end

        if inst.components.inventoryitem and inst.components.inventoryitem:IsHeld() then
            local owner = inst.components.inventoryitem.owner
            inst:Remove()

            if owner then
                owner:PushEvent("nightstickranout", {nightstick = inst})
            end
        end
    end
end

local function onattack(inst)
    if inst ~= nil and inst:IsValid() and inst.fire ~= nil and inst.fire:IsValid() then
        inst.fire:OnAttack()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("nightstick")
    inst.AnimState:SetBuild("nightstick")
    inst.AnimState:PlayAnimation("idle")

    MakeInventoryPhysics(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.NIGHTSTICK_DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)
    inst.components.weapon:SetElectric()

    -- inst.components.weapon:SetOnAttack(
    --     function(attacker, target)
    --         if target.components.burnable then
    --             if math.random() < TUNING.TORCH_ATTACK_IGNITE_PERCENT*target.components.burnable.flammability then
    --                 target.components.burnable:Ignite()
    --             end
    --         end
    --     end
    -- )

    -- -----------------------------------
    -- inst:AddComponent("lighter")
    -- -----------------------------------

    inst:AddComponent("inventoryitem")
    -----------------------------------

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnPocket(onpocket)
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    -----------------------------------

    inst:AddComponent("inspectable")

    -----------------------------------

    inst:AddComponent("burnable")
    inst.components.burnable.canlight = false
    inst.components.burnable.fxprefab = nil
    --inst.components.burnable:AddFXOffset(Vector3(0,1.5,-.01))

    -----------------------------------

    inst:AddComponent("fueled")

    -- inst.components.fueled:SetUpdateFn( function()
    --     if GetSeasonManager():IsRaining() then
    --         inst.components.fueled.rate = 1 + TUNING.TORCH_RAIN_RATE*GetSeasonManager():GetPrecipitationRate()
    --     else
    --         inst.components.fueled.rate = 1
    --     end
    -- end)

    MakeHauntableLaunch(inst)

    inst.components.fueled:SetSectionCallback(sectioncallback)
    inst.components.fueled:InitializeFuelLevel(TUNING.NIGHTSTICK_FUEL)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    return inst
end

return Prefab("nightstick", fn, assets, prefabs)