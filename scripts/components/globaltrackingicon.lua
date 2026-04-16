--V2C: Use this for tracking a (moving) icon globally for one player.
--     Can also be seen by maprevealers or other players when nearby.
--
--*See globalmapicon.lua::MakeGlobalTrackingIcons

local GlobalTrackingIcon = Class(function(self, inst)
	self.inst = inst
	self.globalicon = nil
	self.revealableicon = nil
	self.owner = nil
end)

local function OnFarRevealableIconCreated(inst, icon)
	icon:SetAsProxyExcludingOwner(inst.components.globaltrackingicon.owner)
end

function GlobalTrackingIcon:StartTracking(owner, name)
	self.owner = owner

	name = name or self.inst.prefab

	--disable the cacheable icon
	if self.inst.MiniMapEntity then
		self.inst.MiniMapEntity:SetEnabled(false)
	end

	--globalicon is only seen by the sender
	if self.globalicon == nil then
		self.globalicon = SpawnPrefab(name.."_globalicon")
		self.globalicon:TrackEntity(self.inst)
	end
	self.globalicon:SetClassifiedOwner(owner)

	--near revealable icon seen by NOT the sender
	local revealableiconname = name.."_revealableicon"
	if self.revealableicon == nil then
		self.revealableicon = SpawnPrefab(revealableiconname)
		self.revealableicon.entity:SetParent(self.inst.entity)
	end
	self.revealableicon:SetAsNonProxyExcludingOwner(owner)

	--far revealable icon seen by NOT the sender
	if self.inst.components.maprevealable == nil then
		self.inst:AddComponent("maprevealable")
		self.inst.components.maprevealable:SetIconPrefab(revealableiconname)
		self.inst.components.maprevealable:SetOnIconCreatedFn(OnFarRevealableIconCreated)
	elseif self.inst.components.maprevealable.icon and self.inst.components.maprevealable.icon.prefab == revealableiconname then
		self.inst.components.maprevealable.icon:SetAsProxyExcludingOwner(owner)
	end
end

function GlobalTrackingIcon:StopTracking()
	if self.inst.MiniMapEntity then
		self.inst.MiniMapEntity:SetEnabled(true)
	end

	if self.globalicon then
		self.globalicon:Remove()
		self.globalicon = nil
	end

	if self.revealableicon then
		self.revealableicon:Remove()
		self.revealableicon = nil
	end

	self.inst:RemoveComponent("maprevealable")
	self.owner = nil
end

GlobalTrackingIcon.OnRemoveFromEntity = GlobalTrackingIcon.StopTracking

return GlobalTrackingIcon
