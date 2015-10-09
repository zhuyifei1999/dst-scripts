local mushassets =
{
    Asset("ANIM", "anim/mushrooms.zip"),
}

local cookedassets =
{
    Asset("ANIM", "anim/mushrooms.zip"),
}

local capassets =
{
    Asset("ANIM", "anim/mushrooms.zip"),
}

local function onsave(inst, data)
    data.rain = inst.rain
end

local function onload(inst, data)
    if data.rain or inst.rain then
        inst.rain = data.rain or inst.rain
    end
end

local function onpickedfn(inst)
    if inst.growtask ~= nil then
        inst.growtask:Cancel()
        inst.growtask = nil
    end
    inst.AnimState:PlayAnimation("picked")
    inst.rain = 10 + math.random(10)
end

local function makeemptyfn(inst)
    inst.AnimState:PlayAnimation("picked")
end

local function checkregrow(inst)
    if inst.components.pickable ~= nil and not inst.components.pickable.canbepicked and TheWorld.state.israining then
        inst.rain = inst.rain - 1
        if inst.rain <= 0 then
            inst.components.pickable:Regen()
        end
    end        
end

local function GetStatus(inst)
    if inst.components.pickable == nil or not inst.components.pickable.canbepicked then
        return "PICKED"
    elseif inst.components.pickable.caninteractwith then
        return "GENERIC"
    else
        return "INGROUND"
    end
end

local function open(inst)
    if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
        if inst.growtask then
            inst.growtask:Cancel()
        end
        inst.growtask = inst:DoTaskInTime(3 + math.random() * 6, inst.opentaskfn)
    end        
end

local function close(inst)
    if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
        if inst.growtask then
            inst.growtask:Cancel()
        end
        inst.growtask = inst:DoTaskInTime(3 + math.random() * 6, inst.closetaskfn)
    end
end

local function onregenfn(inst)
    if inst.data.open_time == TheWorld.state.cavephase then
        open(inst)
    end
end

local function testfortransformonload(inst)
    return TheWorld.state.isfullmoon
end

local function OnIsOpenPhase(inst, isopen)
    if isopen then
        open(inst)
    else
        close(inst)
    end
end

local function pickswitchprefab(inst)
    if inst.prefab == "red_cap" then
        if math.random() < .5 then
            return "blue_cap"
        else
            return "green_cap"
        end
    elseif inst.prefab == "blue_cap" then
        if math.random() < .5 then
            return "red_cap"
        else
            return "green_cap"
        end
    elseif inst.prefab == "green_cap" then
        if math.random() < .5 then
            return "blue_cap"
        else
            return "red_cap"
        end
    elseif inst.prefab == "red_cap_cooked" then
        if math.random() < .5 then
            return "blue_cap_cooked"
        else
            return "green_cap_cooked"
        end
    elseif inst.prefab == "blue_cap_cooked" then
        if math.random() < .5 then
            return "red_cap_cooked"
        else
            return "green_cap_cooked"
        end
    elseif inst.prefab == "green_cap_cooked" then
        if math.random() < .5 then
            return "blue_cap_cooked"
        else
            return "red_cap_cooked"
        end
    elseif inst.prefab == "red_mushroom" then
        if math.random() < .5 then
            return "blue_mushroom"
        else
            return "green_mushroom"
        end
    elseif inst.prefab == "blue_mushroom" then
        if math.random() < .5 then
            return "red_mushroom"
        else
            return "green_mushroom"
        end
    elseif inst.prefab == "green_mushroom" then
        if math.random() < .5 then
            return "blue_mushroom"
        else
            return "red_mushroom"
        end
    end
end

