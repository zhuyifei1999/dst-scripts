------- A NOTE TO INDUSTRIOUS MODDERS --------
-- This system is pretty usable and there is already a mod interface for
-- adding your own commands. However, be aware of a few limitations:
--  1) Shards are not fully supported yet. Specific commands like Kick are
--     shard-aware, but other than that, only local commands or commands which
--     affect master-server components (like seasons.lua) will work correctly for now.
--  2) COMMAND_PERMISSION.MODERATOR doesn't actually do anything yet.
--
-- We would like to resolve these things soon, but until we do, those are the
-- limitations of this system.

AddUserCommand("help", {
    prettyname = "Command Help",
    desc = "Get more info on commands.",
    permission = COMMAND_PERMISSION.USER,
    slash = true,
    usermenu = false,
    servermenu = false,
    params = {"commandname"},
    vote = false,
    localfn = function(params, caller)
        local hud = ThePlayer ~= nil and ThePlayer.HUD or nil
        if hud == nil then
            return
        end

        local s = {}

        local UserCommands = require("usercommands")
        if params.commandname == nil then
            table.insert(s, STRINGS.UI.BUILTINCOMMANDS.HELP.OVERVIEW)
            table.insert(s, STRINGS.UI.BUILTINCOMMANDS.HELP.AVAILABLE)
            local names = UserCommands.GetCommandNames()
            table.sort(names)
            table.insert(s, table.concat(names, ", "))
        else
            local command = UserCommands.GetCommandFromName(params.commandname)
            if command ~= nil then
                local call = command.name
                local params = deepcopy(command.params)
                for i,param in ipairs(params) do
                    params[i] = "<"..param..">"
                end
                table.insert(s, command.prettyname)
                table.insert(s, string.format("/%s %s", command.name, table.concat(params, " ")))
                table.insert(s, command.desc)
            else
                table.insert(s, string.format(STRINGS.UI.BUILTINCOMMANDS.HELP.NOTFOUND, params.commandname))
                local names = UserCommands.GetCommandNames()
                table.insert(s, STRINGS.UI.BUILTINCOMMANDS.HELP.AVAILABLE)
                table.sort(names)
                table.insert(s, table.concat(names, ", "))
            end
        end

        hud.controls.networkchatqueue:DisplaySystemMessage(s)
    end,
})


AddUserCommand("bug", {
    prettyname =  STRINGS.UI.BUILTINCOMMANDS.BUG.PRETTYNAME,
    desc = STRINGS.UI.BUILTINCOMMANDS.BUG.DESC,
    permission = COMMAND_PERMISSION.USER,
    slash = true,
    usermenu = false,
    servermenu = false,
    params = {},
    vote = false,
    localfn = function(params, caller)
        VisitURL("http://forums.kleientertainment.com/klei-bug-tracker/dont-starve-together/")
    end,
})

AddUserCommand("rescue", {
    prettyname = STRINGS.UI.BUILTINCOMMANDS.RESCUE.PRETTYNAME,
    desc =  STRINGS.UI.BUILTINCOMMANDS.RESCUE.DESC,
    permission = COMMAND_PERMISSION.USER,
    slash = true,
    usermenu = false,
    servermenu = false,
    params = {},
    vote = false,
    serverfn = function(params, caller)
        caller:PutBackOnGround()
    end,
})

AddUserCommand("kick", {
    aliases = {"boot"},
    prettyname = STRINGS.UI.BUILTINCOMMANDS.KICK.PRETTYNAME,
    desc = STRINGS.UI.BUILTINCOMMANDS.KICK.DESC,
    permission = COMMAND_PERMISSION.MODERATOR,
    confirm = true,
    slash = true,
    usermenu = true, -- automatically supplies the username as a param called "user"
    cantargetself = false,
    cantargetadmin = false,
    servermenu = false,
    params = {"user"},
    vote = true,
    votetimeout = 30,
    votetitlefmt = STRINGS.UI.BUILTINCOMMANDS.KICK.VOTETITLEFMT,
    votenamefmt = STRINGS.UI.BUILTINCOMMANDS.KICK.VOTENAMEFMT,
    voteresultfn = function(params, voteresults)
        --e.g. Not everyone needs to vote (in case of timeout)
        --     Can't have any no
        --     Minimum 2 yes votes
        --     Needs more yes than not voted
        --NOTE: The targetted guy is NOT included in any of the result counts
        local yes = voteresults.options[1]
        local no = voteresults.options[2]
        return no <= 0
            and yes >= 2
            and yes > voteresults.total_not_voted
    end,
    localfn = function(params, caller)
        --NOTE: must support nil caller for voting
        local clientid = UserToClientID(params.user)
        if clientid ~= nil then
            TheNet:Kick(clientid)
        end
    end,
})

