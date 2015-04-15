
local MIN_PLAYERS_FOR_KICK = 3
local VOTING_KICK = 0x01
local VOTING_YES = 0x1

local Voting = Class(function(self, inst)
    self.inst = inst
    self.ismastersim = TheWorld.ismastersim

    self._vote_kick_enabled = net_bool(inst.GUID, "voting._vote_kick_enabled")
    --Don't initialize server settings here, otherwise pristine
    --state may go out of sync with clients.  Use OnPostInit.

    self:Reset()
end)

function Voting:OnPostInit()
    if self.ismastersim then
        self._vote_kick_enabled:set(TheNet:GetDefaultVoteKickEnabled())
    end
end

function Voting:Reset()
    self.user_id = TheNet:GetUserID()
    self.vote_starters = {}    
    self.votes_in_progress = {}
    self.vote_time_remaining = {}
    self.votes_cast = {}
    self.kicked_players = {}
    self.timer_enabled = false
end

-- Server only
function Voting:ReceiveVote(vote_id, poll_id, voter_id, choice, num_votes)  
    --print("***** Voting:ReceiveVote", vote_id, poll_id, voter_id, choice, num_votes)          
    if VOTING_KICK == vote_id then
        if 1 == num_votes then 
            self:StartPlayerKickVote(poll_id, voter_id)      
        end
         
        self:RegisterPlayerKickVote(poll_id, voter_id, num_votes)    
    end
end

-- Server/Client
function Voting:VoteInProgress(poll_id)    
    return nil ~= self.votes_in_progress[poll_id]
end

-- Server/Client
function Voting:VoteAlreadyCast(poll_id)
    return nil ~= self.votes_cast[poll_id]
end

-- Server/Client
function Voting:TimeRemainingInVote(poll_id)
    local time_string = ""
    if self.vote_time_remaining[poll_id] then
        -- duration is in seconds
        local time_in_seconds = self.vote_time_remaining[poll_id]
        local minutes = math.floor(time_in_seconds / 60)
        local seconds = math.floor(time_in_seconds - (minutes * 60))
        time_string = string.format("%d:%02d", minutes, seconds)
    end
    return time_string
end

-- Server/Client
function Voting:UpdateVoteTimes()
    -- called roughly once every second to update vote timers
    local new_times = {}
    for key, time_remaining in pairs(self.vote_time_remaining) do     
        time_remaining = time_remaining - 1
        if time_remaining > 0 then
            new_times[key] = time_remaining
        end        
    end
    
    self.vote_time_remaining = new_times    
    if next(self.vote_time_remaining) ~= nil then
        scheduler:ExecuteInTime(1, function() self:UpdateVoteTimes() end, nil, self)    
    else
        self.timer_enabled = false
    end
end

-- Server/Client; response to broadcast from server, received by all clients and called locally by server as well
function Voting:NotifyVoteStart(vote_id, poll_id, voter_id, choice)
    -- this is a notification broadcast to all clients (server included) 
    -- it is intended as purely informational, the server is doing the actual vote tabulation       
    --print("***** Voting:NotifyVoteStart", vote_id, poll_id, voter_id, choice)
    
    -- record the start of the vote
    self.votes_in_progress[poll_id] = true
    
    -- record the player who started the vote    
    if nil == self.vote_starters[poll_id] then
        self.vote_starters[poll_id] = {}
    end
    table.insert(self.vote_starters[poll_id], voter_id)  
    
    if VOTING_KICK == vote_id then
        self.vote_time_remaining[poll_id] = TUNING.VOTE_KICK_DURATION
    end
    
    if next(self.vote_time_remaining) ~= nil and not self.timer_enabled then
        scheduler:ExecuteInTime(1, function() self:UpdateVoteTimes() end, nil, self)    
        self.timer_enabled = true
    end
end

-- Server/Client; response to broadcast from server, received by all clients and called locally by server as well
function Voting:NotifyVoteEnd(vote_id, poll_id)    
    -- this is a notification broadcast to all clients (server included) 
    -- it is intended as purely informational, the server is doing the actual vote tabulation      
    --print("***** Voting:NotifyVoteEnd", vote_id, poll_id)
        
    -- remove any time remaining
    if self.vote_time_remaining[poll_id] then
        self.vote_time_remaining[poll_id] = nil   
    end    
    
    -- remove the poll from the active polls
    if self.votes_in_progress[poll_id] then
        self.votes_in_progress[poll_id] = nil   
    end
    
    -- remove any votes cast in this poll
    if self.votes_cast[poll_id] then
        self.votes_cast[poll_id] = nil
    end    
end

-- Server/Client; response to broadcast from server, received by all clients and called locally by server as well
function Voting:NotifyVoteCast(vote_id, poll_id, voter_id, choice, num_votes)    
    -- this is a notification broadcast to all clients (server included) 
    -- it is intended as purely informational, the server is doing the actual vote tabulation        
    --print("Voting:NotifyVoteCast", vote_id, poll_id, voter_id, choice, num_votes)       
end

-----------------------------------------------------------------
--
--  Vote Kick specific code below this point
--
-----------------------------------------------------------------

-- Server only
function Voting:EnableVoteKick(enable)
    self._vote_kick_enabled:set(enable ~= false)
end

-- Server/Client
function Voting:VoteKickEnabled()
    return self._vote_kick_enabled:value()
end

