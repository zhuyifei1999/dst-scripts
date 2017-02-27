local assets =
{
    Asset("ANIM", "anim/fossil_stalker.zip"),
}

local prefabs =
{
    "fossil_piece_clean",
    "collapse_small",
}

local NUM_FORMS = 3
local MAX_MOUND_SIZE = 8
local MOUND_WRONG_START_SIZE = 5

local function UpdateFossileMound(inst, size, checkforwrong)
    if size < MOUND_WRONG_START_SIZE then
        --reset case, not really used tho
        inst.form = 1
    elseif checkforwrong and inst.moundsize < MOUND_WRONG_START_SIZE then
        --double chance of form 1 (correct form)
        inst.form = math.max(1, math.random(0, NUM_FORMS))
    end

    inst.moundsize = size
    inst.components.workable:SetWorkLeft(size)
    inst.AnimState:PlayAnimation(tostring(inst.form).."_"..tostring(inst.moundsize))
end

local function lootsetfn(lootdropper)
    local loot = {}
    for i = 1, lootdropper.inst.moundsize do
        table.insert(loot, "fossil_piece_clean")
    end
    lootdropper:SetLoot(loot)
end

local function onworked(inst)
    local pos = inst:GetPosition()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(pos:Get())
    fx:SetMaterial("rock")

    inst.components.lootdropper:DropLoot(pos)
    inst:Remove()
end

local function onrepaired(inst)
    UpdateFossileMound(inst, inst.moundsize + 1, true)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/fossil/repair")
end

local function getstatus(inst)
    return inst.moundsize >= MAX_MOUND_SIZE
        and (inst.form > 1 and "FUNNY" or "COMPLETE")
        or nil
end

local function onsave(inst, data)
    data.moundsize = inst.moundsize > 1 and inst.moundsize or nil
    data.form = inst.form > 1 and inst.form or nil
end

local function onload(inst, data)
    if data ~= nil then
        --backward compatibility for data.wrong
        inst.form = math.clamp(data.form or (data.wrong and 2 or 1), 1, NUM_FORMS)
        UpdateFossileMound(inst, math.clamp(data.moundsize or 1, 1, MAX_MOUND_SIZE), false)
    end
end

local function makemound(name)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, .45)

        inst.AnimState:SetBank(name)
        inst.AnimState:SetBuild(name)
        inst.AnimState:PlayAnimation("1_1")

        inst:AddTag("structure")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = getstatus

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLootSetupFn(lootsetfn)

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetMaxWork(MAX_MOUND_SIZE)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnWorkCallback(onworked)
        inst.components.workable.savestate = true

        inst:AddComponent("repairable")
        inst.components.repairable.repairmaterial = MATERIALS.FOSSIL
        inst.components.repairable.onrepaired = onrepaired
        inst.components.repairable.noannounce = true

        MakeHauntableWork(inst)

        inst.form = 1
        UpdateFossileMound(inst, 1)

        inst.OnSave = onsave
        inst.OnLoad = onload

        return inst
    end

    return Prefab(name, fn, assets, prefabs)
end

return makemound("fossil_stalker")
