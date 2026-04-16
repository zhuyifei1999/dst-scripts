require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/doaction"
require "behaviours/leash"
require "behaviours/standstill"

local BrainCommon = require("brains/braincommon")

--------------------------------------------------------------------------------------------------------------------------------

local Wx78_PossessedBodyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local UPDATE_RATE = 0.5
function Wx78_PossessedBodyBrain:OnStart()
    local root = PriorityNode(
    {
        StandStill(self.inst),
    }, UPDATE_RATE)

    self.bt = BT(self.inst, root)
end

function Wx78_PossessedBodyBrain:OnStop()

end

return Wx78_PossessedBodyBrain