local prefabs = 
{
}

local assets =
{
    Asset("ANIM", "anim/tentacle_pillar.zip"),
    Asset("SOUND", "sound/tentacle.fsb"),
	Asset("MINIMAP_IMAGE", "tentapillar"),
}

local function PillarEmerge(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local pillar = SpawnPrefab("tentacle_pillar")
    pillar.Transform:SetPosition(x,y,z)
    local other = inst.components.teleporter.targetTeleporter
    if other then
        pillar.components.teleporter:Target(other)
        other.components.teleporter:Target(pillar)
    end
    pillar:Emerge(true)

    if c_sel() == inst then
        c_select(pillar)
    end
    inst:Remove()
end

local function OnActivate(inst, doer)
    if doer:HasTag("player") then
        ProfileStatsSet("wormhole_used", true)

        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end

        --Sounds are triggered in player's stategraph
    elseif inst.SoundEmitter ~= nil then
        inst.SoundEmitter:PlaySound("dontstarve/cave/tentapiller_hole_throw_item")
    end
end

local function OnActivateByOther(inst, source, doer)
end

local function StartTravelSound(inst, doer)
    inst.SoundEmitter:PlaySound("dontstarve/cave/tentapiller_hole_enter")
    doer:PushEvent("wormholetravel", WORMHOLETYPE.TENTAPILLAR) --Event for playing local travel sound
end

local function OnDoneTeleporting(inst, obj)
    if inst.emergetask ~= nil then
        inst.emergetask:Cancel()
    end

    inst.SoundEmitter:PlaySound("dontstarve/cave/tentapiller_hole_travel_emerge")

    inst.emergetask = inst:DoTaskInTime(1.5, function()
        if inst.components.teleporter.numteleporting == 0
            and inst.emergetime - GetTime() <= 0 then
            PillarEmerge(inst)
        end
    end)

    if obj ~= nil and obj:HasTag("player") then
        obj:DoTaskInTime(1, obj.PushEvent, "wormholespit") -- for wisecracker
    end
end

local function OnAccept(inst, giver, item)
    inst.components.inventory:DropItem(item)
    inst.components.teleporter:Activate(item)
end

local function OnLongUpdate(inst, dt)
    inst.emergetime = inst.emergetime - dt
end

local function OnEntityWake(inst)
    inst.SoundEmitter:PlaySound("dontstarve/tentacle/tentapiller_hiddenidle_LP","loop") 
end

local function OnNear(inst)
    if inst.emergetime - GetTime() <= 0
        and inst.components.teleporter.numteleporting == 0 then
        PillarEmerge(inst)
    end
end

local function OnSave(inst, data)
    if inst.emergetime then
        data.emergetime = inst.emergetime - GetTime()
    end
end

local function OnLoad(inst, data)
    if data and data.emergetime then
        inst.emergetime = data.emergetime + GetTime()
    end
end

local function GetDebugString(inst)
    return string.format("emergetime: %.2f", inst.emergetime - GetTime())
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 2.0, 24)

    -- HACK: this should really be in the c side checking the maximum size of the anim or the _current_ size of the anim instead
    -- of frame 0
    inst.entity:SetAABB(60, 20)

    inst:AddTag("tentacle_pillar")
    inst:AddTag("rocky")

    inst.MiniMapEntity:SetIcon("tentapillar.png")

    inst.AnimState:SetBank("tentaclepillar")
    inst.AnimState:SetBuild("tentacle_pillar")
    inst.AnimState:PlayAnimation("idle_hole", true)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --------------------
    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(10, 30)
    inst.components.playerprox:SetOnPlayerNear(OnNear)
    --inst.components.playerprox:SetOnPlayerFar(OnFar)

    --------------------
    inst:AddComponent("inspectable")

    --------------------
    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate = OnActivate
    inst.components.teleporter.onActivateByOther = OnActivateByOther
    inst.components.teleporter.offset = 0
    inst:ListenForEvent("starttravelsound", StartTravelSound) -- triggered by player stategraph
    inst:ListenForEvent("doneteleporting", OnDoneTeleporting)

    --------------------
    inst:AddComponent("inventory")
    inst:AddComponent("trader")
    inst.components.trader.acceptnontradable = true
    inst.components.trader.onaccept = OnAccept
    inst.components.trader.deleteitemonaccept = false

    --------------------

    inst.emergetime = GetTime()+TUNING.TENTACLE_PILLAR_ARM_EMERGE_TIME

    inst.OnLongUpdate = OnLongUpdate
    inst.OnEntitySleep = OnEntitySleep
    inst.OnEntityWake = OnEntityWake
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.debugstringfn = GetDebugString

    return inst
end

return Prefab("tentacle_pillar_hole", fn, assets, prefabs)
