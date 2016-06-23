-----------------------------------------------------------------------------------------------------------
-- INCLUDES
-----------------------------------------------------------------------------------------------------------

local PopupDialogScreen = require "screens/popupdialog"

-----------------------------------------------------------------------------------------------------------
-- PRIVATE FIELDS
-----------------------------------------------------------------------------------------------------------

local usercommands = {}
local modusercommands = {}
local cmdqueue = {}

-----------------------------------------------------------------------------------------------------------
-- INTERNAL EXECUTION HANDLERS
-----------------------------------------------------------------------------------------------------------

local function queuelocalcommandexec(fn, params, caller)
    --Queue execution so it runs during sim update loop
    table.insert(cmdqueue, { fn = fn, params = params, caller = caller })
end

function HandleUserCmdQueue()
    while #cmdqueue > 0 do
        local cmd = table.remove(cmdqueue, 1)
        cmd.fn(cmd.params, cmd.caller)
    end
end

-----------------------------------------------------------------------------------------------------------
-- METRICS
-----------------------------------------------------------------------------------------------------------

local Stats = require("stats")

local METRICS_COMMANDS = {"kick", "ban", "rollback", "regenerate"}

local function SendCommandMetricsEvent(command, targetid, caller)
    local found = false
    for i,name in ipairs(METRICS_COMMANDS) do
        if command == name then
            found = true
            break
        end
    end
    if not found then
        return
    end

    local values = {}
    values.target_user = targetid
    --values.source = source
    Stats.PushMetricsEvent("commands."..command, caller, values)
end

local function SendVoteMetricsEvent(command, targetid, success, caller)
    local found = false
    for i,name in ipairs(METRICS_COMMANDS) do
        if command == name then
            found = true
            break
        end
    end
    if not found then
        return
    end

    local values = {}
    values.target_user = targetid
    values.success = success
    Stats.PushMetricsEvent("commands."..command.."_vote", caller, values)
end

-----------------------------------------------------------------------------------------------------------
-- GLOBAL HELPER FUNCTIONS
-----------------------------------------------------------------------------------------------------------

-- resolves string properties in user command definitions
function ResolveCommandStringProperty(command, property, default)
    local strtbl = STRINGS.UI.BUILTINCOMMANDS[string.upper(command.name)]
    local val = command[property]
    return (type(val) == "string" and val)
        or (type(val) == "function" and val(command))
        or (strtbl ~= nil and strtbl[string.upper(property)])
        or default
end

-----------------------------------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-----------------------------------------------------------------------------------------------------------

local function sendsystemmessage(msg)
    if ThePlayer ~= nil and ThePlayer.HUD ~= nil then
        ThePlayer.HUD.controls.networkchatqueue:DisplaySystemMessage(msg)
    end
end

local dealias = nil -- forward declare
local function getcommandfromhash(hash)
    for mod,modcommands in pairs(modusercommands) do
        if modcommands[hash] ~= nil then
            return dealias(modcommands[hash])
        end
    end
    return dealias(usercommands[hash])
end

local function getcommand(name)
    return name ~= nil and getcommandfromhash(smallhash(name)) or nil
end

--forward declared
dealias = function(command)
    if command ~= nil and command.aliasfor ~= nil then
        return getcommand(command.aliasfor)
    end
    return command
end

local function parseinput(input)
    local args = string.split(input, " ")
    local command = getcommand(args[1])
    if command == nil then
        print("Tried running unknown user command: ",args[1])
        dumptable(args)
        print("input:", input)
        return nil
    end
    local params = {}
    for i,paramname in ipairs(command.params) do
        if args[i+1] == nil then
            if command.paramsoptional ~= nil and command.paramsoptional[i] == true then
                break
            else
                print("Didn't supply enough arguments to command!")
                sendsystemmessage(string.format(STRINGS.UI.USERCOMMANDS.MISSINGPARAMSFMT, command.name))
                return
            end
        end
        params[paramname] = args[i+1]
    end

    if command.usermenu == true then
        local client = UserToClient(params.user)
        if client == nil then
            print("Unknown target user for command:",command.name, params.user)
            sendsystemmessage(string.format(STRINGS.UI.USERCOMMANDS.BADUSERFMT, params.user))
            return
        end
    end

    if #args > #command.params+1 then
        local first = #command.params+1+1
        params.rest = args[first]
        for i=first+1,#args do
            params.rest = params.rest .. " " .. args[i]
        end
    end

    dumptable(params)

    return command, params
end

