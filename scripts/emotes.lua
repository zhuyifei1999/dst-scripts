local EMOTES =
{
    ["/wave"] =             { anim = { "emoteXL_waving1", "emoteXL_waving2" }, randomanim = true },
    ["/waves"] =            { anim = { "emoteXL_waving1", "emoteXL_waving2" }, randomanim = true },
    ["/goaway"] =           { anim = { "emoteXL_waving4", "emoteXL_waving3" }, randomanim = true },
    ["/bye"] =              { anim = { "emoteXL_waving4", "emoteXL_waving3" }, randomanim = true },
    ["/goodbye"] =          { anim = { "emoteXL_waving4", "emoteXL_waving3" }, randomanim = true },
    ["/cheer"] =            { anim = "emoteXL_happycheer" },
    ["/cheers"] =           { anim = "emoteXL_happycheer" },
    ["/happy"] =            { anim = "emoteXL_happycheer" },
    ["/angry"] =            { anim = "emoteXL_angry" },
    ["/anger"] =            { anim = "emoteXL_angry" },
    ["/grimace"] =          { anim = "emoteXL_angry" },
    ["/grimaces"] =         { anim = "emoteXL_angry" },
    ["/frustrate"] =        { anim = "emoteXL_angry" },
    ["/frustrated"] =       { anim = "emoteXL_angry" },
    ["/frustration"] =      { anim = "emoteXL_angry" },
    ["/sad"] =              { anim = "emoteXL_sad", fx = "tears", fxoffset = { 0, -.8, 0 }, fxdelay = 17 * FRAMES },
    ["/cry"] =              { anim = "emoteXL_sad", fx = "tears", fxoffset = { 0, -.8, 0 }, fxdelay = 17 * FRAMES },
    ["/annoyed"] =          { anim = "emoteXL_annoyed" },
    ["/annoy"] =            { anim = "emoteXL_annoyed" },
    ["/no"] =               { anim = "emoteXL_annoyed" },
    ["/shakehead"] =        { anim = "emoteXL_annoyed" },
    ["/shake"] =            { anim = "emoteXL_annoyed" },
    ["/confuse"] =          { anim = "emoteXL_annoyed" },
    ["/confused"] =         { anim = "emoteXL_annoyed" },
    ["/click"] =            { anim = "research", fx = false },
    ["/heelclick"] =        { anim = "research", fx = false },
    ["/heels"] =            { anim = "research", fx = false },
    ["/joy"] =              { anim = "research", fx = false },
    ["/celebrate"] =        { anim = "research", fx = false },
    ["/celebration"] =      { anim = "research", fx = false },
    ["/dance"] =            { anim = { "run_pre", "run_loop", "run_loop", "run_loop", "run_pst" } },
    ["/bonesaw"] =          { anim = "emoteXL_bonesaw" },
    ["/ready"] =            { anim = "emoteXL_bonesaw" },
    ["/goingnowhere"] =     { anim = "emoteXL_bonesaw" },
    ["/playtime"] =         { anim = "emoteXL_bonesaw" },
    ["/threeminutes"] =     { anim = "emoteXL_bonesaw" },
    ["/facepalm"] =         { anim = "emoteXL_facepalm" },
    ["/doh"] =              { anim = "emoteXL_facepalm" },
    ["/slapintheface"] =    { anim = "emoteXL_facepalm" },
    ["/kiss"] =             { anim = "emoteXL_kiss" },
    ["/blowkiss"] =         { anim = "emoteXL_kiss" },
    ["/smooch"] =           { anim = "emoteXL_kiss" },
    ["/mwa"] =              { anim = "emoteXL_kiss" },
    ["/mwah"] =             { anim = "emoteXL_kiss" },
}

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