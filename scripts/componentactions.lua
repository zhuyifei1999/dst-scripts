local COMPONENT_ACTIONS =
{
    SCENE = --args: inst, doer, actions, right
    {
        activatable = function(inst, doer, actions)
            if inst:HasTag("inactive") then
                table.insert(actions, ACTIONS.ACTIVATE)
            end
        end,

        book = function(inst, doer, actions)
            if doer:HasTag("reader") then
                table.insert(actions, ACTIONS.READ)
            end
        end,

        burnable = function(inst, doer, actions)
            if inst:HasTag("smolder") then
                table.insert(actions, ACTIONS.SMOTHER)
            end
        end,

        catcher = function(inst, doer, actions)
            if inst:HasTag("cancatch") then
                table.insert(actions, ACTIONS.CATCH)
            end
        end,

        combat = function(inst, doer, actions, right)
            if not right and
                doer:CanDoAction(ACTIONS.ATTACK) and
                inst.replica.health ~= nil and not inst.replica.health:IsDead() and
                inst.replica.combat ~= nil and inst.replica.combat:CanBeAttacked(doer) then
                table.insert(actions, ACTIONS.ATTACK)
            end
        end,

        container = function(inst, doer, actions)
            if not inst:HasTag("burnt") and
                inst.replica.container:CanBeOpened() and
                doer.replica.inventory ~= nil and
                not (doer.replica.rider ~= nil and
                    doer.replica.rider:IsRiding()) then
                table.insert(actions, ACTIONS.RUMMAGE)
            end
        end,

        crop = function(inst, doer, actions)
            if (inst:HasTag("readyforharvest") or inst:HasTag("withered")) and doer.replica.inventory ~= nil then
                table.insert(actions, ACTIONS.HARVEST)
            end
        end,

        dryer = function(inst, doer, actions)
            if inst:HasTag("dried") and not inst:HasTag("burnt") then 
                table.insert(actions, ACTIONS.HARVEST)
            end
        end,

        harvestable = function(inst, doer, actions)
            if inst:HasTag("harvestable") then
                table.insert(actions, ACTIONS.HARVEST)
            end
        end,

        hauntable = function(inst, doer, actions)
            if not (inst:HasTag("haunted") or inst:HasTag("catchable")) then
                table.insert(actions, ACTIONS.HAUNT)
            end
        end,

        inspectable = function(inst, doer, actions)
            if inst ~= doer and
                (doer.CanExamine == nil or doer:CanExamine()) and
                (doer.sg == nil or (doer.sg:HasStateTag("idle") and not doer.sg:HasStateTag("moving"))) and
                doer:HasTag("idle") and not doer:HasTag("moving") then
                --Check state graph as well in case there is movement prediction
                table.insert(actions, ACTIONS.LOOKAT)
            end
        end,

        inventoryitem = function(inst, doer, actions)
            if inst.replica.inventoryitem:CanBePickedUp() and doer.replica.inventory ~= nil and 
                not (inst:HasTag("catchable") or inst:HasTag("fire")) then
                table.insert(actions, ACTIONS.PICKUP)
            end
        end,

        lock = function(inst, doer, actions)
            if inst:HasTag("unlockable") then
                table.insert(actions, ACTIONS.UNLOCK)
            end
        end,

        machine = function(inst, doer, actions, right)
            if right and not inst:HasTag("cooldown") and
                not inst:HasTag("fueldepleted") and
                not (inst.replica.equippable ~= nil and
                    not inst.replica.equippable:IsEquipped() and
                    inst.replica.inventoryitem ~= nil and
                    inst.replica.inventoryitem:IsHeld()) and
                not inst:HasTag("alwayson") and
                not inst:HasTag("emergency") then
                table.insert(actions, inst:HasTag("turnedon") and ACTIONS.TURNOFF or ACTIONS.TURNON)
            end
        end,

        mine = function(inst, doer, actions, right)
            if right and inst:HasTag("minesprung") then
                table.insert(actions, ACTIONS.RESETMINE)
            end
        end,

        occupiable = function(inst, doer, actions)
            if inst:HasTag("occupied") then
                table.insert(actions, ACTIONS.HARVEST)
            end
        end,

        pinnable = function(inst, doer, actions)
            if not doer:HasTag("pinned") and inst:HasTag("pinned") and inst ~= doer then
                table.insert(actions, ACTIONS.UNPIN)
            end
        end,

        pickable = function(inst, doer, actions)
            if inst:HasTag("pickable") and not inst:HasTag("fire") then
                table.insert(actions, ACTIONS.PICK)
            end
        end,

        projectile = function(inst, doer, actions)
            if inst:HasTag("catchable") and doer:HasTag("cancatch") then
                table.insert(actions, ACTIONS.CATCH)
            end
        end,

        rideable = function(inst, doer, actions, right)
            if right and inst:HasTag("rideable") then
                local rider = doer.replica.rider
                if rider ~= nil and not rider:IsRiding() then
                    table.insert(actions, ACTIONS.MOUNT)
                end
            end
        end,

        rider = function(inst, doer, actions)
            if inst == doer and inst.replica.rider:IsRiding() then
                table.insert(actions, ACTIONS.DISMOUNT)
            end
        end,

        shelf = function(inst, doer, actions)
            if inst:HasTag("takeshelfitem") then
                table.insert(actions, ACTIONS.TAKEITEM)
            end
        end,

        --[[
        shop = function()
            table.insert(actions, ACTIONS.OPEN_SHOP)
        end,
        --]]


        sleepingbag = function(inst, doer, actions)
        	if doer:HasTag("player") and not doer:HasTag("insomniac") and not inst:HasTag("hassleeper") then
                table.insert(actions, ACTIONS.SLEEPIN)
            end
        end,

        stewer = function(inst, doer, actions, right)
            if not inst:HasTag("burnt") then
                if inst:HasTag("donecooking") then
                    table.insert(actions, ACTIONS.HARVEST)
                elseif right and
                    (inst:HasTag("readytocook")
                    or (inst.replica.container ~= nil and
                        inst.replica.container:IsFull() and
                        inst.replica.container:IsOpenedBy(doer))) then
                    table.insert(actions, ACTIONS.COOK)
                end
            end
        end,

        talkable = function(inst, doer, actions)
            if inst:HasTag("maxwellnottalking") then
                table.insert(actions, ACTIONS.TALKTO)
            end
        end,

        teleporter = function(inst, doer, actions)
            if inst:HasTag("teleporter") then
                table.insert(actions, ACTIONS.JUMPIN)
            end
        end,

        trap = function(inst, doer, actions)
            if inst:HasTag("trapsprung") then
                table.insert(actions, ACTIONS.CHECKTRAP)
            end 
        end,

        worldmigrator = function(inst, doer, actions)
            if inst:HasTag("migrator") then
                table.insert(actions, ACTIONS.MIGRATE)
            end
        end,

        wardrobe = function(inst, doer, actions)
            if inst:HasTag("wardrobe") and not inst:HasTag("fire") then
                table.insert(actions, ACTIONS.CHANGEIN)
            end
        end,

        writeable = function(inst, doer, actions)
            if inst:HasTag("writeable") then
                table.insert(actions, ACTIONS.WRITE)
            end
        end,

        attunable = function(inst, doer, actions)
            if doer.components.attuner ~= nil and --V2C: this is on clients too
                not doer.components.attuner:IsAttunedTo(inst) then
                table.insert(actions, ACTIONS.ATTUNE)
            end
        end,
    },

    USEITEM = --args: inst, doer, target, actions, right
    {
        bait = function(inst, doer, target, actions)
            if target:HasTag("canbait") then
                table.insert(actions, ACTIONS.BAIT)
            end
        end,

        cookable = function(inst, doer, target, actions)
            if target:HasTag("cooker") and
                not target:HasTag("fueldepleted") and
                (not target:HasTag("dangerouscooker") or doer:HasTag("expertchef")) then
                table.insert(actions, ACTIONS.COOK)
            end
        end,

        cooker = function(inst, doer, target, actions)
            if (not inst:HasTag("dangerouscooker") or doer:HasTag("expertchef")) and
                target:HasTag("cookable") and
                not (inst:HasTag("fueldepleted") or
                    target:HasTag("fire") or
                    target:HasTag("catchable")) then
                local inventoryitem = target.replica.inventoryitem
                if inventoryitem == nil or inventoryitem:IsHeld() or inventoryitem:CanBePickedUp() then
                    table.insert(actions, ACTIONS.COOK)
                end
            end
        end,

        dryable = function(inst, doer, target, actions)
            if not target:HasTag("burnt") then 
                if target:HasTag("candry") and inst:HasTag("dryable") then
                    table.insert(actions, ACTIONS.DRY)
                end
            end
        end,

        edible = function(inst, doer, target, actions, right)
            if right and not (target.replica.rider ~= nil and target.replica.rider:IsRiding()) then
                for k, v in pairs(FOODGROUP) do
                    if target:HasTag(v.name.."_eater") then
                        for i, v2 in ipairs(v.types) do
                            if inst:HasTag("edible_"..v2) then
                                if target:HasTag("player") and (TheNet:GetPVPEnabled() or not (inst:HasTag("badfood") or inst:HasTag("spoiled"))) then
                                    table.insert(actions, ACTIONS.FEEDPLAYER)
                                elseif target:HasTag("small_livestock") then
                                    table.insert(actions, ACTIONS.FEED)
                                end
                                return
                            end
                        end
                    end
                end
                for k, v in pairs(FOODTYPE) do
                    if inst:HasTag("edible_"..v) and target:HasTag(v.."_eater") then
                        if target:HasTag("player") and (TheNet:GetPVPEnabled() or not (inst:HasTag("badfood") or inst:HasTag("spoiled"))) then
                            table.insert(actions, ACTIONS.FEEDPLAYER)
                        elseif target:HasTag("small_livestock") then
                            table.insert(actions, ACTIONS.FEED)
                        end
                        return
                    end
                end
            end
        end,

        fan = function(inst, doer, target, actions)
            table.insert(actions, ACTIONS.FAN)
        end,

        fertilizer = function(inst, doer, target, actions)
            if --[[crop]] (target:HasTag("notreadyforharvest") and not target:HasTag("withered")) or
                --[[grower]] target:HasTag("fertile") or target:HasTag("infertile") or
                --[[pickable]] target:HasTag("barren") then
                table.insert(actions, ACTIONS.FERTILIZE)
            end
        end,

        fillable = function(inst, doer, target, actions)
            if target:HasTag("watersource") then
                table.insert(actions, ACTIONS.FILL)
            end
        end,

        fishingrod = function(inst, doer, target, actions)
            if target:HasTag("fishable") and not inst.replica.fishingrod:HasCaughtFish() then
                if target ~= inst.replica.fishingrod:GetTarget() then
                    table.insert(actions, ACTIONS.FISH)
                elseif doer.sg == nil or doer.sg:HasStateTag("fishing") then
                    table.insert(actions, ACTIONS.REEL)
                end
            end
        end,

        fuel = function(inst, doer, target, actions)
            for k, v in pairs(FUELTYPE) do
                if inst:HasTag(v.."_fuel") then
                    if target:HasTag(v.."_fueled") then
                        if inst:GetIsWet() then
                            table.insert(actions, ACTIONS.ADDWETFUEL)
                        else
                            table.insert(actions, ACTIONS.ADDFUEL)
                        end
                    end
                    return
                end
            end
        end,

        healer = function(inst, doer, target, actions)
            if target.replica.health ~= nil and target.replica.health:CanHeal() then
                table.insert(actions, ACTIONS.HEAL)
            end
        end,

        maxhealer = function(inst, doer, target, actions)
            if target.replica.health ~= nil and target.replica.health:CanHeal() then
                table.insert(actions, ACTIONS.HEAL)
            end
        end,

        inventoryitem = function(inst, doer, target, actions, right)
            if target.replica.container ~= nil and
                target.replica.container:CanBeOpened() and
                inst.replica.inventoryitem:IsGrandOwner(doer) then
                table.insert(actions, ACTIONS.STORE)
            elseif target:HasTag("playerghost") then
                if inst.prefab == "reviver" then
                    table.insert(actions, ACTIONS.GIVETOPLAYER)
                end
            elseif target:HasTag("player") then
                if not (target.replica.rider ~= nil and
                        target.replica.rider:IsRiding()) then
                    table.insert(actions,
                        not (doer.components.playercontroller ~= nil and
                            doer.components.playercontroller:IsControlPressed(CONTROL_FORCE_STACK)) and
                        inst.replica.stackable ~= nil and
                        inst.replica.stackable:IsStack() and
                        ACTIONS.GIVEALLTOPLAYER or
                        ACTIONS.GIVETOPLAYER)
                end
            elseif target:HasTag("alltrader") then
                table.insert(actions, ACTIONS.GIVE)
            end
        end,

        key = function(inst, doer, target, actions)
            for k, v in pairs(LOCKTYPE) do
                if target:HasTag(v.."_lock") then
                    if inst:HasTag(v.."_key") then
                        table.insert(actions, ACTIONS.UNLOCK)
                    end
                    return
                end
            end
        end,

        lighter = function(inst, doer, target, actions)
            if target:HasTag("canlight") and not (target:HasTag("fueldepleted") or target:HasTag("INLIMBO")) then
                table.insert(actions, ACTIONS.LIGHT)
            end
        end,

        occupier = function(inst, doer, target, actions)
            for k, v in pairs(OCCUPANTTYPE) do
                if target:HasTag(v.."_occupiable") then
                    if inst:HasTag(v) then
                        table.insert(actions, ACTIONS.STORE)
                    end
                    return
                end
            end
        end,

        plantable = function(inst, doer, target, actions)
            if target:HasTag("fertile") or target:HasTag("fullfertile") then
                table.insert(actions, ACTIONS.PLANT)
            end
        end,

        repairer = function(inst, doer, target, actions, right)
            if right then
                for k, v in pairs(MATERIALS) do
                    if target:HasTag("repairable_"..v) then
                        if (inst:HasTag("work_"..v) and target:HasTag("workrepairable"))
                            or (inst:HasTag("health_"..v) and target.replica.health ~= nil and not target.replica.health:IsFull())
                            or (inst:HasTag("freshen_"..v) and (target:HasTag("fresh") or target:HasTag("stale") or target:HasTag("spoiled"))) then
                            table.insert(actions, ACTIONS.REPAIR)
                        end
                        return
                    end
                end
            end
        end,

        saddler = function(inst, doer, target, actions)
            if target:HasTag("saddleable") then
                table.insert(actions, ACTIONS.SADDLE)
            end
        end,

        sewing = function(inst, doer, target, actions)
            if target:HasTag("needssewing") then
                table.insert(actions, ACTIONS.SEW)
            end
        end,

        shaver = function(inst, doer, target, actions)
            if target:HasTag("bearded") and
                not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding()) then
                table.insert(actions, ACTIONS.SHAVE)
            end
        end,

        sleepingbag = function(inst, doer, target, actions)
           if doer == target and doer:HasTag("player") and not doer:HasTag("insomniac") and not inst:HasTag("hassleeper") then
                table.insert(actions, ACTIONS.SLEEPIN)
            end
        end,

        smotherer = function(inst, doer, target, actions)
            if target:HasTag("smolder") then
                table.insert(actions, ACTIONS.SMOTHER)
            elseif inst:HasTag("frozen") and target:HasTag("fire") then
                table.insert(actions, ACTIONS.MANUALEXTINGUISH)
            end
        end,

        stackable = function(inst, doer, target, actions)
            if inst.prefab == target.prefab and
                target.replica.stackable ~= nil and
                not target.replica.stackable:IsFull() and
                target.replica.inventoryitem ~= nil and
                not target.replica.inventoryitem:IsHeld() then
                table.insert(actions, ACTIONS.COMBINESTACK)
            end
        end,

        teacher = function(inst, doer, target, actions)
            if target.replica.builder ~= nil then
                table.insert(actions, ACTIONS.TEACH)
            end
        end,

        tool = function(inst, doer, target, actions, right)
            for k, v in pairs(TOOLACTIONS) do
                if inst:HasTag(k.."_tool") then
                    if target:IsActionValid(ACTIONS[k], right) then
                        table.insert(actions, ACTIONS[k])
                        return
                    end
                end
            end
        end,

        tradable = function(inst, doer, target, actions)
            if target:HasTag("trader") and not target:HasTag("player") then
                table.insert(actions, ACTIONS.GIVE)
            end
        end,

        upgrader = function(inst, doer, target, actions)
            for k,v in pairs(UPGRADETYPES) do
                if inst:HasTag(v.."_upgrader") 
                    and doer:HasTag(v.."_upgradeuser")
                    and target:HasTag(v.."_upgradeable") then
                    table.insert(actions, ACTIONS.UPGRADE)
                end
            end
        end,

        weapon = function(inst, doer, target, actions, right)
            if inst.replica.inventoryitem ~= nil and
                target.replica.container ~= nil and
                target.replica.container:CanBeOpened() then
                -- put weapons into chester, don't attack him unless forcing attack with key press
                table.insert(actions, ACTIONS.STORE)
            elseif not right and
                doer.replica.combat ~= nil and
                doer.replica.combat:CanTarget(target) and
                (inst:HasTag("projectile") or not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding())) then
                if target.replica.combat == nil then
                    -- lighting or extinguishing fires
                    table.insert(actions, ACTIONS.ATTACK)
                elseif target.replica.combat:CanBeAttacked(doer) and
                    not doer.replica.combat:IsAlly(target) and
                    not (doer:HasTag("player") and target:HasTag("player")) and
                    not (inst:HasTag("tranquilizer") and not target:HasTag("sleeper")) and
                    not (inst:HasTag("lighter") and (target:HasTag("canlight") or target:HasTag("nolight"))) then
                    table.insert(actions, ACTIONS.ATTACK)
                end
            end
        end,
    },

    POINT = --args: inst, doer, pos, actions, right
    {
        blinkstaff = function(inst, doer, pos, actions, right)
            if right and TheWorld.Map:IsAboveGroundAtPoint(pos:Get()) then
                table.insert(actions, ACTIONS.BLINK)
            end
        end,

        complexprojectile = function(inst, doer, target, actions, right)
            if right then
                table.insert(actions, ACTIONS.TOSS)
            end
        end,

        deployable = function(inst, doer, pos, actions, right)
            if right and inst.replica.inventoryitem ~= nil and inst.replica.inventoryitem:CanDeploy(pos) then
                table.insert(actions, ACTIONS.DEPLOY)
            end
        end,

        inventoryitem = function(inst, doer, pos, actions, right)
            if not right and inst.replica.inventoryitem:IsHeldBy(doer) then
                table.insert(actions, ACTIONS.DROP)
            end
        end,

        spellcaster = function(inst, doer, pos, actions, right)
            if right and inst:HasTag("castonpoint") and
                TheWorld.Map:IsAboveGroundAtPoint(pos:Get()) then
                table.insert(actions, ACTIONS.CASTSPELL)
            end
        end,

        terraformer = function(inst, doer, pos, actions, right)
            if right and TheWorld.Map:CanTerraformAtPoint(pos:Get()) then
                table.insert(actions, ACTIONS.TERRAFORM)
            end
        end,
    },

    EQUIPPED = --args: inst, doer, target, actions, right
    {
        complexprojectile = function(inst, doer, target, actions, right)
            if right then
                table.insert(actions, ACTIONS.TOSS)
            end
        end,

        fishingrod = function(inst, doer, target, actions)
            if target:HasTag("fishable") and not inst.replica.fishingrod:HasCaughtFish() then
                if target ~= inst.replica.fishingrod:GetTarget() then
                    table.insert(actions, ACTIONS.FISH)
                elseif doer.sg == nil or doer.sg:HasStateTag("fishing") then
                    table.insert(actions, ACTIONS.REEL)
                end
            end
        end,

        key = function(inst, doer, target, actions)
            for k, v in pairs(LOCKTYPE) do
                if target:HasTag(v.."_lock") then
                    if inst:HasTag(v.."_key") then
                        table.insert(actions, ACTIONS.UNLOCK)
                    end
                    return
                end
            end
        end,

        cooker = function(inst, doer, target, actions, right)
            if right and
                (not inst:HasTag("dangerouscooker") or doer:HasTag("expertchef")) and
                target:HasTag("cookable") and
                not (inst:HasTag("fueldepleted") or
                    target:HasTag("fire") or
                    target:HasTag("catchable")) then
                local inventoryitem = target.replica.inventoryitem
                if inventoryitem == nil or inventoryitem:IsHeld() or inventoryitem:CanBePickedUp() then
                    table.insert(actions, ACTIONS.COOK)
                end
            end
        end,

        lighter = function(inst, doer, target, actions, right)
            if right and target:HasTag("canlight") and not (target:HasTag("fueldepleted") or target:HasTag("INLIMBO")) then
                table.insert(actions, ACTIONS.LIGHT)
            end
        end,

        spellcaster = function(inst, doer, target, actions, right)
            if right then
                if inst:HasTag("castontargets") then
                    table.insert(actions, ACTIONS.CASTSPELL)
                else
                    local castonrecipes = inst:HasTag("castonrecipes")
                    local castonlocomotors = inst:HasTag("castonlocomotors")
                    if (castonrecipes or castonlocomotors) and
                        (not castonrecipes or AllRecipes[target.prefab] ~= nil) and
                        (not castonlocomotors or target:HasTag("locomotor")) then
                        table.insert(actions, ACTIONS.CASTSPELL)
                    end
                end
            end
        end,

        tool = function(inst, doer, target, actions, right)
            for k, v in pairs(TOOLACTIONS) do
                if inst:HasTag(k.."_tool") then
                    if target:IsActionValid(ACTIONS[k], right) then
                        if not right or ACTIONS[k].rmb or not target:HasTag("smolder") then
                            table.insert(actions, ACTIONS[k])
                            return
                        end
                    end
                end
            end
        end,

        weapon = function(inst, doer, target, actions, right)
            if not right
                and doer.replica.combat ~= nil
                and (inst:HasTag("projectile") or not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding())) then
                if doer.replica.combat:CanExtinguishTarget(target, inst) or
                    doer.replica.combat:CanLightTarget(target, inst) then
                    table.insert(actions, ACTIONS.ATTACK)
                elseif not target:HasTag("wall")
                    and target.replica.combat ~= nil
                    and doer.replica.combat:CanTarget(target)
                    and target.replica.combat:CanBeAttacked(doer)
                    and not doer.replica.combat:IsAlly(target) then
                    if target:HasTag("mole") and inst:HasTag("hammer") then
                        table.insert(actions, ACTIONS.ATTACK)
                    elseif not (doer:HasTag("player") and target:HasTag("player"))
                        and not (inst:HasTag("tranquilizer") and not target:HasTag("sleeper")) then
                        table.insert(actions, ACTIONS.ATTACK)
                    end
                end
            end
        end,
    },

    INVENTORY = --args: inst, doer, actions, right
    {
        balloonmaker = function(inst, doer, actions)
            if doer:HasTag("balloonomancer") then
                table.insert(actions, ACTIONS.MAKEBALLOON)
            end
        end,

        book = function(inst, doer, actions)
            if doer:HasTag("reader") then
                table.insert(actions, ACTIONS.READ)
            end
        end,

        container = function(inst, doer, actions)
            if not inst:HasTag("burnt") then
                local container = inst.replica.container
                if container:CanBeOpened() and
                    doer.replica.inventory ~= nil and
                    not (container:IsSideWidget() and
                        doer.components.playercontroller ~= nil and
                        doer.components.playercontroller.isclientcontrollerattached) then
                    table.insert(actions, ACTIONS.RUMMAGE)
                end
            end
        end,

        deployable = function(inst, doer, actions)
            if doer.components.playercontroller ~= nil and
                not doer.components.playercontroller.deploy_mode and
                inst.replica.inventoryitem ~= nil and
                inst.replica.inventoryitem:IsGrandOwner(doer) then
                table.insert(actions, ACTIONS.TOGGLE_DEPLOY_MODE)
            end
        end,

        edible = function(inst, doer, actions, right)
            if (right or inst.replica.equippable == nil) and
                not (doer.replica.inventory:GetActiveItem() == inst and
                    doer.replica.rider ~= nil and
                    doer.replica.rider:IsRiding()) then
                for k, v in pairs(FOODGROUP) do
                    if doer:HasTag(v.name.."_eater") then
                        for i, v2 in ipairs(v.types) do
                            if inst:HasTag("edible_"..v2) then
                                table.insert(actions, ACTIONS.EAT)
                                return
                            end
                        end
                    end
                end
                for k, v in pairs(FOODTYPE) do
                    if inst:HasTag("edible_"..v) and doer:HasTag(v.."_eater") then
                        table.insert(actions, ACTIONS.EAT)
                        return
                    end
                end
            end
        end,

        equippable = function(inst, doer, actions)
            table.insert(actions, inst.replica.equippable:IsEquipped() and ACTIONS.UNEQUIP or ACTIONS.EQUIP)
        end,

        fan = function(inst, doer, actions)
            table.insert(actions, ACTIONS.FAN)
        end,

        --[[
        fuel = function(inst, doer, target, actions)
            for k, v in pairs(FUELTYPE) do
                if inst:HasTag(v.."_fuel") then
                    if target:HasTag(v.."_fueled") then
                        table.insert(actions, ACTIONS.ADDFUEL)
                    end
                    return
                end
            end
        end,
        --]]

        healer = function(inst, doer, actions)
            if doer.replica.health ~= nil and doer.replica.health:CanHeal() then
                table.insert(actions, ACTIONS.HEAL)
            end
        end,

        maxhealer = function(inst, doer, actions)
            if doer.replica.health ~= nil and doer.replica.health:CanHeal() then
                table.insert(actions, ACTIONS.HEAL)
            end
        end,

        health = function(inst, doer, actions)
            if inst.replica.health:CanMurder() then
                table.insert(actions, ACTIONS.MURDER)
            end
        end,

        inspectable = function(inst, doer, actions)
            if inst ~= doer and (doer.CanExamine == nil or doer:CanExamine()) then
                table.insert(actions, ACTIONS.LOOKAT)
            end
        end,

        instrument = function(inst, doer, actions)
            table.insert(actions, ACTIONS.PLAY)
        end,

        --[[
        inventoryitem = function(inst, doer, actions)
            table.insert(actions, ACTIONS.DROP)
        end,
        --]]

        machine = function(inst, doer, actions, right)
            if right and not inst:HasTag("cooldown") and
                not inst:HasTag("fueldepleted") and
                not (inst.replica.equippable ~= nil and
                    not inst.replica.equippable:IsEquipped() and
                    inst.replica.inventoryitem ~= nil and
                    inst.replica.inventoryitem:IsHeld()) then
                if inst:HasTag("turnedon") then
                    table.insert(actions, ACTIONS.TURNOFF)
                else
                    table.insert(actions, ACTIONS.TURNON)
                end
            end
        end,

        shaver = function(inst, doer, actions)
            if doer:HasTag("bearded") and
                not (doer.replica.inventory:GetActiveItem() == inst and
                    doer.replica.rider ~= nil and
                    doer.replica.rider:IsRiding()) then
                --Don't show mouse active item Shave action when mounted
                --because it's confusing and looks like you're trying to
                --shave your beefalo mount.
                table.insert(actions, ACTIONS.SHAVE)
            end
        end,

        sleepingbag = function(inst, doer, actions)
            if doer:HasTag("player") and not doer:HasTag("insomniac") and not inst:HasTag("hassleeper") then
                table.insert(actions, ACTIONS.SLEEPIN)
            end
        end,

        spellcaster = function(inst, doer, actions)
            if inst:HasTag("castfrominventory") then
                table.insert(actions, ACTIONS.CASTSPELL)
            end
        end,

        talkable = function(inst, doer, actions)
            if inst:HasTag("maxwellnottalking") then
                table.insert(actions, ACTIONS.TALKTO)
            end
        end,

        teacher = function(inst, doer, actions)
            if doer.replica.builder ~= nil then
                table.insert(actions, ACTIONS.TEACH)
            end
        end,

        useableitem = function(inst, doer, actions)
            if not inst:HasTag("inuse") and
                inst.replica.equippable ~= nil and
                inst.replica.equippable:IsEquipped() and
                doer.replica.inventory ~= nil and
                doer.replica.inventory:IsOpenedBy(doer) then
                table.insert(actions, ACTIONS.USEITEM)
            end
        end,
    },

    ISVALID = --args: inst, action, right
    {
        workable = function(inst, action, right)
            return (right or action ~= ACTIONS.HAMMER) and
                inst:HasTag(action.id.."_workable")
        end,
    },
}

