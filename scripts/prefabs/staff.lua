local assets =
{
    Asset("ANIM", "anim/staffs.zip"),
    Asset("ANIM", "anim/swap_staffs.zip"),
}

local prefabs =
{
    "ice_projectile",
    "fire_projectile",
    "staffcastfx",
    "stafflight",
}

---------RED STAFF---------

local function onattack_red(inst, attacker, target, skipsanity)

    if target.components.burnable and not target.components.burnable:IsBurning() then
        if target.components.freezable and target.components.freezable:IsFrozen() then           
            target.components.freezable:Unfreeze()            
        else            
            target.components.burnable:Ignite(true, attacker)
        end   
    end

    if target.components.freezable then
        target.components.freezable:AddColdness(-1) --Does this break ice staff?
        if target.components.freezable:IsFrozen() then
            target.components.freezable:Unfreeze()            
        end
    end

    if target.components.sleeper and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end

    if target.components.combat then
        target.components.combat:SuggestTarget(attacker)
        if target.sg and target.sg.sg.states.hit and not target:HasTag("player") then
            target.sg:GoToState("hit")
        end
    end

    if attacker and attacker.components.sanity and not skipsanity then
        attacker.components.sanity:DoDelta(-TUNING.SANITY_SUPERTINY)
    end

    attacker.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")
    target:PushEvent("attacked", {attacker = attacker, damage = 0})
end

local function onlight(inst, target)
    if inst.components.finiteuses then
        inst.components.finiteuses:Use(1)
    end
end

---------BLUE STAFF---------

local function onattack_blue(inst, attacker, target, skipsanity)

    target:PushEvent("attacked", {attacker = attacker, damage = 0})
    
    if attacker and attacker.components.sanity and not skipsanity then
        attacker.components.sanity:DoDelta(-TUNING.SANITY_SUPERTINY)
    end
    
    if target.components.freezable then
        target.components.freezable:AddColdness(1)
        target.components.freezable:SpawnShatterFX()
    end
    if target.components.sleeper and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end
    if target.components.burnable and target.components.burnable:IsBurning() then
        target.components.burnable:Extinguish()
    end
    if target.components.combat then
        target.components.combat:SuggestTarget(attacker)
        if target.sg and not target.sg:HasStateTag("frozen") and target.sg.sg.states.hit and not target:HasTag("player") then
            target.sg:GoToState("hit")
        end
    end
end

---------PURPLE STAFF---------

