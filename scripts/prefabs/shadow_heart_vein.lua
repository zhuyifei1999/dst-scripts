local assets = {
    Asset("SCRIPT", "scripts/prefabs/tree_rock_data.lua"),
    Asset("ANIM", "anim/shadow_heart_vein.zip"),
}

-- FIXME(JBK): WX: Refactor this to pull this boulder bough item logic into a common.

local NUM_VARIATIONS = 3

local prefabs = {
    "rocks",
    "nitre",
    "flint",
    "goldnugget",
    "moonrocknugget",
    "moonglass",
    -- NOTES(JBK): Keep the above loot items in sync with tree_rocks. [SHLTLP]
}

local TREE_ROCK_DATA = require("prefabs/tree_rock_data")
local WEIGHTED_VINE_LOOT = TREE_ROCK_DATA.WEIGHTED_VINE_LOOT
local VINE_LOOT_DATA = TREE_ROCK_DATA.VINE_LOOT_DATA
local TASKS_TO_LOOT_KEY = TREE_ROCK_DATA.TASKS_TO_LOOT_KEY
local ROOMS_TO_LOOT_KEY = TREE_ROCK_DATA.ROOMS_TO_LOOT_KEY
local STATIC_LAYOUTS_TO_LOOT_KEY = TREE_ROCK_DATA.STATIC_LAYOUTS_TO_LOOT_KEY
local EXTRA_LOOT_MODIFIERS = TREE_ROCK_DATA.EXTRA_LOOT_MODIFIERS
local CheckModifyLootArea = TREE_ROCK_DATA.CheckModifyLootArea
TREE_ROCK_DATA = nil

local function GetLootKey(id)
    local gen_data = ConvertTopologyIdToData(id)
    local loot_key

    if gen_data.layout_id and STATIC_LAYOUTS_TO_LOOT_KEY[gen_data.layout_id] then
        loot_key = STATIC_LAYOUTS_TO_LOOT_KEY[gen_data.layout_id]
    elseif gen_data.room_id and ROOMS_TO_LOOT_KEY[gen_data.room_id] then
        loot_key = ROOMS_TO_LOOT_KEY[gen_data.room_id]
    elseif gen_data.task_id and TASKS_TO_LOOT_KEY[gen_data.task_id] then
        loot_key = TASKS_TO_LOOT_KEY[gen_data.task_id]
    end

    return CheckModifyLootArea(loot_key)
end

local function CountWeightedTotal(choices)
    local total = 0
    for _, weight in pairs(choices) do
        total = total + weight
    end
    return total
end

local function GetLootWeightedTable(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local id, index = TheWorld.Map:GetTopologyIDAtPoint(x, y, z) -- NOTE: This doesn't account for overhang, but that's OK because we can't be planted close to shore anyways.
    if id then
        local loot_key = GetLootKey(id)

        if loot_key then
            local weighted_table = WEIGHTED_VINE_LOOT[loot_key]
            local weighted_total = CountWeightedTotal(weighted_table)
            --
            for id, data in pairs(EXTRA_LOOT_MODIFIERS) do
                if data.test_fn(inst) then
                    local EXTRA_LOOT = FunctionOrValue(data.loot, inst, weighted_total)
                    weighted_table = MergeMapsAdditively(weighted_table, EXTRA_LOOT)
                end
            end
            --
            return weighted_table
        end
    end

    return WEIGHTED_VINE_LOOT.DEFAULT
end

local function GetVineLoots(inst)
    return weighted_random_choices(GetLootWeightedTable(inst), 1)
end

local function SetupVineLoot(inst, loots)
    if inst.vine_loot then
        return
    end

    inst.vine_loot = loots or GetVineLoots(inst)

    local data = VINE_LOOT_DATA[inst.vine_loot[1]]

    if inst.vine_loot[1] == "EMPTY" then
        inst.AnimState:Hide("swap_gem")
    else
        local build, symbol = data.build, (#data.symbols == 0 and data.symbols[1]) or data.symbols[math.random(#data.symbols)]
        inst.AnimState:OverrideSymbol("swap_gem", build, symbol)
    end
end

local function OnChopDown(inst, chopper)
    inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_flesh_wet_sharp")

    if inst.vine_loot then
        if inst.vine_loot[1] ~= "EMPTY" then
            local pt = inst:GetPosition()
            pt.y = pt.y + 1.2
            inst.components.lootdropper:SpawnLootPrefab(inst.vine_loot[1], pt)
        end
    end

    inst.persists = false
    inst.AnimState:PlayAnimation("fall_" .. tostring(inst.variation))
    inst:ListenForEvent("animover", inst.Remove)
end

local function OnChop(inst, chopper, chopsleft, numchops)
    if not (chopper ~= nil and chopper:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound("dontstarve/impacts/impact_flesh_wet_sharp")
    end

    inst.AnimState:PlayAnimation("chop_" .. tostring(inst.variation), false)
    inst.AnimState:PushAnimation("idle_" .. tostring(inst.variation), true)
end

local function SetVariation(inst, variation)
    inst.variation = variation or math.random(NUM_VARIATIONS)
    if inst.variation ~= 1 then
        inst.AnimState:PlayAnimation("grow_" .. tostring(inst.variation), false)
        inst.AnimState:PushAnimation("idle_" .. tostring(inst.variation), true)
    end
end

local function ScheduleForDelete(inst)
    if inst:IsAsleep() then
        inst:Remove()
    else
        inst.persists = false
        inst.AnimState:PlayAnimation("fall_" .. tostring(inst.variation), false)
        inst:ListenForEvent("animover", inst.Remove)
        inst.OnEntitySleep = inst.Remove
    end
end

local function OnSave(inst, data)
    if inst.vine_loot then
        data.vine_loot = inst.vine_loot
    end
    if inst.variation then
        data.variation = inst.variation
    end
end
local function OnLoad(inst, data)
    if not data then
        SetVariation(inst)
        return
    end
    if data.vine_loot then
        SetupVineLoot(inst, data.vine_loot)
    end
    SetVariation(inst, data.variation)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("shadow_heart_vein")
    inst.AnimState:SetBuild("shadow_heart_vein")
    inst.AnimState:PlayAnimation("grow_1", false)
    inst.AnimState:PushAnimation("idle_1", true)

    inst:AddTag("shadow_heart_vein")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    if not POPULATING then
        SetVariation(inst)
    end

    inst:AddComponent("inspectable")

    local lootdropper = inst:AddComponent("lootdropper")
    lootdropper:SetChanceLootTable('tree_rock1_chop')

    local workable = inst:AddComponent("workable")
    workable:SetWorkAction(ACTIONS.CHOP)
    workable:SetWorkLeft(TUNING.SKILLS.WX78.SHADOWHEART_WORK_NEEDED)
    workable:SetOnWorkCallback(OnChop)
    workable:SetOnFinishCallback(OnChopDown)

    inst.ScheduleForDelete = ScheduleForDelete
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:DoTaskInTime(0, SetupVineLoot)

    return inst
end

return Prefab("shadow_heart_vein", fn, assets)
