local assets =
{
    Asset("ANIM", "anim/townportaltalisman.zip"),
    Asset("INV_IMAGE", "townportaltalisman_active"),
}

local function DoRiseAnims(inst)
    inst.AnimState:PlayAnimation("active_rise")
    inst.AnimState:PushAnimation("active_loop")
end

local function DoFallAnims(inst)
    inst.AnimState:PlayAnimation("active_fall")
    inst.AnimState:PushAnimation("inactive", false)
end

local function OnLinkTownPortals(inst, other)
    inst.components.teleporter:Target(other)

    if inst.animtask ~= nil then
        inst.animtask:Cancel()
        inst.animtask = nil
    end

    if other ~= nil then
        inst.components.inventoryitem:ChangeImageName("townportaltalisman_active")
        if inst.components.inventoryitem:IsHeld() then
            inst.AnimState:PlayAnimation("active_loop", true)
        else
            if inst.AnimState:IsCurrentAnimation("active_shake2") then
                inst.AnimState:PlayAnimation("active_loop", true)
                inst.AnimState:SetTime(math.random() * inst.AnimState:GetCurrentAnimationLength())
            else
                inst.AnimState:PlayAnimation("active_shake", true)
                inst.animtask = inst:DoTaskInTime(.2 + math.random() * .4, DoRiseAnims)
            end
            inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/talisman_active", "active") 
        end
    else
        inst.components.inventoryitem:ChangeImageName("townportaltalisman")
        if inst.components.inventoryitem:IsHeld() then
            inst.AnimState:PlayAnimation("inactive")
        elseif inst.AnimState:IsCurrentAnimation("active_shake") then
            inst.AnimState:PlayAnimation("inactive")
        else
            inst.AnimState:PlayAnimation("active_shake2", true)
            inst.animtask = inst:DoTaskInTime(.3 + math.random() * .3, DoFallAnims)
        end
        inst.SoundEmitter:KillSound("active")
    end
end

local function OnStartTeleporting(inst, doer)
    if doer:HasTag("player") then
        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end
        if doer.components.sanity ~= nil then
            doer.components.sanity:DoDelta(-TUNING.SANITY_HUGE)
        end
    end

    inst.components.stackable:Get():Remove()
end

local function topocket(inst)
    if inst.animtask ~= nil then
        inst.animtask:Cancel()
        inst.animtask = nil
        if inst.components.teleporter:IsActive() then
            inst.AnimState:PlayAnimation("active_loop", true)
        else
            inst.AnimState:PlayAnimation("inactive")
        end
    end
    inst.SoundEmitter:KillSound("active")
end

local function toground(inst)
    if inst.components.teleporter:IsActive() then
        inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/talisman_active", "active") 
    end
end

local function GetStatus(inst)
    return inst.components.teleporter:IsActive() and "ACTIVE" or nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("townportaltalisman")
    inst.AnimState:SetBuild("townportaltalisman")
    inst.AnimState:PlayAnimation("inactive")

    inst:AddTag("townportaltalisman")
    inst:AddTag("townportal")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -----------------------
    MakeHauntableLaunch(inst)

    -------------------------
    inst:AddComponent("inventoryitem")

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate = OnStartTeleporting
    inst.components.teleporter.offset = 0
    inst.components.teleporter.saveenabled = false
    --inst:ListenForEvent("starttravelsound", StartTravelSound) -- triggered by player stategraph

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    -----------------------------
    inst:ListenForEvent("linktownportals", OnLinkTownPortals)
    inst:ListenForEvent("onputininventory", topocket)
    inst:ListenForEvent("ondropped", toground)

    TheWorld:PushEvent("ms_registertownportal", inst)

    return inst
end

return Prefab("townportaltalisman", fn, assets)
