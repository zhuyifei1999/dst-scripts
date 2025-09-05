local assets = {
    Asset("ANIM", "anim/whirlbigportal.zip"),
    Asset("SOUND", "sound/rifts6.fsb"),
}

local prefabs = {
    "wave_med",
}


local function OnRemoveEntity(inst)
    inst.SoundEmitter:KillSound("wave")
end

local function OpenWhirlportal_finalize(inst)
    inst:RemoveEventCallback("animover", inst.OpenWhirlportal_finalize)
    inst.openingwhirlportal = nil
    inst.SoundEmitter:PlaySound("rifts6/whirlpool/whirlpool_LP", "wave")
    inst.SoundEmitter:SetParameter("wave", "size", 0.5)
    inst.AnimState:PlayAnimation("open_loop", true)
    inst.components.oceanwhirlportalphysics:SetEnabled(true)
end

local function OpenWhirlportal(inst)
    if not inst:IsAsleep() then
        if not inst.openingwhirlportal then
            inst.SoundEmitter:PlaySound("rifts6/whirlpool/whirlpool_pre")
            inst.AnimState:PlayAnimation("open_pre")
            inst:ListenForEvent("animover", inst.OpenWhirlportal_finalize)
            inst.openingwhirlportal = true
        end
    else
        inst:OpenWhirlportal_finalize()
    end
end

local function CloseWhirlportal(inst)
    if inst.openingwhirlportal then
        inst:RemoveEventCallback("animover", inst.OpenWhirlportal_finalize)
        inst.openingwhirlportal = nil
    end
    inst.SoundEmitter:KillSound("wave")
    inst.SoundEmitter:PlaySound("rifts6/whirlpool/whirlpool_pst")
    inst.AnimState:PlayAnimation("open_pst")
    inst.AnimState:PushAnimation("closed")
    inst.components.oceanwhirlportalphysics:SetEnabled(false)
end

local function SplashWhirlportal(inst, data)
    local doer = data and data.doer or nil
    if doer then
        local x, y, z = doer.Transform:GetWorldPosition()
        local fx_prefabs = GetSinkEntityFXPrefabs(doer, x, y, z)
        if fx_prefabs then
            for _, fx_prefab in pairs(fx_prefabs) do
                local fx = SpawnPrefab(fx_prefab)
                fx.Transform:SetPosition(x, y, z)
            end
        end
    end
end

