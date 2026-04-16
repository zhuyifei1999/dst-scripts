local easing = require("easing")

local assets =
{
	Asset("ANIM", "anim/wx78_drone_zap.zip"),
	Asset("ANIM", "anim/wagdrone_projectile.zip"),
}

local assets_remote =
{
	Asset("ANIM", "anim/wx78_drone_zap.zip"),
	Asset("ANIM", "anim/swap_wx78_drone_zap_remote.zip"),
	Asset("INV_IMAGE", "wx78_drone_zap_remote_held"),
}

local prefabs =
{
	"wx78_drone_zap_projectile_fx",
}

local prefabs_remote =
{
	"wx78_drone_zap",
}

local function GetInventorySkinImage(skin_build)
    return string.gsub(skin_build, "wx78_dronezap_", "wx78_dronezapremote_")
end

local function OnUpdate(inst, dt)
	local owner = inst.owner:value()
	if owner then
		if inst.AnimState:IsCurrentAnimation("deploy") and inst.AnimState:GetCurrentAnimationFrame() < 10 then
			return
		end
		local pan_gain, heading_gain, distance_gain = TheCamera:GetGains()
		TheCamera:SetGains(15, heading_gain, distance_gain)
		owner:PushEvent("dronevision", { enable = true, source = inst })
	end
	inst:RemoveComponent("updatelooper")
end

local function OnOwnerDirty(inst)
	local owner = inst.owner:value()
	if owner and owner.HUD then
		TheFocalPoint.components.focalpoint:StartFocusSource(inst, "drone_cam", nil, math.huge, math.huge, 10, {
			UpdateFn = function(dt, params, parent, dist_sq)
				local offs = FocalPoint_CalcBaseOffset(dt, params, parent, dist_sq)
				local old = offs.y
				--dampen the hover bobbing
				local hover_miny, hover_maxy, dampen_maxy = 6.7, 7.13, 6.85
				local dampen_y = offs.y
				if dampen_y > hover_miny then
					dampen_y = easing.linear(dampen_y - hover_miny, hover_miny, dampen_maxy - hover_miny, hover_maxy - hover_miny)
				end
				local offs_scrndn1 = -0.4
				local offs_scrndn2 = 0.9
				local offs_y1 = offs.y + 1.5
				local offs_y2 = dampen_y
				if inst.AnimState:IsCurrentAnimation("deploy") then
					local fr = inst.AnimState:GetCurrentAnimationFrame()
					if fr < 10 then
						offs = offs + TheCamera:GetDownVec() * offs_scrndn1
						offs.y = offs_y1
					else
						local numfr = inst.AnimState:GetCurrentAnimationNumFrames()
						local k = (fr - 10) / (numfr - 10)
						offs = offs + TheCamera:GetDownVec() * Lerp(offs_scrndn1, offs_scrndn2, k)
						offs.y = Lerp(offs_y1, offs_y2, k)
					end
				else
					offs = offs + TheCamera:GetDownVec() * offs_scrndn2
					offs.y = offs_y2
				end
				TheCamera:SetOffset(offs)
			end,
		})
		local pan_gain, heading_gain, distance_gain = TheCamera:GetGains()
		TheCamera:SetGains(60, heading_gain, distance_gain)
		if inst.components.updatelooper == nil then
			inst:AddComponent("updatelooper")
			inst.components.updatelooper:AddOnUpdateFn(OnUpdate)
		end
	else
		TheFocalPoint.components.focalpoint:StopFocusSource(inst, "drone_cam")
		if ThePlayer then
			ThePlayer:PushEvent("dronevision", { enable = false, source = inst })
		end
		inst:RemoveComponent("updatelooper")
	end
end

