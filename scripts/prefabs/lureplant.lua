local assets =
{
    Asset("ANIM", "anim/eyeplant_trap.zip"),
    Asset("ANIM", "anim/meat_rack_food.zip"),
    Asset("SOUND", "sound/plant.fsb"),
    Asset("MINIMAP_IMAGE", "eyeplant"),
}

local prefabs =
{
    "eyeplant",
    "lureplantbulb",
    "plantmeat",
}

local brain = require "brains/lureplantbrain"

function adjustIdleSound(inst, vol)
    inst.SoundEmitter:SetParameter("loop", "size", vol)
end

local function TryRevealBait(inst)
    inst.task = nil
    inst.lure = inst.lurefn(inst)
    if inst.lure ~= nil and inst.wakeinfo == nil then --There's something to show as bait!
        inst:ListenForEvent("onremove", inst._OnLurePerished, inst.lure)
        inst.components.shelf.cantakeitem = true
        inst.components.shelf.itemonshelf = inst.lure
        inst.sg:GoToState("showbait")
    else --There was nothing to use as bait. Try to reveal bait again until you can.
        inst.task = inst:DoTaskInTime(1, TryRevealBait)
    end
end

local function HideBait(inst)
    if not (inst.sg:HasStateTag("hiding") or inst.components.health:IsDead()) then --Won't hide if it's already hiding.
        if inst.task == nil then
            inst.components.shelf.cantakeitem = false
            inst.sg:GoToState("hidebait")
        end
    end

    if inst.lure ~= nil then
        inst:RemoveEventCallback("onremove", inst._OnLurePerished, inst.lure)
        inst.lure = nil
    end

    if inst.task ~= nil then
        inst.task:Cancel()
    end
    inst.task = inst:DoTaskInTime(math.random() * 3 + 2, TryRevealBait) --Emerge again after some time.
end

local function SetWakeInfo(inst, sleeptime)
    inst.wakeinfo = {}
    inst.wakeinfo.endsleeptime = GetTime() + sleeptime
end

local function WakeUp(inst)
    if not TheWorld.state.iswinter then
        inst.wakeinfo = nil
        inst.components.minionspawner.shouldspawn = true
        inst.components.minionspawner:StartNextSpawn()
        if inst.task == nil then
            inst.task = inst:DoTaskInTime(1, TryRevealBait)
        end
        inst.sg:GoToState("emerge")
    end
end

local function ResumeSleep(inst, seconds)
    inst.sg:GoToState("hibernate")
    inst.components.shelf.cantakeitem = false

    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end

    inst.components.minionspawner.shouldspawn = false
    inst.components.minionspawner:KillAllMinions()
    
    SetWakeInfo(inst, seconds)
    inst:DoTaskInTime(seconds, WakeUp)
end

local function OnPicked(inst)
    if inst.lure ~= nil then
        inst:RemoveEventCallback("onremove", inst._OnLurePerished, inst.lure)
        inst.lure = nil
    end
    inst.components.shelf.cantakeitem = false
    inst.sg:GoToState("picked")

    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end

    inst.components.minionspawner.shouldspawn = false
    inst.components.minionspawner:KillAllMinions()

    SetWakeInfo(inst, TUNING.LUREPLANT_HIBERNATE_TIME)

    if inst.hibernatetask ~= nil then
        inst.hibernatetask:Cancel()
    end
    inst.hibernatetask = inst:DoTaskInTime(TUNING.LUREPLANT_HIBERNATE_TIME, WakeUp)
end

local function FreshSpawn(inst)
    inst.components.shelf.cantakeitem = false
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.components.minionspawner.shouldspawn = false
    inst.components.minionspawner:KillAllMinions()

    SetWakeInfo(inst, TUNING.LUREPLANT_HIBERNATE_TIME)

    if inst.hibernatetask ~= nil then
        inst.hibernatetask:Cancel()
    end
    inst.hibernatetask = inst:DoTaskInTime(TUNING.LUREPLANT_HIBERNATE_TIME, WakeUp)
end

local function CollectItems(inst)
    if inst.components.minionspawner.minions ~= nil then
        for k, v in pairs(inst.components.minionspawner.minions) do
            if v.components.inventory ~= nil then                
                for k = 1, v.components.inventory.maxslots do
                    local item = v.components.inventory.itemslots[k]
                    if item ~= nil and not inst.components.inventory:IsFull() then
                        local it = v.components.inventory:RemoveItem(item)
                        if it.components.perishable ~= nil then
                            local top = it.components.perishable:GetPercent()
                            local bottom = .2
                            if top > bottom then
                                it.components.perishable:SetPercent(bottom + math.random() * (top - bottom))
                            end
                        end
                        inst.components.inventory:GiveItem(it)
                    elseif item ~= nil then
                        local item = v.components.inventory:RemoveItem(item)
                        item:Remove()
                    end
                end
            end
        end
    end
end

