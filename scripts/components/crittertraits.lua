

local TRAIT_MAX = 40
local TRAIT_MIN = -12
local DECAY_TICK_RATE = TUNING.CRITTER_TRAIT_DECAY_DELAY / TUNING.TOTAL_DAY_TIME


local CritterTraits = Class(function(self, inst)
    self.inst = inst
	self.traitscore = {}
	self.dominanttrait = nil
	self.dominanttraitlocked = nil
	
	for k,v in pairs(TUNING.CRITTER_TRAITS) do
		self.traitscore[k] = 0 
	end

    inst:DoTaskInTime(0, function() self:StartTracking() end)
end)

function CritterTraits:OnPet(petter)
	self.inst.sg:GoToState("emote_pet")
end

local function oneat(inst, data)
	local self = inst.components.crittertraits
	
    if self.dominanttrait ~= nil and data ~= nil and data.food ~= nil then
        if data.food.components.edible.foodtype == FOODTYPE.GOODIES then
			self.dominanttraitlocked = true
            inst.sg.mem.queuethankyou = true
        end
    end


	-- critters will always love to eat their favorite food
	local is_favoritefood = data and data.food.prefab == inst.favoritefood or false

    if inst:HasTag("stale") then
		self:IncTracker("wellfed", is_favoritefood and 1.5 or 1)
	elseif is_favoritefood then
		if inst:HasTag("spoiled") then
			-- please forgive me
			self:IncTracker("wellfed", 0.4)
		else
			self:IncTracker("wellfed", 0.2)
		end
	end
end

local function oncombat(self, data)
	local target = data and data.victim or data.target
	if target ~= nil and (not target:HasTag("smallcreature") or target:HasTag("monster")) then
		self:IncTracker("combat", data.damage ~= nil and data.damage or 100) -- nil damage is killing blow
	end
end

local function onpet(inst)
	local self = inst.components.crittertraits
	if self.pettask ~= nil then
		self.pettask:Cancel()
		self.pettask = nil
		self:IncTracker("affectionate")
	else
		self:IncTracker("affectionate", 0.05 ) -- 20 pets equals one really affectionate pet
	end
end

local function wantstobepet(inst)
	local self = inst.components.crittertraits
	if self.pettask ~= nil then
		self.pettask:Cancel()
	end
	
	self.pettask = inst:DoTaskInTime(TUNING.CRITTER_WANTS_TO_BE_PET_TIME,
		function()
			self.pettask = nil
		end)
end

local function OnCrafty(self, chance)
	if self:IsDominantTrait("crafty") and math.random() <= chance then
		self.inst.sg.mem.queuecraftyemote = true
	end
end

local function IsWaitingForPet(inst)
	return inst.pettask ~= nil
end

local function OnTimerDone(self, timer_name)
	if timer_name == "decay" then
		self:DecayTraits()
		self.inst.components.timer:StartTimer("decay", TUNING.CRITTER_TRAIT_DECAY_DELAY)
	elseif timer_name == "dominant" then
		self:RefreshDominantTrait()
		local delay = self.dominanttrait ~= nil and TUNING.CRITTER_TRAIT_DOMINATE_DELAY or TUNING.CRITTER_TRAIT_DOMINATE_RETRY_DELAY
		self.inst.components.timer:StartTimer("dominant", GetRandomWithVariance(delay, TUNING.CRITTER_TRAIT_DOMINATE_DELAY_VARIANCE))
	end
end

