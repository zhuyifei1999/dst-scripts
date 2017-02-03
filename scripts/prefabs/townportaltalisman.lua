local assets =
{
    Asset("ANIM", "anim/townportaltalisman.zip"),
	Asset("INV_IMAGE", "townportaltalisman_active"),
}

local prefabs =
{
}

local function OnLinkTownPortals(inst, other)
	inst.components.teleporter:Target(other)

	if other ~= nil then
		inst.AnimState:PlayAnimation("active_pre")
		inst.AnimState:PushAnimation("active_loop")
	    inst.components.inventoryitem:ChangeImageName("townportaltalisman_active")
		if not inst.components.inventoryitem:IsHeld() then
			inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/talisman_active", "active")	
		end
	else
		inst.AnimState:PlayAnimation("active_pst")
		inst.AnimState:PushAnimation("inactive", false)
	    inst.components.inventoryitem:ChangeImageName("townportaltalisman")
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

local function OnDropped(inst)
	if inst:HasTag("teleporter") then
		inst.AnimState:PlayAnimation("active_loop", true)
		inst.SoundEmitter:PlaySound("dontstarve/common/together/town_portal/talisman_active", "active")	
	else
		inst.AnimState:PlayAnimation("inactive", false)
		inst.SoundEmitter:KillSound("active")
	end
end

local function GetStatus(inst)
    return inst:HasTag("teleporter") and "ACTIVE"
			or nil
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
    inst:ListenForEvent("ondropped", OnDropped)
    

	TheWorld:PushEvent("ms_registertownportal", inst)

    return inst
end

return Prefab("townportaltalisman", fn, assets, prefabs)
