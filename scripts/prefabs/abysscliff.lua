local assets =
{
	Asset("ANIM", "anim/abyss_cliff.zip"),
}

--------------------------------------------------------------------------

local function OverrideTile(map, tile_x, tile_y)
	local current_tile = map:GetTile(tile_x, tile_y)
	if current_tile == WORLD_TILES.ROPE_BRIDGE or TileGroupManager:IsTemporaryTile(current_tile) then
		return false
	end

	map:SetTile(tile_x, tile_y, WORLD_TILES.ROPE_BRIDGE)

	-- V2C: Because of a terraforming callback in farming_manager.lua, the undertile gets cleared during SetTile.
	--      We can circumvent this for now by setting the undertile after SetTile.
	local undertile = TheWorld.components.undertile
	if undertile then
		undertile:SetTileUnderneath(tile_x, tile_y, current_tile)
	end

	return true
end

local function RevertTile(map, tile_x, tile_y, x, z)
	local tile = map:GetTile(tile_x, tile_y)
	if tile ~= WORLD_TILES.ROPE_BRIDGE then
		return false
	end

	local undertile = TheWorld.components.undertile
	local old_tile = undertile and undertile:GetTileUnderneath(tile_x, tile_y)
	if old_tile then
		undertile:ClearTileUnderneath(tile_x, tile_y)
	else
		old_tile = WORLD_TILES.IMPASSABLE
	end

	map:SetTile(tile_x, tile_y, old_tile)

	TempTile_HandleTileChange(x, 0, z, old_tile)

	return true
end

--------------------------------------------------------------------------

local NUM_VARIATIONS =
{
	--[[
	outer_1_ = 1,
	outer_2_ = 1,
	outer_3_ = 1,
	outer_5_ = 1,
	inner_1_ = 1,
	inner_2_ = 1,
	inner_3_ = 1,
	inner_4_ = 1,
	inner_5_ = 1,
	]]
}

--@V2C: bit ops not supported during updateprefabs
--Flags
local _UL = 1
local _UM = 2
local _UR = 4
local _MR = 8
local _DR = 16
local _DM = 32
local _DL = 64
local _ML = 128
local _U = _UL + _UM + _UR --bit.bor(bit.bor(_UL, _UM), _UR)
local _R = _UR + _MR + _DR --bit.bor(bit.bor(_UR, _MR), _DR)
local _D = _DR + _DM + _DL --bit.bor(bit.bor(_DR, _DM), _DL)
local _L = _DL + _ML + _UL --bit.bor(bit.bor(_DL, _ML), _UL)
local _U_L = _U + _ML + _DL --bit.bor(_U, _L)
local _U_R = _U + _MR + _DR --bit.bor(_U, _R)
local _D_R = _D + _MR + _UR --bit.bor(_D, _R)
local _D_L = _D + _ML + _UL --bit.bor(_D, _L)
local _ALL = 255

local function GetLargestPiece(flags)
	if		flags == _ALL then					return 4, 0,	0
	elseif	flags == bit.bxor(_ALL, _DM) then	return 3, 0,	0
	elseif	flags == bit.bxor(_ALL, _ML) then	return 3, 90,	0
	elseif	flags == bit.bxor(_ALL, _UM) then	return 3, 180,	0
	elseif	flags == bit.bxor(_ALL, _MR) then	return 3, 270,	0
	elseif	bit.band(flags, _U_L) == _U_L then	return 2, 0,	bit.bxor(flags, _U_L)
	elseif	bit.band(flags, _U_R) == _U_R then	return 2, 90,	bit.bxor(flags, _U_R)
	elseif	bit.band(flags, _D_R) == _D_R then	return 2, 180,	bit.bxor(flags, _D_R)
	elseif	bit.band(flags, _D_L) == _D_L then	return 2, 270,	bit.bxor(flags, _D_L)
	elseif	bit.band(flags, _U) == _U then		return 1, 0,	bit.bxor(flags, _U)
	elseif	bit.band(flags, _R) == _R then		return 1, 90,	bit.bxor(flags, _R)
	elseif	bit.band(flags, _D) == _D then		return 1, 180,	bit.bxor(flags, _D)
	elseif	bit.band(flags, _L) == _L then		return 1, 270,	bit.bxor(flags, _L)
	elseif	bit.band(flags, _UL) == _UL then	return 5, 0,	bit.bxor(flags, _UL)
	elseif	bit.band(flags, _UR) == _UR then	return 5, 90,	bit.bxor(flags, _UR)
	elseif	bit.band(flags, _DR) == _DR then	return 5, 180,	bit.bxor(flags, _DR)
	elseif	bit.band(flags, _DL) == _DL then	return 5, 270,	bit.bxor(flags, _DL)
	end
