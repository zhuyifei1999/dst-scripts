local assets =
{
    Asset("ANIM", "anim/staffs.zip"),
    Asset("ANIM", "anim/swap_staffs.zip"),
}

local prefabs =
{
    blue =
    {
        "ice_projectile",
    },

    red =
    {
        "fire_projectile",
        "cutgrass",
    },

    --purple = nil,

    orange =
    {
        "sand_puff_large_front",
        "sand_puff_large_back",
        "reticule",
    },

    green =
    {
        "splash_ocean",
        "collapse_small",
    },

    yellow =
    {
        "stafflight",
        "reticule",
    },

    opal =
    {
        "staffcoldlight",
        "reticule",
    },
}

---------RED STAFF---------

local function onattack_red(inst, attacker, target, skipsanity)
    if not skipsanity and attacker ~= nil and attacker.components.sanity ~= nil then
        attacker.components.sanity:DoDelta(-TUNING.SANITY_SUPERTINY)
    end

    attacker.SoundEmitter:PlaySound("dontstarve/wilson/fireball_explo")

    if not target:IsValid() then
        --target killed or removed in combat damage phase
        return
    end

    if target.components.burnable ~= nil and not target.components.burnable:IsBurning() then
        if target.components.freezable ~= nil and target.components.freezable:IsFrozen() then
            target.components.freezable:Unfreeze()
        elseif target.components.fueled == nil then
            target.components.burnable:Ignite(true)
        elseif target.components.fueled.fueltype == FUELTYPE.BURNABLE
            or target.components.fueled.secondaryfueltype == FUELTYPE.BURNABLE then
            local fuel = SpawnPrefab("cutgrass")
            if fuel ~= nil then
                if fuel.components.fuel ~= nil and
                    fuel.components.fuel.fueltype == FUELTYPE.BURNABLE then
                    target.components.fueled:TakeFuelItem(fuel)
                else
                    fuel:Remove()
                end
            end
        end
        --V2C: don't ignite if it doens't accespt burnable fuel!
    end

    if target.components.freezable ~= nil then
        target.components.freezable:AddColdness(-1) --Does this break ice staff?
        if target.components.freezable:IsFrozen() then
            target.components.freezable:Unfreeze()
        end
    end

    if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end

    if target.components.combat ~= nil then
        target.components.combat:SuggestTarget(attacker)
    end

    target:PushEvent("attacked", { attacker = attacker, damage = 0, weapon = inst })
end

local function onlight(inst, target)
    if inst.components.finiteuses ~= nil then
        inst.components.finiteuses:Use(1)
    end
end

