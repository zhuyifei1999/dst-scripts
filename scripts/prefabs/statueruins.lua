local assets =
{
    Asset("ANIM", "anim/statue_ruins_small.zip"),
	Asset("ANIM", "anim/statue_ruins_small_gem.zip"),
    Asset("ANIM", "anim/statue_ruins.zip"),
	Asset("ANIM", "anim/statue_ruins_gem.zip"),
}

local prefabs =
{
    "marble",
    "greengem",
    "redgem",
    "bluegem",
    "yellowgem",
    "orangegem",
    "purplegem",
    "nightmarefuel",
}

local gemlist  =
{
    "greengem",
    "redgem",
    "bluegem",
    "yellowgem",
    "orangegem",
    "purplegem",
}

SetSharedLootTable( 'statue_ruins_no_gem',
{
    {'thulecite',     1.00},
    {'nightmarefuel', 1.00},
    {'thulecite',     0.05},
})

local LIGHT_INTENSITY = .25
local LIGHT_RADIUS = 2.5
local LIGHT_FALLOFF = 5
local FADEIN_TIME = 10

local function turnoff(inst, light)
    if light then
        light:Enable(false)
    end
end

local function DoFx(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")

    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("statue_transition_2")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(1, 2, 1)
    end
    fx = SpawnPrefab("statue_transition")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(1, 1.5, 1)
    end
end

local function fade_in(inst)
    inst.Light:Enable(true)
    --DoFx(inst)
    inst.components.lighttweener:StartTween(nil, 3, nil, nil, nil, 0.5) 
end

local function fade_out(inst)
    --DoFx(inst)
    inst.components.lighttweener:StartTween(nil, 0, nil, nil, nil, 1, turnoff) 
end

local function ShowState(inst, phase, fromwork)
    if inst.fading then
        return
    end

    local nclock = GetNightmareClock()
    local suffix = ""
    local workleft = inst.components.workable.workleft

    if inst.small then
        inst.SoundEmitter:PlaySound("dontstarve/common/floating_statue_hum", "hoverloop")
        if inst.gemmed then
            inst.AnimState:OverrideSymbol("swap_gem", "statue_ruins_small_gem", inst.gemmed)
        end
    else
        if inst.gemmed then
            inst.AnimState:OverrideSymbol("swap_gem", "statue_ruins_gem", inst.gemmed)
        end
    end

    if nclock and nclock:IsNightmare() then
        suffix = "_night"
        inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )
        if not fromwork then
            DoFx(inst)
        end
    end

    if phase ~= nil and inst.phase ~= phase and phase ~= "nightmare" then
        if phase == "warn" then
            fade_in(inst)
        elseif phase == "calm" then
            fade_out(inst)
        else
            inst.AnimState:ClearBloomEffectHandle()
            DoFx(inst)
        end
        inst.phase = phase
    end

    if workleft < TUNING.MARBLEPILLAR_MINE / 3 then
        inst.AnimState:PlayAnimation("hit_low"..suffix, true)
    elseif workleft < TUNING.MARBLEPILLAR_MINE * 2 / 3 then
        inst.AnimState:PlayAnimation("hit_med"..suffix, true)
    else
        inst.AnimState:PlayAnimation("idle_full"..suffix, true)
    end
end

local function OnWork(inst, worked, workleft)
    if workleft <= 0 then
        inst.SoundEmitter:KillSound("hoverloop")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
        inst.components.lootdropper:DropLoot(inst:GetPosition())
	    SpawnAt("collapse_small", inst)

        local nclock = GetNightmareClock()
        if nclock and nclock:IsNightmare() then
            if math.random() <= 0.3 then
                if math.random() <= 0.5 then
                    SpawnAt("crawlingnightmare", inst)
                else
                    SpawnAt("nightmarebeak", inst)
                end
            end
        end

        inst:Remove()
    else                
        ShowState(inst, nil, true)
    end
end

local function commonfn(small)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.66)

    if small then
        inst.AnimState:SetBank("statue_ruins_small")
        inst.AnimState:SetBuild("statue_ruins_small")
    else
        inst.AnimState:SetBank("statue_ruins")
        inst.AnimState:SetBuild("statue_ruins")
    end

    inst.MiniMapEntity:SetIcon("statue_ruins.png")

    inst:AddTag("structure")

    --Sneak these into pristine state for optimization
    inst:AddTag("_named")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.entity:SetPristine()

    --Remove these tags so that they can be added properly when replicating components below
    inst:RemoveTag("_named")

    inst.small = small
    inst.fadeout = fade_out
    inst.fadein = fade_in

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "ANCIENT_STATUE"
    inst:AddComponent("named")
    inst.components.named:SetName(STRINGS.NAMES["ANCIENT_STATUE"])

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.MARBLEPILLAR_MINE)
    inst.components.workable:SetOnWorkCallback(OnWork)

    inst:AddComponent("fader")
    
    inst:AddComponent("lighttweener")
    inst.components.lighttweener:StartTween(inst.Light, 1, .9, 0.9, {255/255,255/255,255/255}, 0, turnoff)

    inst:AddComponent("lootdropper")

    if GetNightmareClock() then
	    inst:WatchWorldState("phase", ShowState)
    end

    inst:DoTaskInTime(1 * FRAMES, ShowState)
    
	--fade_in(inst,0)

    return inst
end

local function gem(small)
    local inst = commonfn(small)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.gemmed = GetRandomItem(gemlist)

    if small then
        inst.AnimState:OverrideSymbol("swap_gem", "statue_ruins_small_gem", inst.gemmed)
    else
        inst.AnimState:OverrideSymbol("swap_gem", "statue_ruins_gem", inst.gemmed)
    end

    inst.components.lootdropper:SetLoot({ "thulecite", inst.gemmed })
    inst.components.lootdropper:AddChanceLoot("thulecite", 0.05)

    return inst
end

local function nogem(small)
    local inst = commonfn(small)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.lootdropper:SetChanceLootTable('statue_ruins_no_gem')

    return inst
end

return Prefab("cave/objects/ruins_statue_head", function() return gem(true) end, assets, prefabs),
       Prefab("cave/objects/ruins_statue_head_nogem", function() return nogem(true) end, assets, prefabs),
       Prefab("cave/objects/ruins_statue_mage", function() return gem() end, assets, prefabs),
       Prefab("cave/objects/ruins_statue_mage_nogem", function() return nogem() end, assets, prefabs)