end

local function GetOverhangFlags(x, z, tile_tags)
	local spacing = 3.9
	local r = SQRT2 * 4 + 0.1
	local flags = 0
	for i, v in ipairs(TheSim:FindEntities(x, 0, z, r, tile_tags)) do
		local x1, _, z1 = v.Transform:GetWorldPosition()
		local dx = x1 - x
		local dz = z1 - z
		if dx > spacing then
			if dz > spacing then
				flags = bit.bor(flags, _UR)
			elseif dz < -spacing then
				flags = bit.bor(flags, _DR)
			else
				flags = bit.bor(flags, _R)
			end
		elseif dx < -spacing then
			if dz > spacing then
				flags = bit.bor(flags, _UL)
			elseif dz < -spacing then
				flags = bit.bor(flags, _DL)
			else
				flags = bit.bor(flags, _L)
			end
		elseif dz > spacing then
			flags = bit.bor(flags, _U)
		elseif dz < -spacing then
			flags = bit.bor(flags, _D)
		else
			return 0
		end
	end
	return flags
end

local function CreateOverhang()
	local overhang = CreateEntity()

	overhang:AddTag("NOCLICK")
	overhang:AddTag("CLASSIFIED")
	overhang:AddTag("abysscliff_overhang")
	--[[Non-networked entity]]
	overhang.entity:SetCanSleep(TheWorld.ismastersim)
	overhang.persists = false

	overhang.entity:AddTransform()
	overhang.entity:AddAnimState()

	overhang.AnimState:SetBank("abyss_cliff")
	overhang.AnimState:SetBuild("abyss_cliff")
	overhang.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	overhang.AnimState:SetLayer(LAYER_GROUND)

	return overhang
end

local function RefreshOverhang(map, tile_x, tile_y, x, z, isremoving)
	local autofill = not (isremoving or POPULATING)

	local tile_tags = { "CLASSIFIED", "abysscliff_tile" }

	if not TheNet:IsDedicated() then
		local overhang_tags = { "CLASSIFIED", "abysscliff_overhang" }

		if not isremoving then
			for i, v in ipairs(TheSim:FindEntities(x, 0, z, 0.1, overhang_tags)) do
				v:Remove()
			end
		end

		for tx = tile_x - 1, tile_x + 1 do
			for ty = tile_y - 1, tile_y + 1 do
				if isremoving or tx ~= tile_x or ty ~= tile_y then
					local _, overhang
					x, _, z = map:GetTileCenterPoint(tx, ty)
					for i, v in ipairs(TheSim:FindEntities(x, 0, z, 0.1, overhang_tags)) do
						if overhang then
							v:Remove()
						else
							overhang = v
						end
					end
					local flags = GetOverhangFlags(x, z, tile_tags)
					local id, rot
					id, rot, flags = GetLargestPiece(flags)
					if id == 4 then
						if overhang then
							overhang:Remove()
						end
						if autofill then
							local fill = SpawnPrefab("abysscliff_tile")
							fill.Transform:SetPosition(x, 0, z)
							fill:AlignToTile()
						end
					elseif id then
						if overhang == nil then
							overhang = CreateOverhang()
							overhang.Transform:SetPosition(x, 0, z)
						end
						local style = TileGroupManager:IsInvalidTile(map:GetTile(tx, ty)) and "outer" or "inner"
						local anim = string.format("%s_%d_", style, id)
						anim = anim..tostring(math.random(NUM_VARIATIONS[anim] or 1))
						overhang.Transform:SetRotation(rot)
						overhang.AnimState:PlayAnimation(anim)
						while flags ~= 0 do
							id, rot, flags = GetLargestPiece(flags)
							local anim = string.format("%s_%d_", style, id)
							anim = anim..tostring(math.random(NUM_VARIATIONS[anim] or 1))
							overhang = CreateOverhang()
							overhang.Transform:SetPosition(x, 0, z)
							overhang.Transform:SetRotation(rot)
							overhang.AnimState:PlayAnimation(anim)
						end
					elseif overhang then
						overhang:Remove()
					end
				end
			end
		end
	elseif autofill then
		for tx = tile_x - 1, tile_x + 1 do
			for ty = tile_y - 1, tile_y + 1 do
				if tx ~= tile_x or ty ~= tile_y then
					local _
					x, _, z = map:GetTileCenterPoint(tx, ty)
					local id, rot = GetOverhangParams(x, z, tile_tags)
					if id == 4 then
						local fill = SpawnPrefab("abysscliff_tile")
						fill.Transform:SetPosition(x, 0, z)
						fill:AlignToTile()
					end
				end
			end
		end
	end