local MAXIMUM_ZAPDRONE_RANGE = 40 -- This is the max before we risk seeing entities pop in and out
local function GetDroneRange(inst, owner) -- This is a common function, make sure code is safe for client and server.
	local range = TUNING.SKILLS.WX78.ZAPDRONE_RANGE_1
	if owner and owner.components.skilltreeupdater then
		if owner.components.skilltreeupdater:IsActivated("wx78_zapdrone_2") then
			range = TUNING.SKILLS.WX78.ZAPDRONE_RANGE_2
		end

		if owner.components.skilltreeupdater:IsActivated("wx78_circuitry_betabuffs_1")
			and owner.GetModuleTypeCount then
			range = range + owner:GetModuleTypeCount("radar") * TUNING.SKILLS.WX78.RADAR_ZAPDRONERANGE
		end
	end

	return math.min(MAXIMUM_ZAPDRONE_RANGE, range)
end

local function UpdateDroneRange(inst, owner)
	inst.range = GetDroneRange(inst, owner)
end

local function SetOwner(inst, owner)
	if not (inst.killed and owner) then
		inst.owner:set(owner)
		UpdateDroneRange(inst, owner)
		OnOwnerDirty(inst)
	end
end

local function Kill(inst)
	if not inst.killed then
		inst.killed = true
		inst:AddTag("CLASSIFIED")
		inst:AddTag("FX")
		inst:AddTag("NOCLICK")
		SetOwner(inst, nil)
		inst.sg:GoToState("collapse")
		inst:ListenForEvent("spawnfaderout", inst.Remove)
		inst.components.spawnfader:FadeOut()
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLight()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()

	--inst.Transform:SetFourFaced() --only use facing model during run states
	inst.MiniMapEntity:SetIcon("wx78_drone_zap.png")

	MakeFlyingCharacterPhysics(inst, 50, 0.4)

	inst.AnimState:SetBank("wx78_drone_zap")
	inst.AnimState:SetBuild("wx78_drone_zap")
	inst.AnimState:PlayAnimation("deploy")
	inst.AnimState:OverrideSymbol("bolt_c", "wagdrone_projectile", "bolt_c")
	inst.AnimState:SetSymbolBloom("bolt_c")
	inst.AnimState:SetSymbolLightOverride("bolt_c", 1)
	inst.AnimState:SetSymbolLightOverride("light_yellow_on", 0.5)
	inst.AnimState:SetSymbolBloom("light_yellow_on")

	inst.Light:SetRadius(0.5)
	inst.Light:SetIntensity(0.8)
	inst.Light:SetFalloff(0.5)
	inst.Light:SetColour(255/255, 255/255, 236/255)
	inst.Light:Enable(false)

	inst:AddTag("rangedweapon")
    inst:AddTag("staysthroughvirtualrooms") -- Maybe follows?

	inst.GetDroneRange = GetDroneRange -- used in zapdroneover

	inst.owner = net_entity(inst.GUID, "wx78_drone_zap.owner", "ownerdirty")

	inst:AddComponent("spawnfader")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("ownerdirty", OnOwnerDirty)

		return inst
	end

	inst.scrapbook_damage = TUNING.SKILLS.WX78.ZAPDRONE_DAMAGE * TUNING.ELECTRIC_DAMAGE_MULT --show dry damage, not immune damage
	inst.scrapbook_nodamage = true -- This disables weapon damage, the above set scrapbook_damage still shows.

	inst.reskin_tool_cannot_target_this = true --must reskin the remote

	inst.AnimState:PushAnimation("idle")

	inst:AddComponent("inspectable")

	--this is just used when we push a 0 damage "attacked" event to draw aggro as a ranged attack
	inst:AddComponent("weapon")
	inst.components.weapon:SetProjectile("wx78_drone_zap_projectile_fx") --dummy, not actually used

	inst.range = TUNING.SKILLS.WX78.ZAPDRONE_RANGE_1

	inst:SetStateGraph("SGwx78_drone_zap")

	inst.SetOwner = SetOwner
	inst.Kill = Kill

	inst.persists = false

	return inst
end

--------------------------------------------------------------------------

