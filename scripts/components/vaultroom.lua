local defs = require("prefabs/vaultroom_defs")

local SAVE_RADIUS = 28
local SAVE_NO_TAGS = { "INLIMBO", "vault_teleporter" }

local VaultRoom = Class(function(self, inst)
	self.inst = inst
	self.roomid = nil
end)

function VaultRoom:GetCurrentRoomId()
	return self.roomid
end

function VaultRoom:LayoutNewRoom(id)
	assert(self.roomid == nil)
	local def = defs[id]
	if def == nil then
		assert(false)
		return
	end

	self.roomid = id

	local x, _, z = self.inst.Transform:GetWorldPosition()
	if def.TerraformRoomAtXZ then
		def.TerraformRoomAtXZ(self.inst, x, z)
	else
		defs.ResetTerraformRoomAtXZ(self.inst, x, z)
	end
	if def.LayoutNewRoomAtXZ then
		POPULATING = true --@V2C: hope this is safe XD
		def.LayoutNewRoomAtXZ(self.inst, x, z)
		POPULATING = false
	end
end

function VaultRoom:ShouldSaveEntity(ent)
	return not ent.isplayer
		and not (ent.components.follower and
				ent.components.follower:GetLeader() and
				ent.components.follower:GetLeader().isplayer)
		and not ent:HasTag("irreplaceable")
end

function VaultRoom:UnloadRoom(save)
	--assert(self.roomid ~= nil)
	local def = defs[self.roomid]
	if def == nil then
		--assert(false)
		return
	end

	self.roomid = nil

	local x, _, z = self.inst.Transform:GetWorldPosition()

	local map = TheWorld.Map
	local tile_x, tile_y = map:GetTileCoordsAtPoint(x, 0, z)

	local function _inroom(ent)
		local x1, _, z1 = ent.Transform:GetWorldPosition()
		local tx, ty = map:GetTileCoordsAtPoint(x1, 0, z1)
		if math.abs(tx - tile_x) <= 5 and math.abs(ty - tile_y) <= 5 then
			return true
		end
		local tile = map:GetTile(tx, ty)
		return tile == WORLD_TILES.VAULT
			or (tile == WORLD_TILES.IMPASSABLE and map:IsVisualGroundAtPoint(x1, 0, z1))
	end

	local recbyguid, refs, toremove
	if save then
		save = { ents = {} }
		recbyguid = {}
		refs = {}
		toremove = {}
	end

	POPULATING = true --@V2C: hope this is safe XD

	local ents = TheSim:FindEntities(x, 0, z, SAVE_RADIUS, nil, SAVE_NO_TAGS)
	local keepidx = 0
	for i = 1, #ents do
		local v = ents[i]
        ents[i] = nil
		if not v:IsValid() or v.entity:GetParent() or not _inroom(v) then
            -- Do nothing.
		elseif self:ShouldSaveEntity(v) then
			if save then
				table.insert(toremove, v) --defer removal so we can save references
				if v.persists and v.prefab --[[and v.Transform and v.entity:GetParent() == nil redundant checks]] then
					local record, new_refs = v:GetSaveRecord()
					record.prefab = nil

					if new_refs then
						refs[v.GUID] = v
						for _, guid in pairs(new_refs) do
							refs[guid] = v
						end
					end

					recbyguid[v.GUID] = record

					if save.ents[v.prefab] == nil then
						save.ents[v.prefab] = {}
					end
					table.insert(save.ents[v.prefab], record)
				end
			else
				v:Remove()
			end
		else
			--Don't remove entities that aren't saved by the room
			keepidx = keepidx + 1
			ents[keepidx] = v
		end
	end

	if refs then
		for guid, v in pairs(refs) do
			local record = recbyguid[guid]
			if record then
				record.id = guid
			else
				print("Missing reference:", v, "->", guid, Ents[guid])
			end
		end
	end

	if toremove then
		for i, v in ipairs(toremove) do
			v:Remove()
		end
	end

	POPULATING = false

	return save, ents --remaining entities that weren't saved/removed
end

function VaultRoom:ResetRoom()
	if self.roomid then
		self:UnloadRoom()
	end
	local x, _, z = self.inst.Transform:GetWorldPosition()
	defs.ResetTerraformRoomAtXZ(self.inst, x, z)
end

function VaultRoom:LoadRoom(id, data)
	if data == nil then
		self:LayoutNewRoom(id)
		return
	end

	assert(self.roomid == nil)
	local def = defs[id]
	if def == nil then
		assert(false)
		return
	end

	self.roomid = id

	local x, _, z = self.inst.Transform:GetWorldPosition()
	if def.TerraformRoomAtXZ then
		def.TerraformRoomAtXZ(self.inst, x, z)
	else
		defs.ResetTerraformRoomAtXZ(self.inst, x, z)
	end

	POPULATING = true --@V2C: hope this is safe XD
	local newents = {}
	for prefab, ents in pairs(data.ents) do
		for i, v in ipairs(ents) do
			v.prefab = v.prefab or prefab -- prefab field is stripped out when entities are saved in global entity collections, so put it back
			SpawnSaveRecord(v, newents)
		end
	end
	--post pass in neccessary to hook up references
	for _, v in pairs(newents) do
		v.entity:LoadPostPass(newents, v.data)
	end
	POPULATING = false
end

function VaultRoom:OnSave()
	return self.roomid and { room = self.roomid } or nil
end

function VaultRoom:OnLoad(data)--, ents)
	self.roomid = data and data.room or nil
end

return VaultRoom
