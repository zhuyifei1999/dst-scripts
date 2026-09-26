local assets =
{
    Asset("ANIM", "anim/charliearena_spike.zip"),
}

local prefabs =
{
    "dreadstone",
}

SetSharedLootTable( 'charliearena_spike',
{
    {'dreadstone',  1.00},
})

local AOEUtil = require("aoeutil")

local AOE_TAGSET
local function GetAOEAttackTagSet(inst) -- only if not tied to shrouden (debug)
	if AOE_TAGSET == nil then
		AOE_TAGSET = AOEUtil.AttackTagSet()
		AOE_TAGSET:AppendCantTags("shadowthrall", "shadow", "shadowcreature", "shadowchesspiece", "shadowboss")
		-- AOE_TAGSET:Register() don't register tags for the debug ones
	end
	return AOE_TAGSET
end

local function PlayCrackSound(inst, vol)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/rocks/crack", nil, vol)
end

local function OnSoundTask(inst, vol)
    inst.soundtask = nil
    PlayCrackSound(inst, vol)
end

local AOE_RADIUS = 1.25
local function DoDamage(inst)
    inst.task = nil
    inst:RemoveTag("NOCLICK")
    inst.Physics:SetActive(true)
    inst.components.workable:SetWorkable(true)
    inst.AnimState:SetLayer(LAYER_WORLD)
    inst.AnimState:SetSortOrder(0)
    PlayCrackSound(inst, 1)

    local tagset
    if inst.shrouden and inst.shrouden:IsValid() then
        tagset = inst.shrouden:GetAOEAttackTagSet()
    else
        tagset = GetAOEAttackTagSet(inst)
        inst.shrouden = nil
    end

    local targets = {}
    AOEUtil.WorkAndDig(inst, AOE_RADIUS, targets)
    AOEUtil.Attack(inst, AOE_RADIUS, tagset, targets)
end

local function Spawn(inst)
    inst:Show()
    inst:AddTag("NOCLICK")
    inst.Physics:SetActive(false)
    inst.components.workable:SetWorkable(false)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:PlayAnimation("spike"..inst.variation.."_pre", false)
    inst.AnimState:PushAnimation("spike"..inst.variation.."_loop", true)
    PlayCrackSound(inst, .1)
    inst.soundtask = inst:DoTaskInTime(15 * FRAMES, OnSoundTask, .25)
    inst.task = inst:DoTaskInTime(29 * FRAMES, DoDamage)
end

local function Destroy(inst)
    if inst.destroy_task then
        inst.destroy_task:Cancel()
        inst.destroy_task = nil
    end
    inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_break")
    inst.AnimState:PlayAnimation("spike_pst")
    inst:ListenForEvent("animover", inst.Remove)
    inst.persists = false
end

local function DestroyInTime(inst, time)
    if inst.destroy_task then
        inst.destroy_task:Cancel()
    end
    inst.destroy_task = inst:DoTaskInTime(time, Destroy)
end

local function OnWorkFinished(inst, worker)
    local pt = inst:GetPosition()
    if worker and worker.isplayer then -- loot only from player
        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetChanceLootTable("charliearena_spike")
        inst.components.lootdropper:DropLoot(pt)
    end

    Destroy(inst)
end

local function SetShrouden(inst, shrouden)
    inst.shrouden = shrouden
    inst:ListenForEvent("resetboss", function() inst:Remove() end, shrouden)
end

local function OnShroudenSummon(inst, shrouden)
    inst:Hide()
    inst.Physics:SetActive(false)
    SetShrouden(inst, shrouden)

    inst:DoTaskInTime(math.random() * .5, inst.Spawn)
end

local function KeepTargetFn()
    return false
end

local function OnSave(inst, data)
    data.variation = inst.variation
end

local function OnLoad(inst, data)
    if data and data.variation then
        inst.variation = data.variation
        if inst.variation ~= 1 then
            inst.AnimState:PlayAnimation("spike"..inst.variation.."_loop", true)
        end
    end
end

local function spikefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("charliearena_spike")
    inst.AnimState:SetBuild("charliearena_spike")
    inst.AnimState:PlayAnimation("spike1_loop", true)
    inst.AnimState:SetSymbolLightOverride("dreadstone_red", 1)
    inst.AnimState:SetSymbolLightOverride("ground_light", 1)

    inst:AddTag("groundspike")
    inst:AddTag("toughworker")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.variation = math.random(3)
    if inst.variation ~= 1 then
        inst.AnimState:PlayAnimation("spike"..inst.variation.."_loop", true)
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetOnFinishCallback(OnWorkFinished)
    inst.components.workable:SetMaxWork(TUNING.CHARLIEARENA_SPIKE_WORK)
    inst.components.workable:SetWorkLeft(TUNING.CHARLIEARENA_SPIKE_WORK)
	inst.components.workable:SetRequiresToughWork(true)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.CHARLIEARENA_SPIKE_DAMAGE)
    inst.components.combat.playerdamagepercent = .5
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst.Spawn = Spawn
    inst.Destroy = Destroy
    inst.DestroyInTime = DestroyInTime

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.SetShrouden = SetShrouden
    inst.OnShroudenSummon = OnShroudenSummon

    return inst
end

return Prefab("charliearena_spike", spikefn, assets, prefabs)