local function unparsecommand(command, params)
    local s = command.name
    for i,paramname in ipairs(command.params) do
        -- handle "optional" params -- once we're missing one, the whole string is moot, so just bail and assume the command fn will nil check.
        if params[paramname] == nil then
            print("Building a command without enough arguments!")
            break
        end
        s = s.. " " .. params[paramname]
    end
    return s
end

local function prettyname(command)
    return ResolveCommandStringProperty(command, "prettyname", command.name)
end

local function commandlevel(command)
    return (command.permission == COMMAND_PERMISSION.ADMIN and 3)
        or (command.permission == COMMAND_PERMISSION.MODERATOR and 2)
        or (command.permission == COMMAND_PERMISSION.USER and 1)
end

local function userlevel(user)
    local client = TheNet:GetClientTableForUser(user.userid)
    return (client == nil and 0)
        or (client.admin and 3)
        or (client.moderator and 2)
        or ((user.components.playervoter == nil or not user.components.playervoter:IsSquelched()) and 1)
        or 0
end

local function validatevotestart(command, caller, targetid)
    --Check min player count requirements
    if command.voteminpasscount ~= nil then
        local isdedicated = not TheNet:GetServerIsClientHosted()
        local clients = TheNet:GetClientTable()
        local numclients = isdedicated and #clients - 1 or #clients

        --Require +1 player if target doesn't get to vote
        local excludetarget = targetid ~= nil and not command.cantargetself
        local minplayers = excludetarget and command.voteminpasscount + 1 or command.voteminpasscount

        if numclients < minplayers then
            return false, "MINPLAYERS"
        end
    end
    --Custom checks
    if command.votecanstartfn == nil then
        return true, nil
    end
    --Expects 2 return values, so don't inline!
    return command.votecanstartfn(command, caller, targetid)
end

local function getexectype(command, caller, targetid)
    if command.usermenu == true and targetid ~= nil then
        local client = TheNet:GetClientTableForUser(targetid)
        if client == nil then
            return COMMAND_RESULT.INVALID
        elseif command.cantargetadmin ~= true and client.admin == true then
            return COMMAND_RESULT.INVALID
        elseif command.cantargetself ~= true and targetid == caller.userid then
            return COMMAND_RESULT.INVALID
        end
    end

    return (command.canstartfn ~= nil and not command.canstartfn(command, caller, targetid) and COMMAND_RESULT.DISABLED)
        or (userlevel(caller) >= commandlevel(command) and COMMAND_RESULT.ALLOW)
        or (not command.vote and COMMAND_RESULT.INVALID)
        or ((TheWorld.net == nil or TheWorld.net.components.worldvoter == nil or not TheWorld.net.components.worldvoter:IsEnabled()) and COMMAND_RESULT.INVALID)
        or (caller.components.playervoter == nil and COMMAND_RESULT.INVALID)
        or (TheWorld.net.components.worldvoter:IsVoteActive() and COMMAND_RESULT.DENY)
        or (caller.components.playervoter:IsSquelched() and COMMAND_RESULT.DENY)
        or (not validatevotestart(command, caller, targetid) and COMMAND_RESULT.DENY)
        or COMMAND_RESULT.VOTE
end

local function runcommand(command, params, caller, onserver, confirm)
    local exec_type = getexectype(command, caller, UserToClientID(params.user)) -- 'user' is the magical param name
    if exec_type == COMMAND_RESULT.DISABLED then
        sendsystemmessage(string.format(STRINGS.UI.USERCOMMANDS.DISABLEDFMT, prettyname(command)))
        print(string.format("User %s tried to run command %s, but it is disabled.", caller.name, command.name))
        return
    elseif exec_type == COMMAND_RESULT.DENY then
        sendsystemmessage(string.format(STRINGS.UI.USERCOMMANDS.SQUELCHEDFMT, prettyname(command)))
        print(string.format("User %s tried to run command %s, but is squelched.", caller.name, command.name))
        return
    elseif exec_type == COMMAND_RESULT.INVALID then
        if params.user ~= nil then
            sendsystemmessage(string.format(STRINGS.UI.USERCOMMANDS.BADTARGETFMT, prettyname(command), UserToName(params.user)))
            print(string.format("User %s tried to run command %s, but target was bad.", caller.name, command.name))
        else
            sendsystemmessage(string.format(STRINGS.UI.USERCOMMANDS.NOTALLOWEDFMT, prettyname(command)))
            print(string.format("User %s tried to run command %s, but was not allowed.", caller.name, command.name))
        end
        return
    end

    if not onserver and command.confirm and not confirm then
        TheFrontEnd:PushScreen(
            PopupDialogScreen(
                params.user ~= nil and string.format(STRINGS.UI.COMMANDSSCREEN.CONFIRMTITLE_TARGET, prettyname(command), UserToName(params.user)) or string.format(STRINGS.UI.COMMANDSSCREEN.CONFIRMTITLE, prettyname(command)),
                ResolveCommandStringProperty(command, "desc", ""),
                {
                    {text=STRINGS.UI.PLAYERSTATUSSCREEN.OK, cb = function() TheFrontEnd:PopScreen() runcommand(command, params, caller, onserver, true) end},
                    {text=STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() end}
                }
            ))
    elseif exec_type == COMMAND_RESULT.VOTE then
        TheNet:StartVote(command.hash, UserToClientID(params.user))
    elseif exec_type == COMMAND_RESULT.ALLOW then
        if not onserver then
            if command.localfn ~= nil then
                queuelocalcommandexec(command.localfn, params, caller)
            end
            if command.serverfn ~= nil then
                TheNet:SendSlashCmdToServer(unparsecommand(command, params)) -- Caller is the client
            end
        elseif command.serverfn ~= nil then
            queuelocalcommandexec(command.serverfn, params, caller)
        end
    end
