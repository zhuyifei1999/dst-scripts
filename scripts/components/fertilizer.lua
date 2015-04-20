local Fertilizer = Class(function(self, inst)
    self.inst = inst
    self.fertilizervalue = 1
    self.soil_cycles = 1
    self.withered_cycles = 1
end)

return Fertilizer