local function getrandomposition(caster)
    local ground = TheWorld
    local centers = {}
    for i, node in ipairs(ground.topology.nodes) do
        if ground.Map:IsPassableAtPoint(node.x, 0, node.y) then
            table.insert(centers, {x = node.x, z = node.y})
        end
    end
    if #centers > 0 then
        local pos = centers[math.random(#centers)]
        return Point(pos.x, 0, pos.z)
    else
        return caster:GetPosition()
    end
end

local function teleport_thread(inst, caster, teletarget, loctarget)
    local ground = TheWorld

    local t_loc = nil
    if loctarget then
        t_loc = loctarget:GetPosition()
    else
        t_loc = getrandomposition(caster)
    end

    local teleportee = teletarget
    local pt = teleportee:GetPosition()
    if teleportee.components.locomotor then
        teleportee.components.locomotor:StopMoving()
    end

    inst.components.finiteuses:Use(1)

    if ground.topology.level_type == "cave" then
        TheCamera:Shake("FULL", 0.3, 0.02, .5, 40)
        ground.components.quaker:MiniQuake(3, 5, 1.5, teleportee)     
        return
    end

    if teleportee.components.health then
        teleportee.components.health:SetInvincible(true)
    end

    --#v2c hacky way to prevent lightning from igniting us
    local preventburning = teleportee.components.burnable ~= nil and not teleportee.components.burnable.burning
    if preventburning then
        teleportee.components.burnable.burning = true
    end
    ground:PushEvent("ms_sendlightningstrike", pt)
    if preventburning then
        teleportee.components.burnable.burning = false
    end

    teleportee:Hide()

    if caster and caster.components.sanity then
        caster.components.sanity:DoDelta(-TUNING.SANITY_HUGE)
    end

    ground:PushEvent("ms_forceprecipitation", true)

    local isplayer = teleportee:HasTag("player")
    if isplayer then
        teleportee.components.playercontroller:Enable(false)
        teleportee:ScreenFade(false, 2)
        Sleep(3)
    end

    if teleportee.Physics ~= nil then
        teleportee.Physics:Teleport(t_loc.x, 0, t_loc.z)
    else
        teleportee.Transform:SetPosition(t_loc.x, 0, t_loc.z)
    end

    if isplayer then
        teleportee:SnapCamera()
        teleportee:ScreenFade(true, 1)
        Sleep(1)
        teleportee.components.playercontroller:Enable(true)
    end
    if loctarget and loctarget.onteleto then
        loctarget.onteleto(loctarget)
    end

    --#v2c hacky way to prevent lightning from igniting us
    preventburning = teleportee.components.burnable ~= nil and not teleportee.components.burnable.burning
    if preventburning then
        teleportee.components.burnable.burning = true
    end
    ground:PushEvent("ms_sendlightningstrike", t_loc)
    if preventburning then
        teleportee.components.burnable.burning = false
    end

    teleportee:Show()
    if teleportee.components.health then
        teleportee.components.health:SetInvincible(false)
    end

    if isplayer then
        teleportee.sg:GoToState("wakeup")
        teleportee.SoundEmitter:PlaySound("dontstarve/common/staffteleport")
    end
end

local function teleport_targets_sort_fn(a, b)
    return a.distance < b.distance
end

local function teleport_func(inst, target)
    print(inst, target)
    local mindistance = 1
    local caster = inst.components.inventoryitem.owner
    local tar = target or caster
    if not caster then caster = tar end
    local pt = tar:GetPosition()
    local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, 9000, {"telebase"})

    if #ents <= 0 then
        --There's no bases, active or inactive. Teleport randomly.
        inst.task = inst:StartThread(function() teleport_thread(inst, caster, tar) end)
        return
    end

    local targets = {}
    for k,v in pairs(ents) do
        local v_pt = v:GetPosition()
        if distsq(pt, v_pt) >= mindistance * mindistance then
            table.insert(targets, {base = v, distance = distsq(pt, v_pt)}) 
        end
    end

    table.sort(targets, teleport_targets_sort_fn)
    for i = 1, #targets do
        local teletarget = targets[i]
        if teletarget.base and teletarget.base.canteleto(teletarget.base) then
            inst.task = inst:StartThread(function() teleport_thread(inst, caster, tar, teletarget.base) end)
            return
        end
    end

    inst.task = inst:StartThread(function() teleport_thread(inst, caster, tar) end)
end

---------ORANGE STAFF-----------

local function onblink(staff, pos, caster)

    if caster.components.sanity then
        caster.components.sanity:DoDelta(-TUNING.SANITY_MED)
    end

    staff.components.finiteuses:Use(1) 

end

-------GREEN STAFF-----------

local DESTSOUNDS =
{
    {   --magic
        soundpath = "dontstarve/common/destroy_magic",
        ing = {"nightmarefuel", "livinglog"},
    },
    {   --cloth
        soundpath = "dontstarve/common/destroy_clothing",
        ing = {"silk", "beefalowool"},
    },
    {   --tool
        soundpath = "dontstarve/common/destroy_tool",
        ing = {"twigs"},
    },
    {   --gem
        soundpath = "dontstarve/common/gem_shatter",
        ing = {"redgem", "bluegem", "greengem", "purplegem", "yellowgem", "orangegem"},
    },
    {   --wood
        soundpath = "dontstarve/common/destroy_wood",
        ing = {"log", "board"}
    },
    {   --stone
        soundpath = "dontstarve/common/destroy_stone",
        ing = {"rocks", "cutstone"}
    },
    {   --straw
        soundpath = "dontstarve/common/destroy_straw",
        ing = {"cutgrass", "cutreeds"}
    },
}

local function CheckSpawnedLoot(loot)
    if not ((loot.components.inventoryitem and loot.components.inventoryitem:IsHeld()) or loot:IsOnValidGround()) then
        SpawnPrefab("splash_ocean").Transform:SetPosition(loot.Transform:GetWorldPosition())
        --PlayFX(loot:GetPosition(), "splash", "splash_ocean", "idle")
        if loot:HasTag("irreplaceable") then
			local x,y,z = FindSafeSpawnLocation(loot.Transform:GetWorldPosition())								
            loot.Transform:SetPosition(x,y,z)
        else
            loot:Remove()
        end
    end
end

local function SpawnLootPrefab(inst, lootprefab)
    if lootprefab then
        local loot = SpawnPrefab(lootprefab)
        if loot ~= nil then
            
            local x, y, z = inst.Transform:GetWorldPosition()
            
            loot.Transform:SetPosition(x, y, z)
            
            if loot.Physics ~= nil then
            
                local angle = math.random()*2*PI
                loot.Physics:SetVel(2*math.cos(angle), 10, 2*math.sin(angle))

                if loot.Physics ~= nil and inst.Physics ~= nil then
                    local len = loot.Physics:GetRadius() + inst.Physics:GetRadius()
                    loot.Transform:SetPosition(x + math.cos(angle) * len, y, z + math.sin(angle) * len)
                end
                
                loot:DoTaskInTime(1, CheckSpawnedLoot)
            end
            
            return loot
        end
    end
end

local function getsoundsforstructure(inst, target)

    local sounds = {}

    local recipe = AllRecipes[target.prefab]

    if recipe ~= nil then       
        for k, soundtbl in pairs(DESTSOUNDS) do
            for k2, ing in pairs(soundtbl.ing) do
                for k3, rec_ingredients in pairs(recipe.ingredients) do
                    if rec_ingredients.type == ing then
                        table.insert(sounds, soundtbl.soundpath)
                    end
                end 
            end
        end
    end

    return sounds

end

local function destroystructure(staff, target)

    local ingredient_percent = 1

    if target.components.finiteuses then
        ingredient_percent = target.components.finiteuses:GetPercent()
    elseif target.components.fueled and target.components.inventoryitem then
        ingredient_percent = target.components.fueled:GetPercent()
    elseif target.components.armor and target.components.inventoryitem then
        ingredient_percent = target.components.armor:GetPercent()
    end

    local recipe = AllRecipes[target.prefab]

    local caster = staff.components.inventoryitem.owner

    local loot = {}

    if recipe then       
        for k,v in ipairs(recipe.ingredients) do
            if not string.find(v.type, "gem") then
                local amt = math.ceil(v.amount * ingredient_percent)
                for n = 1, amt do
                    table.insert(loot, v.type)
                end
            end
        end
    end

    if #loot <= 0 then
        return
    end

    local sounds = {}
    sounds = getsoundsforstructure(staff, target)
    for k,v in pairs(sounds) do
        print("playing ",v)
        staff.SoundEmitter:PlaySound(v)
    end

    for k,v in pairs(loot) do
        SpawnLootPrefab(target, v)
    end

    if caster and caster.components.sanity then
        caster.components.sanity:DoDelta(-TUNING.SANITY_MEDLARGE)
    end

    staff.SoundEmitter:PlaySound("dontstarve/common/staff_star_dissassemble")

    staff.components.finiteuses:Use(1)

    if target.components.inventory then
        target.components.inventory:DropEverything()
    end

    if target.components.container then
        target.components.container:DropEverything()
    end

    if target.components.stackable then
        --if it's stackable we only want to destroy one of them.
        target = target.components.stackable:Get()
    end

    target:Remove()
    
    if target.components.resurrector and not target.components.resurrector.used then
        local player = caster and caster:HasTag("player") and caster or nil
        if player then
            player.components.health:RecalculatePenalty()
        end
    end
end

---------YELLOW STAFF-------------

local function createlight(staff, target, pos)
    local light = SpawnPrefab("stafflight")
    light.Transform:SetPosition(pos:Get())
    staff.components.finiteuses:Use(1)

    local caster = staff.components.inventoryitem.owner
    if caster and caster.components.sanity then
        caster.components.sanity:DoDelta(-TUNING.SANITY_MEDLARGE)
    end

end

---------COMMON FUNCTIONS---------

local function onfinished(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    inst:Remove()
end

local function unimplementeditem(inst)
    local player = ThePlayer
    player.components.talker:Say(GetString(player.prefab, "ANNOUNCE_UNIMPLEMENTED"))
    if player.components.health.currenthealth > 1 then
        player.components.health:DoDelta(-player.components.health.currenthealth * 0.5)
    end

    if inst.components.useableitem then
        inst.components.useableitem:StopUsingItem()
    end
end

local onunequip = function(inst, owner) 
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal") 
end

local function commonfn(colour, tags)

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("staffs")
    inst.AnimState:SetBuild("staffs")
    inst.AnimState:PlayAnimation(colour.."staff")

    if tags ~= nil then
        for i, v in ipairs(tags) do
            inst:AddTag(v)
        end
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()
    
    -------   
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(onfinished)

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    
    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(function(inst, owner) 
        owner.AnimState:OverrideSymbol("swap_object", "swap_staffs", colour.."staff")
        owner.AnimState:Show("ARM_carry") 
        owner.AnimState:Hide("ARM_normal") 
    end)
    inst.components.equippable:SetOnUnequip(onunequip)

    return inst
end

---------COLOUR SPECIFIC CONSTRUCTIONS---------

local function red()
    local inst = commonfn("red", { "firestaff", "rangedfireweapon" })

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(8, 10)
    inst.components.weapon:SetOnAttack(onattack_red)
    inst.components.weapon:SetProjectile("fire_projectile")

    inst:AddComponent("lighter")
    inst.components.lighter:SetOnLightFn(onlight)

    inst.components.finiteuses:SetMaxUses(TUNING.FIRESTAFF_USES)
    inst.components.finiteuses:SetUses(TUNING.FIRESTAFF_USES)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        local x,y,z = inst.Transform:GetWorldPosition() 
        local burnables = TheSim:FindEntities(x, y, z, 6, {"canlight"}, {"fire", "burnt"})
        if burnables and #burnables > 0 and math.random() <= TUNING.HAUNT_CHANCE_RARE then
            for i,v in pairs(burnables) do --#srosen should port over the d-fly's firewave fx and use those here
                onattack_red(inst, haunter, v, true) 
            end
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
        return false
    end, true, false, true)

    return inst
end

local function blue()
    local inst = commonfn("blue", { "icestaff" })

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(8, 10)
    inst.components.weapon:SetOnAttack(onattack_blue)
    inst.components.weapon:SetProjectile("ice_projectile")

    inst.components.finiteuses:SetMaxUses(TUNING.ICESTAFF_USES)
    inst.components.finiteuses:SetUses(TUNING.ICESTAFF_USES)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        local x,y,z = inst.Transform:GetWorldPosition() 
        local freezables = TheSim:FindEntities(x, y, z, 6, {"freezable"})
        if freezables and #freezables > 0 and math.random() <= TUNING.HAUNT_CHANCE_RARE then
            for i,v in pairs(freezables) do
                onattack_blue(inst, haunter, v, true) 
            end
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
        return false
    end, true, false, true)

    return inst
