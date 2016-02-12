
local VoteDialog = require "widgets/votedialog"

local _Voter = nil

--Vote kick functions
local VOTE_KICK_SQUELCH_TABLE = {}
function KickVoteInitOptions( player, parameters_string )
	local index = tonumber(parameters_string)
	local ClientObjs = TheNet:GetClientTable()
	if TheNet:IsDedicated() then
		index = index + 1
	end
	if index == nil or index > #ClientObjs or index < 1 or VOTE_KICK_SQUELCH_TABLE[player.userid] ~= nil then
		return false,nil
	else
		if ClientObjs[index].admin then
			print("Can't vote kick an admin", index, ClientObjs[index].userid, player.userid)
			return false,nil
		end
		
		if player.userid == ClientObjs[index].userid then
			print("Can't vote kick yourself", player.userid)
			return false,nil
		end
		
		local option_data = {title="Vote kick player " .. ClientObjs[index].name, options={}, kick_userid=ClientObjs[index].userid, player_name = ClientObjs[index].name, vote_caller_userid=player.userid}
		option_data.options[1] = {description="Yes", value=true}
		option_data.options[2] = {description="No", value=false}
		return true,option_data
	end
end

VOTE_KICK_REQUIRED_SCALE = 0.75
VOTE_KICK_SQUELCH_TIME = 5 * 60
function KickVoteProcessResult( option_data, vote_result, total_votes )
	local votes_required = VOTE_KICK_REQUIRED_SCALE * total_votes
	votes_required = math.max( votes_required, 1 ) --must have atleast 1 vote
	if vote_result.vote_count >= votes_required and vote_result.value == true then
		TheNet:Kick(option_data.kick_userid)
		TheNet:Announce( "Vote kick passed: Kicking " .. option_data.player_name, nil, nil, "vote" )
	else
		VOTE_KICK_SQUELCH_TABLE[option_data.vote_caller_userid] = VOTE_KICK_SQUELCH_TIME
		_Voter:UpdateSquelchTable()
		if vote_result.value == true then
			TheNet:Announce( "Vote kick failed. " .. string.format("Received %d vote%s of the required %d", vote_result.vote_count, (vote_result.vote_count == 1 and "" or "s"), math.ceil(votes_required)) .. ".", nil, nil, "vote" )
		else
			TheNet:Announce( "Vote kick failed.", nil, nil, "vote" )	
		end
	end
end

local MAX_VOTES = 8

local Voter = Class(function(self, inst)
    self.inst = inst
	_Voter = self
	
	self.vote_timer = 0
	self.vote_timer_start = 0
	self.net_vote_timer_start = net_float(self.inst.GUID, "net_vote_timer_start", "none" )
	
	self.active_vote = nil	
	self.net_is_vote_active = net_bool(self.inst.GUID, "is_vote_active", "is_vote_activedirty" )
	self.net_is_kick_enabled = net_bool(self.inst.GUID, "is_kick_enabled", "is_kick_enableddirty" )
	self.net_kick_squelch_users = net_string(self.inst.GUID, "kick_squelch_users", "kick_squelch_usersdirty" )
	
	self:EmptyVoteOptions()
	self.networked_vote_options = { title = net_string(self.inst.GUID, "title", "titledirty" ), num_options = net_byte(self.inst.GUID, "num_options", "none" ), options={} }
	for i = 1,MAX_VOTES,1 do
		self.networked_vote_options.options[i] = { description = net_string(self.inst.GUID, "description"..i, "none" ), vote_count = net_byte(self.inst.GUID, "vote_count"..i, "vote_countdirty"..i ) }
	end
	
	self.show_dialog = false
	self.net_show_dialog = net_bool(self.inst.GUID, "show_dialog_event", "show_dialogdirty" )
  
    if TheWorld.ismastersim then
		self:SetupCommands()
	else
		for i = 1,MAX_VOTES,1 do
			local closure_i = i
			self.inst:ListenForEvent("vote_countdirty"..i, function() self:OnVoteCountDirty(closure_i) end )
		end
		self.inst:ListenForEvent("show_dialogdirty", function() self:OnShowDialogDirty() end )
		self.inst:ListenForEvent("kick_squelch_usersdirty", function() self:OnKickSquelchUsersDirty() end )
	end
end)

function Voter:OnVoteCountDirty(i)
	self.vote_options.options[i].vote_count = self.networked_vote_options.options[i].vote_count:value()