end

local function AlignToTile(inst)
	local map = TheWorld.Map
	local tile_x, tile_y = map:GetTileCoordsAtPoint(inst.Transform:GetWorldPosition())
	local x, _, z = map:GetTileCenterPoint(tile_x, tile_y)
	local tile_tags = { "CLASSIFIED", "abysscliff_tile" }
	for i, v in ipairs(TheSim:FindEntities(x, 0, z, 0.1, tile_tags)) do
		if v ~= inst then
			inst.OnRemoveEntity = nil
			inst:Remove()
			return
		end
	end

	if not OverrideTile(map, tile_x, tile_y) then
		inst.OnRemoveEntity = nil
		inst:Remove()
		return
	end

	inst.Transform:SetPosition(x, 0, z)

	RefreshOverhang(map, tile_x, tile_y, x, z, false)
end

--Client & Non-Dedicated Server
local function InitOverhang(inst)
	local map = TheWorld.Map
	local tile_x, tile_y = map:GetTileCoordsAtPoint(inst.Transform:GetWorldPosition())
	local x, _, z = map:GetTileCenterPoint(tile_x, tile_y)
	RefreshOverhang(map, tile_x, tile_y, x, z, false)

	--V2C: technically not safe to remove post update fns during update loop, but
	--     we will do it anyway as long as we don't use any other post update fns
	inst:RemoveComponent("updatelooper") --only exists on clients
end

local function OnRemoveEntity(inst)
	local map = TheWorld.Map
	local x, _, z = inst.Transform:GetWorldPosition()
	local tile_x, tile_y = map:GetTileCoordsAtPoint(x, 0, z)
	RefreshOverhang(map, tile_x, tile_y, x, z, true)
	if TheWorld.ismastersim then
		RevertTile(map, tile_x, tile_y, x, z)
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("abyss_cliff")
	inst.AnimState:SetBuild("abyss_cliff")
	inst.AnimState:PlayAnimation("inner_4_1")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_GROUND)

	inst:AddTag("NOCLICK")
	inst:AddTag("CLASSIFIED")
	inst:AddTag("abysscliff_tile")

	inst.OnRemoveEntity = OnRemoveEntity

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:AddComponent("updatelooper")
		inst.components.updatelooper:AddPostUpdateFn(InitOverhang)

		return inst
	end

	inst.AlignToTile = AlignToTile
	if not TheNet:IsDedicated() then
		inst.OnLoadPostPass = InitOverhang
	end

	return inst
end

return Prefab("abysscliff_tile", fn, assets)
