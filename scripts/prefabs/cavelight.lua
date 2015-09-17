local assets=
{
	Asset("ANIM", "anim/cave_exit_lightsource.zip"),
}

local function OnEntityWake(inst)
    inst.SoundEmitter:PlaySound("dontstarve/cave/forestAMB_spot", "loop")
end

local function OnEntitySleep(inst)
	inst.SoundEmitter:KillSound("loop")
end

local function turnoff(inst, light)
    if light then
        light:Enable(false)
    end
    inst:Hide()
end

local colours = {
    day = {180/255, 195/255, 150/255},
    dusk = {91/255, 164/255, 255/255},
    night = {0,0,0},
    fullmoon = {131/255, 194/255, 255/255},
}

local tint_colours = { }
for k,v in pairs(colours) do
    tint_colours[k] = {}
    for i,colour in ipairs(v) do
        tint_colours[k][i] = colour*0.5
    end
    tint_colours[k][4] = 0 -- alpha, zero for additive blending
end

local phasefunctions = 
{
    day = function(inst)
        inst.Light:Enable(true)
        inst:Show()
        inst.components.lighttweener:StartTween(nil, 5*inst.widthscale, .85, .3, colours.day, 2)
        inst.components.colourtweener:StartTween(tint_colours.day, 2)
        inst.components.hideout:StartSpawning()
    end,

    dusk = function(inst) 
        inst.Light:Enable(true)
        inst.components.lighttweener:StartTween(nil, 5*inst.widthscale, .6, .6, colours.dusk, 4)
        inst.components.colourtweener:StartTween(tint_colours.dusk, 4)
        inst.components.hideout:StopSpawning()
    end,

    night = function(inst) 
        if TheWorld.state.isfullmoon then
            -- Whether full moon or night happens first is uncertain
            inst.components.lighttweener:StartTween(nil, 5*inst.widthscale, .6, .6, colours.fullmoon, 4)
            inst.components.colourtweener:StartTween(tint_colours.fullmoon, 4)
        else
            inst.components.lighttweener:StartTween(nil, 0, 0, 1, colours.night, 6, turnoff)
            inst.components.colourtweener:StartTween(tint_colours.night, 4)
        end
        inst.components.hideout:StopSpawning()
    end,
}

local function OnPhase(inst, phase)
    local fn = phasefunctions[phase]
    if fn then
        fn(inst)
    end
end

local function OnFullMoon(inst)
    if TheWorld.state.isnight then
        -- Whether full moon or night happens first is uncertain
        inst.components.lighttweener:StartTween(nil, 5*inst.widthscale, .6, .6, colours.fullmoon, 4)
        inst.components.colourtweener:StartTween(tint_colours.fullmoon, 4)
    end
end

local function onspawned(inst, child)
    child:PushEvent("fly_back")
end

local function fn(Sim, widthscale)
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    local light = inst.entity:AddLight()

	inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake

    inst.AnimState:SetBank("cavelight")
    inst.AnimState:SetBuild("cave_exit_lightsource")
    inst.AnimState:PlayAnimation("idle_loop", false) -- the looping is annoying
    inst.AnimState:SetLightOverride(1)

    inst.AnimState:SetMultColour(unpack(tint_colours.day))

    inst.Transform:SetScale(2*widthscale, 2, 2*widthscale) -- Art is made small coz of flash weirdness, the giant stage was exporting strangely

    inst:AddTag("NOCLICK")
    inst:AddTag("sinkhole")
    inst:AddTag("batdestination")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:WatchWorldState("cavephase", OnPhase)
    inst:WatchWorldState("startfullmoon", OnFullMoon)

    inst:AddComponent("lighttweener")
    inst.components.lighttweener:StartTween(light, 5*widthscale, .9, .3, colours.day, 0)

    inst:AddComponent("colourtweener")
    inst.components.colourtweener:StartTween(tint_colours.day, 0)

    inst:AddComponent("hideout")
    inst.components.hideout:SetSpawnPeriod(5,4)
    inst.components.hideout:SetSpawnedFn(onspawned)

    inst.widthscale = widthscale

    return inst
end

local function normalfn(Sim)
    return fn(Sim, 1)
end

local function smallfn(Sim)
    return fn(Sim, 0.5)
end

local function tinyfn(Sim)
    return fn(Sim, 0.2)
end

return Prefab( "common/cavelight", normalfn, assets),
       Prefab( "common/cavelight_small", smallfn, assets),
       Prefab( "common/cavelight_tiny", tinyfn, assets)
