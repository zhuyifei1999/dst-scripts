local function UpdatePosition(inst, target)
    local x, y, z = target.Transform:GetWorldPosition()
    if inst._x ~= x or inst._z ~= z then
        inst._x = x
        inst._z = z
        inst.Transform:SetPosition(x, 0, z)
    end
end

local function TrackEntity(inst, target, restriction, icon)
    if restriction ~= nil then
        inst.MiniMapEntity:SetRestriction(restriction)
    end
    inst.MiniMapEntity:SetIcon(icon or (target.prefab..".png"))
    inst:ListenForEvent("onremove", function() inst:Remove() end, target)
    inst:DoPeriodicTask(0, UpdatePosition, nil, target)
    UpdatePosition(inst, target)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst:AddTag("CLASSIFIED")

    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)
    inst.MiniMapEntity:SetIsProxy(true)

    inst.entity:SetCanSleep(false)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._target = nil
    inst.TrackEntity = TrackEntity

    inst.persists = false

    return inst
end

return Prefab("globalmapicon", fn)
