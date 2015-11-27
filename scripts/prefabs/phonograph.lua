local assets =
{
    Asset("ANIM", "anim/phonograph.zip"),
}

local WORLD_UNLOCK_DB_RECORD = "d9ney"

local function Phonograph(name, frame, description)
    local function onpickup(inst)
        ProfileStatsAddItemChunk("collect:"..WORLD_UNLOCK_DB_RECORD, name)
        inst:Remove()
        local stats = json.encode({ title = "Found!", name = name, description = description })
        TheSim:SendUITrigger(stats)
        return true
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        if not TheWorld.ismastersim then
            return inst
        end

        inst.MiniMapEntity:SetIcon("phonograph.png")

        inst.AnimState:SetBank("phonograph")
        inst.AnimState:SetBuild("phonograph")
        inst.AnimState:PlayAnimation(frame, false)

        inst:AddComponent("inspectable")
        inst.components.inspectable:SetDescription(description)

        inst:AddComponent("inventoryitem")

        if name ~= "phonograph_complete" then
            inst.components.inventoryitem:SetOnPickupFn(onpickup)
        end

        --print("Making phono: ", name, frame, description)
        return inst
    end

    return Prefab("common/objects/treasure/"..name, fn, assets)
end

return Phonograph("phonograph_gears", "gears", "This looks like it might be useful to make something fun."),
		Phonograph("phonograph_box", "box", "Mysteriouser and mysteriouser... maybe I should keep it for later."),
		Phonograph("phonograph_crank", "crank", "I wonder what this is for? Probably part of some nefarious doomsday device."),
		Phonograph("phonograph_cone", "cone", "Its either a fnny shaped trumpet or a hearing aid for a person signignificantly hard of hearing."),
		Phonograph("phonograph_complete", "complete", "A fully assempled phonograph! Good times ahead!")