local function OnEntityTouchingFocalFn(inst, ent)
    if not inst.components.worldmigrator:Activate(ent) then
        if ent:HasTag("boat") and ent.components.health then
            if not ent.components.health:IsDead() then
                ent.components.health:SetPercent(math.max(ent.components.health:GetPercent() - TUNING.OCEANWHIRLBIGPORTAL_BOAT_PERCENT_DAMAGE_PER_TICK), 0)
                if ent.components.health:IsDead() then
                    ent:InstantlyBreakBoat()
                else
                    if ent.sounds and ent.sounds.damage then
                        ent.SoundEmitter:PlaySoundWithParams(ent.sounds.damage, {intensity = 1})
                    end
                end
            end
        else
            SinkEntity(ent)
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("whirlbigportal")
    inst.AnimState:SetBank("whirlbigportal")
    inst.AnimState:PlayAnimation("closed")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(ANIM_SORT_ORDER.OCEAN_WHIRLPORTAL)
    inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT)

    inst.MiniMapEntity:SetIcon("oceanwhirlbigportal.png")
    inst.MiniMapEntity:SetPriority(-2)

    inst:AddTag("birdblocker")
    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("oceanwhirlportal")
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst:SetDeployExtraSpacing(TUNING.OCEANWHIRLBIGPORTAL_RADIUS)

    inst.highlightoverride = {0.1, 0.1, 0.3}
    inst.scrapbook_inspectonseen = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_anim = "open_loop"
    --inst.scrapbook_scale = 1.5
    --inst.scrapbook_animoffsetx = 30
    --inst.scrapbook_animoffsety = -10
    --inst.scrapbook_animoffsetbgx = 80
    --inst.scrapbook_animoffsetbgy = 40

    local wateryprotection = inst:AddComponent("wateryprotection")
    wateryprotection.extinguishheatpercent = TUNING.OCEANWHIRLPORTAL_EXTINGUISH_HEAT_PERCENT
    wateryprotection.temperaturereduction = TUNING.OCEANWHIRLPORTAL_TEMP_REDUCTION
    wateryprotection.witherprotectiontime = TUNING.OCEANWHIRLPORTAL_PROTECTION_TIME
    wateryprotection.addcoldness = TUNING.OCEANWHIRLPORTAL_ADD_COLDNESS
    wateryprotection.addwetness = TUNING.OCEANWHIRLPORTAL_ADD_WETNESS
    wateryprotection.applywetnesstoitems = true

    local oceanwhirlportalphysics = inst:AddComponent("oceanwhirlportalphysics")
    oceanwhirlportalphysics:SetFocalRadius(TUNING.OCEANWHIRLBIGPORTAL_FOCALRADIUS)
    oceanwhirlportalphysics:SetRadius(TUNING.OCEANWHIRLBIGPORTAL_RADIUS)
    oceanwhirlportalphysics:SetPullStrength(TUNING.OCEANWHIRLBIGPORTAL_PULLSTRENGTH)
    oceanwhirlportalphysics:SetRadialStrength(TUNING.OCEANWHIRLBIGPORTAL_RADIALSTRENGTH)
    oceanwhirlportalphysics:SetOnEntityTouchingFocalFn(OnEntityTouchingFocalFn)

    inst.OnRemoveEntity = OnRemoveEntity

    local worldmigrator = inst:AddComponent("worldmigrator")
    worldmigrator.shard_name = "Caves" -- SERVER_LEVEL_SHARDS
    worldmigrator:SetID("oceanwhirlbigportal")
    worldmigrator:SetHideActions(true)
    inst.OpenWhirlportal = OpenWhirlportal
    inst.OpenWhirlportal_finalize = OpenWhirlportal_finalize
    inst.CloseWhirlportal = CloseWhirlportal
    inst.SplashWhirlportal = SplashWhirlportal
    inst:ListenForEvent("migration_available", inst.OpenWhirlportal)
    inst:ListenForEvent("migration_unavailable", inst.CloseWhirlportal)
    inst:ListenForEvent("migration_full", inst.CloseWhirlportal)
    inst:ListenForEvent("migration_activate", inst.SplashWhirlportal)

    return inst
end

local assets_exit = {
    Asset("ANIM", "anim/bigwaterfall.zip"),
    Asset("ANIM", "anim/moonglass_bigwaterfall_steam.zip"),
}

local function makebigmist(proxy)
    if not proxy then
        return nil
    end

    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    local parent = proxy.entity:GetParent()
    if parent ~= nil then
        inst.entity:SetParent(parent.entity)
    end

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.Transform:SetFromProxy(proxy.GUID)

    inst.AnimState:SetBuild("moonglass_bigwaterfall_steam")
    inst.AnimState:SetBank("moonglass_bigwaterfall_steam")
    inst.AnimState:PlayAnimation("steam_small"..math.random(1,2), true)
    inst.AnimState:SetLightOverride(0.5)

    proxy:ListenForEvent("onremove", function() inst:Remove() end)

    return inst
end
local function initclientfx(inst)
    makebigmist(inst)
    TheWorld:PushEvent("ms_registergrottopool", {pool = inst, small = false}) -- Register into the waterfall sound system.
end


local function fn_exit()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    --inst.MiniMapEntity:SetIcon("oceanwhirlbigportalexit.png") -- FIXME(JBK): rifts6 minimap icon

    inst.AnimState:SetBuild("bigwaterfall")
    inst.AnimState:SetBank("bigwaterfall")
    inst.AnimState:PlayAnimation("idle", true)

    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, initclientfx)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    local worldmigrator = inst:AddComponent("worldmigrator")
    worldmigrator.shard_name = "Master" -- SERVER_LEVEL_SHARDS
    worldmigrator:SetID("oceanwhirlbigportal")
    worldmigrator:SetEnabled(false) -- Always closed, one way.

    return inst
end

return Prefab("oceanwhirlbigportal", fn, assets, prefabs),
    Prefab("oceanwhirlbigportalexit", fn_exit, assets_exit)

-- NOTES(JBK): Search terms: "oceanwhirlbigpool", "whirlbigpool",
