local assets =
{
    Asset("ANIM", "anim/minifan.zip"),
    Asset("ANIM", "anim/swap_minifan.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "fan_wheel",
}

local function onequipfueldelta(inst)
    if inst.components.fueled.currentfuel < inst.components.fueled.maxfuel then
        inst.components.fueled:DoDelta(-inst.components.fueled.maxfuel*.01)
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_minifan", "swap_minifan")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.wheel == nil then
        inst.wheel = SpawnPrefab("fan_wheel")
        inst.wheel.Transform:SetPosition(inst:GetPosition():Get())
        inst.wheel:SetFollowTarget(owner)
    end

    inst.onlocomote = function(owner)
        if owner.components.locomotor.wantstomoveforward
            and not inst.components.fueled.consuming then
            inst.components.fueled:StartConsuming()
            inst.wheel.AnimState:PlayAnimation("spin_pre")
            inst.wheel.AnimState:PushAnimation("spin_loop",true)
            inst.wheel.SoundEmitter:PlaySound("dontstarve/common/fan_twirl_LP", "twirl")
            inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)
            inst.components.heater:SetThermics(false, true)
        elseif not owner.components.locomotor.wantstomoveforward
            and inst.components.fueled.consuming then
            inst.components.fueled:StopConsuming()
            inst.wheel.AnimState:PlayAnimation("spin_pst")
            inst.wheel.AnimState:PushAnimation("idle")
            inst.wheel.SoundEmitter:KillSound("twirl")
            inst.components.insulator:SetInsulation(0)
            inst.components.heater:SetThermics(false, false)
        end
    end

    inst:ListenForEvent("locomote", inst.onlocomote, owner)

    --take a percent of fuel next frame instead of this one, so we can remove the torch properly if it runs out at that point
    inst:DoTaskInTime(0, onequipfueldelta)
end

local function onunequip(inst, owner)
    if inst.wheel ~= nil then
        inst.wheel:SetFollowTarget(nil)
        inst.wheel = nil
    end

    if inst.components.fueled then
        inst.components.fueled:StopConsuming()
    end

    inst:RemoveEventCallback("locomote", inst.onlocomote, owner)

    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function ondepleted(inst)
    if inst.wheel ~= nil then
        inst.wheel:SetFollowTarget(nil)
        inst.wheel = nil
    end

    local owner = inst.components.inventoryitem.owner

    inst:RemoveEventCallback("locomote", inst.onlocomote, owner)

    if inst.components.inventoryitem ~= nil
        and inst.components.inventoryitem.owner ~= nil then
        local data = {
            prefab = inst.prefab,
            equipslot = inst.components.equippable.equipslot,
            announce = "ANNOUNCE_FAN_OUT",
        }
        inst.components.inventoryitem.owner:PushEvent("itemranout", data)
    end

    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("minifan")
    inst.AnimState:SetBuild("minifan")
    inst.AnimState:PlayAnimation("idle")

    --HASHEATER (from heater component) added to pristine state for optimization
    inst:AddTag("HASHEATER")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.MINIFAN_DAMAGE)

    -----------------------------------

    inst:AddComponent("inventoryitem")

    -----------------------------------

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    -----------------------------------

    inst:AddComponent("heater")
    inst.components.heater:SetThermics(false, true)
    inst.components.heater.equippedheat = TUNING.MINIFAN_COOLER

    -----------------------------------

    inst:AddComponent("insulator")
    inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)
    inst.components.insulator:SetSummer()

    -----------------------------------

    inst:AddComponent("inspectable")

    -----------------------------------

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(TUNING.MINIFAN_FUEL)
    inst.components.fueled:SetDepletedFn(ondepleted)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("minifan", fn, assets, prefabs)
