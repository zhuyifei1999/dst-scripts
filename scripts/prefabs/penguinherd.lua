local assets =
{
	--Asset("ANIM", "anim/arrow_indicator.zip"),
}

local prefabs =
{
    "bird_egg",
}

local function InMood(inst)
    -- dprint("::::::::::::::::::::::::::::::Penguinherd enters egg-laying season")
    if inst.components.periodicspawner then
        inst.components.periodicspawner:Start()
    end
    if inst.components.herd then
        for k,v in pairs(inst.components.herd.members) do
            k:PushEvent("entermood")
        end
    end
end

local function LeaveMood(inst)
    -- dprint("::::::::::::::::::::::::::::::Penguinherd LEAVES egg-laying season")
    if inst.components.periodicspawner then
        inst.components.periodicspawner:Stop()
    end
    if inst.components.herd then
        for k,v in pairs(inst.components.herd.members) do
            k:PushEvent("leavemood")
        end
    end
end

local function AddMember(inst, member)
    if inst.components.mood then
        if inst.components.mood:IsInMood() then
            member:PushEvent("entermood")
        else
            member:PushEvent("leavemood")
        end
    end
end

local function OnFull(inst)
end
   
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    --[[
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    if not TheWorld.ismastersim then
        return inst
    end
    --]]
    --[[Non-networked entity]]

    inst:AddTag("herd")

    inst:AddComponent("herd")
    inst.components.herd:SetMemberTag("penguin")
    inst.components.herd:SetGatherRange(40)
    inst.components.herd:SetUpdateRange(20)
    inst.components.herd:SetOnEmptyFn(inst.Remove)
    inst.components.herd:SetOnFullFn(OnFull)
    inst.components.herd:SetAddMemberFn(AddMember)
    inst.components.herd:GatherNearbyMembers()

    inst:AddComponent("mood")
    inst.components.mood:SetMoodTimeInDays(TUNING.PENGUIN_MATING_SEASON_LENGTH, 0)
    inst.components.mood:SetInMoodFn(InMood)
    inst.components.mood:SetLeaveMoodFn(LeaveMood)
    inst.components.mood:CheckForMoodChange()

    return inst
end

return Prefab("forest/animals/penguinherd", fn, assets, prefabs)