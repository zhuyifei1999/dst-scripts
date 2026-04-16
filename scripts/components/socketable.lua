
local Socketable = Class(function(self, inst)
    self.inst = inst

	self.socketname = "socket_DEFAULT"
    self.socketquality = SOCKETQUALITY.NONE
end)


-- Common interface

function Socketable:SetSocketName(socketname)
    self.socketname = socketname
end

function Socketable:GetSocketName()
    return self.socketname
end


-- Server interface

function Socketable:SetSocketQuality(socketquality)
    self.socketquality = socketquality
end

function Socketable:GetSocketQuality()
    return self.socketquality
end


return Socketable
