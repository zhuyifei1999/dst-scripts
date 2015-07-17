local function PostInit(inst)
    inst:LongUpdate(0)
    inst.entity:FlushLocalDirtyNetVars()

    for k, v in pairs(inst.components) do
        if v.OnPostInit then
            v:OnPostInit()
        end
    end
end

local function OnRemoveEntity(inst)
    if TheWorld ~= nil then
        assert(TheWorld.net == inst)
        TheWorld.net = nil
    end
end

local function DoPostInit(inst)
    if not TheWorld.ismastersim then
        --master sim would have already done a proper PostInit in loading
        TheWorld:PostInit()
    end
    if not TheNet:IsDedicated() and ThePlayer == nil then
        TheNet:SendResumeRequestToServer(TheNet:GetUserID())
    end
    
    PlayerHistory:StartListening()
end

local function fn()
    local inst = CreateEntity()
    
    assert(TheWorld ~= nil and TheWorld.net == nil)
    TheWorld.net = inst

    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddNetwork()
    inst:AddTag("CLASSIFIED")
    inst.entity:SetPristine()

    inst:AddComponent("autosaver")
    inst:AddComponent("clock")
    inst:AddComponent("weather")
    inst:AddComponent("seasons")
    inst:AddComponent("worldreset")
    --inst:AddComponent("voting")
    inst:AddComponent("voter")

    inst.PostInit = PostInit
    inst.OnRemoveEntity = OnRemoveEntity

    inst:DoTaskInTime(0, DoPostInit)

    return inst
end

return Prefab("world_network", fn)