local assets =
{
    Asset("ANIM", "anim/amulets.zip"),
    Asset("ANIM", "anim/torso_amulets.zip"),
}

--[[ Each amulet has a seperate onequip and onunequip function so we can also
add and remove event listeners, or start/stop update functions here. ]]

---RED
local function healowner(inst, owner)
    if (owner.components.health and owner.components.health:IsHurt())
    and (owner.components.hunger and owner.components.hunger.current > 5 )then
        owner.components.health:DoDelta(TUNING.REDAMULET_CONVERSION,false,"redamulet")
        owner.components.hunger:DoDelta(-TUNING.REDAMULET_CONVERSION)
        inst.components.finiteuses:Use(1)
    end
end

local function onequip_red(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "torso_amulets", "redamulet")
    inst.task = inst:DoPeriodicTask(30, healowner, nil, owner)
end

local function onunequip_red(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

---BLUE
local function onequip_blue(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "torso_amulets", "blueamulet")

    inst.freezefn = function(attacked, data)
        if data and data.attacker and data.attacker.components.freezable then
            data.attacker.components.freezable:AddColdness(0.67)
            data.attacker.components.freezable:SpawnShatterFX()
            inst.components.fueled:DoDelta(-0.03 * inst.components.fueled.maxfuel)
        end 
    end

    inst:ListenForEvent("attacked", inst.freezefn, owner)

    if inst.components.fueled then
        inst.components.fueled:StartConsuming()
    end

end

local function onunequip_blue(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")

    inst:RemoveEventCallback("attacked", inst.freezefn, owner)

    if inst.components.fueled then
        inst.components.fueled:StopConsuming()
    end
end

---PURPLE
local function onequip_purple(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "torso_amulets", "purpleamulet")
    if inst.components.fueled then
        inst.components.fueled:StartConsuming()
    end
    if owner.components.sanity ~= nil then
        owner.components.sanity:SetInducedInsanity(inst, true)
    end
end

local function onunequip_purple(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    if inst.components.fueled then
        inst.components.fueled:StopConsuming()
    end
    if owner.components.sanity ~= nil then
        owner.components.sanity:SetInducedInsanity(inst, false)
    end
end

---GREEN

local function onequip_green(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "torso_amulets", "greenamulet")
    owner.components.builder.ingredientmod = TUNING.GREENAMULET_INGREDIENTMOD
    inst.onitembuild = function()
        inst.components.finiteuses:Use(1)
    end
    inst:ListenForEvent("consumeingredients", inst.onitembuild, owner)

end

local function onunequip_green(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner.components.builder.ingredientmod = 1
    inst:RemoveEventCallback("consumeingredients", inst.onitembuild, owner)
end

---ORANGE
local function pickup(inst, owner)
    if owner == nil or owner.components.inventory == nil then
        return
    end
    local x, y, z = owner.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.ORANGEAMULET_RANGE, { "_inventoryitem" }, { "INLIMBO", "catchable", "fire" })
    for i, v in ipairs(ents) do
        if v.components.inventoryitem ~= nil and
            v.components.inventoryitem.canbepickedup and
            v.components.inventoryitem.cangoincontainer and
            not v.components.inventoryitem:IsHeld() and
            owner.components.inventory:CanAcceptCount(v, 1) > 0 then

            --Amulet will only ever pick up items one at a time. Even from stacks.
            local fx = SpawnPrefab("small_puff")
            fx.Transform:SetPosition(v.Transform:GetWorldPosition())
            fx.Transform:SetScale(.5, .5, .5)

            inst.components.finiteuses:Use(1)

            if v.components.stackable ~= nil then
                v = v.components.stackable:Get()
            end

            if v.components.trap ~= nil and v.components.trap:IsSprung() then
                v.components.trap:Harvest(owner)
            else
                owner.components.inventory:GiveItem(v)
            end
            return
        end
    end
end

local function onequip_orange(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "torso_amulets", "orangeamulet")
    inst.task = inst:DoPeriodicTask(TUNING.ORANGEAMULET_ICD, pickup, nil, owner)
end

local function onunequip_orange(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

---YELLOW
local function onequip_yellow(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "torso_amulets", "yellowamulet")

    if inst.components.fueled then
        inst.components.fueled:StartConsuming()        
    end

    inst.Light:Enable(true)

    owner.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

end

local function onunequip_yellow(inst, owner)
    owner.AnimState:ClearBloomEffectHandle()
    owner.AnimState:ClearOverrideSymbol("swap_body")
    if inst.components.fueled then
        inst.components.fueled:StopConsuming()        
    end

    inst.Light:Enable(false)
end

---COMMON FUNCTIONS
--[[
local function unimplementeditem(inst)
    local player = ThePlayer
    player.components.talker:Say(GetString(player, "ANNOUNCE_UNIMPLEMENTED"))
    if player.components.health.currenthealth > 1 then
        player.components.health:DoDelta(-0.5 * player.components.health.currenthealth)
    end

    if inst.components.useableitem then
        inst.components.useableitem:StopUsingItem()
    end
end
--]]

local function commonfn(anim, tag, custom_init)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("amulets")
    inst.AnimState:SetBuild("amulets")
    inst.AnimState:PlayAnimation(anim)

    if tag ~= nil then
        inst:AddTag(tag)
    end

    inst.foleysound = "dontstarve/movement/foley/jewlery"

    if custom_init ~= nil then
        custom_init(inst)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL    

    inst:AddComponent("inventoryitem")

    return inst
end

local function red()
    local inst = commonfn("redamulet", "resurrector")

    if not TheWorld.ismastersim then
        return inst
    end

    -- red amulet now falls off on death, so you HAVE to haunt it
    -- This is more straightforward for prototype purposes, but has side effect of allowing amulet steals
    -- inst.components.inventoryitem.keepondeath = true
    
    inst.components.equippable:SetOnEquip(onequip_red)
    inst.components.equippable:SetOnUnequip(onunequip_red)
    
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetMaxUses(TUNING.REDAMULET_USES)
    inst.components.finiteuses:SetUses(TUNING.REDAMULET_USES)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)

    return inst
end

local function blue()
    local inst = commonfn("blueamulet", "HASHEATER")
    --HASHEATER (from heater component) added to pristine state for optimization

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.equippable:SetOnEquip(onequip_blue)
    inst.components.equippable:SetOnUnequip(onunequip_blue)
    inst:AddComponent("heater")
    inst.components.heater:SetThermics(false, true)
    inst.components.heater.equippedheat = TUNING.BLUEGEM_COOLER

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.MAGIC
    inst.components.fueled:InitializeFuelLevel(TUNING.BLUEAMULET_FUEL)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
            local x,y,z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x,y,z, 10, {"freezable"}, {"FX", "NOCLICK", "DECOR","INLIMBO"}) 
            for i,v in pairs(ents) do
                if v and v.components.freezable then
                    v.components.freezable:AddColdness(0.67)
                    v.components.freezable:SpawnShatterFX()
                end
            end
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        end
    end, true, nil, true)

    return inst
end

local function purple()
    local inst = commonfn("purpleamulet")

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.MAGIC
    inst.components.fueled:InitializeFuelLevel(TUNING.PURPLEAMULET_FUEL)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    inst.components.equippable:SetOnEquip(onequip_purple)
    inst.components.equippable:SetOnUnequip(onunequip_purple)

    inst.components.equippable.dapperness = -TUNING.DAPPERNESS_MED    

    MakeHauntableLaunch(inst)

    return inst
end

local function green()
    local inst = commonfn("greenamulet")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.equippable:SetOnEquip(onequip_green)
    inst.components.equippable:SetOnUnequip(onunequip_green)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetMaxUses(TUNING.GREENAMULET_USES)
    inst.components.finiteuses:SetUses(TUNING.GREENAMULET_USES)

    MakeHauntableLaunch(inst)

    return inst
end

local function orange()
    local inst = commonfn("orangeamulet")

    if not TheWorld.ismastersim then
        return inst
    end

    -- inst.components.inspectable.nameoverride = "unimplemented"
    -- inst:AddComponent("useableitem")
    -- inst.components.useableitem:SetOnUseFn(unimplementeditem)
    inst.components.equippable:SetOnEquip(onequip_orange)
    inst.components.equippable:SetOnUnequip(onunequip_orange)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetMaxUses(TUNING.ORANGEAMULET_USES)
    inst.components.finiteuses:SetUses(TUNING.ORANGEAMULET_USES)

    MakeHauntableLaunch(inst)

    return inst
end

local function DisableLight(inst)
    inst.Light:Enable(false)
end

local function InitLight(inst)
    inst.entity:AddLight()
    inst.Light:Enable(false)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.65)
    inst.Light:SetColour(223 / 255, 208 / 255, 69 / 255)
end

local function yellow()
    local inst = commonfn("yellowamulet", nil, InitLight)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.equippable:SetOnEquip(onequip_yellow)
    inst.components.equippable:SetOnUnequip(onunequip_yellow)
    inst.components.equippable.walkspeedmult = 1.2
    inst.components.inventoryitem:SetOnDroppedFn(DisableLight)

    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.MAGIC
    inst.components.fueled:InitializeFuelLevel(TUNING.YELLOWAMULET_FUEL)
    inst.components.fueled:SetDepletedFn(inst.Remove)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("common/inventory/amulet", red, assets),
Prefab("common/inventory/blueamulet", blue, assets),
Prefab("common/inventory/purpleamulet", purple, assets),
Prefab("common/inventory/orangeamulet", orange, assets),
Prefab("common/inventory/greenamulet", green, assets),
Prefab("common/inventory/yellowamulet", yellow, assets)
