local BoatLeak = Class(function(self, inst)
    self.inst = inst    

    self.is_leak_count_incremented = false

end)

function BoatLeak:Repair(doer, patch_item)    
    if not self.inst:HasTag("boat_leak") then return false end

    if patch_item.components.stackable ~= nil then
        patch_item.components.stackable:Get():Remove()
    else
        patch_item:Remove()
    end

    self.inst.AnimState:PlayAnimation("leak_small_pst")
    self.inst:ListenForEvent("animqueueover", 
        function(inst)             
            self:SetState("repaired") 
        end)  

	return true
end

function BoatLeak:SetState(state)
	if state == self.current_state then return end

    local anim_state = self.inst.AnimState

	if state == "small_leak" then
	    self.inst:AddTag("boat_leak")

        anim_state:SetBank("boat_leak")
        anim_state:SetBuild("boat_leak")        
    	anim_state:PlayAnimation("leak_small_pre")   
    	anim_state:PushAnimation("leak_small_loop", true)  
        anim_state:SetSortOrder(0)
        anim_state:SetOrientation(ANIM_ORIENTATION.BillBoard) 
        anim_state:SetLayer(LAYER_WORLD)           

        self.inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/fountain_small_LP", "small_leak")                  

        if not self.is_leak_count_incremented then
            self.boat.components.boatphysics:IncrementLeakCount()
            self.is_leak_count_incremented = true
        end

		if self.onsprungleak ~= nil then
			self.onsprungleak(self.inst, state)
		end
	elseif state == "med_leak" then
	    self.inst:AddTag("boat_leak")

        anim_state:SetBank("boat_leak")
        anim_state:SetBuild("boat_leak")         
    	anim_state:PlayAnimation("leak_med_pre")   
    	anim_state:PushAnimation("leak_med_loop", true)  
        anim_state:SetSortOrder(0)
        anim_state:SetOrientation(ANIM_ORIENTATION.BillBoard) 
        anim_state:SetLayer(LAYER_WORLD)                   

        self.inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/fountain_medium_LP", "med_leak")                  

        if not self.is_leak_count_incremented then
            self.boat.components.boatphysics:IncrementLeakCount()
            self.is_leak_count_incremented = true

			if self.onsprungleak ~= nil then
				self.onsprungleak(self.inst, state)
			end
        end
	elseif state == "repaired" then
	    self.inst:RemoveTag("boat_leak")

        anim_state:SetBank("boat_repair")
        anim_state:SetBuild("boat_repair")       
        anim_state:PlayAnimation("pre_idle")     
        anim_state:SetSortOrder(3)
        anim_state:SetOrientation(ANIM_ORIENTATION.OnGround) 
        anim_state:SetLayer(LAYER_BACKGROUND)                   

        self.inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/repair")
        self. inst.SoundEmitter:KillSound("small_leak")                
        self. inst.SoundEmitter:KillSound("med_leak")
        
        if self.is_leak_count_incremented then
            self.boat.components.boatphysics:DecrementLeakCount()
            self.is_leak_count_incremented = false
        end

		if self.onrepairedleak ~= nil then
			self.onrepairedleak(self.inst)
		end
    end

	self.current_state = state
end

function BoatLeak:SetBoat(boat)
    self.boat = boat

end

return BoatLeak