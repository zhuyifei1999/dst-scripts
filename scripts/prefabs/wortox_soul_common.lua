local function EndBlockSoulHealFX(v)
    v.blocksoulhealfxtask = nil
end

local function DoHeal(inst)
    local targets = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(AllPlayers) do
        if not (v.components.health:IsDead() or v:HasTag("playerghost")) and
            v.entity:IsVisible() and
            v:GetDistanceSqToPoint(x, y, z) < TUNING.WORTOX_SOULHEAL_RANGE * TUNING.WORTOX_SOULHEAL_RANGE then
            table.insert(targets, v)
        end
    end
    if #targets > 0 then
        local amt = TUNING.HEALING_MED - math.min(8, #targets) + 1
        for i, v in ipairs(targets) do
            --always heal, but don't stack visual fx
            v.components.health:DoDelta(amt, nil, inst.prefab)
            if v.blocksoulhealfxtask == nil then
                v.blocksoulhealfxtask = v:DoTaskInTime(.5, EndBlockSoulHealFX)
                local fx = SpawnPrefab("wortox_soul_heal_fx")
                fx.entity:AddFollower():FollowSymbol(v.GUID, v.components.combat.hiteffectsymbol, 0, -50, 0)
                fx:Setup(v)
            end
        end
    end
end

return {
    DoHeal = DoHeal,
}
