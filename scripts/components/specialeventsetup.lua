

--------------------------------------------------------------------------
--[[ RetrofitForestMap_ANR class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "SpecialEventSetup should not exist on client")

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
	if IsSpecialEventActive(SPECIAL_EVENTS.HALLOWED_NIGHTS) then
		if not self.halloweentrinkets then
			self.halloweentrinkets = true
			local count = 0
			for i,area in pairs(TheWorld.topology.nodes) do
				if (i % 3) == 0 then
					local points_x, points_y = TheWorld.Map:GetRandomPointsForSite(area.x, area.y, area.poly, 1)
					if #points_x == 1 and #points_y == 1 then
						local x = points_x[1]
						local z = points_y[1]

						local ents = TheSim:FindEntities(x, 0, z, 1)
						if #ents == 0 then
							local e = SpawnPrefab("trinket_" .. math.random(32, 37))
							e.Transform:SetPosition(x, 0, z)
							count = count + 1
						end
					end
				end
			end

			print("Halloween Trinkets added: " ..count)
		end
	end

end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
	return {halloweentrinkets = self.halloweentrinkets}
end

function self:OnLoad(data)
    if data ~= nil then
		self.halloweentrinkets = data.halloweentrinkets
    end
end


--------------------------------------------------------------------------
end)