end

local function getsomecommands(user, targetid, predicate)
    local ret = {}
    for hash,command in pairs(usercommands) do
        if command.aliasfor == nil and predicate(command) then
            local exectype = user and getexectype(command, user, targetid) or COMMAND_RESULT.ALLOW
            table.insert(ret, {commandname=command.name, prettyname=prettyname(command), exectype=exectype})
        end
    end
    for mod, modcommands in pairs(modusercommands) do
        for hash, command in pairs(modcommands) do
            if command.aliasfor == nil and predicate(command) then
                local exectype = user and getexectype(command, user, targetid) or COMMAND_RESULT.ALLOW
                table.insert(ret, {commandname=command.name, prettyname=prettyname(command), exectype=exectype, mod=mod})
            end
        end
    end
    return ret
end

-----------------------------------------------------------------------------------------------------------
-- MODULE FUNCTIONS
-----------------------------------------------------------------------------------------------------------

local function UserRunCommandResult(commandname, player, targetid)
    local command = getcommand(commandname)
    assert(command.usermenu ~= true or targetid ~= nil, "UserRunCommandResult must specify a target for user actions!")

    return getexectype(command, player, targetid)
end

local function CanUserAccessCommand(commandname, player, targetid)
    local exectype = UserRunCommandResult(commandname, player, targetid)
    return exectype ~= COMMAND_RESULT.INVALID
end

local function CanUserStartCommand(commandname, player, targetid)
    local command = getcommand(commandname)
    if command.canstartfn == nil then
        return true, nil
    end
    --Expects 2 return values, so don't inline!
    return command.canstartfn(command, player, targetid)
end

local function CanUserStartVote(commandname, player, targetid)
    local command = getcommand(commandname)
    assert(command.vote)

    return validatevotestart(command, player, targetid)
end

local function RunUserCommand(commandname, params, caller, onserver)
    local command = getcommand(commandname)
    if command == nil then
        return
    end

    print(caller.userid, "running command:",command.name, tostring(onserver))
    dumptable(params)

    runcommand(command, params, caller, onserver)
end

local function RunTextUserCommand(input, caller, onserver)
    local command, params = parseinput(input)
    if command == nil then
        return
    end

    print(caller.userid, "running text command:",command.name, tostring(onserver))
    dumptable(params)

    runcommand(command, params, caller, onserver)
end

local function ClearModData(mod)
    if mod ~= nil then
        modusercommands[mod] = nil
    else
        modusercommands = {}
    end
end

local function FinishVote(commandname, params, voteresults)
    local command = getcommand(commandname)

    local passed = false
    if command.allownotvoted or voteresults.total_not_voted <= 0 then
        local result, count = command.voteresultfn(params, voteresults)
        if result ~= nil and count >= (command.voteminpasscount or 1) then
            --the winning selection passes and we have enough votes for it
            --insert it into the params
            passed = true
            params.voteselection = result
            params.votecount = count
        end
    end

    TheNet:AnnounceVoteResult(command.hash, UserToName(params.user), passed)
    if passed then
        -- Vote always runs commands they were called by the server, so just run both localfn and serverfn
        -- Don't need to queue these because we reach here during game component (worldvoter) update loop.
        if command.localfn ~= nil then
            command.localfn(params, nil)
        end
        if command.serverfn ~= nil then
            command.serverfn(params, nil)
        end
    end
    return passed
end

local function GetCommandFromName(name)
    return getcommand(name)
end

local function GetCommandFromHash(hash)
    return getcommandfromhash(hash)
end

