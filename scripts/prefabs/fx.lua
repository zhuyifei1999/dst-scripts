local function PlaySound(inst, sound)
    inst.SoundEmitter:PlaySound(sound)
end

local function MakeFx(t)
    local assets =
    {
        Asset("ANIM", "anim/"..t.build..".zip")
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

        if type(t.anim) ~= "string" then
            t.anim = t.anim[math.random(#t.anim)]
        end

        if t.sound ~= nil then
            inst.entity:AddSoundEmitter()
            inst:DoTaskInTime(t.sounddelay or 0, PlaySound, t.sound)
        end

        if t.sound2 ~= nil then
            if inst.SoundEmitter == nil then
                inst.entity:AddSoundEmitter()
            end
            inst:DoTaskInTime(t.sounddelay2 or 0, PlaySound, t.sound2)
        end
        
        if t.fn ~= nil and t.fntime ~= nil then
            inst:DoTaskInTime(t.fntime, t.fn)
        end

        inst.AnimState:SetBank(t.bank)
        inst.AnimState:SetBuild(t.build)
        inst.AnimState:PlayAnimation(t.anim)
        if t.tint ~= nil then
            inst.AnimState:SetMultColour(t.tint.x, t.tint.y, t.tint.z, t.tintalpha or 1)
        elseif t.tintalpha ~= nil then
            inst.AnimState:SetMultColour(t.tintalpha, t.tintalpha, t.tintalpha, t.tintalpha)
        end
        --print(inst.AnimState:GetMultColour())
        if t.transform ~= nil then
            inst.AnimState:SetScale(t.transform:Get())
        end

        if t.nameoverride then
            if not inst.components.inspectable then inst:AddComponent("inspectable") end
            inst.components.inspectable.nameoverride = t.nameoverride
            inst.name = t.nameoverride
        end

        if t.description then
            if not inst.components.inspectable then inst:AddComponent("inspectable") end
            inst.components.inspectable.descriptionfn = t.description
        end

        if t.bloom then
            inst.bloom = true
            inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
         end

        if not t.nameoverride and not t.description then
            inst:AddTag("FX")
        end
        --[[Non-networked entity]]
        inst.entity:SetCanSleep(false)
        inst.persists = false

        inst:ListenForEvent("animover", function() 
            if inst.bloom then inst.AnimState:ClearBloomEffectHandle() end
            inst:Remove() 
        end)
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

        if not t.twofaced then
            inst.Transform:SetFourFaced()
        else
            inst.Transform:SetTwoFaced()
        end

        inst:AddTag("FX")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false
        inst:DoTaskInTime(1, inst.Remove)

        return inst
    end

    return Prefab("common/"..t.name, fn, assets)
end

local prefs = {}
local fx = require("fx")

for k, v in pairs(fx) do
    table.insert(prefs, MakeFx(v))
end

return unpack(prefs)
