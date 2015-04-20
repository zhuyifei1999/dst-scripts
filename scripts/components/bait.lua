local Bait = Class(function(self, inst)
    self.inst = inst
    self.trap = nil
    self.inst:ListenForEvent( "onpickup", function() if self.trap then self.trap:RemoveBait() end end )  
    self.inst:ListenForEvent( "oneaten", function(inst, data) if self.trap then self.trap:BaitTaken(data.eater) end end )  
    self.inst:ListenForEvent( "onstolen", function(inst, data) 
    	if self.trap then 
    		self.trap:BaitTaken(data.thief) 
    	elseif data.thief.components.inventory then
    		data.thief.components.inventory:GiveItem(self.inst)
    	end 
    end )
end)

function Bait:DebugString()
    return "Trap:"..tostring(self.trap)
end

function Bait:IsFree() 
    return self.trap == nil
end

return Bait