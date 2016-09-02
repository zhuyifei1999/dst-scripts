SetSharedLootTable("gargoyles_loot",
{
    { "moonrocknugget", 1 },
    { "moonrocknugget", .5 },
})

SetSharedLootTable("brokenhound_loot",
{
    { "monstermeat", 1 },
    { "moonrocknugget", .5 },
})

SetSharedLootTable("brokenwerepig_loot",
{
    { "meat", 1 },
    { "pigskin", .5 },
    { "moonrocknugget", .5 },
})

local function makegargoyle(data)
    local assets =
    {
        Asset("ANIM", "anim/sculpture_"..data.name..".zip"),
        Asset("ANIM", "anim/sculpture_"..data.name.."_moonrock_build.zip"),
    }

    local prefabs =
    {
        "moonrocknugget",
        data.petrify_prefab,
    }

    local function crumble(inst)
        if inst._petrifytask ~= nil then
            inst._petrifytask:Cancel()
            inst._petrifytask = nil
        end
        if inst._reanimatetask ~= nil then
            inst._reanimatetask:Cancel()
        end
        inst.AnimState:PlayAnimation("transform_"..data.anim.."2")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(inst:GetPosition())
        RemovePhysicsColliders(inst)
        inst:AddTag("NOCLICK")
        inst.persists = false
        inst._reanimatetask = inst:DoTaskInTime(1, ErodeAway)
    end

    local function onwork(inst, worker, workleft)
        if workleft <= 0 then
            crumble(inst)
        else
            inst.AnimState:PlayAnimation(workleft > TUNING.GARGOYLE_MINE_LOW and data.anim or (data.anim.."2"))
        end
    end

    local function onworkload(inst)
        inst.AnimState:PlayAnimation(inst.components.workable.workleft > TUNING.GARGOYLE_MINE_LOW and data.anim or (data.anim.."2"))
    end

    local function OnSettled(inst)
        inst._petrifytask = nil
        inst.components.workable:SetWorkable(true)
    end

    local function OnPetrified(inst)
        inst.AnimState:SetBank("sculpture_"..data.name)
        inst.AnimState:SetBuild("sculpture_"..data.name.."_moonrock_build")
        inst.AnimState:PlayAnimation(data.anim.."_pre")
        inst._petrifytask = inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength(), OnSettled)
    end

    local function Petrify(inst)
        if inst._petrifytask == nil then
            inst.components.workable:SetWorkable(false)
            inst.AnimState:SetBank(data.petrify_bank)
            inst.AnimState:SetBuild(data.petrify_build)
            inst.AnimState:PlayAnimation(data.petrify_anim)
            inst._petrifytask = inst:DoTaskInTime(data.petrify_time, OnPetrified)
        end
    end

    local function OnReanimate(inst, moonbase)
        inst.AnimState:PlayAnimation("transform_"..data.anim)
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        RemovePhysicsColliders(inst)
        inst:AddTag("NOCLICK")
        inst.persists = false
        inst._reanimatetask = inst:DoTaskInTime(1, ErodeAway)

        local creature = SpawnPrefab(data.petrify_prefab)
        creature.Transform:SetPosition(inst.Transform:GetWorldPosition())
        creature.Transform:SetRotation(inst.Transform:GetRotation())
        if moonbase ~= nil and moonbase:IsValid() then
            creature.components.entitytracker:TrackEntity("moonbase", moonbase)
        end
        creature.sg:GoToState("reanimate", { anim = data.reanimate_anim, time = data.reanimate_time })
        if data.petrify_anim == "death" then
            creature.components.health:Kill()
        end
    end

    local function Struggle2(inst, moonbase)
        inst.AnimState:PlayAnimation(data.anim.."_pre", true)
        inst._reanimatetask = inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() * math.random(2) - 5 * FRAMES, OnReanimate, moonbase)
    end

    local function Struggle(inst, moonbase)
        inst.AnimState:PlayAnimation(data.anim.."_pre")
        inst._reanimatetask = inst:DoTaskInTime(math.random() * .5 + .5, Struggle2, moonbase)
    end

    local function Reanimate(inst, moonbase)
        if inst._petrifytask ~= nil then
            inst._petrifytask:Cancel()
            inst._petrifytask = nil
        end
        if inst._reanimatetask == nil then
            if inst.components.workable.workleft > TUNING.GARGOYLE_MINE_LOW then
                inst.components.workable:SetWorkable(false)
                inst._reanimatetask = inst:DoTaskInTime(math.random() * 1.5 + .5, Struggle, moonbase)
            else
                inst.components.lootdropper:SetChanceLootTable("broken"..data.name.."_loot")
                crumble(inst)
            end
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.entity:AddTag("gargoyle")

        MakeObstaclePhysics(inst, .9)

        inst.Transform:SetFourFaced()

        inst.AnimState:SetBank("sculpture_"..data.name)
        inst.AnimState:SetBuild("sculpture_"..data.name.."_moonrock_build")
        inst.AnimState:PlayAnimation(data.anim)
        inst.AnimState:SetFinalOffset(1)

        inst:SetPrefabNameOverride("gargoyle_"..data.name)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable("gargoyles_loot")

        inst:AddComponent("inspectable")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.MINE)
        inst.components.workable:SetWorkLeft(TUNING.GARGOYLE_MINE)
        inst.components.workable:SetOnWorkCallback(onwork)
        inst.components.workable:SetOnLoadFn(onworkload)
        inst.components.workable.savestate = true

        MakeHauntableWork(inst)

        inst._petrifytask = nil
        inst._reanimatetask = nil
        inst.Petrify = Petrify
        inst.Reanimate = Reanimate

        return inst
    end

    return Prefab("gargoyle_"..data.name..data.anim, fn, assets, prefabs)
end

local data =
{
    {
        name = "hound",
        anim = "atk",
        petrify_prefab = "moonhound",
        petrify_bank = "hound",
        petrify_build = "hound",
        petrify_anim = "atk_petrify",
        petrify_time = 14 * FRAMES,
        reanimate_anim = "atk_reanimate",
    },
    {
        name = "hound",
        anim = "death",
        petrify_prefab = "moonhound",
        petrify_bank = "hound",
        petrify_build = "hound",
        petrify_anim = "death",
        petrify_time = 14 * FRAMES,
        reanimate_anim = "death",
        reanimate_time = 14 * FRAMES,
    },
    {
        name = "werepig",
        anim = "atk",
        petrify_prefab = "moonpig",
        petrify_bank = "pigman",
        petrify_build = "werepig_build",
        petrify_anim = "were_atk_petrify",
        petrify_time = 16 * FRAMES,
        reanimate_anim = "were_atk_reanimate",
    },
    {
        name = "werepig",
        anim = "death",
        petrify_prefab = "moonpig",
        petrify_bank = "pigman",
        petrify_build = "werepig_build",
        petrify_anim = "death",
        petrify_time = 13 * FRAMES,
        reanimate_anim = "death",
        reanimate_time = 13 * FRAMES,
    },
    {
        name = "werepig",
        anim = "howl",
        petrify_prefab = "moonpig",
        petrify_bank = "pigman",
        petrify_build = "werepig_build",
        petrify_anim = "howl",
        petrify_time = 29 * FRAMES,
        reanimate_anim = "howl",
        reanimate_time = 29 * FRAMES,
    },
}

local t = {}
for i, v in ipairs(data) do
    table.insert(t, makegargoyle(v))
end
data = nil
return unpack(t)
