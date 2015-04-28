local Leader = Class(function(self, inst)
    self.inst = inst
    self.followers = {}
    self.numfollowers = 0
    
    self.inst:ListenForEvent("newcombattarget", function(inst, data) self:OnNewTarget(data.target) end)
    self.inst:ListenForEvent("attacked", function(inst, data) self:OnAttacked(data.attacker) end)    
    self.inst:ListenForEvent("death", function(inst) self:RemoveAllFollowersOnDeath() end)
end)

function Leader:IsFollower(guy)
    return self.followers[guy] ~= nil
end

function Leader:OnAttacked(attacker)
    if not self:IsFollower(attacker) and self.inst ~= attacker then
        for k,v in pairs(self.followers) do
            if k.components.combat and k.components.follower and k.components.follower.canaccepttarget then
                k.components.combat:SuggestTarget(attacker)
            end
        end
    end
end

function Leader:CountFollowers(tag)
    if not tag then
        return self.numfollowers
    else
        local count = 0
        for k,v in pairs(self.followers) do
            if k:HasTag(tag) then
                count = count + 1
            end
        end
        return count
    end
end

function Leader:OnNewTarget(target)
    for k,v in pairs(self.followers) do
        if k.components.combat and k.components.follower and k.components.follower.canaccepttarget then
            k.components.combat:SuggestTarget(target)
        end
    end
end

function Leader:RemoveFollower(follower, invalid)
    if follower and self.followers[follower] then
        self.followers[follower] = nil
        self.numfollowers = self.numfollowers - 1
        if self.onremovefollower then
            self.onremovefollower(self.inst, follower)
        end

		if not invalid then
	        follower:PushEvent("stopfollowing", {leader = self.inst} )
	        follower.components.follower:SetLeader(nil)
		end
    end
end

function Leader:AddFollower(follower, keepondeath)
    if self.followers[follower] == nil and follower.components.follower then
        self.followers[follower] = true
        self.numfollowers = self.numfollowers + 1
        follower.components.follower:SetLeader(self.inst)
        follower:PushEvent("startfollowing", { leader = self.inst })

        if not keepondeath then
            local ondeath = function()
                self:RemoveFollower(follower)
            end
            self.inst:ListenForEvent("death", ondeath, follower)
            follower:ListenForEvent("death", ondeath, self.inst)
        end

        self.inst:ListenForEvent("onremove", function(inst, data) self:RemoveFollower(follower, true) end, follower)

	    if self.inst:HasTag("player") and follower.prefab ~= nil then
		    ProfileStatsAdd("befriend_"..follower.prefab)
	    end
	end
end

function Leader:RemoveFollowersByTag(tag, validateremovefn)
    for k,v in pairs(self.followers) do
        if k:HasTag(tag) then
            if validateremovefn then
                if validateremovefn(k) then
                    self:RemoveFollower(k)
                end
            else
                self:RemoveFollower(k)
            end
        end
    end
end

function Leader:RemoveAllFollowers()
    for k,v in pairs(self.followers) do
        self:RemoveFollower(k)
    end
end

function Leader:RemoveAllFollowersOnDeath()
    for k, v in pairs(self.followers) do
        if not (k.components.follower ~= nil and k.components.follower.keepdeadleader) then
            self:RemoveFollower(k)
        end
    end
end

function Leader:IsBeingFollowedBy(prefabName)
    for k,v in pairs(self.followers) do
        if k.prefab == prefabName then
            return true
        end
    end
    return false
end


function Leader:OnSave()
    if self.inst:HasTag("player") then
        return
    end

    local followers = {}
    for k, v in pairs(self.followers) do
        table.insert(followers, k.GUID)
    end
    
    if #followers > 0 then
        return { followers = followers }, followers
    end
end

function Leader:LoadPostPass(newents, savedata)
    if self.inst:HasTag("player") then
        return
    end

    if savedata and savedata.followers then
        for k,v in pairs(savedata.followers) do
            local targ = newents[v]
            if targ and targ.entity.components.follower then
                self:AddFollower(targ.entity)
            end
        end
    end
end

function Leader:OnRemoveEntity()
    --print("Leader:OnRemoveEntity")
	self:RemoveAllFollowers()
end

function Leader:GetDebugString()
    return "followers:"..self.numfollowers
end

return Leader