local function GetCommandNames()
    local ret = {}

    for mod,modcommands in pairs(modusercommands) do
        for hash,command in pairs(modcommands) do
            if command.aliasfor == nil then
                table.insert(ret, command.name)
            end
        end
    end
    for hash,command in pairs(usercommands) do
        if command.aliasfor == nil then
            table.insert(ret, command.name)
        end
    end

    return ret
end

local function GetUserActions(caller, targetid)
    return getsomecommands(caller, targetid, function(command)
        local exectype = getexectype(command, caller, targetid)
        return command.usermenu == true and exectype ~= COMMAND_RESULT.INVALID
    end)
end

local function GetServerActions(caller)
    return getsomecommands(caller, nil, function(command)
        local exectype = getexectype(command, caller)
        return command.servermenu == true and exectype ~= COMMAND_RESULT.INVALID
    end)
end

-----------------------------------------------------------------------------------------------------------
-- GLOBAL FUNCTIONS
-----------------------------------------------------------------------------------------------------------

function AddUserCommand(name, data)
    local hash = smallhash(name)
    data.name = name
    data.hash = hash
    usercommands[hash] = data
    if data.aliases ~= nil then
        for i,alias in ipairs(data.aliases) do
            hash = smallhash(alias)
            usercommands[hash] = {aliasfor=name}
        end
    end
end

function AddModUserCommand(mod, name, data)
    local hash = smallhash(name)
    data.name = name
    data.hash = hash
    if modusercommands[mod] == nil then
        modusercommands[mod] = {}
    end
    modusercommands[mod][hash] = data
    if data.aliases ~= nil then
        for i,alias in ipairs(data.aliases) do
            hash = smallhash(alias)
            usercommands[mod][hash] = {aliasfor=name}
        end
    end
end

-- converts a variety of inputs that could be used in usercommands to a valid client object
function UserToClient(input)
    if input == nil then
        return
    end

    local isdedicated = not TheNet:GetServerIsClientHosted()
    local clients = TheNet:GetClientTable()
    local numclients = isdedicated and #clients - 1 or #clients
    if numclients <= 0 then
        return
    end

    -- Priority (highest to lowest):
    --  4: userid
    --  3: case-sensitive name
    --  2: case-insensitive name 
    --  1: player listing index
    local clientmatch = nil
    local lowerinput = string.lower(input)
    local inputidx = tonumber(input)
    local priority = inputidx ~= nil and inputidx > 0 and inputidx <= numclients and 0 or 1
    local index = 1
    for i, client in ipairs(clients) do
        if isdedicated and client.performance ~= nil then
            --skip true dedicated server [Host] client

        --Priority 4: match by userid
        elseif client.userid == input then
            return client

        --Priority 3: match by case-sensitive name
        elseif priority >= 3 then
        elseif client.name == input then
            clientmatch = client
            priority = 3

        --Priority 2: match by case-insensitive name
        elseif priority >= 2 then
        elseif string.lower(client.name) == lowerinput then
            clientmatch = client
            priority = 2

        --Priority 1: match by listing index
        elseif priority >= 1 then
        elseif index == inputidx then
            clientmatch = client
            priority = 1
        else
            index = index + 1
        end
    end
    return clientmatch
end

-- converts a variety of inputs that could be used in usercommands to a valid user name
function UserToName(input)
    local client = UserToClient(input)
    return client ~= nil and client.name or nil
end

-- converts a variety of inputs that could be used in usercommands to a valid client id
function UserToClientID(input)
    local client = UserToClient(input)
    return client ~= nil and client.userid or nil
end

-- converts a variety of inputs that could be used in usercommands to a valid player entity
function UserToPlayer(input)
    local userid = UserToClientID(input)
    if userid == nil then
        return
    end
    for i, player in ipairs(AllPlayers) do
        if player.userid == userid then
            return player
        end
    end
end

-----------------------------------------------------------------------------------------------------------
-- EXPORT
-----------------------------------------------------------------------------------------------------------

return {
    SendCommandMetricsEvent = SendCommandMetricsEvent,
    SendVoteMetricsEvent = SendVoteMetricsEvent,
    RunUserCommand = RunUserCommand,
    RunTextUserCommand = RunTextUserCommand,
    UserRunCommandResult = UserRunCommandResult,
    CanUserAccessCommand = CanUserAccessCommand,
    CanUserStartCommand = CanUserStartCommand,
    CanUserStartVote = CanUserStartVote,
    FinishVote = FinishVote,
    ClearModData = ClearModData,
    GetUserActions = GetUserActions,
    GetServerActions = GetServerActions,
    GetCommandFromHash = GetCommandFromHash,
    GetCommandFromName = GetCommandFromName,
    GetCommandNames = GetCommandNames,
}
