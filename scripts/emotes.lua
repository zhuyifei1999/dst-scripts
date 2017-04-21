local EMOTES =
{
    ["wave"] = {
            aliases = { "waves", "hi" },
            data = { anim = { "emoteXL_waving1", "emoteXL_waving2" }, randomanim = true, mounted = true },
        },

    ["bye"] = {
            aliases = { "goaway", "goodbye" },
            data = { anim = { "emoteXL_waving4", "emoteXL_waving3" }, randomanim = true, mounted = true },
        },

    ["cheer"] = {
            aliases = { "cheers", "happy" },
            data = { anim = "emoteXL_happycheer", mounted = true },
        },

    ["angry"] = {
            aliases = { "anger", "grimace", "grimaces", "frustrate", "frustrated", "frustration" },
            data = { anim = "emoteXL_angry", mounted = true },
        },

    ["cry"] = {
            aliases = { "sad", "cries" },
            data = { anim = "emoteXL_sad", fx = "tears", fxdelay = 17 * FRAMES, mounted = true },
        },

    ["no"] = {
            aliases = { "annoyed", "annoy", "shakehead", "shake", "confuse", "confused" },
            data = { anim = "emoteXL_annoyed", mounted = true },
        },

    ["joy"] = {
            aliases = { "click", "heelclick", "heels", "celebrate", "celebration" },
            data = { anim = "research", fx = false },
        },

    ["dance"] = {
            data = { anim = { "emoteXL_pre_dance0", "emoteXL_loop_dance0" }, loop = true, fx = false, beaver = true, mounted = true, tags = { "dancing" } },
        },

    ["sit"] = {
           data = { anim = { { "emote_pre_sit2", "emote_loop_sit2" }, { "emote_pre_sit4", "emote_loop_sit4" } }, randomanim = true, loop = true, fx = false, mounted = true },
        },

    ["squat"] = {
           data = { anim = { { "emote_pre_sit1", "emote_loop_sit1" }, { "emote_pre_sit3", "emote_loop_sit3" } }, randomanim = true, loop = true, fx = false, mounted = true },
        },

    ["bonesaw"] = {
            aliases = { "ready", "goingnowhere", "playtime", "threeminutes" },
            data = { anim = "emoteXL_bonesaw", mounted = true },
        },

    ["facepalm"] = {
            aliases = { "doh", "slapintheface" },
            data = { anim = "emoteXL_facepalm", mounted = true },
        },

    ["kiss"] = {
            aliases = { "blowkiss", "smooch", "mwa", "mwah" },
            data = { anim = "emoteXL_kiss", mounted = true },
        },

    ["pose"] = {
            aliases = { "strut", "strikepose" },
            data = { anim = "emote_strikepose", zoom = true, soundoverride = "pose", mounted = true },
        },
}

local function CreateEmoteCommand(emotedef)
    return {
        aliases = emotedef.aliases,
        prettyname = function(command) return string.format(STRINGS.UI.BUILTINCOMMANDS.EMOTES.PRETTYNAMEFMT, FirstToUpper(command.name)) end,
        desc = function() return STRINGS.UI.BUILTINCOMMANDS.EMOTES.DESC end,
        permission = COMMAND_PERMISSION.USER,
        params = {},
        emote = true,
        slash = true,
        usermenu = false,
        servermenu = false,
        vote = false,
        serverfn = function(params, caller)
            local player = UserToPlayer(caller.userid)
            if player ~= nil then
                player:PushEvent("emote", emotedef.data)
            end
        end,
        displayname = emotedef.displayname
    }
end

for k, v in pairs(EMOTES) do
    AddUserCommand(k, CreateEmoteCommand(v))
end

--------------------------------------------------------------------------
for item_type, v in pairs(EMOTE_ITEMS) do
    local cmd_data = CreateEmoteCommand(v)
    cmd_data.requires_item_type = item_type
    cmd_data.hasaccessfn = function(command, caller)
        if caller == nil then
            return false
        elseif TheWorld.ismastersim then
            return TheInventory:CheckClientOwnership(caller.userid, item_type)
        else
            return caller.userid == TheNet:GetUserID() and TheInventory:CheckOwnership(item_type)
        end
    end
    AddUserCommand(v.cmd_name, cmd_data)
end

--------------------------------------------------------------------------
CreateEmoteCommand = nil