end

local function purple()
    local inst = commonfn("purple", { "nopunch" })

    if not TheWorld.ismastersim then
        return inst
    end

    inst.fxcolour = {104/255,40/255,121/255}
    inst.components.finiteuses:SetMaxUses(TUNING.TELESTAFF_USES)
    inst.components.finiteuses:SetUses(TUNING.TELESTAFF_USES)
    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(teleport_func)
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canusefrominventory = true
    inst.components.spellcaster.canonlyuseonlocomotors = true

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        local target = FindEntity(inst, 20, function(guy)
            return guy.components.locomotor ~= nil
        end,
        nil,
        {"playerghost"}
        )
        if target and math.random() <= TUNING.HAUNT_CHANCE_RARE then
            teleport_func(inst, target) 
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
        return false
    end, true, false, true)

    return inst
end

local function yellow_reticuletargetfn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(5, 0, 0))
end

local function yellow()
    local inst = commonfn("yellow", { "nopunch" })

    if not TheWorld.ismastersim then
        return inst
    end

    inst.fxcolour = {223/255, 208/255, 69/255}
    inst.castsound = "dontstarve/common/staffteleport"

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(createlight)
    inst.components.spellcaster.canuseonpoint = true

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = yellow_reticuletargetfn
    inst.components.reticule.ease = true

    inst.components.finiteuses:SetMaxUses(TUNING.YELLOWSTAFF_USES)
    inst.components.finiteuses:SetUses(TUNING.YELLOWSTAFF_USES)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        if math.random() <= TUNING.HAUNT_CHANCE_RARE then
            local pos = Vector3(inst.Transform:GetWorldPosition())
            local start_angle = math.random()*2*PI
            local offset = FindWalkableOffset(pos, start_angle, math.random(3,12), 60, false, true)
            local pt = pos + offset
            createlight(inst, nil, pt)
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
        return false
    end, true, false, true)

    return inst
