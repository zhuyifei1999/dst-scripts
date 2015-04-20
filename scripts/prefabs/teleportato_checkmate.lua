local assets =
{
    Asset("ANIM", "anim/teleportato.zip"),
    Asset("ANIM", "anim/teleportato_build.zip"),
    Asset("ANIM", "anim/teleportato_adventure_build.zip"),
}

local function reset(inst)
    inst.activatedonce = false
    inst.components.activatable.inactive = true
    inst.AnimState:PlayAnimation("idle_off", true)
end

local function dolaugh(inst)
    inst.AnimState:PlayAnimation("laugh", false)
    inst.AnimState:PushAnimation("active_idle", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_maxwelllaugh", "teleportato_laugh")
    TheFrontEnd:Fade(false, 3)
end

local function dowakeup(inst, wilson)
    wilson.sg:GoToState("wakeup")
    TheFrontEnd:Fade(true, 3)
    reset(inst)
end

local function doonsave(inst, wilson)
    if inst.teleportposition then
        inst:DoTaskInTime(3, dowakeup, wilson)
        ThePlayer.Transform:SetPosition(inst.teleportposition.Transform:GetWorldPosition())
        local puppet = TheSim:FindFirstEntityWithTag("maxwellthrone")
        if puppet and puppet.puppet then 
            puppet = puppet.puppet
            if puppet.telefail then puppet.telefail(puppet) end
        end
    end
end

local function DoTeleport(inst, wilson) 
    wilson.sg:GoToState("teleportato_teleport") 

    local function onsave()
        scheduler:ExecuteInTime(110 * FRAMES, dolaugh, nil, inst)
        scheduler:ExecuteInTime(110 * FRAMES + 3, doonsave, nil, inst, wilson)
    end

    wilson.profile:Save(onsave) 
end

local function GetStatus()
    return "ACTIVE"
end

local function PlayActivateSound(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_activate_mouth", "teleportato_activatemouth")
end

local function OnActivate(inst)
    inst.components.activatable.inactive = false
    if not inst.activatedonce then
        inst.activatedonce = true
        inst.AnimState:PlayAnimation("activate", false)
        inst.AnimState:PushAnimation("active_idle", true)
        inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_activate", "teleportato_activate")
        inst.SoundEmitter:KillSound("teleportato_idle")
        inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_activeidle_LP", "teleportato_active_idle")

        inst:DoTaskInTime(40 * FRAMES, PlayActivateSound)
        --inst:DoTaskInTime(2, DoTeleport, ThePlayer)
    end

end

local function PowerUp(inst)
    inst.AnimState:PlayAnimation("power_on", false)
    inst.AnimState:PushAnimation("idle_on", true)

    inst.components.activatable.inactive = true

    inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_powerup", "teleportato_on")
    inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_idle_LP", "teleportato_idle")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1.1)

    inst:AddTag("teleportato")

    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetIcon("teleportato.png")
    inst.MiniMapEntity:SetPriority(1)

    inst.AnimState:SetBank("teleporter")
    inst.AnimState:SetBuild("teleportato_adventure_build")
    inst.AnimState:PlayAnimation("idle_off", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst.components.inspectable.nameoverride = "teleportato_base"
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("activatable")    
    inst.components.activatable.OnActivate = OnActivate
    inst.components.activatable.inactive = true
    inst.components.activatable.quickaction = true

    inst.teleportposition = TheSim:FindFirstEntityWithTag("teleportlocation")

    return inst
end

return Prefab("common/objects/teleportato_checkmate", fn, assets)