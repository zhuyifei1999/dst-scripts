

--------------------------------------------------------------------------
--[[ RetrofitCaveMap_ANR class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "RetrofitCaveMapA_NR should not exist on client")

--------------------------------------------------------------------------
--[[ Dependencies ]]
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local MAX_PLACEMENT_ATTEMPTS = 50

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private
local retrofit_warts = false

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function RetrofitNewCaveContentPrefab(inst, prefab, min_space, dist_from_structures)
	local attempt = 1
	local topology = TheWorld.topology

	while attempt <= MAX_PLACEMENT_ATTEMPTS do
		local area =  topology.nodes[math.random(#topology.nodes)]
        
        if not table.contains(area.tags, "Nightmare") then
			local points_x, points_y = TheWorld.Map:GetRandomPointsForSite(area.x, area.y, area.poly, 1)
			if #points_x == 1 and #points_y == 1 then
				local x = points_x[1]
				local z = points_y[1]

				if TheWorld.Map:CanPlacePrefabFilteredAtPoint(x, 0, z, prefab) and
					TheWorld.Map:CanPlacePrefabFilteredAtPoint(x + min_space, 0, z, prefab) and
					TheWorld.Map:CanPlacePrefabFilteredAtPoint(x, 0, z + min_space, prefab) and
					TheWorld.Map:CanPlacePrefabFilteredAtPoint(x - min_space, 0, z, prefab) and
					TheWorld.Map:CanPlacePrefabFilteredAtPoint(x, 0, z - min_space, prefab) then
					
					local ents = TheSim:FindEntities(x, 0, z, min_space)
					if #ents == 0 then
						if dist_from_structures ~= nil then
							ents = TheSim:FindEntities(x, 0, z, dist_from_structures, {"structure"} )
						end
						
						if #ents == 0 then
							local e = SpawnPrefab(prefab)
							e.Transform:SetPosition(x, 0, z)
							break
						end
					end
				end
			end
		end
		attempt = attempt + 1
	end
	print ("Retrofitting world for " .. prefab .. ": " .. (attempt < MAX_PLACEMENT_ATTEMPTS and ("Success after "..attempt.." attempts.") or "Failed."))
	return attempt < MAX_PLACEMENT_ATTEMPTS
end

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
	if retrofit_warts then
		print ("Retrofitting for A New Reign: Warts And All.")
		local success = false
		success = RetrofitNewCaveContentPrefab(inst, "toadstool_cap", 7, 40) or success
		success = RetrofitNewCaveContentPrefab(inst, "toadstool_cap", 7, 40) or success
		success = RetrofitNewCaveContentPrefab(inst, "toadstool_cap", 7, 40) or success
		while not success do
			print ("Retrofitting for A New Reign: Warts And All. - Trying really hard to find a spot for Toadstool.")
			success = RetrofitNewCaveContentPrefab(inst, "toadstool_cap", 4, 40)
		end
	end

end

--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
	return {}
end

function self:OnLoad(data)
               print "HERE OnLoad"

    if data ~= nil then
		retrofit_warts = data.retrofit_warts or false
    end
end


--------------------------------------------------------------------------
end)