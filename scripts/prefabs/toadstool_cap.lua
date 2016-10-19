local assets =
{
    Asset("ANIM", "anim/toadstool_actions.zip"),
    Asset("ANIM", "anim/toadstool_build.zip"),
    Asset("MINIMAP_IMAGE", "toadstool_hole"),
}

local prefabs =
{
    "toadstool",
}

local function onworked(inst, worker)
    if not (worker ~= nil and worker:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_mushroom")
    end
    inst.AnimState:PlayAnimation("mushroom_toad_hit")
end

local function tracktoad(inst, toadstool)
    local function onremovetoad()
        if inst._state:value() == 0 then
            inst.components.timer:StartTimer("respawn", 2 + math.random())
        end
    end
    inst:ListenForEvent("onremove", onremovetoad, toadstool)
    inst:ListenForEvent("death", function(toadstool)
        inst:RemoveEventCallback("onremove", onremovetoad, toadstool)
        if inst.components.entitytracker:GetEntity("toadstool") == toadstool then
            inst.components.entitytracker:ForgetEntity("toadstool")
        end
        inst:PushEvent("toadstoolkilled", toadstool)
    end, toadstool)
end

local setstate

local function onspawntoad(inst)
    inst:RemoveEventCallback("animover", onspawntoad)
    inst.SoundEmitter:PlaySound("dontstarve/common/mushroom_up")

    local toadstool = SpawnPrefab("toadstool")
    inst.components.entitytracker:TrackEntity("toadstool", toadstool)
    tracktoad(inst, toadstool)
    setstate(inst, 0)

    toadstool.Transform:SetPosition(inst.Transform:GetWorldPosition())
    toadstool.sg:GoToState("surface")
end

local function onworkfinished(inst)
    inst.components.workable:SetWorkable(false)
    if inst.AnimState:IsCurrentAnimation("mushroom_toad_hit") then
        inst:ListenForEvent("animover", onspawntoad)
    else
        onspawntoad(inst)
    end
end

local function ongrown(inst)
    inst:RemoveEventCallback("animover", ongrown)
    inst.MiniMapEntity:SetIcon("toadstool_cap.png")
    inst.AnimState:PlayAnimation("mushroom_toad_idle_loop", true)
    inst:AddComponent("workable")
    inst.components.workable:SetWorkLeft(3)
    inst.components.workable:SetOnWorkCallback(onworked)
    inst.components.workable:SetOnFinishCallback(onworkfinished)
end

local function ongrowing(inst)
    inst:RemoveEventCallback("animqueueover", ongrowing)
    inst.SoundEmitter:PlaySound("dontstarve/common/mushroom_up")
    inst.AnimState:PlayAnimation("spawn_appear_mushroom")
    inst:ListenForEvent("animover", ongrown)
end

local function ontimerdone(inst, data)
    if data.name == "respawn" then
        setstate(inst, 2)
    end
end

setstate = function(inst, state)
    state = (state == 1 or state == 2) and state or 0
    if state ~= inst._state:value() then
        if inst._state:value() == 0 then
            inst:RemoveEventCallback("timerdone", ontimerdone)
            inst.components.timer:StopTimer("respawn")
        elseif inst._state:value() == 2 then
            if inst.components.workable ~= nil then
                inst:RemoveComponent("workable")
                inst:RemoveEventCallback("animover", onspawntoad)
            else
                inst:RemoveEventCallback("animqueueover", ongrowing)
                inst:RemoveEventCallback("animover", ongrown)
            end
        end
        if state == 0 then
            inst.MiniMapEntity:SetIcon("toadstool_hole.png")
            inst.AnimState:SetLayer(LAYER_BACKGROUND)
            inst.AnimState:SetSortOrder(3)
            inst.AnimState:PlayAnimation("picked")
            inst:ListenForEvent("timerdone", ontimerdone)
        elseif state == 1 then
            inst.MiniMapEntity:SetIcon("toadstool_cap.png")
            inst.AnimState:SetLayer(LAYER_WORLD)
            inst.AnimState:SetSortOrder(0)
            inst.AnimState:PlayAnimation("inground")
        elseif POPULATING then
            inst.AnimState:SetLayer(LAYER_WORLD)
            inst.AnimState:SetSortOrder(0)
            ongrown(inst)
        elseif inst._state:value() == 0 then
            inst.AnimState:SetLayer(LAYER_WORLD)
            inst.AnimState:SetSortOrder(0)
            inst.AnimState:PlayAnimation("open_inground")
            inst:ListenForEvent("animqueueover", ongrowing)
        else
            inst.AnimState:PlayAnimation("inground_pre")
            inst.AnimState:PushAnimation("open_inground", false)
            inst:ListenForEvent("animqueueover", ongrowing)
        end
        inst._state:set(state)
        inst:PushEvent("toadstoolstatechanged", state)
    end
end

local function getstatus(inst)
    return (inst._state:value() == 0 and "EMPTY")
        or (inst._state:value() == 1 and "INGROUND")
        or nil
end

local function displaynamefn(inst)
    return inst._state:value() == 0 and STRINGS.NAMES.TOADSTOOL_HOLE or nil
end

local function onsave(inst, data)
    data.state = inst._state:value() > 0 and inst._state:value() or nil
end

local function onload(inst, data)
    if data ~= nil and data.state ~= nil then
        setstate(inst, data.state)
    end
end

local function onloadpostpass(inst)
    local toadstool = inst.components.entitytracker:GetEntity("toadstool")
    if toadstool ~= nil then
        tracktoad(inst, toadstool)
    end
end

local function hastoadstool(inst)
    return inst._state:value() > 0 or inst.components.entitytracker:GetEntity("toadstool") ~= nil
end

local function ontriggerspawn(inst)
    setstate(inst, 2)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("toadstool_hole.png")

    inst.Transform:SetSixFaced()

    inst.AnimState:SetBank("toadstool")
    inst.AnimState:SetBuild("toadstool_build")
    inst.AnimState:PlayAnimation("picked")
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    --DO THE PHYSICS STUFF MANUALLY SO THAT WE CAN SHUT OFF THE BOSS COLLISION.
    --don't yell at me plz...
    --MakeObstaclePhysics(inst, .5)
    ----------------------------------------------------
    inst:AddTag("blocker")
    inst.entity:AddPhysics()
    inst.Physics:SetMass(0) 
    inst.Physics:SetCapsule(.5, 2)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    --inst.Physics:CollidesWith(COLLISION.GIANTS)
    ----------------------------------------------------

    inst._state = net_tinybyte(inst.GUID, "toadstool_cap._state")

    inst.displaynamefn = displaynamefn

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("entitytracker")

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("timer")
    inst:ListenForEvent("timerdone", ontimerdone)

    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.OnLoadPostPass = onloadpostpass

    inst.HasToadstool = hastoadstool

    TheWorld:PushEvent("ms_registertoadstoolspawner", inst)
    inst:ListenForEvent("ms_spawntoadstool", ontriggerspawn)

    return inst
end

return Prefab("toadstool_cap", fn, assets, prefabs)
