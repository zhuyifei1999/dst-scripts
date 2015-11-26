local EMOTES =
{
    ["/wave"] =             { anim = { "emoteXL_waving1", "emoteXL_waving2" }, randomanim = true },
    ["/waves"] =            "/wave",
    ["/hi"] = 				"/wave",

    ["/bye"] =              { anim = { "emoteXL_waving4", "emoteXL_waving3" }, randomanim = true },
    ["/goaway"] =           "/bye",
    ["/goodbye"] =          "/bye",

    ["/cheer"] =            { anim = "emoteXL_happycheer" },
    ["/cheers"] =           "/cheer",
    ["/happy"] =            "/cheer",

    ["/angry"] =            { anim = "emoteXL_angry" },
    ["/anger"] =            "/angry",
    ["/grimace"] =          "/angry",
    ["/grimaces"] =         "/angry",
    ["/frustrate"] =        "/angry",
    ["/frustrated"] =       "/angry",
    ["/frustration"] =      "/angry",

    ["/cry"] =              { anim = "emoteXL_sad", fx = "tears", fxoffset = Vector3(0, -.8, 0), fxdelay = 17 * FRAMES },
    ["/sad"] =              "/cry",

    ["/no"] =               { anim = "emoteXL_annoyed" },
    ["/annoyed"] =          "/no",
    ["/annoy"] =            "/no",
    ["/shakehead"] =        "/no",
    ["/shake"] =            "/no",
    ["/confuse"] =          "/no",
    ["/confused"] =         "/no",

    ["/joy"] =              { anim = "research", fx = false },
    ["/click"] =            "/joy",
    ["/heelclick"] =        "/joy",
    ["/heels"] =            "/joy",
    ["/celebrate"] =        "/joy",
    ["/celebration"] =      "/joy",

    ["/dance"] =            { anim = { "emoteXL_pre_dance0", "emoteXL_loop_dance0" }, loop = true, fx = false, beaver = true },

    ["/bonesaw"] =          { anim = "emoteXL_bonesaw" },
    ["/ready"] =            "/bonesaw",
    ["/goingnowhere"] =     "/bonesaw",
    ["/playtime"] =         "/bonesaw",
    ["/threeminutes"] =     "/bonesaw",

    ["/facepalm"] =         { anim = "emoteXL_facepalm" },
    ["/doh"] =              "/facepalm",
    ["/slapintheface"] =    "/facepalm",

    ["/kiss"] =             { anim = "emoteXL_kiss" },
    ["/blowkiss"] =         "/kiss",
    ["/smooch"] =           "/kiss",
    ["/mwa"] =              "/kiss",
    ["/mwah"] =             "/kiss",

    ["/pose"] = 			{ anim = "emote_strikepose", zoom = true, soundoverride = "/pose"},
    ["/strut"] = 			"/pose",
    ["/strikepose"] = 		"/pose",
}

for k, v in pairs(EMOTES) do
    if type(v) == "string" then
        EMOTES[k] = EMOTES[v]
    end
end

local REGEX_EMOTES =
{
    ["/bonesaw"] =          "/b+o+n+e+s+a+w+",
    ["/ready"] =            "/r+e+a+d+y+",
    ["/goingnowhere"] =     "/g+o+i+n+g+n+o+w+h+e+r+e+",
    ["/playtime"] =         "/p+l+a+y+t+i+m+e+",
    ["/threeminutes"] =     "/t+h+r+e+e+m+i+n+u+t+e+s+",
    ["/mwa"] =              "/m+w+a+",
    ["/mwah"] =             "/m+w+a+h+",
}

local function translate_regex(str)
    for k, v in pairs(REGEX_EMOTES) do
        if string.match(str, v) then
            return k, EMOTES[k]
        end
    end
end

local function translate(str)
    str = string.lower(str)
    local emote = EMOTES[str]
    if emote ~= nil then
        return str, emote
    else
        return translate_regex(str)
    end
end

return {
    translate = translate,
}
