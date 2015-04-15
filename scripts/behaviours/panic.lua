local RUNNING = "running"
local STANDING = "standing"

Panic = Class(BehaviourNode, function(self, inst)
    BehaviourNode._ctor(self, "Panic")
    self.inst = inst
    self.waittime = 0
end)

function Panic:Visit()

    if self.status == READY then
        self:PickNewDirection()
        self.status = RUNNING
    
    else
        if GetTime() > self.waittime then
            if self.status == RUNNING then
                self:WaitForTime()
            else                
                self:PickNewDirection()
            end
        end
        self:Sleep(self.waittime - GetTime())
    end
    
    
end

function Panic:WaitForTime()
    self.inst.components.locomotor:Stop()
    self.waittime = GetTime() + 1 + math.random()*2
    self.status = STANDING
end
function Panic:PickNewDirection()
    self.inst.components.locomotor:RunInDirection(math.random()*360)
    self.waittime = GetTime() + 4 + math.random()*2
    self.status = RUNNING
end



