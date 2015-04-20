local MakePlayerCharacter = require "prefabs/player_common"

local assets =
{
    Asset("ANIM", "anim/wathgrithr.zip"),
    Asset("ANIM", "anim/ghost_wathgrithr_build.zip"),
    Asset("SOUND", "sound/wathgrithr.fsb"),
}

local prefabs =
{
    "spear_wathgrithr",
    "wathgrithrhat",
    "wathgrithr_spirit",
}

local start_inv =
{
    "spear_wathgrithr",
    "wathgrithrhat",
    "meat",
    "meat",
    "meat",
    "meat",
}

local smallScale = 0.5
local medScale = 0.7
local largeScale = 1.1

local function spawnspirit(inst, x, y, z, scale)
    local fx = SpawnPrefab("wathgrithr_spirit")
    fx.Transform:SetPosition(x, y, z)
    fx.Transform:SetScale(scale, scale, scale)
end

local function onkilled(inst, data)
    local victim = data.victim
    if not (victim:HasTag("prey") or
            victim:HasTag("veggie") or
            victim:HasTag("structure")) then
        local delta = victim.components.combat.defaultdamage * 0.25
        inst.components.health:DoDelta(delta, false, "battleborn")
        inst.components.sanity:DoDelta(delta)

        if not victim.components.health.nofadeout and (victim:HasTag("epic") or math.random() < .1) then
            local time = victim.components.health.destroytime or 2
            local x, y, z = victim.Transform:GetWorldPosition()
            local scale = (victim:HasTag("smallcreature") and smallScale)
                        or (victim:HasTag("largecreature") and largeScale)
                        or medScale
            inst:DoTaskInTime(time, spawnspirit, x, y, z, scale)
        end
    end
end

local function common_init(inst)
    inst:AddTag("valkyrie")

    inst.talker_path_override = "dontstarve_DLC001/characters/"

    inst.components.talker.font = Profile:IsWathgrithrFontEnabled() and TALKINGFONT_WATHGRITHR or TALKINGFONT
    inst:ListenForEvent("continuefrompause", function()
        inst.components.talker.font = Profile:IsWathgrithrFontEnabled() and TALKINGFONT_WATHGRITHR or TALKINGFONT
    end, TheWorld)
end

local function master_init(inst)
    inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODTYPE.MEAT })

    inst.components.health:SetMaxHealth(TUNING.WATHGRITHR_HEALTH)
    inst.components.hunger:SetMax(TUNING.WATHGRITHR_HUNGER)
    inst.components.sanity:SetMax(TUNING.WATHGRITHR_SANITY)
    inst.components.combat.damagemultiplier = TUNING.WATHGRITHR_DAMAGE_MULT
    inst.components.health:SetAbsorptionAmount(TUNING.WATHGRITHR_ABSORPTION)

    inst:ListenForEvent("killed", onkilled)
end

return MakePlayerCharacter("wathgrithr", prefabs, assets, common_init, master_init, start_inv)