require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/follow"
require "behaviours/doaction"
require "behaviours/minperiod"
require "behaviours/panic"
require "behaviours/runaway"

local SEE_DIST = 30
local TOOCLOSE = 6

local function CanSteal(item)
    return item.components.inventoryitem ~= nil and
        item.components.inventoryitem.canbepickedup and
        not item.components.inventoryitem:IsHeld() and
        item:IsOnValidGround() and
        not item:IsNearPlayer(TOOCLOSE)
end

local function StealAction(inst)
    if not inst.components.inventory:IsFull() then
        local target = FindEntity(inst, SEE_DIST,
            CanSteal,
            { "_inventoryitem" }, --see entityreplica.lua
            { "irreplaceable", "prey", "bird" })
        if target ~= nil then
            return BufferedAction(inst, target, ACTIONS.PICKUP)
        end
    end
end

local function CanHammer(item)
    return item.prefab == "treasurechest" and
        item.components.container ~= nil and
        not item.components.container:IsEmpty() and
        not item:IsNearPlayer(TOOCLOSE)
end

local function EmptyChest(inst)
    if not inst.components.inventory:IsFull() then
        local target = FindEntity(inst, SEE_DIST,
            CanHammer,
            { "_container" }) --see entityreplica.lua
        if target ~= nil then
            return BufferedAction(inst, target, ACTIONS.HAMMER)
        end
    end
end

local MIN_FOLLOW = 10
local MAX_FOLLOW = 20
local MED_FOLLOW = 15

local MIN_RUNAWAY = 8
local MAX_RUNAWAY = MED_FOLLOW

local KrampusBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
	self.mytarget = nil
    self.greed = 2 + math.random(4)
end)

function KrampusBrain:SetTarget(target)
	self.listenerfunc = function() self.mytarget = nil end
	if target ~= self.target then
		if self.mytarget then
			self.inst:RemoveEventCallback("onremove", self.listenerfunc, self.mytarget)
		end
		if target then
			self.inst:ListenForEvent("onremove", self.listenerfunc, target)
		end
	end
	self.mytarget = target
end

function KrampusBrain:OnStart()
	self:SetTarget(self.inst.spawnedforplayer)
    
    local stealnode = PriorityNode(
	{
		DoAction(self.inst, function() return StealAction(self.inst) end, "steal", true ),        
		DoAction(self.inst, function() return EmptyChest(self.inst) end, "emptychest", true )
	}, 2)

    local root = PriorityNode(
    {
    	WhileNode( function() return self.inst.components.hauntable and self.inst.components.hauntable.panic end, "PanicHaunted", Panic(self.inst)),
        WhileNode( function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
        ChaseAndAttack(self.inst, 100),
		IfNode( function() return self.inst.components.inventory:NumItems() >= self.greed and not self.inst.sg:HasStateTag("busy") end, "donestealing",
			ActionNode(function() self.inst.sg:GoToState("exit") return SUCCESS end, "leave" )),
		MinPeriod(self.inst, 10, true,
			stealnode),

        RunAway(self.inst, "player", MIN_RUNAWAY, MAX_RUNAWAY),
		Follow(self.inst, function() return self.mytarget end, MIN_FOLLOW, MED_FOLLOW, MAX_FOLLOW),	
        Wander(self.inst, function() local player = self.mytarget if player then return Vector3(player.Transform:GetWorldPosition()) end end, 20)
    }, 2)
    
    self.bt = BT(self.inst, root)
   
end

return KrampusBrain