end
function Voter:ReadNetVars()
	self.vote_timer_start = self.net_vote_timer_start:value()
	self.vote_options.title = self.networked_vote_options.title:value()
	self.vote_options.num_options = self.networked_vote_options.num_options:value()
	for i = 1,self.vote_options.num_options,1 do
		self.vote_options.options[i].description = self.networked_vote_options.options[i].description:value()
		self.vote_options.options[i].vote_count = self.networked_vote_options.options[i].vote_count:value()
	end	
end
function Voter:OnShowDialogDirty()
	self.show_dialog = self.net_show_dialog:value()
	if self.show_dialog then
		self:ReadNetVars()
		TheWorld:PushEvent("showvotedialog")
		self.vote_timer = self.vote_timer_start
		self.inst:StartUpdatingComponent(self)
	else
		TheWorld:PushEvent("hidevotedialog")
	end
end

function Voter:EmptyVoteOptions()
	self.vote_options = { title="", num_options = 0, options={} }
	for i = 1,MAX_VOTES,1 do
		self.vote_options.options[i] = { description = "", vote_count = 0 }
	end
end

function Voter:SetupCommands()
	self.commands = {}
		
	self.commands["kick"] = { InitOptionsFn = KickVoteInitOptions, ProcessResultFn = KickVoteProcessResult, Timeout = 30 }
	self.commands["kick"].enabled = TheSim:GetSetting("GAMEPLAY", "vote_kick_enabled") == "true"
	self.net_is_kick_enabled:set( self.commands["kick"].enabled )
	
	--Add in all the commands added by mods
	for command_name,command in pairs( ModManager:GetVoteCommands() ) do
		self.commands[command_name] = command
		self.commands[command_name].enabled = true
	end
end

function Voter:GetOptionData()
	return self.vote_options
end
function Voter:GetTimer()
	return self.vote_timer
end
function Voter:GetShowDialog()
	return self.show_dialog
end

function Voter:SetActiveVote( command )
	self.active_vote = command
	self.net_is_vote_active:set( self.active_vote ~= nil )
end

function Voter:StartVoteInternal( player, command_name, parameters )
	if not self:IsVoteActive() and self.commands[command_name] ~= nil and self.commands[command_name].enabled then
		self:SetActiveVote( self.commands[command_name] )
		local success = false
		success,self.vote_options = self.active_vote.InitOptionsFn(player, parameters)
		if success then
			self.vote_timer = self.commands[command_name].Timeout
			self.net_vote_timer_start:set( self.vote_timer )
			
			self.vote_options.num_options = #self.vote_options.options
			self.vote_options.voters = {}
			--set the vote counts to 0
			for _,option in pairs(self.vote_options.options) do
				option.vote_count = 0
			end

			--populate networked_vote_options
			self.networked_vote_options.title:set(self.vote_options.title)
			self.networked_vote_options.num_options:set(self.vote_options.num_options)
			for i = 1,self.vote_options.num_options,1 do
				self.networked_vote_options.options[i].description:set(self.vote_options.options[i].description)
				self.networked_vote_options.options[i].vote_count:set(self.vote_options.options[i].vote_count)
			end
			for i = self.vote_options.num_options+1,MAX_VOTES,1 do
				self.networked_vote_options.options[i].description:set("")
				self.networked_vote_options.options[i].vote_count:set(0)
			end
			
			TheWorld:PushEvent("showvotedialog")
			self.show_dialog = true
			self.net_show_dialog:set(true)
			self.inst:StartUpdatingComponent(self)
		else
			self:SetActiveVote(nil)
		end
	end
end

function Voter:StartVote( player, command_name, parameters )
	print("Voter:StartVote " .. command_name .. ":" .. parameters )
	if TheWorld.ismastersim then
		self:StartVoteInternal( player, command_name, parameters )
	else
		SendRPCToServer(RPC.StartVote, command_name, parameters)
	end	
end

function Voter:ReceivedVoteInternal( player, option_index )
	if self.vote_options ~= nil and self.vote_options.options ~= nil and self.vote_options.options[option_index] ~= nil then
		if not table.contains( self.vote_options.voters, player.userid ) then
			local option = self.vote_options.options[option_index]
			option.vote_count = option.vote_count + 1
			
			self.networked_vote_options.options[option_index].vote_count:set(option.vote_count)
			
			table.insert( self.vote_options.voters, player.userid )
			print("vote received for " .. option.description .. " from " .. player.userid )

			--check if all votes are in
			local ClientObjs = TheNet:GetClientTable()
			local pending_vote = false
            local is_dedicated = not TheNet:GetServerIsClientHosted()
			for _,client in pairs(ClientObjs) do
				if not is_dedicated or client.performance == nil then
					if not table.contains( self.vote_options.voters, client.userid ) then
						print("pending vote", client.userid)
						pending_vote = true
						break
					end
				end
			end			
			if not pending_vote then			
				self:VoteComplete()
				return
			end
		else
			print( player.userid .. " already voted")
		end
	end
