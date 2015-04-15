local assets =
{
	Asset("ANIM", "anim/teleportato_parts.zip"),
	Asset("ANIM", "anim/teleportato_parts_build.zip"),
	Asset("ANIM", "anim/teleportato_adventure_parts_build.zip"),
}

local function makefn(name, frame)
    return function()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
        inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("parts")
        inst.AnimState:PlayAnimation(frame, false)

        inst:AddTag("irreplaceable")
        inst:AddTag("teleportato_part")

        if not TheWorld.ismastersim then
            return inst
        end

        inst.entity:SetPristine()

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")

        if SaveGameIndex:GetCurrentMode(Settings.save_slot) == "adventure" then
	        inst.AnimState:SetBuild("teleportato_adventure_parts_build")
	        inst.components.inventoryitem:ChangeImageName(name.."_adv")
	    else
	        inst.AnimState:SetBuild("teleportato_parts_build")
	    end

		inst:AddComponent("tradable")

		MakeHauntableLaunch(inst)

       	return inst
	end
end

local function TeleportatoPart(name, frame)
    return Prefab("common/inventory/" .. name, makefn(name, frame), assets)
end

return TeleportatoPart("teleportato_ring", "ring"),
		TeleportatoPart("teleportato_box", "lever"),
		TeleportatoPart("teleportato_crank", "support"), 
		TeleportatoPart("teleportato_potato", "potato")