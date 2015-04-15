-- KAJ: TODO MP_TALK - there's a lot of Say() in here
-- KAJ: TODO Strings assume woodie

local SentientAxe = Class(function(self, inst)
    self.inst = inst
    self.time_to_convo = 10

    self.inst:ListenForEvent("equipped", function(_, data) self:OnEquipped(data.owner) end)
	self.inst:ListenForEvent("onpickup", function(_, data) self:OnPickedUp(data.owner) end)

    local dt = 5
    self.inst:DoPeriodicTask(dt, function() self:OnUpdate(dt) end)
    self.warnlevel = 0

	self.OnDroppedClosure = function() self:OnDropped() end
	self.OnFinishedWorkClosure = function(_,data) self:OnFinishedWork(data.target, data.action) end
	self.OnBeaverDeltaClosure = function(_, data) self:OnBeaverDelta(data.oldpercent, data.newpercent) end
	self.OnBecomeBeaverClosure = function(_, data) self:OnBecomeBeaver() end
	self.OnBecomeHumanClosure = function(_, data) self:OnBecomeHuman() end
end)

function SentientAxe:SetOwner(owner)
	if owner then
		if owner ~= self.owner then
		    self.inst:ListenForEvent("ondropped", self.OnDroppedClosure)
		    self.inst:ListenForEvent("finishedwork", self.OnFinishedWorkClosure, owner)
		    self.inst:ListenForEvent("beavernessdelta", self.OnBeaverDeltaClosure, owner)
		    self.inst:ListenForEvent("beaverstart", self.OnBecomeBeaverClosure, owner)
		    self.inst:ListenForEvent("beaverend", self.OnBecomeHumanClosure, owner)
		end
	else
		if self.owner then
			-- remove owner specific listeners
		    self.inst:RemoveEventCallback("ondropped", self.OnDroppedClosure)
		    self.inst:RemoveEventCallback("finishedwork", self.OnFinishedWorkClosure, self.owner)
		    self.inst:RemoveEventCallback("beavernessdelta", self.OnBeaverDeltaClosure, self.owner)
		    self.inst:RemoveEventCallback("beaverstart", self.OnBecomeBeaverClosure, self.owner)
    		self.inst:RemoveEventCallback("beaverend", self.OnBecomeHumanClosure, self.owner)
		end
	end
	self.owner = owner
end

function SentientAxe:OnPickedUp(owner)
	self:SetOwner(owner)
end

function SentientAxe:OnFinishedWork(target, action)
        self:Say(STRINGS.LUCY.on_chopped)
    if action == ACTIONS.CHOP and 
        self.inst.components.inventoryitem.owner and self.inst.components.inventoryitem.owner:HasTag("player") and 
        self.inst.components.equippable:IsEquipped() and
        (self.owner.components.beaverness and self.owner.components.beaverness:GetPercent() < .25) then
        self:Say(STRINGS.LUCY.on_chopped)
    end
end

function SentientAxe:OnBeaverDelta(old, new)
	-- KAJ: TODO: MP_LOGIC - What does this do if we don't have an owner? Should it pick the nearest player? Last owner?
	if not self.owner then
		return
	end
    
    if self.owner.components.beaverness:IsBeaver() then return end

    if new > old then
        if new > .33 and old <= .33 and self.warnlevel < 1 then
            self:Say(STRINGS.LUCY.beaver_up_early)     
            self.warnlevel = 1
        elseif new > .66 and old <= .66 and self.warnlevel < 2 then
            self:Say(STRINGS.LUCY.beaver_up_mid)     
            self.warnlevel = 2
        elseif new > .9 and old <= .9 and self.warnlevel < 3 then
            self:Say(STRINGS.LUCY.beaver_up_late)
            self.warnlevel = 3   
            self.washigh = true  
        end

    else
        if self.warnlevel == 3 and new < .66 then
            self.warnlevel = 2
        elseif self.warnlevel == 2 and new < .33 then
            self.warnlevel = 1
        end

        if new <= 0 and old > 0 then
            if self.washigh then
                
                local warn_sounds = {"dontstarve/characters/woodie/lucy_warn_1","dontstarve/characters/woodie/lucy_warn_2","dontstarve/characters/woodie/lucy_warn_3"}
				-- KAJ: TODO: MP_TALK
                self:Say(STRINGS.LUCY.beaver_down_washigh, warn_sounds[self.warnlevel])     
                self.warnlevel = 0
                self.washigh = false
            end
        end            
    end
end

function SentientAxe:OnBecomeHuman()
    self:Say(STRINGS.LUCY.transform_woodie)
end

function SentientAxe:OnBecomeBeaver()
    self:Say(STRINGS.LUCY.transform_beaver, "dontstarve/characters/woodie/lucy_transform")
end

function SentientAxe:OnDropped()
	assert(self.owner)
	if self.owner then
	    if self.owner.components.beaverness and self.owner.components.beaverness:IsBeaver() then
    	    self:Say(STRINGS.LUCY.transform_beaver)
	    else	
    	    self:Say(STRINGS.LUCY.on_dropped)
	    end
		self:SetOwner(nil)
	end
end

function SentientAxe:OnEquipped(picked_up_by)
	self:SetOwner(picked_up_by)
    if picked_up_by:HasTag("player") then
        self:Say(STRINGS.LUCY.on_pickedup) 
    end
end

function SentientAxe:OnUpdate(dt)
    self.time_to_convo = self.time_to_convo - dt
    if self.time_to_convo <= 0 then
        self:MakeConversation()
    end
end

function SentientAxe:Say(list, sound_override)
    self.sound_override = sound_override
    self.inst.components.talker:Say(list[math.random(#list)])
    self.time_to_convo = math.random(60, 120)
end


function SentientAxe:MakeConversation()
    
    local grand_owner = self.inst.components.inventoryitem:GetGrandOwner()
    local owner = self.inst.components.inventoryitem.owner

    local quiplist = nil
    if owner and owner:HasTag("player") then
        if self.inst.components.equippable:IsEquipped() then
            --currently equipped
            quiplist = STRINGS.LUCY.equipped
        else
            --in player inventory
        end
    elseif owner == nil then
        --on the ground
        quiplist = STRINGS.LUCY.on_ground
    elseif grand_owner and grand_owner ~= owner and grand_owner:HasTag("player")  then
        --in a backpack
        quiplist = STRINGS.LUCY.in_container
    elseif owner and owner.components.container then
        --in a container
        quiplist = STRINGS.LUCY.in_container
    else
        --owned by someone else
        quiplist = STRINGS.LUCY.other_owner
    end

    if quiplist then
        self:Say(quiplist)
    end
end

return SentientAxe