local function WatchSkillRefresh(inst, owner) -- Also listens for modules to increase range
	if inst._owner then
		inst:RemoveEventCallback("onactivateskill_server", inst._onskillrefresh, inst._owner)
		inst:RemoveEventCallback("ondeactivateskill_server", inst._onskillrefresh, inst._owner)
		inst:RemoveEventCallback("rangecircuitupdate", inst._oncircuitrefresh, inst._owner)
	end
	inst._owner = owner
	if owner then
		inst:ListenForEvent("onactivateskill_server", inst._onskillrefresh, owner)
		inst:ListenForEvent("ondeactivateskill_server", inst._onskillrefresh, owner)
		inst:ListenForEvent("rangecircuitupdate", inst._oncircuitrefresh, owner)
	end
	inst._onskillrefresh(owner)
	inst._oncircuitrefresh(owner) -- _onskillrefresh already handles what _oncircuitrefresh does, but run it again anyways.
end

local function OnEquip(inst, owner)
	local skin_build = inst:GetSkinBuild()
	if skin_build then
		owner:PushEvent("equipskinneditem", inst:GetSkinName())

		owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_drone_zap_remote", inst.GUID, "swap_wx78_drone_zap_remote")
		owner.AnimState:OverrideItemSkinSymbol("drone_zap_remote_parts", skin_build, "drone_zap_remote_parts", inst.GUID, "swap_wx78_drone_zap_remote")

		inst.components.inventoryitem:ChangeImageName(GetInventorySkinImage(skin_build).."_held")
	else
		owner.AnimState:OverrideSymbol("swap_object", "swap_wx78_drone_zap_remote", "swap_drone_zap_remote")
		owner.AnimState:OverrideSymbol("drone_zap_remote_parts", "swap_wx78_drone_zap_remote", "drone_zap_remote_parts")

		inst.components.inventoryitem:ChangeImageName("wx78_drone_zap_remote_held")
	end
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")

	WatchSkillRefresh(inst, owner)
end

local function OnUnequip(inst, owner)
	owner.AnimState:ClearOverrideSymbol("drone_zap_remote_parts")
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")

	if inst.components.useableequippeditem and inst.components.useableequippeditem:IsInUse() then
		inst.components.useableequippeditem:StopUsingItem(owner)
	end

	local skin_build = inst:GetSkinBuild()
	if skin_build then
		owner:PushEvent("unequipskinneditem", inst:GetSkinName())
		inst.components.inventoryitem:ChangeImageName(GetInventorySkinImage(skin_build))
	else
		inst.components.inventoryitem:ChangeImageName()
	end

	WatchSkillRefresh(inst, nil)
end

local function OnUse(inst, doer)
    if not IsFlyingPermittedFromPoint(doer.Transform:GetWorldPosition()) then
        return false, "BADPOSITION"
    end

	if inst.drone == nil then
        local dronebuild = inst.linked_skinname and string.gsub(inst.linked_skinname, "wx78_dronezapremote_", "wx78_dronezap_") or nil
		inst.drone = SpawnPrefab("wx78_drone_zap", dronebuild, inst.skin_id)
		local x, y, z = inst.Transform:GetWorldPosition()
		inst.drone.Transform:SetPosition(x, 1.5, z)
		inst:ListenForEvent("ms_drone_zap_fired", function(drone)
			inst.components.finiteuses:Use(
				doer and
				doer.components.skilltreeupdater and
				doer.components.skilltreeupdater:IsActivated("wx78_zapdrone_2") and
				TUNING.SKILLS.WX78.ZAPDRONE_USE_PER_ATTACK_2 or
				TUNING.SKILLS.WX78.ZAPDRONE_USE_PER_ATTACK_1)
		end, inst.drone)
	end
	inst.drone:SetOwner(doer)
end

local function OnStopUse(inst, doer)
	if inst.drone then
		inst.drone:Kill()
		inst.drone = nil
	end
end

local function SetUseable(inst, useable)
	if useable then
		if inst.components.useableequippeditem == nil then
			inst:AddComponent("useableequippeditem")
			inst.components.useableequippeditem:SetOnUseFn(OnUse)
			inst.components.useableequippeditem:SetOnStopUseFn(OnStopUse)
		end
	elseif inst.components.useableequippeditem then
		if inst.components.useableequippeditem:IsInUse() then
			inst.components.useableequippeditem:StopUsingItem()
		end
		inst:RemoveComponent("useableequippeditem")
	end