local function mushcommonfn(data)
    local inst = CreateEntity()

    inst.entity:AddSoundEmitter()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("mushrooms")
    inst.AnimState:SetBuild("mushrooms")
    inst.AnimState:PlayAnimation(data.animname)
    inst.AnimState:SetRayTestOnBB(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.data = data

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst.opentaskfn = function()
        inst.AnimState:PlayAnimation("open_inground")
        inst.AnimState:PushAnimation("open_"..data.animname)
        inst.AnimState:PushAnimation(data.animname)
        inst.SoundEmitter:PlaySound("dontstarve/common/mushroom_up")
        inst.growtask = nil
        if inst.components.pickable ~= nil then
            inst.components.pickable.caninteractwith = true
        end
    end

    inst.closetaskfn = function()
        inst.AnimState:PlayAnimation("close_"..data.animname)
        inst.AnimState:PushAnimation("inground")
        inst:DoTaskInTime(.25, function() inst.SoundEmitter:PlaySound("dontstarve/common/mushroom_down") end )
        inst.growtask = nil
        if inst.components.pickable then
            inst.components.pickable.caninteractwith = false
        end
    end

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_plants"
    inst.components.pickable:SetUp(data.pickloot, nil)
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable:SetMakeEmptyFn(makeemptyfn)
    --inst.components.pickable.quickpick = true

    inst.rain = 0

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(function(inst, chopper)
        if inst.components.pickable ~= nil and inst.components.pickable:CanBePicked() then
            inst.components.lootdropper:SpawnLootPrefab(data.pickloot)
        end

        inst.components.lootdropper:SpawnLootPrefab(data.pickloot)
        inst:Remove()
    end)
    inst.components.workable:SetWorkLeft(1)

    --inst:AddComponent("transformer")
    --inst.components.transformer:SetTransformWorldEvent("isfullmoon", true)
    --inst.components.transformer:SetRevertWorldEvent("isfullmoon", false)
    --inst.components.transformer:SetOnLoadCheck(testfortransformonload)
    --inst.components.transformer.transformPrefab = data.transform_prefab

    MakeSmallBurnable(inst)
    MakeSmallPropagator(inst)
    MakeNoGrowInWinter(inst)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetOnHauntFn(function(inst, haunter)
        local ret = false
        if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
            local fx = SpawnPrefab("small_puff")
            if fx then fx.Transform:SetPosition(inst.Transform:GetWorldPosition()) end
            local prefab = pickswitchprefab(inst)
            local new = nil
            if prefab then new = SpawnPrefab(prefab) end
            if new then
                new.Transform:SetPosition(inst.Transform:GetWorldPosition())
                -- Make it the right state
                if inst.components.pickable and not inst.components.pickable.canbepicked then
                    if new.components.pickable then
                        new.components.pickable:MakeEmpty()
                    end
                elseif inst.components.pickable and not inst.components.pickable.caninteractwith then
                    new.AnimState:PlayAnimation("inground")
                    if new.components.pickable then
                        new.components.pickable.caninteractwith = false
                    end
                else
                    new.AnimState:PlayAnimation(new.data.animname)
                    if new.components.pickable then
                        new.components.pickable.caninteractwith = true
                    end
                end
            end
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
            inst:DoTaskInTime(0, inst.Remove)
            ret = true
        elseif inst.components.pickable and inst.components.pickable:CanBePicked() and inst.components.pickable.caninteractwith then
            inst:closetaskfn()
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
            ret = true
        end
        --#HAUNTFIX
        --if math.random() <= TUNING.HAUNT_CHANCE_VERYRARE then
            --if inst.components.burnable and not inst.components.burnable:IsBurning() and
            --inst.components.pickable and inst.components.pickable.canbepicked then
                --inst.components.burnable:Ignite()
                --inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
                --inst.components.hauntable.cooldown_on_successful_haunt = false
                --ret = true
            --end
        --end
        return ret
    end)

    inst:WatchWorldState("iscave"..data.open_time, OnIsOpenPhase)

    inst:DoPeriodicTask(TUNING.SEG_TIME, checkregrow, TUNING.SEG_TIME + math.random()*TUNING.SEG_TIME)        

    if data.open_time == TheWorld.state.cavephase then
        inst.AnimState:PlayAnimation(data.animname)
        inst.components.pickable.caninteractwith = true
    else
        inst.AnimState:PlayAnimation("inground")
        inst.components.pickable.caninteractwith = false
    end

    return inst
end

local function capcommonfn(data)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("mushrooms")
    inst.AnimState:SetBuild("mushrooms")
    inst.AnimState:PlayAnimation(data.animname.."_cap")

    MakeDragonflyBait(inst, 3)

    --cookable (from cookable component) added to pristine state for optimization
    inst:AddTag("cookable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)
    inst:AddComponent("inventoryitem")

    --this is where it gets interesting
    inst:AddComponent("edible")
    inst.components.edible.healthvalue = data.health
    inst.components.edible.hungervalue = data.hunger
    inst.components.edible.sanityvalue = data.sanity
    inst.components.edible.foodtype = FOODTYPE.VEGGIE

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunchAndPerish(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_RARE then
            local fx = SpawnPrefab("small_puff")
            if fx then fx.Transform:SetPosition(inst.Transform:GetWorldPosition()) end
            local prefab = pickswitchprefab(inst)
            local new = nil
            if prefab then new = SpawnPrefab(prefab) end
            if new then
                new.Transform:SetPosition(inst.Transform:GetWorldPosition())
                if new.components.perishable and inst.components.perishable then
                    new.components.perishable:SetPercent(inst.components.perishable:GetPercent())
                end
                new:PushEvent("spawnedfromhaunt", {haunter=haunter, oldPrefab=inst})
            end
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
            inst:DoTaskInTime(0, inst.Remove)
            return true
        end
        return false
    end, true, false, true)
    inst:ListenForEvent("spawnedfromhaunt", function(inst, data)
        Launch(inst, data.haunter, TUNING.LAUNCH_SPEED_SMALL)
    end)

    inst:AddComponent("cookable")
    inst.components.cookable.product = data.pickloot.."_cooked"

    return inst
end

local function cookedcommonfn(data)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("mushrooms")
    inst.AnimState:SetBuild("mushrooms")
    inst.AnimState:PlayAnimation(data.pickloot.."_cooked")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.TINY_FUEL
    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)
    inst:AddComponent("inventoryitem")

    MakeHauntableLaunchAndPerish(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_RARE then
            local fx = SpawnPrefab("small_puff")
            if fx then fx.Transform:SetPosition(inst.Transform:GetWorldPosition()) end
            local prefab = pickswitchprefab(inst)
            local new = nil
            if prefab then new = SpawnPrefab(prefab) end
            if new then
                new.Transform:SetPosition(inst.Transform:GetWorldPosition())
                if new.components.perishable and inst.components.perishable then
                    new.components.perishable:SetPercent(inst.components.perishable:GetPercent())
                end
                new:PushEvent("spawnedfromhaunt", {haunter=haunter, oldPrefab=inst})
            end
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
            inst:DoTaskInTime(0, inst.Remove)
            return true
        end
        return false
    end, true, false, true)
    inst:ListenForEvent("spawnedfromhaunt", function(inst, data)
        Launch(inst, data.haunter, TUNING.LAUNCH_SPEED_SMALL)
    end)

    --this is where it gets interesting
    inst:AddComponent("edible")
    inst.components.edible.healthvalue = data.cookedhealth
    inst.components.edible.hungervalue = data.cookedhunger
    inst.components.edible.sanityvalue = data.cookedsanity
    inst.components.edible.foodtype = FOODTYPE.VEGGIE

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    return inst
end

local function MakeMushroom(data)

    local prefabs =
    {
        data.pickloot,
        data.pickloot.."_cooked",
    }

    local function mushfn()
        return mushcommonfn(data)
    end

    local function capfn()
        return capcommonfn(data)
    end

    local function cookedfn()
        return cookedcommonfn(data)
    end

    return Prefab(data.name, mushfn, mushassets, prefabs),
           Prefab(data.pickloot, capfn, capassets),
           Prefab(data.pickloot.."_cooked", cookedfn, cookedassets)
end

local data = {
    {
        name = "red_mushroom",
        animname="red",
        pickloot="red_cap",
        open_time = "day",
        sanity = 0,
        health = -TUNING.HEALING_MED,
        hunger = TUNING.CALORIES_SMALL,
        cookedsanity = -TUNING.SANITY_SMALL,
        cookedhealth = TUNING.HEALING_TINY,
        cookedhunger = 0,
        transform_prefab = "mushtree_medium",
    }, 
    {
        name = "green_mushroom",
        animname="green",
        pickloot="green_cap",
        open_time = "dusk", sanity = -TUNING.SANITY_HUGE,
        health= 0,
        hunger = TUNING.CALORIES_SMALL,
        cookedsanity = TUNING.SANITY_MED,
        cookedhealth = -TUNING.HEALING_TINY,
        cookedhunger = 0,
        transform_prefab = "mushtree_small",
    },
    {
        name = "blue_mushroom",
        animname="blue",
        pickloot="blue_cap",
        open_time = "night",    sanity = -TUNING.SANITY_MED,
        health= TUNING.HEALING_MED,
        hunger = TUNING.CALORIES_SMALL,
        cookedsanity = TUNING.SANITY_SMALL,
        cookedhealth = -TUNING.HEALING_SMALL,
        cookedhunger = 0,
        transform_prefab = "mushtree_tall",
    },
}

local prefabs = {}

for k,v in pairs(data) do
    local shroom, cap, cooked = MakeMushroom(v)
    table.insert(prefabs, shroom)
    table.insert(prefabs, cap)
    table.insert(prefabs, cooked)
end

return unpack(prefabs)
