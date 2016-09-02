chestfunctions = require("scenarios/chestfunctions")
local loot =
{
    {
        item = "green_cap",
        count = 7
    },
    {
        item = "nightsword",
        --initfn = function(inst) inst.components.finiteuses:SetUses(TUNING.NIGHTSWORD_USES*math.random()) end,
        count = 1
    },
    {
        item = "nightmarefuel",
        count = 3
    },
}

local function triggertrap(inst, scenariorunner, data)
    local pt = Vector3(inst.Transform:GetWorldPosition())
    local theta = math.random() * 2 * PI
    local radius = 10
    local steps = 32
    local ground = TheWorld
    local player = data.player

    chestfunctions.AddChestItems(inst, loot)

    local function spawnrock(rock, wander_point)
        rock.Transform:SetPosition( wander_point.x, wander_point.y, wander_point.z )
        if player and player.components.sanity:IsSane() then
            rock.AnimState:PlayAnimation("raise")
            rock.AnimState:PushAnimation("idle_active", true)
        else
            rock.AnimState:PlayAnimation("lower")
            rock.AnimState:PushAnimation("idle_inactive", true)

        end
        local fx = SpawnPrefab("sanity_raise")
        fx.Transform:SetPosition(rock:GetPosition():Get())
    end

    -- Walk the circle trying to find a valid spawn point
    for i = 1, steps do
        local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
        local wander_point = pt + offset

        if ground.Map and ground.Map:GetTileAtPoint(wander_point.x, wander_point.y, wander_point.z) ~= GROUND.IMPASSABLE then
            local rock = SpawnPrefab("sanityrock")
            rock:DoTaskInTime(0.05*i, spawnrock, wander_point)
        end
        theta = theta - (2 * PI / steps)
    end
end

local function OnCreate(inst, scenariorunner)
end

local function OnLoad(inst, scenariorunner)
    chestfunctions.InitializeChestTrap(inst, scenariorunner, triggertrap)
end

local function OnDestroy(inst)
    chestfunctions.OnDestroy(inst)
end

return
{
    OnCreate = OnCreate,
    OnLoad = OnLoad,
    OnDestroy = OnDestroy
}
