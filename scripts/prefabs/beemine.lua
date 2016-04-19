local assets =
{
    Asset("ANIM", "anim/bee_mine.zip"),
    Asset("ANIM", "anim/bee_mine_maxwell.zip"),
    Asset("SOUND", "sound/bee.fsb"),
}

local prefabs =
{
    "bee",
    "mosquito",
}

local function SpawnBees(inst)
    inst.SoundEmitter:PlaySound("dontstarve/bee/beemine_explo")
    local target = inst.components.mine ~= nil and inst.components.mine:GetTarget() or nil
    if target == nil or not target:IsValid() then
        target = FindEntity(inst, 25, nil, nil,
            { "insect", "playerghost" },
            { "character", "animal", "monster" })
    end
    if target ~= nil then
        for i = 1, TUNING.BEEMINE_BEES do
            local bee = SpawnPrefab(inst.beeprefab)
            if bee ~= nil then
                local x, y, z = inst.Transform:GetWorldPosition()
                local dist = math.random()
                local angle = math.random() * 2 * PI
                bee.Physics:Teleport(x + dist * math.cos(angle), y, z + dist * math.sin(angle))
                if bee.components.combat ~= nil then
                    bee.components.combat:SetTarget(target)
                end
            end
        end
        target:PushEvent("coveredinbees")
    end
    inst:RemoveComponent("mine")
end

local function OnExplode(inst)
    if inst.rattletask then
        inst.rattletask:Cancel()
        inst.rattletask = nil
    end
    if inst.spawntask then -- We've already been told to explode
        return
    end
    inst.AnimState:PlayAnimation("explode")
    inst.SoundEmitter:PlaySound("dontstarve/bee/beemine_launch")
    inst.spawntask = inst:DoTaskInTime(9 * FRAMES, SpawnBees)
    inst:ListenForEvent("animover", inst.Remove)
    if inst.components.inventoryitem ~= nil then
        inst.components.inventoryitem.canbepickedup = false
    end
end

local function onhammered(inst, worker)
    if inst.components.mine then
        inst.components.mine:Explode(worker)
    end
end

local function MineRattle(inst)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
    inst.SoundEmitter:PlaySound("dontstarve/bee/beemine_rattle")
    inst.rattletask = inst:DoTaskInTime(4 + math.random(), MineRattle)
end

local function StartRattling(inst)
    if inst.rattletask ~= nil then
        inst.rattletask:Cancel()
    end
    inst.rattletask = inst:DoTaskInTime(1, MineRattle)
end

local function StopRattling(inst)
    if inst.rattletask ~= nil then
        inst.rattletask:Cancel()
        inst.rattletask = nil
    end
end

local function ondeploy(inst, pt, deployer)
    inst.components.mine:Reset()
    inst.Physics:Teleport(pt:Get())
    StartRattling(inst)
end

local function SetInactive(inst)
    inst.AnimState:PlayAnimation("inactive")
    StopRattling(inst)
end

local function OnDropped(inst)
    inst.components.mine:Deactivate()
end

local function OnHaunt(inst)
    if math.random() <= TUNING.HAUNT_CHANCE_RARE then
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_MEDIUM
        OnExplode(inst)
        return true
    end
    inst.components.hauntable.hauntvalue = TUNING.HAUNT_TINY
    StopRattling(inst)
    MineRattle(inst)
    return true
end

local function BeeMine(name, alignment, skin, spawnprefab, inventory)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.MiniMapEntity:SetIcon("beemine.png")

        inst.AnimState:SetBank(skin)
        inst.AnimState:SetBuild(skin)
        inst.AnimState:PlayAnimation("idle")

        inst:AddTag("mine")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("mine")
        inst.components.mine:SetOnExplodeFn(OnExplode)
        inst.components.mine:SetAlignment(alignment)
        inst.components.mine:SetRadius(TUNING.BEEMINE_RADIUS)
        inst.components.mine:SetOnDeactivateFn(SetInactive)

        inst.components.mine:StartTesting()
        inst.beeprefab = spawnprefab

        inst:AddComponent("inspectable")
        inst:AddComponent("lootdropper")
        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(onhammered)

        if inventory then
            inst:AddComponent("inventoryitem")
            inst.components.inventoryitem.nobounce = true
            inst.components.inventoryitem:SetOnPutInInventoryFn(StopRattling)
            inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

            inst:AddComponent("deployable")
            inst.components.deployable.ondeploy = ondeploy
            inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)
        else
            StartRattling(inst)
        end

        inst:AddComponent("hauntable")
        inst.components.hauntable:SetOnHauntFn(OnHaunt)

        return inst
    end
    return Prefab(name, fn, assets, prefabs)
end

return BeeMine("beemine", "player", "bee_mine", "bee", true),
    MakePlacer("beemine_placer", "bee_mine", "bee_mine", "idle"),
    BeeMine("beemine_maxwell", "nobody", "bee_mine_maxwell", "mosquito", false)
