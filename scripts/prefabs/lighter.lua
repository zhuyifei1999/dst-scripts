local assets =
{
    Asset("ANIM", "anim/lighter.zip"),
    Asset("ANIM", "anim/swap_lighter.zip"),
    --Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "lighterfire",
}

local function onequipfueldelta(inst)
    if inst.components.fueled.currentfuel < inst.components.fueled.maxfuel then
        inst.components.fueled:DoDelta(-inst.components.fueled.maxfuel*.01)
    end
end

local function onequip(inst, owner)
    --owner.components.combat.damage = TUNING.PICK_DAMAGE 
    inst.components.burnable:Ignite()
    owner.AnimState:OverrideSymbol("swap_object", "swap_lighter", "swap_lighter")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal") 

    inst.SoundEmitter:PlaySound("dontstarve/wilson/lighter_LP", "torch")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/lighter_on")
    inst.SoundEmitter:SetParameter("torch", "intensity", 1)

    if inst.fire == nil then
        inst.fire = SpawnPrefab("lighterfire")
        --inst.fire.Transform:SetScale(.125, .125, .125)
        local follower = inst.fire.entity:AddFollower()
        follower:FollowSymbol(owner.GUID, "swap_object", 40, -40, 0)
    end

    inst:DoTaskInTime(0, onequipfueldelta)
end

local function onunequip(inst,owner)
    if inst.fire ~= nil then
        inst.fire:Remove()
        inst.fire = nil
    end

    inst.components.burnable:Extinguish()
    owner.components.combat.damage = owner.components.combat.defaultdamage 
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal")
    inst.SoundEmitter:KillSound("torch")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/lighter_off")        
end

local function onpocket(inst, owner)
    inst.components.burnable:Extinguish()
end

local function onattack(weapon, attacker, target)
    if target ~= nil and target.components.burnable ~= nil and math.random() < TUNING.LIGHTER_ATTACK_IGNITE_PERCENT * target.components.burnable.flammability then
        target.components.burnable:Ignite(nil, attacker)
    end
end

local function onupdatefueled(inst)
    if TheWorld.state.israining then
        inst.components.fueled.rate = 1 + TUNING.LIGHTER_RAIN_RATE * TheWorld.state.precipitationrate
    else
        inst.components.fueled.rate = 1
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

    inst.AnimState:SetBank("lighter")
    inst.AnimState:SetBuild("lighter")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("irreplaceable")

    inst.MiniMapEntity:SetIcon("lighter.png")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()
 
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.LIGHTER_DAMAGE)
    inst.components.weapon:SetAttackCallback(onattack)

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
    
    inst:AddComponent("inspectable")

    -----------------------------------

    inst:AddComponent("heater")
    inst.components.heater.equippedheat = 5

    -----------------------------------

    inst:AddComponent("burnable")
    inst.components.burnable.canlight = false
    inst.components.burnable.fxprefab = nil
    --inst.components.burnable:AddFXOffset(Vector3(0, 1.5, -.01))

    inst:AddComponent("fueled")

    inst.components.fueled:SetUpdateFn(onupdatefueled)
    inst.components.fueled:SetSectionCallback(
        function(section)
            if section == 0 then
                --when we burn out
                if inst.components.burnable then
                    inst.components.burnable:Extinguish()
                end
                
                if inst.components.inventoryitem and inst.components.inventoryitem:IsHeld() then
                    local owner = inst.components.inventoryitem.owner
                    inst:Remove()
                    
                    if owner then
                        owner:PushEvent("torchranout", {torch = inst})
                    end
                end
                
            end
        end)

    inst.components.fueled:InitializeFuelLevel(TUNING.LIGHTER_FUEL)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_RARE then
            local x,y,z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x,y,z, 5, {"canlight"}, {"fire", "burnt"})
            for i,v in pairs(ents) do --#srosen should port over the d-fly's firewave fx and use those here
                if v and v.components.burnable then
                    v.components.burnable:Ignite()
                end
            end
            if #ents > 0 then
                inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            end
            return true
        end
        return false
    end, true, false, true)


    inst:AddComponent("characterspecific")
    inst.components.characterspecific:SetOwner("willow")

    return inst
end

return Prefab("common/lighter", fn, assets, prefabs)