local function SelectLure(inst)    
    if inst.components.inventory ~= nil then
        local lures = {}
        for k = 1, inst.components.inventory.maxslots do
            local item = inst.components.inventory.itemslots[k]
            if item ~= nil and
                item.components.weapon == nil and
                item.components.edible ~= nil and
                inst.components.eater:CanEat(item) and
                not item:HasTag("preparedfood") then
                table.insert(lures, item)
            end
        end

        if #lures >= 1 then
            return lures[math.random(#lures)]
        elseif inst.components.minionspawner.numminions * 2 >= inst.components.minionspawner.maxminions then
            local meat = SpawnPrefab("plantmeat")
            inst.components.inventory:GiveItem(meat)
            return meat
        end
    end
end

local function OnDeath(inst)
    inst.components.minionspawner.shouldspawn = false
    inst.components.minionspawner:KillAllMinions()
    inst.components.lootdropper:DropLoot(inst:GetPosition())
end

local function CanDigest(owner, item)
    --If it's not itemonshelf, then go ahead and digest it
    --If it IS itemonshelf, only digest if there's more than a stack of 5
    return item ~= owner.components.shelf.itemonshelf
        or (item.components.stackable ~= nil and
            item.components.stackable.stacksize > 5)
end

local function OnLoad(inst, data)
    if data ~= nil and data.timeuntilwake ~= nil then
        ResumeSleep(inst, data.timeuntilwake)
    end
end

local function OnSave(inst, data)
    if inst.wakeinfo ~= nil then
        data.timeuntilwake = inst.wakeinfo.endsleeptime - GetTime()
    end
end

local function OnLongUpdate(inst, dt)
    if inst.wakeinfo ~= nil and inst.wakeinfo.endsleeptime ~= nil then
        if inst.hibernatetask ~= nil then
            inst.hibernatetask:Cancel()
            inst.hibernatetask = nil
        end

        local time_to_wait = inst.wakeinfo.endsleeptime - GetTime() - dt

        if time_to_wait <= 0 then
            WakeUp(inst)
        else
            inst.wakeinfo.endsleeptime = GetTime() + time_to_wait
            inst.hibernatetask = inst:DoTaskInTime(time_to_wait, WakeUp)
        end
    end
end

local function SeasonChanges(inst)
    if TheWorld.state.iswinter then
        --hibernate if you aren't already
        if inst.sg.currentstate.name ~= "hibernate" then
            OnPicked(inst)
        else
            --it's already hibernating & it's still winter. Make it sleep for longer!
            SetWakeInfo(inst, TUNING.LUREPLANT_HIBERNATE_TIME)
            if inst.hibernatetask ~= nil then
                inst.hibernatetask:Cancel()
            end
            inst.hibernatetask = inst:DoTaskInTime(TUNING.LUREPLANT_HIBERNATE_TIME, WakeUp)
        end
    end
end

local function OnEntityWake(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeplant/eye_central_idle", "loop")
    adjustIdleSound(inst, inst.components.minionspawner.numminions / inst.components.minionspawner.maxminions)
end

local function OnEntitySleep(inst)
    inst.SoundEmitter:KillSound("loop")
end

local function OnStartFireDamage(inst)
    inst.components.minionspawner.shouldspawn = false
    inst.components.minionspawner:KillAllMinions()
end

local function OnMinionChange(inst)
    if not inst:IsAsleep() then
        adjustIdleSound(inst, inst.components.minionspawner.numminions / inst.components.minionspawner.maxminions)
    end
end

local function OnHaunt(inst)
    --if math.random() <= TUNING.HAUNT_CHANCE_ALWAYS then
        HideBait(inst)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_TINY
        return true
    --end
    --return false
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, .7)

    inst:AddTag("lureplant")
    inst:AddTag("hostile")
    inst:AddTag("veggie")
    inst:AddTag("wildfirepriority")

    inst.MiniMapEntity:SetIcon("eyeplant.png")

    inst.AnimState:SetBank("eyeplant_trap")
    inst.AnimState:SetBuild("eyeplant_trap")
    inst.AnimState:PlayAnimation("idle_hidden", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(300)

    inst:AddComponent("combat")
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("hidebait", HideBait)

    inst:AddComponent("shelf")
    inst.components.shelf.ontakeitemfn = OnPicked

    inst:AddComponent("inventory")

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"lureplantbulb"})

    inst:AddComponent("minionspawner")
    inst.components.minionspawner.onminionattacked = HideBait
    inst.components.minionspawner.validtiletypes = {4,5,6,7,8,13,14,15,17,30,24,25}

    inst:AddComponent("digester")
    inst.components.digester.itemstodigestfn = CanDigest

    inst:SetStateGraph("SGlureplant")

    inst:ListenForEvent("startfiredamage", OnStartFireDamage)

    inst:ListenForEvent("freshspawn", FreshSpawn)
    inst:ListenForEvent("minionchange", OnMinionChange)

    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake

    MakeLargeBurnable(inst)
    MakeMediumPropagator(inst)

    MakeHauntableIgnite(inst, TUNING.HAUNT_CHANCE_OCCASIONAL)
    AddHauntableCustomReaction(inst, OnHaunt, false, false, true)

    inst.OnLoad = OnLoad
    inst.OnSave = OnSave

    inst.OnLongUpdate = OnLongUpdate

    inst._OnLurePerished = function() HideBait(inst) end
    inst.lurefn = SelectLure
    inst:DoPeriodicTask(2, CollectItems) -- Always do this.
    TryRevealBait(inst)

    inst.ListenForWinter = inst:DoPeriodicTask(30, SeasonChanges)
    SeasonChanges(inst)

    inst:SetBrain(brain)

    return inst
end

return Prefab("lureplant", fn, assets, prefabs)
