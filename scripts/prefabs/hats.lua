local function MakeHat(name)
    local fname = "hat_"..name
    local symname = name.."hat"
    local prefabname = symname

    --If you want to use generic_perish to do more, it's still
    --commented in all the relevant places below in this file.
    --[[local function generic_perish(inst)
        inst:Remove()
    end]]

    local function onequip(inst, owner, fname_override)
        local build = fname_override or fname
        owner.AnimState:OverrideSymbol("swap_hat", build, "swap_hat")
        owner.AnimState:Show("HAT")
        owner.AnimState:Show("HAT_HAIR")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")

        if owner:HasTag("player") then
            owner.AnimState:Hide("HEAD")
            owner.AnimState:Show("HEAD_HAT")
        end
        
        if inst.components.fueled ~= nil then
            inst.components.fueled:StartConsuming()
        end
    end

    local function onunequip(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_hat")
        owner.AnimState:Hide("HAT")
        owner.AnimState:Hide("HAT_HAIR")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")

        if owner:HasTag("player") then
            owner.AnimState:Show("HEAD")
            owner.AnimState:Hide("HEAD_HAT")
        end

        if inst.components.fueled ~= nil then
            inst.components.fueled:StopConsuming()
        end
    end

    local function opentop_onequip(inst, owner)
        owner.AnimState:OverrideSymbol("swap_hat", fname, "swap_hat")
        owner.AnimState:Show("HAT")
        owner.AnimState:Hide("HAT_HAIR")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")
        
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")

        if inst.components.fueled then
            inst.components.fueled:StartConsuming()
        end
    end

    local function simple(custom_init)
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(symname)
        inst.AnimState:SetBuild(fname)
        inst.AnimState:PlayAnimation("anim")

        inst:AddTag("hat")

        if custom_init ~= nil then
            custom_init(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inventoryitem")
        inst:AddComponent("inspectable")

        inst:AddComponent("tradable")

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD

        inst.components.equippable:SetOnEquip(onequip)

        inst.components.equippable:SetOnUnequip(onunequip)

        MakeHauntableLaunch(inst)

        return inst
    end

    local function straw_custom_init(inst)
        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    local function straw()
        local inst = simple(straw_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

        inst:AddComponent("insulator")
        inst.components.insulator:SetSummer()
        inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.STRAWHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(--[[generic_perish]]inst.Remove)

        return inst
    end

    local function default()
        return simple()
    end

    local function bee_custom_init(inst)
        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    local function bee()
        local inst = simple(bee_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("armor")
        inst.components.armor:InitCondition(TUNING.ARMOR_BEEHAT, TUNING.ARMOR_BEEHAT_ABSORPTION)
        inst.components.armor:SetTags({"bee"})
        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)
        return inst
    end

    local function earmuffs_custom_init(inst)
        inst.AnimState:SetRayTestOnBB(true)
    end

    local function earmuffs()
        local inst = simple(earmuffs_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("insulator")
        inst.components.insulator:SetInsulation( TUNING.INSULATION_SMALL )
        inst.components.equippable:SetOnEquip( opentop_onequip )
        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.EARMUFF_PERISHTIME)
        inst.components.fueled:SetDepletedFn(inst.Remove)
        return inst
    end

    local function winter()
        local inst = simple()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_TINY
        inst:AddComponent("insulator")
        inst.components.insulator:SetInsulation( TUNING.INSULATION_MED )

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.WINTERHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(inst.Remove)

        return inst
    end

    local function football_custom_init(inst)
        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    local function football()
        local inst = simple(football_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("armor")
        inst.components.armor:InitCondition(TUNING.ARMOR_FOOTBALLHAT, TUNING.ARMOR_FOOTBALLHAT_ABSORPTION)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)
        return inst
    end

    local function ruinshat_proc(inst, owner)
        inst:AddTag("forcefield")
        inst.components.armor:SetAbsorption(TUNING.FULL_ABSORPTION)
        local fx = SpawnPrefab("forcefieldfx")
        fx.entity:SetParent(owner.entity)
        fx.Transform:SetPosition(0, 0.2, 0)
        local fx_hitanim = function()
            fx.AnimState:PlayAnimation("hit")
            fx.AnimState:PushAnimation("idle_loop")
        end
        fx:ListenForEvent("blocked", fx_hitanim, owner)

        inst.components.armor.ontakedamage = function(inst, damage_amount)
            if owner then
                local sanity = owner.components.sanity
                if sanity then
                    local unsaneness = damage_amount * TUNING.ARMOR_RUINSHAT_DMG_AS_SANITY
                    sanity:DoDelta(-unsaneness, false)
                end
            end
        end

        inst.active = true

        owner:DoTaskInTime(--[[Duration]] TUNING.ARMOR_RUINSHAT_DURATION, function()
            fx:RemoveEventCallback("blocked", fx_hitanim, owner)
            fx.kill_fx(fx)
            if inst:IsValid() then
                inst:RemoveTag("forcefield")
                inst.components.armor.ontakedamage = nil
                inst.components.armor:SetAbsorption(TUNING.ARMOR_RUINSHAT_ABSORPTION)
                owner:DoTaskInTime(--[[Cooldown]] TUNING.ARMOR_RUINSHAT_COOLDOWN, function() inst.active = false end)
            end
        end)
    end

    local function tryproc(inst, owner)
        if not inst.active and math.random() < --[[ Chance to proc ]] TUNING.ARMOR_RUINSHAT_PROC_CHANCE then
           ruinshat_proc(inst, owner)
        end
    end

    local function ruins_onunequip(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_hat")
        
        owner.AnimState:Hide("HAT")
        owner.AnimState:Hide("HAT_HAIR")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")

        if owner:HasTag("player") then
            owner.AnimState:Show("HEAD")
            owner.AnimState:Hide("HEAD_HAT")
        end

        owner:RemoveEventCallback("attacked", inst.procfn)

    end

    local function ruins_onequip(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_hat")

        owner.AnimState:OverrideSymbol("swap_hat", fname, "swap_hat")
        owner.AnimState:Show("HAT")
        owner.AnimState:Hide("HAT_HAIR")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")
        
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        inst.procfn = function() tryproc(inst, owner) end
        owner:ListenForEvent("attacked", inst.procfn)
    end

    local function ruins_custom_init(inst)
        inst:AddTag("metal")
    end

    local function ruins()
        local inst = simple(ruins_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("armor")
        inst.components.armor:InitCondition(TUNING.ARMOR_RUINSHAT, TUNING.ARMOR_RUINSHAT_ABSORPTION)

        inst.components.equippable:SetOnEquip(ruins_onequip)
        inst.components.equippable:SetOnUnequip(ruins_onunequip)

        return inst
    end

    local function feather_equip(inst, owner)
        onequip(inst, owner)
        local birdspawner = TheWorld.components.birdspawner
        if birdspawner ~= nil then
            birdspawner:SetSpawnTimes(TUNING.BIRD_SPAWN_DELAY_FEATHERHAT)
            birdspawner:SetMaxBirds(TUNING.BIRD_SPAWN_MAX_FEATHERHAT)
        end
    end

    local function feather_unequip(inst, owner)
        onunequip(inst, owner)
        local birdspawner = TheWorld.components.birdspawner
        if birdspawner ~= nil then
            birdspawner:SetSpawnTimes(TUNING.BIRD_SPAWN_DELAY)
            birdspawner:SetMaxBirds(TUNING.BIRD_SPAWN_MAX)
        end
    end

    local function feather()
        local inst = simple()
        
        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_SMALL
        inst.components.equippable:SetOnEquip( feather_equip )
        inst.components.equippable:SetOnUnequip( feather_unequip )
        
        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.FEATHERHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(inst.Remove)
        
        return inst
    end

    local function beefalo_equip(inst, owner)
        onequip(inst, owner)
        owner:AddTag("beefalo")
    end

    local function beefalo_unequip(inst, owner)
        onunequip(inst, owner)
        owner:RemoveTag("beefalo")
    end

    local function beefalo_custom_init(inst)
        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    local function beefalo()
        local inst = simple(beefalo_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable:SetOnEquip( beefalo_equip )
        inst.components.equippable:SetOnUnequip( beefalo_unequip )

        inst:AddComponent("insulator")
        inst.components.insulator:SetInsulation( TUNING.INSULATION_LARGE )

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)
 
        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.BEEFALOHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(inst.Remove)

        return inst
    end

    local function walrus()
        local inst = simple()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_LARGE

        inst:AddComponent("insulator")
        inst.components.insulator:SetInsulation( TUNING.INSULATION_MED )

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.WALRUSHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(inst.Remove)
        
        return inst
    end

    local function miner_turnon(inst)
        local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
        if not inst.components.fueled:IsEmpty() then
            if inst._light == nil or not inst._light:IsValid() then
                inst._light = SpawnPrefab("minerhatlight")
            end
            if owner ~= nil then
                onequip(inst, owner)
                inst._light.entity:SetParent(owner.entity)
            end
            inst.components.fueled:StartConsuming()
            inst.SoundEmitter:PlaySound("dontstarve/common/minerhatAddFuel")
        elseif owner ~= nil then
            onequip(inst, owner, "hat_miner_off")
        end
    end

    local function miner_turnoff(inst)
        if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
            if owner ~= nil then
                onequip(inst, owner, "hat_miner_off")
            end
        end
        inst.components.fueled:StopConsuming()
        inst.SoundEmitter:PlaySound("dontstarve/common/minerhatOut")
        if inst._light ~= nil then
            if inst._light:IsValid() then
                inst._light:Remove()
            end
            inst._light = nil
        end
    end

    local function miner_unequip(inst, owner)
        onunequip(inst, owner)
        miner_turnoff(inst)
    end

    local function miner_perish(inst)
        local equippable = inst.components.equippable
        if equippable ~= nil and equippable:IsEquipped() then
            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
            if owner ~= nil then
                local data =
                {
                    prefab = inst.prefab,
                    equipslot = equippable.equipslot,
                }
                miner_turnoff(inst)
                owner:PushEvent("torchranout", data)
                return
            end
        end
        miner_turnoff(inst)
    end

    local function miner_takefuel(inst)
        if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
            miner_turnon(inst)
        end
    end

    local function miner_custom_init(inst)
        inst.entity:AddSoundEmitter()
    end

    local function miner_onremove(inst)
        if inst._light ~= nil and inst._light:IsValid() then
            inst._light:Remove()
        end
    end

    local function miner()
        local inst = simple(miner_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.inventoryitem:SetOnDroppedFn(miner_turnoff)
        inst.components.equippable:SetOnEquip(miner_turnon)
        inst.components.equippable:SetOnUnequip(miner_unequip)

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.CAVE
        inst.components.fueled:InitializeFuelLevel(TUNING.MINERHAT_LIGHTTIME)
        inst.components.fueled:SetDepletedFn(miner_perish)
        inst.components.fueled.ontakefuelfn = miner_takefuel
        inst.components.fueled.accepting = true

        inst._light = nil
        inst.OnRemoveEntity = miner_onremove

        return inst
    end

    local function spider_disable(inst)
        if inst.updatetask then
            inst.updatetask:Cancel()
            inst.updatetask = nil
        end
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        if owner and owner.components.leader then
            
            if not owner:HasTag("spiderwhisperer") then --Webber has to stay a monster.
                owner:RemoveTag("monster")

                for k,v in pairs(owner.components.leader.followers) do
                    if k:HasTag("spider") and k.components.combat then
                        k.components.combat:SuggestTarget(owner)
                    end
                end
                owner.components.leader:RemoveFollowersByTag("spider")
            else
                owner.components.leader:RemoveFollowersByTag("spider", function(follower)
                    if follower and follower.components.follower then
                        if follower.components.follower:GetLoyaltyPercent() > 0 then
                            return false
                        else
                            return true
                        end
                    end
                end)
            end

        end
    end

    local function spider_update(inst)
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        if owner and owner.components.leader then
            owner.components.leader:RemoveFollowersByTag("pig")
            local x,y,z = owner.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x,y,z, TUNING.SPIDERHAT_RANGE, {"spider"})
            for k,v in pairs(ents) do
                if v.components.follower and not v.components.follower.leader and not owner.components.leader:IsFollower(v) and owner.components.leader.numfollowers < 10 then
                    owner.components.leader:AddFollower(v)
                end
            end
        end
    end

    local function spider_enable(inst)
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        if owner and owner.components.leader then
            owner.components.leader:RemoveFollowersByTag("pig")
            owner:AddTag("monster")
        end
        inst.updatetask = inst:DoPeriodicTask(0.5, spider_update, 1)
    end

    local function spider_equip(inst, owner)
        onequip(inst, owner)
        spider_enable(inst)
    end

    local function spider_unequip(inst, owner)
        onunequip(inst, owner)
        spider_disable(inst)
    end

    local function spider_perish(inst)
        spider_disable(inst)
        inst:Remove()--generic_perish(inst)
    end

    local function spider_custom_init(inst)
        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    local function spider()
        local inst = simple(spider_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.inventoryitem:SetOnDroppedFn(spider_disable)

        inst.components.equippable.dapperness = -TUNING.DAPPERNESS_SMALL
        inst.components.equippable:SetOnEquip(spider_equip)
        inst.components.equippable:SetOnUnequip(spider_unequip)

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.SPIDERHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(spider_perish)
        inst.components.fueled.no_sewing = true

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

        return inst
    end

    local function top_custom_init(inst)
        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    local function top()
        local inst = simple(top_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.TOPHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(--[[generic_perish]]inst.Remove)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

        return inst
    end

    local function stopusingbush(inst, data)
        local hat = inst.components.inventory ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
        if hat ~= nil and data.statename ~= "hide" then
            hat.components.useableitem:StopUsingItem()
        end
    end

    local function onequipbush(inst, owner)
        owner.AnimState:OverrideSymbol("swap_hat", fname, "swap_hat")
        owner.AnimState:Show("HAT")
        owner.AnimState:Show("HAT_HAIR")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")
        
        if owner:HasTag("player") then
            owner.AnimState:Hide("HEAD")
            owner.AnimState:Show("HEAD_HAT")
        end
        
        if inst.components.fueled then
            inst.components.fueled:StartConsuming()
        end

        inst:ListenForEvent("newstate", stopusingbush, owner)
    end

    local function onunequipbush(inst, owner)
        owner.AnimState:ClearOverrideSymbol("swap_hat")

        owner.AnimState:Hide("HAT")
        owner.AnimState:Hide("HAT_HAIR")
        owner.AnimState:Show("HAIR_NOHAT")
        owner.AnimState:Show("HAIR")

        if owner:HasTag("player") then
            owner.AnimState:Show("HEAD")
            owner.AnimState:Hide("HEAD_HAT")
        end

        if inst.components.fueled then
            inst.components.fueled:StopConsuming()        
        end

        inst:RemoveEventCallback("newstate", stopusingbush, owner)
    end

    local function onusebush(inst)
        local owner = inst.components.inventoryitem.owner
        if owner then
            owner.sg:GoToState("hide")
        end
    end

    local function bush_custom_init(inst)
        inst:AddTag("hide")
    end

    local function bush()
        local inst = simple(bush_custom_init)

        inst.foleysound = "dontstarve/movement/foley/bushhat"

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("useableitem")
        inst.components.useableitem:SetOnUseFn(onusebush)

        inst.components.equippable:SetOnEquip( onequipbush )
        inst.components.equippable:SetOnUnequip( onunequipbush )

        return inst
    end

    local function flower_custom_init(inst)
        inst:AddTag("show_spoilage")
    end

    local function flower()
        local inst = simple(flower_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_TINY

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
        inst.components.perishable:StartPerishing()
        inst.components.perishable:SetOnPerishFn(inst.Remove)
        inst.components.equippable:SetOnEquip( opentop_onequip )

        MakeHauntableLaunchAndPerish(inst)

        return inst
    end

    local function slurtle_custom_init(inst)
        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    local function slurtle()
        local inst = simple(slurtle_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("armor")
        inst.components.armor:InitCondition(TUNING.ARMOR_SLURTLEHAT, TUNING.ARMOR_SLURTLEHAT_ABSORPTION)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

        return inst
    end

    local function rain_custom_init(inst)
        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    local function rain()
        local inst = simple(rain_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.RAINHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(--[[generic_perish]]inst.Remove)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_LARGE)

        inst.components.equippable.insulated = true

        return inst
    end

    local function eyebrella_onequip(inst, owner) 
        opentop_onequip(inst, owner)
        
        owner.DynamicShadow:SetSize(2.2, 1.4)
    end

    local function eyebrella_onunequip(inst, owner) 
        onunequip(inst, owner)

        owner.DynamicShadow:SetSize(1.3, 0.6)
    end
    
    local function eyebrella_perish(inst)
        local equippable = inst.components.equippable
        if equippable ~= nil and equippable:IsEquipped() then
            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
            if owner ~= nil then
                owner.DynamicShadow:SetSize(1.3, 0.6)
                local data =
                {
                    prefab = inst.prefab,
                    equipslot = equippable.equipslot,
                }
                inst:Remove()--generic_perish(inst)
                owner:PushEvent("umbrellaranout", data)
                return
            end
        end
        inst:Remove()--generic_perish(inst)
    end

    local function eyebrella_custom_init(inst)
        inst:AddTag("umbrella")

        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    local function eyebrella()
        local inst = simple(eyebrella_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.EYEBRELLA_PERISHTIME)
        inst.components.fueled:SetDepletedFn(eyebrella_perish)

        inst.components.equippable:SetOnEquip(eyebrella_onequip)
        inst.components.equippable:SetOnUnequip(eyebrella_onunequip)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_ABSOLUTE)

        inst:AddComponent("insulator")
        inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)
        inst.components.insulator:SetSummer()

        inst.components.equippable.insulated = true

        return inst
    end

    local function wathgrithr_custom_init(inst)
        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    local function wathgrithr()
        local inst = simple(wathgrithr_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("armor")
        inst.components.armor:InitCondition(TUNING.ARMOR_WATHGRITHRHAT, TUNING.ARMOR_WATHGRITHRHAT_ABSORPTION)

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

        return inst
    end

    local function ice_custom_init(inst)
        inst:AddTag("show_spoilage")
        inst:AddTag("frozen")
        inst:AddTag("icebox_valid")

        --HASHEATER (from heater component) added to pristine state for optimization
        inst:AddTag("HASHEATER")

        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    local function ice()
        local inst = simple(ice_custom_init)
        
        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("heater")
        inst.components.heater:SetThermics(false, true)
        inst.components.heater.equippedheat = TUNING.ICEHAT_COOLER

        inst.components.equippable.walkspeedmult = 0.9
        inst.components.equippable.equippedmoisture = 1
        inst.components.equippable.maxequippedmoisture = 49 -- Meter reading rounds up, so set 1 below

        inst:AddComponent("insulator")
        inst.components.insulator:SetInsulation(TUNING.INSULATION_LARGE)
        inst.components.insulator:SetSummer()

        inst:AddComponent("waterproofer")
        inst.components.waterproofer.effectiveness = 0

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.PERISH_FASTISH)
        inst.components.perishable:StartPerishing()
        inst.components.perishable:SetOnPerishFn(function(inst)
            local owner = inst.components.inventoryitem.owner
            if owner ~= nil then
                if owner.components.moisture ~= nil then
                    owner.components.moisture:DoDelta(30)
                elseif owner.components.inventoryitem ~= nil then
                    owner.components.inventoryitem:AddMoisture(50)
                end
            end
            inst:Remove()--generic_perish(inst)
        end)

        inst:AddComponent("repairable")
        inst.components.repairable.repairmaterial = MATERIALS.ICE
        inst.components.repairable.announcecanfix = false

        return inst
    end

    local function catcoon()
        local inst = simple()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.USAGE
        inst.components.fueled:InitializeFuelLevel(TUNING.CATCOONHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(--[[generic_perish]]inst.Remove)

        inst.components.equippable.dapperness = TUNING.DAPPERNESS_MED

        inst:AddComponent("insulator")
        inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

        return inst
    end

    local function watermelon_custom_init(inst)
        inst:AddTag("icebox_valid")

        --HASHEATER (from heater component) added to pristine state for optimization
        inst:AddTag("HASHEATER")

        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")
    end

    local function watermelon()
        local inst = simple(watermelon_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("heater")
        inst.components.heater:SetThermics(false, true)
        inst.components.heater.equippedheat = TUNING.WATERMELON_COOLER

        inst.components.equippable.equippedmoisture = 0.5
        inst.components.equippable.maxequippedmoisture = 32 -- Meter reading rounds up, so set 1 below

        inst:AddComponent("insulator")
        inst.components.insulator:SetInsulation(TUNING.INSULATION_MED)
        inst.components.insulator:SetSummer()

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERFAST)
        inst.components.perishable:StartPerishing()
        inst.components.perishable:SetOnPerishFn(--[[generic_perish]]inst.Remove)
        inst:AddTag("show_spoilage")

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

        inst.components.equippable.dapperness = -TUNING.DAPPERNESS_SMALL

        return inst
    end

    local function mole_turnon(owner)
        owner.SoundEmitter:PlaySound("dontstarve_DLC001/common/moggles_on")
    end

    local function mole_turnoff(owner)
        owner.SoundEmitter:PlaySound("dontstarve_DLC001/common/moggles_off")
    end
     
    local function mole_onequip(inst, owner)
        onequip(inst, owner)
        mole_turnon(owner)
    end

    local function mole_onunequip(inst, owner)
        onunequip(inst, owner)
        mole_turnoff(owner)
    end

    local function mole_perish(inst)
        if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
            local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
            if owner ~= nil then
                mole_turnoff(owner)
            end
        end
        inst:Remove()--generic_perish(inst)
    end

    local function mole_custom_init(inst)
        inst:AddTag("nightvision")
    end

    local function mole()
        local inst = simple(mole_custom_init)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.components.equippable:SetOnEquip(mole_onequip)
        inst.components.equippable:SetOnUnequip(mole_onunequip)

        inst:AddComponent("fueled")
        inst.components.fueled.fueltype = FUELTYPE.WORMLIGHT
        inst.components.fueled:InitializeFuelLevel(TUNING.MOLEHAT_PERISHTIME)
        inst.components.fueled:SetDepletedFn(mole_perish)
        inst.components.fueled.accepting = true

        return inst
    end

    local fn = nil
    local assets = { Asset("ANIM", "anim/"..fname..".zip") }
    local prefabs = nil

    if name == "bee" then
        fn = bee
    elseif name == "straw" then
        fn = straw
    elseif name == "top" then
        fn = top
    elseif name == "feather" then
        fn = feather
    elseif name == "football" then
        fn = football
    elseif name == "flower" then
        fn = flower
    elseif name == "spider" then
        fn = spider
    elseif name == "miner" then
        fn = miner
        table.insert(assets, Asset("ANIM", "anim/hat_miner_off.zip"))
        prefabs = { "minerhatlight" }
    elseif name == "earmuffs" then
        fn = earmuffs
    elseif name == "winter" then
        fn = winter
    elseif name == "beefalo" then
        fn = beefalo
    elseif name == "bush" then
        fn = bush
    elseif name == "walrus" then
        fn = walrus
    elseif name == "slurtle" then
        fn = slurtle
    elseif name == "ruins" then
        fn = ruins
        prefabs = { "forcefieldfx" }
    elseif name == "mole" then
        fn = mole
    elseif name == "wathgrithr" then
        fn = wathgrithr
    elseif name == "ice" then
        fn = ice
    elseif name == "rain" then
        fn = rain
    elseif name == "catcoon" then
        fn = catcoon
    elseif name == "watermelon" then
        fn = watermelon
    elseif name == "eyebrella" then 
        fn = eyebrella
    end

    return Prefab("common/inventory/"..prefabname, fn or default, assets, prefabs)
end

local function minerhatlightfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.Light:SetFalloff(0.4)
    inst.Light:SetIntensity(.7)
    inst.Light:SetRadius(2.5)
    inst.Light:SetColour(180 / 255, 195 / 255, 150 / 255)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return  MakeHat("straw"),
        MakeHat("top"),
        MakeHat("beefalo"),
        MakeHat("feather"),
        MakeHat("bee"),
        MakeHat("miner"),
        MakeHat("spider"),
        MakeHat("football"),
        MakeHat("earmuffs"),
        MakeHat("winter"),
        MakeHat("bush"),
        MakeHat("flower"),
        MakeHat("walrus"),
        MakeHat("slurtle"),
        MakeHat("ruins"),
        MakeHat("mole"),
        MakeHat("wathgrithr"),
        MakeHat("ice"),
        MakeHat("rain"),
        MakeHat("catcoon"),
        MakeHat("watermelon"),
        MakeHat("eyebrella"),
        Prefab("common/inventory/minerhatlight", minerhatlightfn)