-- Server/Client
function Voting:EnoughPlayersForVoteKick()
    return TheNet:GetPlayerCount() >= MIN_PLAYERS_FOR_KICK
end

-- Server/Client
function Voting:HasStartedVoteKick(victim_id)
    local has_started = false
    if nil ~= self.vote_starters[victim_id] then
        for index, id in pairs(self.vote_starters[victim_id]) do
            if self.user_id == id then
                has_started = true
            end
        end
    end
    
    --print("**** Voting:HasStartedVoteKick: ", self.user_id, victim_id, has_started)
    return has_started
end

-- Server/Client
function Voting:CanInitiateVoteKick(victim_id)    
    return (self:EnoughPlayersForVoteKick() and (not self:HasStartedVoteKick(victim_id)))
end

-- Server/Client
function Voting:VoteKick(victim_id)
    --print("**** Voting:VoteKick: ", self.user_id, victim_id)
    if self:EnoughPlayersForVoteKick() and (not self:VoteAlreadyCast(victim_id)) then
        self.votes_cast[victim_id] = VOTING_YES -- this must come before the call to TheNet otherwise things might happen in the wrong order on the server
        TheNet:CastVote(VOTING_KICK, victim_id, VOTING_YES)
    end
end

-- Server only
function Voting:StartPlayerKickVote(victim_id, voter_id)
    if not self.ismastersim then return end
    
    -- sanity check: the vote shouldn't already be in progress
    --assert(nil == self.votes_in_progress[victim_id])
    
    if self.votes_in_progress[victim_id] then
        --print("Voting:StartPlayerKickVote trying to start a vote already in progress: victim: " .. victim_id .. " voter: " .. voter_id)
        return
    end    
    
    -- check that the same voter hasn't already started another vote against this victim    
    if nil == self.vote_starters[victim_id] then
        self.vote_starters[victim_id] = {}
    else
        local player_already_started = false
        for index, id in pairs(self.vote_starters[victim_id]) do
            if voter_id == id then
                player_already_started = true
            end
        end
        
        -- you can't start more than one vote against the same player in the same world
        if player_already_started then            
            --print("Voting: Player " .. voter_id .. " has already started a vote against " .. victim_id)
            return
        end
    end    
                
    local voter_inst = TheNet:LookupPlayerInstByUserID(voter_id)	
    local victim_inst = TheNet:LookupPlayerInstByUserID(victim_id)	
    -- only start the vote if the voter and victim are still present
    if voter_inst and victim_inst then
        local announcement = string.format(STRINGS.VOTING.KICK.START, voter_inst.name, victim_inst.name)    
        TheNet:Announce(announcement, victim_inst.entity)
    
        -- broadcase the start of the vote
        TheNet:StartVote(VOTING_KICK, victim_id, voter_id, VOTING_YES)
            
        scheduler:ExecuteInTime(TUNING.VOTE_KICK_DURATION, function() self:ExpirePlayerKickVote(victim_id) end, nil, self)    
    end    
end

-- Server only
function Voting:ExpirePlayerKickVote(victim_id)
    if not self.ismastersim then return end
    
    -- the vote may or may not exist depending on whether it already succeeded
    if self.votes_in_progress[victim_id] then               
        -- announce failure
        local victim_inst = TheNet:LookupPlayerInstByUserID(victim_id)	
        -- only announce if the player is still around. he may have left...
        if victim_inst then
            local announcement = string.format(STRINGS.VOTING.KICK.FAILURE, victim_inst.name)
            TheNet:Announce(announcement, victim_inst.entity)
        end
        
        -- end the vote
        self:EndKickVote(victim_id)        
    end
end

-- Server only
function Voting:RegisterPlayerKickVote(victim_id, voter_id, num_votes)     
    if not self.ismastersim then return end       
    
    -- sanity check: the vote should exist
    if not self.votes_in_progress[victim_id] then
        --print("Voting:RegisterPlayerKickVote trying to register a vote not in progress: victim: " .. victim_id .. " voter: " .. voter_id)
        return
    end
    
    -- sanity check: verify the vote count
    assert(num_votes == TheNet:CountVotes(victim_id, VOTING_YES))
    
    -- check whether there are enough votes
    local required_votes = TheNet:GetPlayerCount() - 1
    if num_votes >= required_votes then
        -- announce success
        local victim_inst = TheNet:LookupPlayerInstByUserID(victim_id)	
        -- only announce if the player is still around. he may have left...
        if victim_inst then
            local announcement = string.format(STRINGS.VOTING.KICK.SUCCESS, victim_inst.name)
            TheNet:Announce(announcement, victim_inst.entity)
        end
                
        -- record the kick and escalate penalties as necessary
        if nil == self.kicked_players[victim_id] then
            self.kicked_players[victim_id] = 0
        else
            self.kicked_players[victim_id] = self.kicked_players[victim_id] + 1
        end
        
        local ban_time = self.kicked_players[victim_id] * TUNING.VOTE_KICK_BAN_DURATION               
        if 0 < ban_time then        
            -- timed ban if appropriate
            TheNet:BanForTime(victim_id, ban_time)
        else
            -- only kick the first time
            TheNet:Kick(victim_id)    
        end
               
        -- end the vote
        self:EndKickVote(victim_id)
    end

end

-- Server only
function Voting:EndKickVote(victim_id)
    if not self.ismastersim then return end
    
    -- remove the vote
    TheNet:EndVote(VOTING_KICK, victim_id)
end

return Voting