local function onhauntred(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_RARE then
        local x, y, z = inst.Transform:GetWorldPosition() 
        local ents = TheSim:FindEntities(x, y, z, 6, { "canlight" }, { "fire", "burnt", "INLIMBO" })
        if #ents > 0 then
            for i, v in ipairs(ents) do
                if v:IsValid() and not v:IsInLimbo() then
                    onattack_red(inst, haunter, v, true) 
                end
            end
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
    end
    return false
end

---------BLUE STAFF---------

local function onattack_blue(inst, attacker, target, skipsanity)
    if not skipsanity and attacker ~= nil and attacker.components.sanity ~= nil then
        attacker.components.sanity:DoDelta(-TUNING.SANITY_SUPERTINY)
    end

    if not target:IsValid() then
        --target killed or removed in combat damage phase
        return
    end

    if target.components.sleeper ~= nil and target.components.sleeper:IsAsleep() then
        target.components.sleeper:WakeUp()
    end

    if target.components.burnable ~= nil then
        if target.components.burnable:IsBurning() then
            target.components.burnable:Extinguish()
        elseif target.components.burnable:IsSmoldering() then
            target.components.burnable:SmotherSmolder()
        end
    end

    if target.components.combat ~= nil then
        target.components.combat:SuggestTarget(attacker)
    end

    if target.sg ~= nil and not target.sg:HasStateTag("frozen") then
        target:PushEvent("attacked", { attacker = attacker, damage = 0, weapon = inst })
    end

    if target.components.freezable ~= nil then
        target.components.freezable:AddColdness(1)
        target.components.freezable:SpawnShatterFX()
    end
end

local function onhauntblue(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_RARE then
        local x, y, z = inst.Transform:GetWorldPosition() 
        local ents = TheSim:FindEntities(x, y, z, 6, { "freezable" }, { "INLIMBO" })
        if #ents > 0 then
            for i, v in ipairs(ents) do
                if v:IsValid() and not v:IsInLimbo() then
                    onattack_blue(inst, haunter, v, true) 
                end
            end
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
    end
    return false
end

---------PURPLE STAFF---------

require "prefabs/telebase"

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

local function teleport_end(teleportee, locpos, loctarget)
    if loctarget ~= nil and loctarget:IsValid() and loctarget.onteleto ~= nil then
        loctarget:onteleto()
    end

    if teleportee.components.inventory ~= nil and teleportee.components.inventory:IsHeavyLifting() then
        teleportee.components.inventory:DropItem(
            teleportee.components.inventory:Unequip(EQUIPSLOTS.BODY),
            true,
            true
        )
    end

    --#v2c hacky way to prevent lightning from igniting us
    local preventburning = teleportee.components.burnable ~= nil and not teleportee.components.burnable.burning
    if preventburning then
        teleportee.components.burnable.burning = true
    end
    TheWorld:PushEvent("ms_sendlightningstrike", locpos)
    if preventburning then
        teleportee.components.burnable.burning = false
    end

    if teleportee:HasTag("player") then
        teleportee.sg.statemem.teleport_task = nil
        teleportee.sg:GoToState(teleportee:HasTag("playerghost") and "appear" or "wakeup")
        teleportee.SoundEmitter:PlaySound("dontstarve/common/staffteleport")
    else
        teleportee:Show()
        if teleportee.DynamicShadow ~= nil then
            teleportee.DynamicShadow:Enable(true)
        end
        if teleportee.components.health ~= nil then
            teleportee.components.health:SetInvincible(false)
        end
        teleportee:PushEvent("teleported")
    end
end

local function teleport_continue(teleportee, locpos, loctarget)
    if teleportee.Physics ~= nil then
        teleportee.Physics:Teleport(locpos.x, 0, locpos.z)
    else
        teleportee.Transform:SetPosition(locpos.x, 0, locpos.z)
    end

    if teleportee:HasTag("player") then
        teleportee:SnapCamera()
        teleportee:ScreenFade(true, 1)
        teleportee.sg.statemem.teleport_task = teleportee:DoTaskInTime(1, teleport_end, locpos, loctarget)
    else
        teleport_end(teleportee, locpos, loctarget)
    end
end

local function teleport_start(teleportee, staff, caster, loctarget)
    local ground = TheWorld

    --V2C: Gotta do this RIGHT AWAY in case anything happens to loctarget or caster
    local locpos = loctarget == nil and getrandomposition(caster)
				or loctarget.teletopos ~= nil and loctarget:teletopos()
				or loctarget:GetPosition() 

    if teleportee.components.locomotor ~= nil then
        teleportee.components.locomotor:StopMoving()
    end

    staff.components.finiteuses:Use(1)

    if ground:HasTag("cave") then
        -- There's a roof over your head, magic lightning can't strike!
        ground:PushEvent("ms_miniquake", { rad = 3, num = 5, duration = 1.5, target = teleportee })
        return
    end

    local isplayer = teleportee:HasTag("player")
    if isplayer then
        teleportee.sg:GoToState("forcetele")
    else
        if teleportee.components.health ~= nil then
            teleportee.components.health:SetInvincible(true)
        end
        if teleportee.DynamicShadow ~= nil then
            teleportee.DynamicShadow:Enable(false)
        end
        teleportee:Hide()
    end

    --#v2c hacky way to prevent lightning from igniting us
    local preventburning = teleportee.components.burnable ~= nil and not teleportee.components.burnable.burning
    if preventburning then
        teleportee.components.burnable.burning = true
    end
    ground:PushEvent("ms_sendlightningstrike", teleportee:GetPosition())
    if preventburning then
        teleportee.components.burnable.burning = false
    end

    if caster ~= nil and caster.components.sanity ~= nil then
        caster.components.sanity:DoDelta(-TUNING.SANITY_HUGE)
    end

    ground:PushEvent("ms_deltamoisture", TUNING.TELESTAFF_MOISTURE)

    if isplayer then
        teleportee.sg.statemem.teleport_task = teleportee:DoTaskInTime(3, teleport_continue, locpos, loctarget)
    else
        teleport_continue(teleportee, locpos, loctarget)
    end
end

local function teleport_targets_sort_fn(a, b)
    return a.distance < b.distance
end

local function teleport_func(inst, target)
    local caster = inst.components.inventoryitem.owner or target
    if target == nil then
        target = caster
    end
    local x, y, z = target.Transform:GetWorldPosition()
    local loctarget = target.components.minigame_participator ~= nil and target.components.minigame_participator:GetMinigame() or FindNearestActiveTelebase(x, y, z, nil, 1)
    teleport_start(target, inst, caster, loctarget)
end

local function onhauntpurple(inst)
    if math.random() <= TUNING.HAUNT_CHANCE_RARE then
        local target = FindEntity(inst, 20, nil, { "locomotor" }, { "playerghost", "INLIMBO" })
        if target ~= nil then
            teleport_func(inst, target) 
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
    end
    return false
end

---------ORANGE STAFF-----------

local function onblink(staff, pos, caster)
    if caster.components.sanity ~= nil then
        caster.components.sanity:DoDelta(-TUNING.SANITY_MED)
    end
    staff.components.finiteuses:Use(1) 
end

local function NoHoles(pt)
    return not TheWorld.Map:IsGroundTargetBlocked(pt)
end

local function blinkstaff_reticuletargetfn()
    local player = ThePlayer
    local rotation = player.Transform:GetRotation() * DEGREES
    local pos = player:GetPosition()
    for r = 13, 1, -1 do
        local numtries = 2 * PI * r
        local offset = FindWalkableOffset(pos, rotation, r, numtries, false, true, NoHoles)
        if offset ~= nil then
            pos.x = pos.x + offset.x
            pos.y = 0
            pos.z = pos.z + offset.z
            return pos
        end
    end
end

local function onhauntorange(inst)
    if math.random() <= TUNING.HAUNT_CHANCE_OCCASIONAL then
        local target = FindEntity(inst, 20, nil, { "locomotor" }, { "playerghost", "INLIMBO" })
        if target ~= nil then
            local pos = target:GetPosition()
            local start_angle = math.random() * 2 * PI
            local offset = FindWalkableOffset(pos, start_angle, math.random(8, 12), 16, false, true, NoHoles)
            if offset ~= nil then
                pos.x = pos.x + offset.x
                pos.y = 0
                pos.z = pos.z + offset.z
                inst.components.blinkstaff:Blink(pos, target)
                inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
                return true
            end
        end
    end
    return false
end

-------GREEN STAFF-----------

local DESTSOUNDS =
{
    {   --magic
        soundpath = "dontstarve/common/destroy_magic",
        ing = { "nightmarefuel", "livinglog" },
    },
    {   --cloth
        soundpath = "dontstarve/common/destroy_clothing",
        ing = { "silk", "beefalowool" },
    },
    {   --tool
        soundpath = "dontstarve/common/destroy_tool",
        ing = { "twigs" },
    },
    {   --gem
        soundpath = "dontstarve/common/gem_shatter",
        ing = { "redgem", "bluegem", "greengem", "purplegem", "yellowgem", "orangegem" },
    },
    {   --wood
        soundpath = "dontstarve/common/destroy_wood",
        ing = { "log", "boards" },
    },
    {   --stone
        soundpath = "dontstarve/common/destroy_stone",
        ing = { "rocks", "cutstone" },
    },
    {   --straw
        soundpath = "dontstarve/common/destroy_straw",
        ing = { "cutgrass", "cutreeds" },
    },
}
local DESTSOUNDSMAP = {}
for i, v in ipairs(DESTSOUNDS) do
    for i2, v2 in ipairs(v.ing) do
        DESTSOUNDSMAP[v2] = v.soundpath
    end
end
DESTSOUNDS = nil

local function CheckSpawnedLoot(loot)
    if loot.components.inventoryitem == nil or not loot.components.inventoryitem:IsHeld() then
        local x, y, z = loot.Transform:GetWorldPosition()
        if not loot:IsOnValidGround() or TheWorld.Map:IsPointNearHole(Vector3(x, 0, z)) then
            SpawnPrefab("splash_ocean").Transform:SetPosition(x, y, z)
            if loot:HasTag("irreplaceable") then
                loot.Transform:SetPosition(FindSafeSpawnLocation(x, y, z))
            else
                loot:Remove()
            end
        end
    end
end

local function SpawnLootPrefab(inst, lootprefab)
    if lootprefab == nil then
        return
    end

    local loot = SpawnPrefab(lootprefab)
    if loot == nil then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()

    if loot.Physics ~= nil then
        local angle = math.random() * 2 * PI
        loot.Physics:SetVel(2 * math.cos(angle), 10, 2 * math.sin(angle))

        if inst.Physics ~= nil then
            local len = loot:GetPhysicsRadius(0) + inst:GetPhysicsRadius(0)
            x = x + math.cos(angle) * len
            z = z + math.sin(angle) * len
        end

        loot:DoTaskInTime(1, CheckSpawnedLoot)
    end

    loot.Transform:SetPosition(x, y, z)

    return loot
end

local function destroystructure(staff, target)
    local recipe = AllRecipes[target.prefab]
    if recipe == nil then
        --Action filters should prevent us from reaching here normally
        return
    end

    local ingredient_percent =
        (   (target.components.finiteuses ~= nil and target.components.finiteuses:GetPercent()) or
            (target.components.fueled ~= nil and target.components.inventoryitem ~= nil and target.components.fueled:GetPercent()) or
            (target.components.armor ~= nil and target.components.inventoryitem ~= nil and target.components.armor:GetPercent()) or
            1
        ) / recipe.numtogive

    --V2C: Can't play sounds on the staff, or nobody
    --     but the user and the host will hear them!
    local caster = staff.components.inventoryitem.owner

    for i, v in ipairs(recipe.ingredients) do
        if caster ~= nil and DESTSOUNDSMAP[v.type] ~= nil then
            caster.SoundEmitter:PlaySound(DESTSOUNDSMAP[v.type])
        end
        if string.sub(v.type, -3) ~= "gem" or string.sub(v.type, -11, -4) == "precious" then
            --V2C: always at least one in case ingredient_percent is 0%
            local amt = math.max(1, math.ceil(v.amount * ingredient_percent))
            for n = 1, amt do
                SpawnLootPrefab(target, v.type)
            end
        end
    end

    if caster ~= nil then
        caster.SoundEmitter:PlaySound("dontstarve/common/staff_dissassemble")

        if caster.components.sanity ~= nil then
            caster.components.sanity:DoDelta(-TUNING.SANITY_MEDLARGE)
        end
    end

    staff.components.finiteuses:Use(1)

    if target.components.inventory ~= nil then
        target.components.inventory:DropEverything()
    end

    if target.components.container ~= nil then
        target.components.container:DropEverything()
    end

    if target.components.spawner ~= nil and target.components.spawner:IsOccupied() then
        target.components.spawner:ReleaseChild()
    end

    if target.components.occupiable ~= nil and target.components.occupiable:IsOccupied() then
        local item = target.components.occupiable:Harvest()
        if item ~= nil then
            item.Transform:SetPosition(target.Transform:GetWorldPosition())
            item.components.inventoryitem:OnDropped()
        end
    end

    if target.components.trap ~= nil then
        target.components.trap:Harvest()
    end

    if target.components.dryer ~= nil then
        target.components.dryer:DropItem()
    end

    if target.components.harvestable ~= nil then
        target.components.harvestable:Harvest()
    end

    if target.components.stewer ~= nil then
        target.components.stewer:Harvest()
    end

   	target:PushEvent("ondeconstrcutstructure", caster)

    if target.components.stackable ~= nil then
        --if it's stackable we only want to destroy one of them.
        target.components.stackable:Get():Remove()
    else
        target:Remove()
    end
end

local function HasRecipe(guy)
    return guy.prefab ~= nil and AllRecipes[guy.prefab] ~= nil
end

local function onhauntgreen(inst)
    if math.random() <= TUNING.HAUNT_CHANCE_RARE then
        local target = FindEntity(inst, 20, HasRecipe, nil, { "INLIMBO" })
        if target ~= nil then
            destroystructure(inst, target) 
            SpawnPrefab("collapse_small").Transform:SetPosition(target.Transform:GetWorldPosition())
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
    end
    return false
end

---------YELLOW/OPAL STAFF-------------

local function createlight(staff, target, pos)
    local light = SpawnPrefab(staff.prefab == "opalstaff" and "staffcoldlight" or "stafflight")
    light.Transform:SetPosition(pos:Get())
    staff.components.finiteuses:Use(1)

    local caster = staff.components.inventoryitem.owner
    if caster ~= nil and caster.components.sanity ~= nil then
        caster.components.sanity:DoDelta(-TUNING.SANITY_MEDLARGE)
    end
end

local function light_reticuletargetfn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(5, 0.001, 0)) -- raised this off the ground a touch so it wont have any z-fighting with the ground biome transition tiles.
end

local function onhauntlight(inst)
    if math.random() <= TUNING.HAUNT_CHANCE_RARE then
        local pos = inst:GetPosition()
        local start_angle = math.random() * 2 * PI
        local offset = FindWalkableOffset(pos, start_angle, math.random(3, 12), 60, false, true, NoHoles)
        if offset ~= nil then
            createlight(inst, nil, pos + offset)
            inst.components.hauntable.hauntvalue = TUNING.HAUNT_LARGE
            return true
        end
    end
    return false
end

---------COMMON FUNCTIONS---------

local function onfinished(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    inst:Remove()
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function onunequip_skinned(inst, owner)
    if inst:GetSkinBuild() ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    onunequip(inst, owner)
end

local function commonfn(colour, tags, hasskin)
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

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------
    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(onfinished)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("tradable")

    inst:AddComponent("equippable")

    if hasskin then
        inst.components.equippable:SetOnEquip(function(inst, owner)
            local skin_build = inst:GetSkinBuild()
            if skin_build ~= nil then
                owner:PushEvent("equipskinneditem", inst:GetSkinName())
                owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_"..colour.."staff", inst.GUID, "swap_staffs")
            else
                owner.AnimState:OverrideSymbol("swap_object", "swap_staffs", "swap_"..colour.."staff")
            end
            owner.AnimState:Show("ARM_carry")
            owner.AnimState:Hide("ARM_normal")
        end)
        inst.components.equippable:SetOnUnequip(onunequip_skinned)
    else
        inst.components.equippable:SetOnEquip(function(inst, owner)
            owner.AnimState:OverrideSymbol("swap_object", "swap_staffs", "swap_"..colour.."staff")
            owner.AnimState:Show("ARM_carry")
            owner.AnimState:Hide("ARM_normal")
        end)
        inst.components.equippable:SetOnUnequip(onunequip)
    end

    return inst
end

---------COLOUR SPECIFIC CONSTRUCTIONS---------

local function red()
    local inst = commonfn("red", { "firestaff", "rangedweapon", "rangedlighter" }, true)

    inst.projectiledelay = FRAMES

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)
    inst.components.weapon:SetRange(8, 10)
    inst.components.weapon:SetOnAttack(onattack_red)
    inst.components.weapon:SetProjectile("fire_projectile")

    inst.components.finiteuses:SetMaxUses(TUNING.FIRESTAFF_USES)
    inst.components.finiteuses:SetUses(TUNING.FIRESTAFF_USES)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, onhauntred, true, false, true)

    return inst
