local function oncancast(self)
    if self.spell ~= nil then
        if self.canusefrominventory then
            self.inst:AddTag("castfrominventory")
        else
            self.inst:RemoveTag("castfrominventory")
        end

        if self.canuseontargets then
            if not self.canonlyuseonrecipes and not self.canonlyuseonlocomotors then
                self.inst:AddTag("castontargets")
            else
                self.inst:RemoveTag("castontargets")
            end

            if self.canonlyuseonrecipes then
                self.inst:AddTag("castonrecipes")
            else
                self.inst:RemoveTag("castonrecipes")
            end

            if self.canonlyuseonlocomotors then
                self.inst:AddTag("castonlocomotors")
            else
                self.inst:RemoveTag("castonlocomotors")
            end
        else
            self.inst:RemoveTag("castontargets")
            self.inst:RemoveTag("castonrecipes")
            self.inst:RemoveTag("castonlocomotors")
        end

        if self.canuseonpoint then
            self.inst:AddTag("castonpoint")
        else
            self.inst:RemoveTag("castonpoint")
        end
    else
        self.inst:RemoveTag("castfrominventory")
        self.inst:RemoveTag("castontargets")
        self.inst:RemoveTag("castonrecipes")
        self.inst:RemoveTag("castonlocomotors")
        self.inst:RemoveTag("castonpoint")
    end
end

local SpellCaster = Class(function(self, inst)
	self.inst = inst
	self.onspellcast = nil
    self.canusefrominventory = false
    self.canuseontargets = false
    self.canonlyuseonrecipes = false
    self.canonlyuseonlocomotors = false
    self.canuseonpoint = false
    self.spell = nil
end,
nil,
{
    spell = oncancast,
    canusefrominventory = oncancast,
    canuseontargets = oncancast,
    canonlyuseonrecipes = oncancast,
    canonlyuseonlocomotors = oncancast,
    canuseonpoint = oncancast,
})

function SpellCaster:OnRemoveFromEntity()
    self.inst:RemoveTag("castfrominventory")
    self.inst:RemoveTag("castontargets")
    self.inst:RemoveTag("castonrecipes")
    self.inst:RemoveTag("castonlocomotors")
    self.inst:RemoveTag("castonpoint")
end

function SpellCaster:SetSpellFn(fn)
	self.spell = fn
end

function SpellCaster:SetOnSpellCastFn(fn)
	self.onspellcast = fn
end

function SpellCaster:CastSpell(target, pos)
	if self.spell then
		self.spell(self.inst, target, pos)

		if self.onspellcast then
			self.onspellcast(self.inst, target, pos)
		end
	end
end

function SpellCaster:CanCast(doer, target, pos)
    if target == nil then
        if pos == nil then
            return self.inst:HasTag("castfrominventory")
        end
        return self.inst:HasTag("castonpoint") and TheWorld.Map:IsAboveGroundAtPoint(pos:Get())
    elseif target:IsInLimbo()
        or not target.entity:IsVisible()
        or (target.sg ~= nil and target.sg:HasStateTag("death")) then
        return false
    elseif self.inst:HasTag("castontargets") then
        return true
    end

    local castonrecipes = self.inst:HasTag("castonrecipes")
    local castonlocomotors = self.inst:HasTag("castonlocomotors")
    return (castonrecipes or castonlocomotors) and
        (not castonrecipes or AllRecipes[target.prefab] ~= nil) and
        (not castonlocomotors or target:HasTag("locomotor"))
end

return SpellCaster