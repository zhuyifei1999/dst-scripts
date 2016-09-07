local function settrap_hounds(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 20)
    local staff_hounds = {}
    for k,v in pairs(ents) do
        if v and v.sg and v:HasTag("hound") then
            v.components.sleeper.hibernate = true
            v.sg:GoToState("forcesleep")
            table.insert(staff_hounds, v)
        end
    end
    return staff_hounds
end

local function TriggerTrap(inst, scenariorunner, data, hounds)
    --Here we wake the dogs up if they exist then stop waiting to spring the trap.
    local player = data.player
    if player and player.components.sanity then player.components.sanity:DoDelta(-TUNING.SANITY_HUGE) end
    TheWorld:PushEvent("ms_forceprecipitation", true)
    for wakeup = 1, #hounds do
        if hounds[wakeup].components.sleeper then hounds[wakeup].components.sleeper.hibernate = false end
        inst:DoTaskInTime(math.random(1,3), function() if hounds[wakeup] and hounds[wakeup].sg then hounds[wakeup].sg:GoToState("wake") end end)
    end
    scenariorunner:ClearScenario()
end

local function OnLoad(inst, scenariorunner)
    local hounds = settrap_hounds(inst)
    inst.scene_putininventoryfn = function(inst, owner)
        TriggerTrap(
            inst,
            scenariorunner,
            { player = owner ~= nil and owner.components.inventoryitem ~= nil and owner.components.inventoryitem:GetGrandOwner() or owner },
            hounds
        )
    end
    inst:ListenForEvent("onputininventory", inst.scene_putininventoryfn)
end

local function OnDestroy(inst)
    if inst.scene_putininventoryfn then
        inst:RemoveEventCallback("onputininventory", inst.scene_putininventoryfn)
        inst.scene_putininventoryfn = nil
    end
end

return
{
    OnLoad = OnLoad,
    OnDestroy = OnDestroy,
}
