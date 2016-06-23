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

for k, v in pairs(EMOTES) do
    AddUserCommand(k, {
        aliases = v.aliases,
        prettyname = function(command) return string.format(STRINGS.UI.BUILTINCOMMANDS.EMOTES.PRETTYNAMEFMT, command.name) end,
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
                player:PushEvent("emote", v.data)
            end
        end
    })
end
