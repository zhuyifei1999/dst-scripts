local function PlaySound(inst, sound)
    inst.SoundEmitter:PlaySound(sound)
end

local function MakeFx(name, bank, build, anim, sound, sounddelay, tint, tintalpha, transform, sound2, sounddelay2, fnc, fntime)
    local assets =
    {
        Asset("ANIM", "anim/"..build..".zip")
    }

    local function startfx(proxy)
        --print ("SPAWN", debugstack())
    	local inst = CreateEntity()

    	inst.entity:AddTransform()
    	inst.entity:AddAnimState()

        if proxy.entity:GetParent() ~= nil then
            inst.entity:SetParent(proxy.entity:GetParent().entity)
        end
        inst.Transform:SetFromProxy(proxy.GUID)

        if type(anim) ~= "string" then
            anim = anim[math.random(#anim)]
        end

        if sound ~= nil then
            inst.entity:AddSoundEmitter()
            inst:DoTaskInTime(sounddelay or 0, PlaySound, sound)
        end

        if sound2 ~= nil then
            if inst.SoundEmitter == nil then
                inst.entity:AddSoundEmitter()
            end
            inst:DoTaskInTime(sounddelay2 or 0, PlaySound, sound2)
        end
        
        if fnc ~= nil and fntime ~= nil then
            inst:DoTaskInTime(fntime, fnc)
        end

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)
        if tint ~= nil then
            inst.AnimState:SetMultColour(tint.x, tint.y, tint.z, tintalpha or 1)
        elseif tintalpha ~= nil then
            inst.AnimState:SetMultColour(tintalpha, tintalpha, tintalpha, tintalpha)
        end
        --print(inst.AnimState:GetMultColour())
        if transform ~= nil then
            inst.AnimState:SetScale(transform:Get())
        end

        inst:AddTag("FX")
        --[[Non-networked entity]]
        inst.entity:SetCanSleep(false)
        inst.persists = false

        inst:ListenForEvent("animover", inst.Remove)
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()

        --Dedicated server does not need to spawn the local fx
        if not TheNet:IsDedicated() then
            --Delay one frame so that we are positioned properly before starting the effect
            --or in case we are about to be removed
            inst:DoTaskInTime(0, startfx, inst)
        end

        inst.Transform:SetFourFaced()

        inst:AddTag("FX")

        if not TheWorld.ismastersim then
            return inst
        end

        inst.entity:SetPristine()

        inst.persists = false
        inst:DoTaskInTime(1, inst.Remove)

        return inst
    end

    return Prefab("common/"..name, fn, assets)
end

local prefs = {}
local fx = require("fx")

for k,v in pairs(fx) do
    table.insert(prefs, MakeFx(v.name, v.bank, v.build, v.anim, v.sound, v.sounddelay, v.tint, v.tintalpha, v.transform, v.sound2, v.sounddelay2, v.fn, v.fntime))
end

return unpack(prefs)