function CritterTraits:StartTracking()
	local owner = self.inst.components.follower.leader
	
	-- Events on critter
    self.inst:ListenForEvent("oneat", oneat)
    self.inst:ListenForEvent("perished", function(inst) self:IncTracker("wellfed", -1) end)
    self.inst:ListenForEvent("critter_onpet", onpet)
    self.inst:ListenForEvent("critter_onnuzzle", wantstobepet)
    self.inst:ListenForEvent("oncritterplaying", function(inst) self:IncTracker("playful") end)
	self.inst:ListenForEvent("timerdone", function(inst, data) OnTimerDone(self, data and data.name or nil) end)
	
	if not self.inst.components.timer:TimerExists("decay") then
		self.inst.components.timer:StartTimer("decay", TUNING.CRITTER_TRAIT_DECAY_DELAY)
	end
	if not self.inst.components.timer:TimerExists("dominant") then
		self.inst.components.timer:StartTimer("dominant", TUNING.CRITTER_TRAIT_INITIAL_DOMINATE_DELAY)
	end
	
	-- Events on owner - combat
    self.inst:ListenForEvent("killed", function(player, data) oncombat(self, data) end, owner)
    self.inst:ListenForEvent("onhitother", function(player, data) oncombat(self, data) end, owner)
    self.inst:ListenForEvent("death", function() self:IncTracker("combat", -5/TUNING.CRITTER_TRAITS.COMBAT.inc) end, owner)
    
	-- Events on owner - crafty
    self.inst:ListenForEvent("finishedwork",	function(player, data) if not data.target:HasTag("wall") then self:IncTracker("crafty") OnCrafty(self, 0.33) end end, owner)
    self.inst:ListenForEvent("unlockrecipe",	function() self:IncTracker("crafty", 5) end, owner)
    self.inst:ListenForEvent("builditem",		function() self:IncTracker("crafty") OnCrafty(self, 0.25) end, owner)
    self.inst:ListenForEvent("buildstructure",	function() self:IncTracker("crafty", 2) OnCrafty(self, 1) end, owner)
    --self.inst:ListenForEvent("deployitem",		function() self:IncTracker("crafty", 0.25) end, owner)
end

function CritterTraits:IncTracker(name, multiplier)
	name = string.upper(name)
	if self.traitscore[name] then
		multiplier = (multiplier == nil) and 1 or multiplier
		if self.dominanttrait and name == self.dominanttrait then
			multiplier = multiplier * 1.1 -- small bias to the dominant trait
		end
		self.traitscore[name] = math.min(self.traitscore[name] + (multiplier * TUNING.CRITTER_TRAITS[name].inc), TRAIT_MAX)
		--print (" + Tracker: " .. name .. ":" .. self.traitscore[name] .. " .. (" .. multiplier .. ")")
	end
end

function CritterTraits:DecayTraits()
	for k,v in pairs(self.traitscore) do
		self.traitscore[k] = math.max(v - (TUNING.CRITTER_TRAITS[k].decay * DECAY_TICK_RATE), TRAIT_MIN)
	end
end

function CritterTraits:SetDominantTrait(trait)
	trait = trait ~= nil and string.upper(trait) or nil
	
	if self.dominanttrait ~= nil then
		self.inst:RemoveTag("trait_" .. self.dominanttrait)
	end
	
	self.dominanttrait = trait 
	if trait then
		self.inst:AddTag("trait_" .. trait)
	end
end

function CritterTraits:IsDominantTrait(trait)
	trait = string.upper(trait)
	return self.dominanttrait == trait
end

function CritterTraits:RefreshDominantTrait()
	if self.dominanttraitlocked then
		return
	end

	local best_trait = {name = "",  score = TRAIT_MIN - 1}
	for k,v in pairs(self.traitscore) do
		if v > best_trait.score then
			best_trait.score = v
			best_trait.name = k
		end
	end

	if best_trait.score > 0 then 
		if self.dominanttrait ~= best_trait.name then
			self:SetDominantTrait(best_trait.name)
			self.inst:PushEvent("crittertraitchanged", {trait=best_trait.name})
		end
	else
		self:SetDominantTrait(nil)
	end

--[[
	local worst_trait = {name = "",  score = TRAIT_MAX + 1}
	for k,v in pairs(self.traitscore) do
		if v < worst_trait.score then
			worst_trait.score = v
			worst_trait.name = k
		end
	end

	local trait_spread = best_trait.score < worst_trait.score
	-- todo: normalize trait_spread so we dont have everything tanking
]]
	
end

function CritterTraits:OnSave()
    local data = {}
	data.dominanttrait = self.dominanttrait
	data.dominanttraitlocked = self.dominanttraitlocked
	data.traitscore = {}
	for k,v in pairs(self.traitscore) do
        data.traitscore[k] = v
    end
    return data
end

function CritterTraits:OnLoad(data)
    if data ~= nil then
		self:SetDominantTrait(data.dominanttrait)
		self.dominanttraitlocked = data.dominanttraitlocked
		if data.traitscore ~= nil then
			for k,v in pairs(data.traitscore) do
				self.traitscore[k] = v
			end
		end
    end
end

function CritterTraits:GetDebugString()
    local str = "dominanttrait: " .. tostring(self.dominanttrait) .. (self.dominanttraitlocked and " - Locked" or "")
	for k,v in pairs(self.traitscore) do
        str = str..string.format(
            "\n  %.4f  -  %s",
            v,
            k)
	end
    return str
end
return CritterTraits
