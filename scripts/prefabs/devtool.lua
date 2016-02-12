local assets =
{
    Asset("ANIM", "anim/axe.zip"),
    Asset("ANIM", "anim/goldenaxe.zip"),
    Asset("ANIM", "anim/swap_axe.zip"),
    Asset("ANIM", "anim/swap_goldenaxe.zip"),
    Asset("INV_IMAGE", "goldenaxe"),
}

local function giveitems(inst, data)
    if data.owner.components.inventory and data.recipe then
        for ik, iv in pairs(data.recipe.ingredients) do
            if not data.owner.components.inventory:Has(iv.type, iv.amount) then
                for i = 1, iv.amount do
                    local item = SpawnPrefab(iv.type)
                    data.owner.components.inventory:GiveItem(item)
                end
            end
        end
    end
end

local function onequipgold(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_object", "swap_goldenaxe", "swap_goldenaxe")
    owner.SoundEmitter:PlaySound("dontstarve/wilson/equip_item_gold")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal") 
    inst.Light:Enable(true)
    inst.task = inst:DoPeriodicTask(0.25, function()
        if owner.components.health ~= nil then
            owner.components.health:DoDelta(500)
        end

        if owner.components.hunger ~= nil then
            owner.components.hunger:DoDelta(500)
        end
    end)
    owner.components.hunger:SetRate(0)
    owner:ListenForEvent("cantbuild", giveitems)
end

local function onunequip(inst, owner) 
    inst.Light:Enable(false)
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal") 

    if inst.task then
        inst.task:Cancel()
        inst.task = nil
    end
    owner.components.hunger:SetRate(TUNING.WILSON_HUNGER_RATE)
    owner:RemoveEventCallback("cantbuild", giveitems)
end

local function HeatFn(inst, observer)
    local worldTemp = TheWorld.state.temperature
    if worldTemp < 10 then
        inst.components.heater:SetThermics(true, false)
        return 50
    elseif worldTemp > 50 then
        inst.components.heater:SetThermics(false, true)
        return -50
    else
        inst.components.heater:SetThermics(false, false)
        return 0
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("axe")
    inst.AnimState:SetBuild("goldenaxe")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")

    if BRANCH == "dev" then
        --prototyper (from prototyper component) added to pristine state for optimization
        inst:AddTag("prototyper")

        --HASHEATER (from heater component) added to pristine state for optimization
        inst:AddTag("HASHEATER")

        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")

        inst.entity:AddLight()
        inst.Light:SetColour(255 / 255, 255 / 255, 192 / 255)
        inst.Light:SetIntensity(.8)
        inst.Light:SetRadius(5)
        inst.Light:SetFalloff(.33)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("goldenaxe")

    if BRANCH == "dev" then
        inst:AddComponent("weapon")
        inst.components.weapon:SetRange(20)
        inst.components.weapon:SetDamage(1500)

        inst:AddComponent("heater")
        inst.components.heater.equippedheatfn = HeatFn
        --inst.components.heater.equippedheat = math.huge

        --inst:AddComponent("blinkstaff")

        inst:AddComponent("tool")
        inst.components.tool:SetAction(ACTIONS.CHOP, 100)
        inst.components.tool:SetAction(ACTIONS.MINE, 100)
        inst.components.tool:SetAction(ACTIONS.HAMMER)
        inst.components.tool:SetAction(ACTIONS.DIG, 100)
        inst.components.tool:SetAction(ACTIONS.NET)

        inst:AddComponent("prototyper")
        -- tech level net vars limited by net_tinybyte!
        inst.components.prototyper.trees = { SCIENCE = 3, MAGIC = 3, ANCIENT = 3 }

        inst:AddComponent("equippable")
        inst.components.equippable:SetOnEquip( onequipgold )  
        inst.components.equippable:SetOnUnequip( onunequip)
        inst.components.equippable.walkspeedmult = 2
        inst.components.equippable.dapperness = math.huge

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(1)
    else
        inst.persists = false
        inst.entity:Hide()
        inst:DoTaskInTime(0, inst.Remove)
    end

    return inst
end

return Prefab("devtool", fn, assets)