end

local function blue()
    local inst = commonfn("blue", { "icestaff", "rangedweapon", "extinguisher" }, true)

    inst.projectiledelay = FRAMES

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
    AddHauntableCustomReaction(inst, onhauntblue, true, false, true)

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
    inst.components.spellcaster.canonlyuseonlocomotorspvp = true

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, onhauntpurple, true, false, true)

    return inst
end

local function yellow()
    local inst = commonfn("yellow", { "nopunch" })

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = light_reticuletargetfn
    inst.components.reticule.ease = true

    if not TheWorld.ismastersim then
        return inst
    end

    inst.fxcolour = {223/255, 208/255, 69/255}
    inst.castsound = "dontstarve/common/staffteleport"

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(createlight)
    inst.components.spellcaster.canuseonpoint = true

    inst.components.finiteuses:SetMaxUses(TUNING.YELLOWSTAFF_USES)
    inst.components.finiteuses:SetUses(TUNING.YELLOWSTAFF_USES)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, onhauntlight, true, false, true)

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
    AddHauntableCustomReaction(inst, onhauntgreen, true, false, true)

    return inst
end

local function orange()
    local inst = commonfn("orange", { "nopunch" }, true)

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = blinkstaff_reticuletargetfn
    inst.components.reticule.ease = true

    if not TheWorld.ismastersim then
        return inst
    end

    inst.fxcolour = {1, 145/255, 0}
    inst.castsound = "dontstarve/common/staffteleport"

    inst:AddComponent("blinkstaff")
    inst.components.blinkstaff:SetFX("sand_puff_large_front", "sand_puff_large_back")
    inst.components.blinkstaff.onblinkfn = onblink

    inst.components.equippable.walkspeedmult = TUNING.CANE_SPEED_MULT

    inst.components.finiteuses:SetMaxUses(TUNING.ORANGESTAFF_USES)
    inst.components.finiteuses:SetUses(TUNING.ORANGESTAFF_USES)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, onhauntorange, true, false, true)

    return inst
end

local function opal()
    local inst = commonfn("opal", { "nopunch" })

    inst:AddComponent("reticule")
    inst.components.reticule.targetfn = light_reticuletargetfn
    inst.components.reticule.ease = true

    if not TheWorld.ismastersim then
        return inst
    end

    inst.fxcolour = {64/255, 64/255, 208/255}
    inst.castsound = "dontstarve/common/staffteleport"

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(createlight)
    inst.components.spellcaster.canuseonpoint = true

    inst.components.finiteuses:SetMaxUses(TUNING.OPALSTAFF_USES)
    inst.components.finiteuses:SetUses(TUNING.OPALSTAFF_USES)

    MakeHauntableLaunch(inst)
    AddHauntableCustomReaction(inst, onhauntlight, true, false, true)

    return inst
end

return Prefab("icestaff", blue, assets, prefabs.blue),
    Prefab("firestaff", red, assets, prefabs.red),
    Prefab("telestaff", purple, assets, prefabs.purple),
    Prefab("orangestaff", orange, assets, prefabs.orange),
    Prefab("greenstaff", green, assets, prefabs.green),
    Prefab("yellowstaff", yellow, assets, prefabs.yellow),
    Prefab("opalstaff", opal, assets, prefabs.opal)
