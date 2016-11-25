require "behaviours/wander"
require "behaviours/panic"

local BrainCommon = {}
--------------------------------------------------------------------------

local TIME_TO_SEEK_SALT = 16

local function OnSaltlickPlaced(inst)
    inst._brainsaltlick = nil
    inst:RemoveEventCallback("saltlick_placed", OnSaltlickPlaced)
end

local function FindSaltlick(inst)
    if inst._brainsaltlick == nil or
        not inst._brainsaltlick:IsValid() or
        not inst:HasTag("saltlick") or
        inst._brainsaltlick:IsInLimbo() or
        (inst._brainsaltlick.components.burnable ~= nil and inst._brainsaltlick.components.burnable:IsBurning()) or
        inst._brainsaltlick:HasTag("burnt") then
        local hadsaltlick = inst._brainsaltlick ~= nil
        inst._brainsaltlick = FindEntity(inst, TUNING.SALTLICK_CHECK_DIST, nil, { "saltlick" }, { "INLIMBO", "fire", "burnt" })
        inst._brainsaltlickplaced = nil
        if inst._brainsaltlick ~= nil then
            if not hadsaltlick then
                inst:ListenForEvent("saltlick_placed", OnSaltlickPlaced)
            end
        elseif hadsaltlick then
            inst:RemoveEventCallback("saltlick_placed", OnSaltlickPlaced)
        end
    end
    return inst._brainsaltlick ~= nil
end

local function WanderFromSaltlickDistFn(inst)
    local t = inst.components.timer ~= nil and (inst.components.timer:GetTimeLeft("salt") or 0) or nil
    return t ~= nil
        and t < TIME_TO_SEEK_SALT
        and Remap(math.max(TIME_TO_SEEK_SALT * .5, t), TIME_TO_SEEK_SALT * .5, TIME_TO_SEEK_SALT, TUNING.SALTLICK_USE_DIST * .75, TUNING.SALTLICK_CHECK_DIST * .75)
        or TUNING.SALTLICK_CHECK_DIST * .75
end

local function ShouldSeekSalt(inst)
    return inst._brainsaltlick ~= nil
        and inst.components.timer ~= nil
        and (inst.components.timer:GetTimeLeft("salt") or 0) < TIME_TO_SEEK_SALT
end

local function AnchorToSaltlick(inst)
    return WhileNode(
        function()
            return FindSaltlick(inst)
        end,
        "Stay Near Salt",
        Wander(inst,
            function()
                return inst._brainsaltlick ~= nil
                    and inst._brainsaltlick:IsValid()
                    and inst._brainsaltlick:GetPosition()
                    or inst:GetPosition()
            end,
            WanderFromSaltlickDistFn)
    )
end

BrainCommon.ShouldSeekSalt = ShouldSeekSalt
BrainCommon.AnchorToSaltlick = AnchorToSaltlick

--------------------------------------------------------------------------

local function PanicWhenScared(inst, loseloyaltychance, chatty)
    local scareendtime = 0

    inst:ListenForEvent("epicscare", function(inst, data)
        scareendtime = math.max(scareendtime, data.duration + GetTime() + math.random())
    end)

    local panicscarednode = Panic(inst)

    if chatty ~= nil then
        panicscarednode = ChattyNode(inst, chatty, panicscarednode)
    end

    if loseloyaltychance ~= nil and loseloyaltychance > 0 then
        panicscarednode = ParallelNode{
            panicscarednode,
            LoopNode({
                WaitNode(3),
                ActionNode(function()
                    if math.random() < loseloyaltychance and
                        inst.components.follower ~= nil and
                        inst.components.follower:GetLoyaltyPercent() > 0 and
                        inst.components.follower:GetLeader() ~= nil then
                        inst.components.follower:SetLeader(nil)
                    end
                end),
            }),
        }
    end

    local scared = false
    return WhileNode(
        function()
            if (GetTime() < scareendtime) ~= scared then
                if inst.components.combat ~= nil then
                    inst.components.combat:SetTarget(nil)
                end
                scared = not scared
            end
            return scared
        end,
        "PanicScared",
        panicscarednode
    )
end

BrainCommon.PanicWhenScared = PanicWhenScared

--------------------------------------------------------------------------
return BrainCommon
