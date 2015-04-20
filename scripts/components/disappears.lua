


local Disappears = Class(function(self, inst)
    self.inst = inst
    self.delay = 25
    self.disappearsFn = nil
    self.sound = nil
    self.anim = "disappear"
end,
nil,
{
    
})


function Disappears:Disappear()
	if self.disappeartask then
		self.disappeartask:Cancel()
    	self.disappeartask = nil
    end
   
   	if self.disappearFn then 
   		self.disappearFn(self.inst)
   	end

   	self.inst.persists = false
    self.inst:RemoveComponent("inventoryitem")
    self.inst:RemoveComponent("inspectable")
    if self.sound then 
		self.inst.SoundEmitter:PlaySound(self.sound)
	end
	self.inst.AnimState:PlayAnimation(self.anim)
	self.inst:ListenForEvent("animover", self.inst.Remove)
end

function Disappears:StopDisappear()
	if self.disappeartask then
		self.disappeartask:Cancel()
		self.disappeartask = nil
	end
end
		
function Disappears:PrepareDisappear()
	self:StopDisappear()
	self.disappeartask = self.inst:DoTaskInTime(self.delay+math.random()*10, function() self:Disappear() end)
end


return Disappears