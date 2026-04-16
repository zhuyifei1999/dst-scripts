-- OMAR: For wx78_possessedbody only, right now.

RunAwayToDist = Class(BehaviourNode, function(self, inst, hunterparams, safe_dist, fn, fix_overhang, walk_instead, allow_boats)
    BehaviourNode._ctor(self, "RunAway")
    self.safe_dist = safe_dist
    if type(hunterparams) == "table" then
		self.gethunterfn = hunterparams.getfn
    end
    self.inst = inst
    self.shouldrunfn = fn
	self.fix_overhang = fix_overhang -- this will put the point check back on land if self.inst is stepping on the ocean overhang part of the land
    self.walk_instead = walk_instead
    self.allow_boats = allow_boats or nil
end)

function RunAwayToDist:__tostring()
    return string.format("RUNAWAY %f from: %s", self.safe_dist, tostring(self.hunter))
end

function RunAwayToDist:GetRunPosition(pt, hp, safe_dist)
    if self.avoid_angle ~= nil then
        local avoid_time = GetTime() - self.avoid_time
        if avoid_time < 1 then
            return self.avoid_angle
        else
            self.avoid_time = nil
            self.avoid_angle = nil
        end
    end

	local angle = self.inst:GetAngleToPoint(hp) + 180 -- + math.random(30)-15
    if angle > 360 then
        angle = angle - 360
    end

    local radius = safe_dist

	local find_offset_fn = self.inst.components.locomotor:IsAquatic() and FindSwimmableOffset or FindWalkableOffset
    local allowwater_or_allowboat = nil
    if find_offset_fn == FindWalkableOffset then
        allowwater_or_allowboat = self.inst.components.locomotor:CanPathfindOnWater()
    end

	local result_offset, result_angle, deflected = find_offset_fn(pt, angle*DEGREES, radius, 8, true, false, nil, allowwater_or_allowboat or self.allow_boats) -- try avoiding walls
    if result_angle == nil then
		result_offset, result_angle, deflected = find_offset_fn(pt, angle*DEGREES, radius, 8, true, true, nil, self.allow_boats) -- ok don't try to avoid walls
        if result_angle == nil then
			if self.fix_overhang and not TheWorld.Map:IsAboveGroundAtPoint(pt:Get()) then
                if self.inst.components.locomotor:IsAquatic() then
                    local back_on_ocean = FindNearbyOcean(pt, 1)
				    if back_on_ocean ~= nil then
			            result_offset, result_angle, deflected = FindSwimmableOffset(back_on_ocean, math.random()*2*math.pi, radius - 1, 8, true, true)
				    end
                else
				    local back_on_ground = FindNearbyLand(pt, 1) -- find a point back on proper ground
				    if back_on_ground ~= nil then
			            result_offset, result_angle, deflected = FindWalkableOffset(back_on_ground, math.random()*2*math.pi, radius - 1, 8, true, true, nil, nil, self.allow_boats) -- ok don't try to avoid walls, but at least avoid water
				    end
                end
			end
			if result_angle == nil then
	            return result_offset -- ok whatever, just run
			end
        end
    end

    result_angle = result_angle / DEGREES
    if deflected then
        self.avoid_time = GetTime()
        self.avoid_angle = result_offset
    end
    return result_offset
end

local TOLERANCE_DIST = .5
local TOLERANCE_DIST_SQ = TOLERANCE_DIST*TOLERANCE_DIST
function RunAwayToDist:Visit()
    if self.status == READY then
		if self.gethunterfn then
			self.hunter = self.gethunterfn(self.inst)
        end

        if self.hunter ~= nil and self.shouldrunfn ~= nil and not self.shouldrunfn(self.hunter, self.inst) then
            self.hunter = nil
        end

        self.status = self.hunter ~= nil and RUNNING or FAILED
    end

    if self.status == RUNNING then
        if self.hunter == nil or not self.hunter.entity:IsValid() or IsEntityDead(self.hunter) then
            self.status = FAILED
            self.inst.components.locomotor:Stop()
        else
            local pt = self.inst:GetPosition()
            local hp = self.hunter:GetPosition()
            local safe_dist = FunctionOrValue(self.safe_dist, self.inst, self.hunter)
            local pos = self:GetRunPosition(pt, hp, safe_dist)

            if distsq(pos, pt) <= TOLERANCE_DIST_SQ then
                self.status = FAILED
                self.inst.components.locomotor:Stop()
                return
            end

            if pos ~= nil then
                pos = hp + pos
                if self.walk_instead then
                    self.inst.components.locomotor.dest = nil
                    self.inst.components.locomotor:GoToPoint(pos, nil, false)
                else
                    self.inst.components.locomotor:GoToPoint(pos, nil, true)
                end
            else
                self.status = FAILED
                self.inst.components.locomotor:Stop()
            end

            local dist_sq = safe_dist * safe_dist
            if math.abs(distsq(hp, pt) - dist_sq) < 0.75 then
                self.status = SUCCESS
                self.inst.components.locomotor:Stop()
            end

            self:Sleep(.125)
        end
    end
end