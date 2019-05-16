local function onissailraised(self, issailraised)
	if issailraised then
		self.inst:RemoveTag("saillowered")
		self.inst:AddTag("sailraised")
	else
		self.inst:RemoveTag("sailraised")
		self.inst:AddTag("saillowered")
	end
end

local Mast = Class(function(self, inst)
    self.inst = inst
    self.is_sail_raised = false
    self.sail_force = 0.4
    self.has_speed = false
    self.lowered_anchor_count = 0
    self.boat = nil
    self.rudder = nil

    self.inst:StartUpdatingComponent(self)

    self.inst:ListenForEvent("onsink", function(inst) self:OnSink() end)

    self.inst:DoTaskInTime(0,
    	function() 
    		local mast_x, mast_y, mast_z = self.inst.Transform:GetWorldPosition()
    		self:SetBoat(TheWorld.Map:GetPlatformAtPoint(mast_x, mast_z))
            self:SetRudder(SpawnPrefab('rudder'))
    	end)
end,
nil,
{	
    is_sail_raised = onissailraised,
})

function Mast:SetBoat(boat)
    if boat ~= nil then
        self.boat = boat
        self.boat.components.boatphysics:AddMast(self)
        self.boat:ListenForEvent("onbuilt", function(inst, data)  self:OnBuilt(data.builder, data.pos) end)
        self.boat:ListenForEvent("deployed", function(inst, data)  self:OnBuilt(data.deployer, data.pos) end)
        self.boat:ListenForEvent("death", function() self:OnDeath() end)
    end
end

function Mast:OnSink()
    self.inst:Remove()
end

function Mast:SetRudder(obj)
    self.rudder = obj;
    obj:ListenForEvent("onsink", function() obj:Remove() end, self.inst)
    self.inst:ListenForEvent("onremove", function(e) if e == self.rudder then self.rudder = nil end end, obj)  
    obj.entity:SetParent(self.inst.entity)
    obj.Transform:SetPosition(0,0,0)
    obj.AnimState:SetSortOrder(ANIM_SORT_ORDER.OCEAN_BOAT)
    obj.AnimState:SetFinalOffset(2)
    obj.Transform:SetRotation(90)
end

function Mast:OnDeath()
	self.sinking = true

    self.inst.SoundEmitter:KillSound("boat_movement")
end

function Mast:RaiseSail()
	if self.is_sail_raised then return end

	self.inst.AnimState:PlayAnimation("open2_pre")
	self.inst.AnimState:PushAnimation("open2_loop", true)

    self.inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/mast/sail_open")    

	self.is_sail_raised = true
end

function Mast:LowerSail()
	if not self.is_sail_raised then return end

	self.inst.AnimState:PushAnimation("open2_pst", false)	
	self.inst.AnimState:PushAnimation("open1_pst", false)	

    self.inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/mast/sail_open")    

	self.is_sail_raised = false
end

function Mast:OnUpdate(dt)
	if self.boat == nil then return end

    local mast_x, mast_y, mast_z = self.inst.Transform:GetWorldPosition()

    local boat_physics = self.boat.components.boatphysics

    local rudder_direction_x, rudder_direction_z = boat_physics.rudder_direction_x, boat_physics.rudder_direction_z

	self.inst:FacePoint(rudder_direction_x + mast_x, 0, rudder_direction_z + mast_z)
end

return Mast
