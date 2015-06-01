--------------------------------------------------------------------------
--Common interface
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--Server interface
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--Client interface
--------------------------------------------------------------------------

local function OnRemoveEntity(inst)
    if inst._parent ~= nil then
        inst._parent.writeable_classified = nil
    end
end

local function OnEntityReplicated(inst)
    inst._parent = inst.entity:GetParent()
    if inst._parent == nil then
        print("Unable to initialize classified data for writeable")
    elseif inst._parent.replica.writeable ~= nil then
        inst._parent.replica.writeable:AttachClassified(inst)
    else
        inst._parent.writeable_classified = inst
        inst.OnRemoveEntity = OnRemoveEntity
    end
end

--------------------------------------------------------------------------
--Client sync event handlers that translate and dispatch local UI messages
--------------------------------------------------------------------------

--local function RegisterNetListeners(inst)
--end

--------------------------------------------------------------------------
--Client preview actions while waiting for RPC response from server
--------------------------------------------------------------------------


--------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    if TheWorld.ismastersim then
        inst.entity:AddTransform() --So we can follow parent's sleep state
    end
    inst.entity:AddNetwork()
    inst.entity:Hide()
    inst:AddTag("CLASSIFIED")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        --Client interface
        inst.OnEntityReplicated = OnEntityReplicated

        --Delay net listeners until after initial values are deserialized
        --inst:DoTaskInTime(0, RegisterNetListeners)
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("writeable_classified", fn)
