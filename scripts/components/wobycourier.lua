local WobyCourier = Class(function(self, inst)
    self.inst = inst

    self.shardid = TheShard:GetShardId()

    self.positions = {}
end)

function WobyCourier:NetworkLocation()
    if self.inst.player_classified then
        local xz = self.positions[self.shardid]
        if xz then
            self.inst.player_classified.wobycourier_chest_posx:set(xz.x)
            self.inst.player_classified.wobycourier_chest_posz:set(xz.z)
        else
            self.inst.player_classified.wobycourier_chest_posx:set(WOBYCOURIER_NO_CHEST_COORD)
            self.inst.player_classified.wobycourier_chest_posz:set(WOBYCOURIER_NO_CHEST_COORD)
        end
        if self.inst == ThePlayer then -- Server is client.
            self.inst:PushEvent("updatewobycourierchesticon")
        end
    end
end

function WobyCourier:StoreXZ(x, z) -- World coordinates in.
    local xz = self.positions[self.shardid] or {}
    local y
    x, y, z = TheWorld.Map:GetTileCenterPoint(x, 0, z)
    xz.x = math.floor(x / TILE_SCALE)
    xz.z = math.floor(z / TILE_SCALE)
    self.positions[self.shardid] = xz
    self:NetworkLocation()
    return true
end

function WobyCourier:ClearXZ()
    if self.positions[self.shardid] then
        self.positions[self.shardid] = nil
        self:NetworkLocation()
        return true
    end
    return false
end

function WobyCourier:OnSave()
    if next(self.positions) == nil then
        return nil
    end

    return {
        positions = self.positions,
    }
end

function WobyCourier:OnLoad(data)
    if data == nil then
        return
    end

    if data.positions then
        self.positions = data.positions
        self:NetworkLocation()
    end
end

function WobyCourier:GetDebugString()
    local x, z = self:GetXZ()
    if not x then
        return "NPOS"
    end
    return string.format("Pos: %.1f %.1f", x, z)
end

return WobyCourier
