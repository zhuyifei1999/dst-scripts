local function AttachToEntity(inst, entity)
    inst.entity:SetParent(entity)
    TheCamera:SetDefault()
    TheCamera:Snap()
end

local function fn()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:Hide()
    inst:AddTag("CLASSIFIED")

    inst.persists = false

    inst:ListenForEvent("playeractivated", function(world, player) AttachToEntity(inst, player.entity) end, TheWorld)
    inst:ListenForEvent("playerdeactivated", function() AttachToEntity(inst, nil) end, TheWorld)

    return inst
end

return Prefab("focalpoint", fn)