end

local function CalcBatteryChargeMult(inst, battery)
	local pct = inst.components.finiteuses:GetPercent()
	return math.clamp(1 - pct, 0, 1)
end

local function OnBatteryUsed(inst, battery, mult)
	local oldpct = inst.components.finiteuses:GetPercent()
	if oldpct >= 1 or mult <= 0 then
		return false, "CHARGE_FULL"
	end

	local newpct = math.clamp(oldpct + mult, 0, 1)
	inst.components.finiteuses:SetPercent(newpct)
	SpawnElectricHitSparks(inst, battery, true)

	return true
end

local function OnDroneZapSkinChanged(inst, skin_build)
	if inst.drone then
		TheSim:ReskinEntity(inst.drone.GUID, inst.drone.skinname, inst.linked_skinname, inst.skin_id)
	end
	if skin_build then
		inst.components.inventoryitem:ChangeImageName(inst.components.equippable:IsEquipped() and GetInventorySkinImage(skin_build).."_held" or GetInventorySkinImage(skin_build))
	else
		inst.components.inventoryitem:ChangeImageName(inst.components.equippable:IsEquipped() and "wx78_drone_zap_remote_held" or nil)
	end
end

local function OnRemoveEntity(inst)
	if inst.drone then
		inst.drone:Kill()
		inst.drone = nil
	end
end

local function GetStatus(inst, viewer)
	return viewer
		and viewer.components.skilltreeupdater
		and viewer.components.skilltreeupdater:IsActivated("wx78_zapdrone_1")
		and "CANUSE"
		or nil
end

local function remotefn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("wx78_drone_zap")
	inst.AnimState:SetBuild("wx78_drone_zap")
	inst.AnimState:PlayAnimation("drone_zap_bundle")

	inst:AddTag("donotautopick")
	inst:AddTag("wx_remotecontroller")

	--batteryuser (from batteryuser component) added to pristine state for optimization
	inst:AddTag("batteryuser")

	MakeInventoryFloatable(inst, "med", 0.27, { 0.85, 1, 1 })

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = GetStatus

	inst:AddComponent("inventoryitem")

	inst:AddComponent("equippable")
	inst.components.equippable.restrictedtag = "drone_zap_user"
	inst.components.equippable:SetOnEquip(OnEquip)
	inst.components.equippable:SetOnUnequip(OnUnequip)

	inst:AddComponent("finiteuses")
	inst.components.finiteuses:SetMaxUses(TUNING.SKILLS.WX78.ZAPDRONE_USES)
	inst.components.finiteuses:SetUses(TUNING.SKILLS.WX78.ZAPDRONE_USES)

	inst:AddComponent("batteryuser")
	inst.components.batteryuser:SetChargeMultFn(CalcBatteryChargeMult)
	inst.components.batteryuser:SetOnBatteryUsedFn(OnBatteryUsed)
	inst.components.batteryuser:SetAllowPartialCharge(true)

	MakeHauntableLaunch(inst)

	inst._onskillrefresh = function(owner)
		local skilltreeupdater = owner and owner.components.skilltreeupdater
		SetUseable(inst, skilltreeupdater ~= nil and skilltreeupdater:IsActivated("wx78_zapdrone_1"))
		if inst.drone then
			UpdateDroneRange(inst.drone, owner)
		end
	end

	inst._oncircuitrefresh = function(owner)
		if inst.drone then
			UpdateDroneRange(inst.drone, owner)
		end
	end

	inst.OnDroneZapSkinChanged = OnDroneZapSkinChanged
	inst.OnRemoveEntity = OnRemoveEntity

	return inst
end

return Prefab("wx78_drone_zap", fn, assets, prefabs),
	Prefab("wx78_drone_zap_remote", remotefn, assets_remote, prefabs_remote)
