local PopupDialogScreen = require "screens/popupdialog"

local assets =
{
    Asset("ANIM", "anim/cave_exit.zip"),
}

local function close(inst)
    inst.AnimState:PlayAnimation("no_access", true)
end

local function open(inst)
    inst.AnimState:PlayAnimation("open", true)
end

local function full(inst)
    inst.AnimState:PlayAnimation("over_capacity", true)
end

local function activate(inst)
    -- nothing
end

local function GetStatus(inst)
    if inst.components.worldmigrator:IsActive() then
        return "OPEN"
    elseif inst.components.worldmigrator:IsFull() then
        return "FULL"
    end
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter() 
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 2)

    inst.MiniMapEntity:SetIcon("cave_open2.png")

    inst.AnimState:SetBank("cave_stairs")
    inst.AnimState:SetBuild("cave_exit")
    inst.AnimState:PlayAnimation("open")

    inst:AddTag("sinkhole")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("worldmigrator")
    inst:ListenForEvent("migration_available", open)
    inst:ListenForEvent("migration_unavailable", close)
    inst:ListenForEvent("migration_full", full)
    inst:ListenForEvent("migration_activate", activate)

    return inst
end

return Prefab("common/cave_exit", fn, assets)
