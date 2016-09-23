
-------------------------------------------------------------------------------
-- SourceMultipliers manages multipliers applied by external sources.
--   Optionally, it will also handle multiple multiplier from the same source, 
--   provided a key is passed in for each multiplier
-------------------------------------------------------------------------------

SourceMultipliers = Class(function(self, inst)
    self.inst = inst

	-- Private members
    self._multipliers = {}
    self._multiplier = 1
    
end)

-------------------------------------------------------------------------------
function SourceMultipliers:Get()
	return self._multiplier
end

-------------------------------------------------------------------------------
local function RecalculateMultiplier(inst)
    local m = 1
    for source, src_params in pairs(inst._multipliers) do
        for k, v in pairs(src_params.multipliers) do
            m = m * v
        end
    end
    inst._multiplier = m
end

-------------------------------------------------------------------------------
-- Source can be an object or a name. If it is an object, then it will handle 
--   removing the multiplier if the object is forcefully removed from the game.
-- Key is optional if you are only going to have one multiplier from a source.
function SourceMultipliers:SetMultiplier(source, m, key)
	if source == nil then
		return
	end

    if key == nil then
        key = "key"
    end
    
    if m == nil or m == 1 then
        self:RemoveMultiplier(source, key)
        return
    end

    local src_params = self._multipliers[source]
    if src_params == nil then
        self._multipliers[source] = {
            multipliers = { [key] = m },
        }
        
        -- If the source is an object, then add a onremove event listener to cleanup if source is removed from the game
        if type(source) == "table" then
            self._multipliers[source].onremove = function(source)
                self._multipliers[source] = nil
                RecalculateMultiplier(self)
            end

            self.inst:ListenForEvent("onremove", self._multipliers[source].onremove, source)
        end
        
        RecalculateMultiplier(self)
    elseif src_params.multipliers[key] ~= m then
        src_params.multipliers[key] = m
        RecalculateMultiplier(self)
    end
end

-------------------------------------------------------------------------------
-- Key is optional if you want to remove the entire source
function SourceMultipliers:RemoveMultiplier(source, key)
    local src_params = self._multipliers[source]
    if src_params == nil then
        return
    elseif key ~= nil then
        src_params.multipliers[key] = nil
        if next(src_params.multipliers) ~= nil then
            --this source still has other keys
			RecalculateMultiplier(self)
            return
        end
    end
    
    --remove the entire source
    if src_params.onremove ~= nil then
        self.inst:RemoveEventCallback("onremove", src_params.onremove, source)
    end
    self._multipliers[source] = nil
    RecalculateMultiplier(self)
end

-------------------------------------------------------------------------------
-- Key is optional if you want to calculate the entire source
function SourceMultipliers:CalculateMultiplierFromSource(source, key)
    local src_params = self._multipliers[source]
    if src_params == nil then
        return 1
    elseif key == nil then
        local m = 1
        for k, v in pairs(src_params.multipliers) do
            m = m * v
        end
        return m
    end
    return src_params.multipliers[key] or 1
end



-------------------------------------------------------------------------------
return SourceMultipliers