end

local function green()
    local inst = commonfn("green", { "nopunch" })

    if not TheWorld.ismastersim then
        return inst
    end

    inst.fxcolour = {51/255,153/255,51/255}
    inst:AddComponent("spellcaster")
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canonlyuseonrecipes = true
    inst.components.spellcaster:SetSpellFn(destroystructure)

    inst.components.finiteuses:SetMaxUses(TUNING.GREENSTAFF_USES)
    inst.components.finiteuses:SetUses(TUNING.GREENSTAFF_USES)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        local target = FindEntity(inst, 20, function(guy)
            return guy.prefab and AllRecipes[guy.prefab] ~= nil
        end)
        if target and math.random() <= TUNING.HAUNT_CHANCE_RARE then
            destroystructure(inst, target) 
            SpawnPrefab("collapse_small").Transform:SetPosition(target.Transform:GetWorldPosition())
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
        return false
    end, true, false, true)

    return inst
end

local function orange()
    local inst = commonfn("orange", { "nopunch" })

    if not TheWorld.ismastersim then
        return inst
    end

    inst.fxcolour = {1, 145/255, 0}
    inst.castsound = "dontstarve/common/staffteleport"

    inst:AddComponent("blinkstaff")
    inst.components.blinkstaff.onblinkfn = onblink

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = function() 
        return inst.components.blinkstaff:GetBlinkPoint()
    end
    inst.components.reticule.ease = true

    inst.components.equippable.walkspeedmult = TUNING.CANE_SPEED_MULT

    inst.components.finiteuses:SetMaxUses(TUNING.ORANGESTAFF_USES)
    inst.components.finiteuses:SetUses(TUNING.ORANGESTAFF_USES)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, function(inst, haunter)
        local target = FindEntity(inst, 20, function(guy)
            return guy.components.locomotor ~= nil
        end,
        nil,
        {"playerghost"}
        )

        if target and math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
            local pos = Vector3(target.Transform:GetWorldPosition())
            local start_angle = math.random()*2*PI
            local offset = FindWalkableOffset(pos, start_angle, math.random(8,12), 60, false, true)
            local pt = pos + offset

            inst.components.blinkstaff:Blink(pt, target)
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
        return false
    end, true, false, true)

    return inst
end

return Prefab("common/inventory/icestaff", blue, assets, prefabs),
Prefab("common/inventory/firestaff", red, assets, prefabs),
Prefab("common/inventory/telestaff", purple, assets, prefabs),
Prefab("common/inventory/orangestaff", orange, assets, prefabs),
Prefab("common/inventory/greenstaff", green, assets, prefabs),
Prefab("common/inventory/yellowstaff", yellow, assets, prefabs)