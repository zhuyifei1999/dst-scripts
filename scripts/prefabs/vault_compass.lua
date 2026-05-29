local assets =
{
    Asset("ANIM", "anim/vault_compass.zip"),
}

local prefabs =
{
    "vault_compass_marker",
    "vault_compass_visual",
}

local DIRS =
{
	N = 1,
	E = 2,
	S = 3,
	W = 4,
}
local INVERTED = table.invert(DIRS)

local KEY_ROOM_ID = "key1"

local function OnUpdateDirection(inst)
    local vaultroommanager = TheWorld.components.vaultroommanager
    if vaultroommanager then
        local vaultroomid = vaultroommanager:GetVaultRoomId()
        local direction = vaultroomid ~= nil and vaultroommanager:GetClosestDirectionFromRoomToRoom(vaultroomid, KEY_ROOM_ID) or nil

        if direction then
            local shuffleddirections = vaultroommanager.rooms[vaultroomid].shuffleddirections
            local realdirection = shuffleddirections[direction]

            for i, directionname in ipairs(shuffleddirections) do
                if directionname == INVERTED[direction] then
                    realdirection = directionname
                    break
                end
            end

            for teledirection, teleporter in pairs(vaultroommanager.teleporters) do
                if teleporter.components.vault_teleporter:GetUnshuffledDirectionName() == realdirection then
                    inst.marker_pointer.Transform:SetRotation(inst:GetAngleToPoint(teleporter.Transform:GetWorldPosition()) - 90)
                    break
                end
            end
        end
    end
end

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "vault_compass", "swap_vault_compass")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.marker == nil then
        inst.marker = SpawnPrefab("vault_compass_marker")
        inst.marker.entity:SetParent(owner.entity)
        inst.marker.Network:SetClassifiedTarget(owner)

        inst.marker_pointer = SpawnPrefab("vault_compass_visual")
        inst.marker_pointer.Follower:FollowSymbol(inst.marker.GUID, "empty", 0, 0, 0)

        inst.update_direction_task = inst:DoPeriodicTask(0, OnUpdateDirection)
        OnUpdateDirection(inst)
    end

    if owner.components.maprevealable ~= nil then
        owner.components.maprevealable:AddRevealSource(inst, "compassbearer")
    end
    owner:AddTag("compassbearer")
end

local function OnUnequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    if inst.marker ~= nil then
        inst.update_direction_task:Cancel()
        inst.marker:Remove()
        inst.marker_pointer:Remove()
        inst.update_direction_task = nil
        inst.marker = nil
        inst.marker_pointer = nil
    end

    if owner.components.maprevealable ~= nil then
        owner.components.maprevealable:RemoveRevealSource(inst)
    end
    owner:RemoveTag("compassbearer")
end

local function OnEquipToModel(inst, owner, from_ground)
    if inst.pointer ~= nil then
        inst.pointer:Remove()
        inst.pointer = nil
    end
    if owner.components.maprevealable ~= nil then
        owner.components.maprevealable:RemoveRevealSource(inst)
    end
    owner:RemoveTag("compassbearer")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("vault_compass")
    inst.AnimState:SetBuild("vault_compass")
    inst.AnimState:PlayAnimation("idle", true)

    -- inst:AddTag("compass")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    MakeInventoryFloatable(inst, "med", 0.1, 0.6)

    inst.scrapbook_subcat = "tool"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    --inst.components.inspectable.getstatus = GetStatus

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnequip)
    inst.components.equippable:SetOnEquipToModel(OnEquipToModel)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.UNARMED_DAMAGE)

    MakeHauntableLaunch(inst)

    return inst
end

----------------------------------------------

local function markerfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("vault_compass")
    inst.AnimState:SetBuild("vault_compass")
    inst.AnimState:PlayAnimation("empty")

    inst:AddTag("staysthroughvirtualrooms")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end

----------------------------------------------

local function visualpointerfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("archive_resonator")
    inst.AnimState:SetBuild("archive_resonator")
    inst.AnimState:PlayAnimation("idle_marker", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("staysthroughvirtualrooms")
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

----------------------------------------------

return Prefab("vault_compass", fn, assets, prefabs),
    Prefab("vault_compass_marker", markerfn, assets),
    Prefab("vault_compass_visual", visualpointerfn, assets)