local Saddler = Class(function(self, inst)
    self.inst = inst
    self.swapsymbol = nil
    self.swapbuild = nil

    self.bonusdamage = nil
end)

function Saddler:SetSwaps(build, symbol)
    self.swapbuild = build
    self.swapsymbol = symbol
end

function Saddler:SetBonusDamage(damage)
    self.bonusdamage = damage
end

function Saddler:GetBonusDamage(target)
    return self.bonusdamage or 0
end

function Saddler:SetDiscardedCallback(cb)
    self.discardedcb = cb
end

return Saddler