AddUserCommand("ban", {
    prettyname = STRINGS.UI.BUILTINCOMMANDS.BAN.PRETTYNAME,
    desc = STRINGS.UI.BUILTINCOMMANDS.BAN.DESC,
    permission = COMMAND_PERMISSION.ADMIN,
    confirm = true,
    slash = true,
    usermenu = true, -- automatically supplies the username as a param called "user"
    cantargetself = false,
    cantargetadmin = false,
    servermenu = false,
    params = {"user"},
    vote = false,
    localfn = function(params, caller)
        local clientid = UserToClientID(params.user)
        if clientid ~= nil then
            TheNet:Ban(clientid)
        end
    end,
})

AddUserCommand("stopvote", {
    aliases = {"veto"},
    prettyname = STRINGS.UI.BUILTINCOMMANDS.STOPVOTE.PRETTYNAME,
    desc = STRINGS.UI.BUILTINCOMMANDS.STOPVOTE.DESC,
    permission = COMMAND_PERMISSION.ADMIN,
    confirm = false,
    slash = true,
    usermenu = false,
    servermenu = false,
    params = {},
    vote = false,
    localfn = function(params, caller)
        TheNet:StopVote()
    end,
})

AddUserCommand("rollback", {
    prettyname = STRINGS.UI.BUILTINCOMMANDS.ROLLBACK.PRETTYNAME,
    desc = STRINGS.UI.BUILTINCOMMANDS.ROLLBACK.DESC,
    permission = COMMAND_PERMISSION.ADMIN,
    confirm = true,
    slash = true,
    usermenu = false,
    servermenu = true,
    params = {"numsaves"},
    paramsoptional = true,
    vote = true,
    votetitlefmt = STRINGS.UI.BUILTINCOMMANDS.ROLLBACK.VOTETITLEFMT,
    votenamefmt = STRINGS.UI.BUILTINCOMMANDS.ROLLBACK.VOTENAMEFMT,
    votepassedfmt = STRINGS.UI.BUILTINCOMMANDS.ROLLBACK.VOTEPASSEDFMT,
    voteresultfn = function(params, voteresults)
        --e.g. Everyone must vote and must be unanimous
        local yes = voteresults.options[1]
        local no = voteresults.options[2]
        return voteresults.total_not_voted <= 0
            and no <= 0
    end,
    serverfn = function(params, caller)
        --NOTE: must support nil caller for voting
        TheWorld:DoTaskInTime(5, function(world)
            if world.ismastersim then
                TheNet:SendWorldRollbackRequestToServer(params.numsaves)
            end
        end)
    end,
})

AddUserCommand("regenerate", {
    prettyname = STRINGS.UI.BUILTINCOMMANDS.REGENERATE.PRETTYNAME,
    desc = STRINGS.UI.BUILTINCOMMANDS.REGENERATE.DESC,
    permission = COMMAND_PERMISSION.ADMIN,
    confirm = true,
    slash = true,
    usermenu = false,
    servermenu = true,
    params = {},
    vote = true,
    votetimeout = 30,
    votetitlefmt = STRINGS.UI.BUILTINCOMMANDS.REGENERATE.VOTETITLEFMT,
    votenamefmt = STRINGS.UI.BUILTINCOMMANDS.REGENERATE.VOTENAMEFMT,
    votepassedfmt = STRINGS.UI.BUILTINCOMMANDS.REGENERATE.VOTEPASSEDFMT,
    voteresultfn = function(params, voteresults)
        --e.g. Everyone must vote and must be unanimous
        local yes = voteresults.options[1]
        local no = voteresults.options[2]
        return voteresults.total_not_voted <= 0
            and no <= 0
    end,
    serverfn = function(params, caller)
        --NOTE: must support nil caller for voting
        TheWorld:DoTaskInTime(5, function(world)
            if world.ismastersim then
                TheNet:SendWorldResetRequestToServer()
            end
        end)
    end,
})


