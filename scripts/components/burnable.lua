
require("standardcomponents")

local SMOLDER_TICK_TIME = 2

local function SmolderUpdate(inst)
    local burnable = inst.components.burnable

    if burnable.smolder_task then
        burnable.smolder_task:Cancel()
        burnable.smolder_task = nil
    end

    local pos = Vector3(inst.Transform:GetWorldPosition())
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 12, {"propagator"}) -- this radius should be larger than the propogation, so that once there's a lot of blazes in an area, fire starts spreading quickly.
    local nearbyheat = 0
    for _,v in ipairs(ents) do
        if v.components.propagator then
            nearbyheat = nearbyheat + v.components.propagator.currentheat
        end
    end
    local smoldermod = math.clamp(Remap(nearbyheat, 20, 90, 1, 2.2), 1, 2.2) -- smolder about twice as fast if there's lots of heat nearby

    burnable.smoldertimeremaining = burnable.smoldertimeremaining - SMOLDER_TICK_TIME * smoldermod

    if burnable.smoldertimeremaining <= 0 then
        burnable:Ignite()
    else
        burnable.smolder_task = inst:DoTaskInTime(SMOLDER_TICK_TIME, SmolderUpdate)
    end
end

local function OnKilled(inst)
    if inst.components.burnable and inst.components.burnable:IsBurning() and not inst:HasTag("player") then
        inst.AnimState:SetMultColour(.2,.2,.2,1)
    end
end

local function DoneBurning(inst, self)
    RemoveDragonflyBait(inst)

    inst:PushEvent("onburnt")

    if self.onburnt ~= nil then
        self.onburnt(inst)
    end

    if inst.components.explosive ~= nil then
        --explosive explode
        inst.components.explosive:OnBurnt()
    end

    if self.extinguishimmediately then
        self:Extinguish()
    end
end

local function oncanlight(self)
    if not self.burning and self.canlight then
        self.inst:AddTag("canlight")
        self.inst:RemoveTag("nolight")
    else
        self.inst:RemoveTag("canlight")
        self.inst:AddTag("nolight")
    end
end

local function stopsmoldering(inst)
    if self:IsSmoldering() then
        self:StopSmoldering()
    end 
end

local function onrainstart(inst, data)
	inst:DoTaskInTime(2, stopsmoldering)
end

local Burnable = Class(function(self, inst)
    self.inst = inst

    self.flammability = 1

    self.fxdata = {}
    self.fxlevel = 1
    self.fxchildren = {}
    self.burning = false
    self.burntime = nil
    self.extinguishimmediately = true
    self.smoldertimeremaining = nil

    self.onignite = nil
    self.onextinguish = nil
    self.onburnt = nil
    self.canlight = true

    self.lightningimmune = false
    
    self.smoldering = false
    self.inst:ListenForEvent("rainstart", onrainstart, TheWorld)
end,
nil,
{
    burning = oncanlight,
    canlight = oncanlight,
})

--- Set the function that will be called when the object starts burning
function Burnable:SetOnIgniteFn(fn)
    self.onignite = fn
end

--- Set the function that will be called when the object has burned completely
function Burnable:SetOnBurntFn(fn)
    self.onburnt = fn
end

--- Set the function that will be called when the object stops burning
function Burnable:SetOnExtinguishFn(fn)
    self.onextinguish = fn
end

--- Set the prefab to use for the burning effect. Overrides the default
function Burnable:SetBurningFX(name)
    self.fxprefab = name
end

function Burnable:SetBurnTime(time)
    self.burntime = time
end

function Burnable:IsSmoldering()
    return self.smoldering
end

--- Add an effect to be spawned when burning
-- @param prefab The prefab to spawn as the effect
-- @param offset The offset from the burning entity/symbol that the effect should appear at
-- @param followsymbol Optional symbol for the effect to follow
function Burnable:AddBurnFX(prefab, offset, followsymbol)
    table.insert(self.fxdata, {prefab=prefab, x = offset.x, y = offset.y, z = offset.z, follow=followsymbol})
end

--- Set the level of any current or future burning effects
function Burnable:SetFXLevel(level, percent)
    self.fxlevel = level

	for k,v in pairs(self.fxchildren) do
	    if v.components.firefx then
	        v.components.firefx:SetLevel(level)
            v.components.firefx:SetPercentInLevel(percent or 1)
        end
	end
end

function Burnable:GetLargestLightRadius()
    local largestRadius = nil
    for k,v in pairs(self.fxchildren) do
        if v.Light and v.Light:IsEnabled() then
            local radius = v.Light:GetCalculatedRadius()
            if not largestRadius or radius > largestRadius then
                largestRadius = radius
            end
        end
    end
    return largestRadius
end

function Burnable:IsBurning()
    return self.burning
end

function Burnable:GetDebugString()
    if self.smoldering then
        return string.format("SMOLDERING %.2f", self.smoldertimeremaining)
    elseif self.burning then
        return "BURNING"
    else
        return "NOT BURNING"
    end
end

function Burnable:OnRemoveEntity()
	self:StopSmoldering()
	self:KillFX()
end