local ACTION_COMPONENT_NAMES = {}
local ACTION_COMPONENT_IDS = {}

local function RemapComponentActions()
    for k, v in pairs(COMPONENT_ACTIONS) do
        for cmp, fn in pairs(v) do
            if ACTION_COMPONENT_IDS[cmp] == nil then
                table.insert(ACTION_COMPONENT_NAMES, cmp)
                ACTION_COMPONENT_IDS[cmp] = #ACTION_COMPONENT_NAMES
            end
        end
    end
end
RemapComponentActions()
assert(#ACTION_COMPONENT_NAMES <= 255, "Increase actioncomponents network data size.")

local MOD_COMPONENT_ACTIONS = {}
local MOD_ACTION_COMPONENT_NAMES = {}
local MOD_ACTION_COMPONENT_IDS = {}

function AddComponentAction(actiontype, component, fn, modname)
    --ensure this mod is setup in the tables
    if MOD_COMPONENT_ACTIONS[modname] == nil then
        MOD_COMPONENT_ACTIONS[modname] = {}
        MOD_ACTION_COMPONENT_NAMES[modname] = {}
        MOD_ACTION_COMPONENT_IDS[modname] = {}
    end

    if MOD_COMPONENT_ACTIONS[modname][actiontype] == nil then
        MOD_COMPONENT_ACTIONS[modname][actiontype] = {}
    end

    MOD_COMPONENT_ACTIONS[modname][actiontype][component] = fn
    table.insert(MOD_ACTION_COMPONENT_NAMES[modname], component)
    MOD_ACTION_COMPONENT_IDS[modname][component] = #MOD_ACTION_COMPONENT_NAMES[modname]
end

function EntityScript:RegisterComponentActions(name)
    local id = ACTION_COMPONENT_IDS[name]
    if id ~= nil then
        table.insert(self.actioncomponents, id)
        if self.actionreplica ~= nil then
            self.actionreplica.actioncomponents:set(self.actioncomponents)
        end
    end

    for modname,modtable in pairs(MOD_ACTION_COMPONENT_IDS) do
        id = modtable[name]
        if id ~= nil then
            --found this component in this mod's table
            if self.modactioncomponents == nil then
                self.modactioncomponents = {}
                --print("on ", self, " adding self.modactioncomponents")
            end
            if self.modactioncomponents[modname] == nil then
                self.modactioncomponents[modname] = {}
                --print("on ", self, " adding self.modactioncomponents[",modname,"]")
            end
            --print("Adding to self.modactioncomponents[",modname,"] ",id)
            table.insert( self.modactioncomponents[modname], id )
            if self.actionreplica ~= nil then
                self.actionreplica.modactioncomponents[modname]:set(self.modactioncomponents[modname])
            end
        end
    end
end

function EntityScript:UnregisterComponentActions(name)
    local id = ACTION_COMPONENT_IDS[name]
    if id ~= nil then
        for i, v in ipairs(self.actioncomponents) do
            if v == id then
                table.remove(self.actioncomponents, i)
                if self.actionreplica ~= nil then
                    self.actionreplica.actioncomponents:set(self.actioncomponents)
                end
                return
            end
        end
    else
        for modname,modtable in pairs(MOD_ACTION_COMPONENT_IDS) do
            id = modtable[name]
            if id ~= nil then
                for i, v in ipairs(self.modactioncomponents[modname]) do
                    if v == id then
                        table.remove(self.modactioncomponents[modname], i)
                        if self.actionreplica ~= nil then
                            self.actionreplica.modactioncomponents[modname]:set(self.modactioncomponents[modname])
                        end
                        return
                    end
                end
            end
        end
    end
end

function EntityScript:CollectActions(type, ...)
    local t = COMPONENT_ACTIONS[type]
    if t ~= nil then
        for i, v in ipairs(self.actioncomponents) do
            local collector = t[ACTION_COMPONENT_NAMES[v]]
            if collector ~= nil then
                collector(self, ...)
            end
        end
        if self.modactioncomponents ~= nil then
            --print("EntityScript:CollectActions on ", self)
            for modname,modtable in pairs(self.modactioncomponents) do
                --print("modname ",modname, #modtable)
                if MOD_COMPONENT_ACTIONS[modname] == nil then
                    print( "ERROR: Mod component actions are out of sync for mod " .. (modname or "unknown") .. ". This is likely a result of your mod's calls to AddComponentAction not happening on both the server and the client." )
                    print( "self.modactioncomponents is\n" .. (dumptable(self.modactioncomponents) or "") )
                    print( "MOD_COMPONENT_ACTIONS is\n" .. (dumptable(MOD_COMPONENT_ACTIONS) or "") )
                end
                t = MOD_COMPONENT_ACTIONS[modname][type]
                if t ~= nil then
                    for i, v in ipairs(modtable) do
                        local collector = t[MOD_ACTION_COMPONENT_NAMES[modname][v]]
                        if collector ~= nil then
                            collector(self, ...)
                        end
                    end
                end
            end
        end
    else
        print("Type ",type," doesn't exist in the table of component actions. Is your component name correct in AddComponentAction?")
    end
end

function EntityScript:IsActionValid(action, right)
    if action.rmb and action.rmb ~= right then
        return false
    end
    local t = COMPONENT_ACTIONS.ISVALID
    for i, v in ipairs(self.actioncomponents) do
        local vaildator = t[ACTION_COMPONENT_NAMES[v]]
        if vaildator ~= nil and vaildator(self, action, right) then
            return true
        end
    end

    if self.modactioncomponents ~= nil then
        for modname,modtable in ipairs(self.modactioncomponents) do
            t = MOD_COMPONENT_ACTIONS[modname][type]
            for i, v in ipairs(modtable) do
                local vaildator = t[MOD_ACTION_COMPONENT_NAMES[modname][v]]
                if vaildator ~= nil and vaildator(self, action, right) then
                    return true
                end
            end
        end
    end
end

function EntityScript:HasActionComponent(name)
    local id = ACTION_COMPONENT_IDS[name]
    if id ~= nil then
        for i, v in ipairs(self.actioncomponents) do
            if v == id then
                return true
            end
        end
    else
        for modname,modtable in pairs(MOD_ACTION_COMPONENT_IDS) do
            id = modtable[name]
            if id ~= nil then
                for i, v in ipairs(self.modactioncomponents[modname]) do
                    if v == id then
                        return true
                    end
                end
            end
        end
    end
    return false
end
