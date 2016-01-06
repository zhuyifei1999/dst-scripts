local assets =
{
    Asset("ANIM", "anim/whip.zip"),
    Asset("ANIM", "anim/swap_whip.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_whip", "swap_whip")
    owner.AnimState:OverrideSymbol("whipline", "swap_whip", "whipline")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function supercrack(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, TUNING.WHIP_SUPERCRACK_RANGE, { "_combat" }, { "player" })
    for i,v in ipairs(ents) do
        if v.components.combat:HasTarget() then
            v.components.combat:DropTarget()
            if v.sg ~= nil and v.sg:HasState("hit")
                and v.components.health ~= nil and not v.components.health:IsDead()
                and not v.sg:HasStateTag("transform")
                and not v.sg:HasStateTag("nointerrupt")
                and not v.sg:HasStateTag("frozen")
                --and not v.sg:HasStateTag("attack")
                --and not v.sg:HasStateTag("busy")
                then

                v.sg:GoToState("hit")
            end
        end
    end
end

local function onattack(inst, attacker, target)
    if target ~= nil and target:IsValid() then
        local chance =
            (target:HasTag("epic") and TUNING.WHIP_SUPERCRACK_EPIC_CHANCE) or
            (target:HasTag("monster") and TUNING.WHIP_SUPERCRACK_MONSTER_CHANCE) or
            TUNING.WHIP_SUPERCRACK_CREATURE_CHANCE

        local snap = SpawnPrefab("impact")

        local x, y, z = inst.Transform:GetWorldPosition()
        local x1, y1, z1 = target.Transform:GetWorldPosition()
        local angle = -math.atan2(z1 - z, x1 - x)
        snap.Transform:SetPosition(x1, y1, z1)
        snap.Transform:SetRotation(angle * RADIANS)

        if math.random() < chance then
            snap.Transform:SetScale(3, 3, 3)
            snap.SoundEmitter:PlaySound("dontstarve/common/whip_large")
            inst:DoTaskInTime(0, supercrack)
        end
            snap.SoundEmitter:PlaySound("dontstarve/common/whip_small")
        else
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("whip")
    inst.AnimState:SetBuild("whip")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("whip")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.WHIP_DAMAGE)
    inst.components.weapon:SetRange(TUNING.WHIP_RANGE)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.WHIP_USES)
    inst.components.finiteuses:SetUses(TUNING.WHIP_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("whip", fn, assets)