function Burnable:StartWildfire()
    if not self.burning and not self.smoldering and not self.inst:HasTag("fireimmune") then
        self.smoldering = true
        self.inst:AddTag("smolder")
        self.smoke = SpawnPrefab("smoke_plant")
        if self.smoke then
            if #self.fxdata == 1 and self.fxdata[1].follow then
                local follower = self.smoke.entity:AddFollower()
                follower:FollowSymbol( self.inst.GUID, self.fxdata[1].follow, self.fxdata[1].x,self.fxdata[1].y,self.fxdata[1].z)
            else
                self.inst:AddChild(self.smoke)
            end
            self.smoke.Transform:SetPosition(0,0,0)
        end

        self.smoldertimeremaining = self.inst.components.propagator and self.inst.components.propagator.flashpoint
                                or math.random(TUNING.MIN_SMOLDER_TIME, TUNING.MAX_SMOLDER_TIME)

        SmolderUpdate(self.inst)
    end
end

function Burnable:Ignite(immediate, source)
    if not self.burning and not self.inst:HasTag("fireimmune") then
    	if self.smoldering then
            self.smoldering = false
            self.inst:RemoveTag("smolder")
            if self.inst.components.inspectable then self.inst.components.inspectable.smoldering = false end
            if self.smoke then 
                self.smoke.SoundEmitter:KillSound("smolder")
                self.smoke:Remove() 
            end
        end
        self.inst:AddTag("fire")
        self.burning = true

        self.inst:ListenForEvent("death", OnKilled)
        
        self:SpawnFX(immediate)
        self.inst:PushEvent("onignite")
        if self.onignite then
            self.onignite(self.inst)
        end

        if self.inst.components.explosive then
            --explosive on ignite
            self.inst.components.explosive:OnIgnite()
        end
        
        if self.inst.components.fueled then
            self.inst.components.fueled:StartConsuming()
        end
        if self.inst.components.propagator then
            self.inst.components.propagator:StartSpreading(source)
        end
        
        if self.burntime then
            if self.task ~= nil then
                self.task:Cancel()
            end
            self.task = self.inst:DoTaskInTime(self.burntime, DoneBurning, self)
        end
    end
end

function Burnable:LongUpdate(dt)
	--kind of a coarse assumption...
	if self.burning then
		if self.task ~= nil then
			self.task:Cancel()
			self.task = nil
		end
		DoneBurning(self.inst, self)
	end
end

function Burnable:SmotherSmolder(smotherer)
    if smotherer and smotherer.components.finiteuses then
        smotherer.components.finiteuses:Use()
    elseif smotherer and smotherer.components.stackable then
        smotherer.components.stackable:Get(1):Remove()
    elseif smotherer and smotherer.components.health and smotherer.components.combat then
        smotherer.components.health:DoFireDamage(TUNING.SMOTHER_DAMAGE, nil, true)
        smotherer:PushEvent("burnt")
    end
    self:StopSmoldering(-1.0) -- After you smother something, it has a bit of forgiveness before it will light again
end

function Burnable:StopSmoldering(heatpct)
    if self.smoldering then
        if self.smoke then 
            self.smoke.SoundEmitter:KillSound("smolder")
            self.smoke:Remove() 
        end
        self.smoldering = false
        self.inst:RemoveTag("smolder")
        if self.smolder_task then
            self.smolder_task:Cancel()
            self.smolder_task = nil
        end

        if self.inst.components.propagator then
            self.inst.components.propagator:StopSpreading(true, heatpct)
        end
    end
end


function Burnable:Extinguish(resetpropagator, heatpct, smotherer)
    self:StopSmoldering()

    if smotherer and smotherer.components.finiteuses then
        smotherer.components.finiteuses:Use()
    elseif smotherer and smotherer.components.stackable then
        smotherer.components.stackable:Get(1):Remove()
    end
    if self.burning then
    
        if self.task then
            self.task:Cancel()
            self.task = nil
        end
        
        if self.inst.components.propagator then
        	if resetpropagator then
                self.inst.components.propagator:StopSpreading(true, heatpct)
            else
            	self.inst.components.propagator:StopSpreading()
            end
        end
        
        self.inst:RemoveTag("fire")
        self.burning = false
        self:KillFX()
        if self.inst.components.fueled then
            self.inst.components.fueled:StopConsuming()
        end
        if self.onextinguish then
            self.onextinguish(self.inst)
        end
        self.inst:PushEvent("onextinguish")
    end
end


function Burnable:SpawnFX(immediate)
    self:KillFX()
    
    if not self.fxdata then
        self.fxdata = { x = 0, y = 0, z = 0, level=self:GetDefaultFXLevel() }
    end
    
    if self.fxdata then
	    for k,v in pairs(self.fxdata) do
			local fx = SpawnPrefab(v.prefab)
			if fx then
				fx.Transform:SetScale(self.inst.Transform:GetScale())
				if v.follow then
					local follower = fx.entity:AddFollower()
					follower:FollowSymbol( self.inst.GUID, v.follow, v.x,v.y,v.z)
				else
				    self.inst:AddChild(fx)
				    fx.Transform:SetPosition(v.x, v.y, v.z)
				end
                fx.persists = false
				table.insert(self.fxchildren, fx)
				if fx.components.firefx then
					fx.components.firefx:SetLevel(self.fxlevel, immediate)
				end
				
			end
		end
    end
end

function Burnable:KillFX()
	for k,v in pairs(self.fxchildren) do
		if v.components.firefx and v.components.firefx:Extinguish() then
            v:ListenForEvent("animover", function(inst) inst:Remove() end)  --remove once the pst animation has finished
        else
            v:Remove()
		end
		self.fxchildren[k] = nil
	end
end

function Burnable:OnRemoveFromEntity()
	self:StopSmoldering()
    self:Extinguish()
    RemoveDragonflyBait(self.inst)
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
    self.inst:RemoveTag("canlight")
    self.inst:RemoveTag("nolight")
end

return Burnable