end

function Voter:ReceivedVote( player, option_index )
	if TheWorld.ismastersim then
		self:ReceivedVoteInternal( player, option_index )
	else
		SendRPCToServer(RPC.Vote, option_index)
	end
end

function Voter:IsVoteActive()
	if TheWorld.ismastersim then
		return self.active_vote ~= nil
	else
		return self.net_is_vote_active:value()
	end
end

function Voter:IsVoteKickEnabled()
	if TheWorld.ismastersim then
		return self.commands["kick"].enabled
	else
		return self.net_is_kick_enabled:value()
	end
end

function Voter:IsUserSquelched(userid)
	--print("IsUserSquelched", userid)
	--dumptable(VOTE_KICK_SQUELCH_TABLE)
	return VOTE_KICK_SQUELCH_TABLE[userid] ~= nil
end

function Voter:OnKickSquelchUsersDirty()
	--print("### OnKickSquelchUsersDirty called", self.net_kick_squelch_users:value())
	VOTE_KICK_SQUELCH_TABLE = {}
	for userid in string.gmatch(self.net_kick_squelch_users:value(), '([^,]+)') do
		print("enabled userid " .. userid)
		VOTE_KICK_SQUELCH_TABLE[userid] = true
	end
end

function Voter:UpdateSquelchTable()
	local str_squelch_users = ""
	for userid,_ in pairs( VOTE_KICK_SQUELCH_TABLE ) do
		str_squelch_users = str_squelch_users .. userid .. ","
	end
	str_squelch_users = string.sub( str_squelch_users, 1, -2 )
	--print("Setting squelch users" .. str_squelch_users)
	self.net_kick_squelch_users:set(str_squelch_users)
end


function Voter:OnUpdate(dt)
	self.vote_timer = self.vote_timer - dt
	if self.vote_timer < 0 then
		self.vote_timer = 0
	end
	
	if TheWorld.ismastersim then
		self:ServerOnUpdate(dt)
	else
		if not self:IsVoteActive() then
			self.inst:StopUpdatingComponent(self)
		end
	end
end

function Voter:VoteComplete()
	local winning_option = nil
	local is_tie = false
	local total_votes = 0
	for _,option in pairs(self.vote_options.options) do
		total_votes = total_votes + option.vote_count
		if winning_option == nil or option.vote_count > winning_option.vote_count then
			winning_option = option
			is_tie = false
		elseif option.vote_count == winning_option.vote_count then
			is_tie = true
		end
	end
	winning_option.is_tie = is_tie
	self.active_vote.ProcessResultFn( self.vote_options, winning_option, total_votes )
	TheWorld:PushEvent("hidevotedialog")
	self.show_dialog = false
	self.net_show_dialog:set(false)
	
	self:SetActiveVote(nil)
end


function Voter:ServerOnUpdate(dt)
	self.net_vote_timer_start:set_local( self.vote_timer ) --ensure players who join late, get the right start time

	for k,v in pairs(VOTE_KICK_SQUELCH_TABLE) do
		VOTE_KICK_SQUELCH_TABLE[k] = v - dt
		if VOTE_KICK_SQUELCH_TABLE[k] < 0 then
			VOTE_KICK_SQUELCH_TABLE[k] = nil
			self:UpdateSquelchTable()
		end
	end
	if next(VOTE_KICK_SQUELCH_TABLE) == nil and not self:IsVoteActive() then --is the table empty and no active vote
		self.inst:StopUpdatingComponent(self)
	end
	
	if self:IsVoteActive() then		
		if self.vote_timer <= 0 then
			--vote is over, find the option with the largest count
			self:VoteComplete()
		end
	end
end

function Voter:ToggleVoteKick()
    if TheWorld.ismastersim then
        local kick_enabled = not self.commands["kick"].enabled
        self.commands["kick"].enabled = kick_enabled
        TheSim:SetSetting("GAMEPLAY", "vote_kick_enabled", tostring(kick_enabled)) 
        UpdateServerTagsString()
        self.net_is_kick_enabled:set( kick_enabled )

        print("Vote kick is now ", kick_enabled)
    end
end

return Voter
