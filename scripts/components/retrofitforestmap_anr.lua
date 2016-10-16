

--------------------------------------------------------------------------
--[[ RetrofitForestMap_ANR class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "RetrofitForestMapA_NR should not exist on client")

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
local retrofit_part1 = false

--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local function RetrofitNewContentPrefab(inst, prefab, min_space, dist_from_structures)
	local attempt = 1
	local topology = TheWorld.topology

	while attempt <= MAX_PLACEMENT_ATTEMPTS do
		local area =  topology.nodes[math.random(#topology.nodes)]
        
		local points_x, points_y = TheWorld.Map:GetRandomPointsForSite(area.x, area.y, area.poly, 1)
		if #points_x == 1 and #points_y == 1 then
			local x = points_x[1]
			local z = points_y[1]

			if TheWorld.Map:CanPlacePrefabFilteredAtPoint(x, 0, z, prefab) then
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
		attempt = attempt + 1
	end
	print ("Retrofitting world for " .. prefab .. ": " .. (attempt < MAX_PLACEMENT_ATTEMPTS and ("Success after "..attempt.." attempts.") or "Failed."))
end

--------------------------------------------------------------------------
--[[ Post initialization ]]
--------------------------------------------------------------------------

function self:OnPostInit()
	if retrofit_part1 then
		local requires_retrofitting = true
	    for k,v in pairs(Ents) do
			if v ~= inst and v.prefab == "moonbase" then
				print ("Retrofitting for A New Reign Part1 is not required.")
				requires_retrofitting = false
				break
			end
		end

		if requires_retrofitting then
			print ("Retrofitting for A New Reign Part1.")
			RetrofitNewContentPrefab(inst, "stagehand", 2, 10)
			RetrofitNewContentPrefab(inst, "moonbase", 2, 40)
			RetrofitNewContentPrefab(inst, "sculpture_rookbody", 2, 40)
			RetrofitNewContentPrefab(inst, "sculpture_rooknose", 1, 10)
			RetrofitNewContentPrefab(inst, "sculpture_knightbody", 2, 40)
			RetrofitNewContentPrefab(inst, "sculpture_knighthead", 1, 10)
			RetrofitNewContentPrefab(inst, "sculpture_bishopbody", 2, 40)
			RetrofitNewContentPrefab(inst, "sculpture_bishophead", 1, 10)
		end
	end

	if self.retrofit_artsandcrafts then
		self.retrofit_artsandcrafts = nil
		
		local requires_retrofitting = true
		local missing_sculpture = {pawn=true, knight=true, rook=true, bishop=true, muse=true, formal=true}
	    for k,v in pairs(Ents) do
			if v ~= inst then
				if v.prefab == "statue_marble" then
					if v.typeid == 1 or v.typeid == 2 then
						missing_sculpture.muse = nil
					elseif v.typeid == 4 then
						missing_sculpture.pawn = nil
					end
				elseif v.prefab == "statuemaxwell" then
					missing_sculpture.formal = nil
				elseif v.prefab == "sculpture_rookbody" then
					missing_sculpture.rook = nil
				elseif v.prefab == "sculpture_knightbody" then
					missing_sculpture.knight = nil
				elseif v.prefab == "sculpture_bishopbody" then
					missing_sculpture.bishop = nil
				end
				
				if next(missing_sculpture) == nil then
					print ("Retrofitting for A New Reign: Arts and Crafts is not required.")
					break;
				end
			end
		end

		if next(missing_sculpture) ~= nil then
			print ("Retrofitting for A New Reign: Arts and Crafts.")
			for key,_ in pairs(missing_sculpture) do
				RetrofitNewContentPrefab(inst, "chesspiece_"..key.."_sketch", 1, 5)
			end
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
    if data ~= nil then
		retrofit_part1 = data.retrofit_part1 or false
		self.retrofit_artsandcrafts = data.retrofit_artsandcrafts or false
    end
end


--------------------------------------------------------------------------
end)