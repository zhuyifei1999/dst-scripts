require "prefabs/winter_ornaments"

local assets =
{
    Asset("ANIM", "anim/klaus_bag.zip"),
}

local prefabs =
{
    "klaus",
    "boneshard",
    "bundle",
    "gift",

    --loot
    "krampus_sack",
    "charcoal",
    "goldnugget",
    "amulet",

    --winter loot
    "goatmilk",
    "winter_food1", --gingerbread cookies
    "winter_food2", --sugar cookies
}

local giant_loot1 =
{
    "deerclops_eyeball",
    "dragon_scales",
    "hivehat",
    "shroom_skin",
}

local giant_loot2 =
{
    "dragonflyfurnace_blueprint",
    "red_mushroomhat_blueprint",
    "green_mushroomhat_blueprint",
    "blue_mushroomhat_blueprint",
    "mushroom_light2_blueprint",
    "mushroom_light_blueprint",
}

local giant_loot3 =
{
    "bearger_fur", --2
    "royal_jelly", --6
    "goose_feather", --5
    "lavae_egg",
    "spiderhat",
}

for i, v in ipairs(giant_loot1) do
    table.insert(prefabs, v)
end

for i, v in ipairs(giant_loot2) do
    table.insert(prefabs, v)
end

for i, v in ipairs(giant_loot3) do
    table.insert(prefabs, v)
end

for i, v in ipairs(GetAllWinterOrnamentPrefabs()) do
    table.insert(prefabs, v)
end

local KLAUS_SPAWN_DIST_FROM_PLAYER = 25

local function NotNearPlayers(pt) 
    return not IsAnyPlayerInRange(pt.x, pt.y, pt.z, KLAUS_SPAWN_DIST_FROM_PLAYER)
end

local function DropBundle(inst, items)
    local bundle = SpawnPrefab(IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) and "gift" or "bundle")
    bundle.components.unwrappable:WrapItems(items)
    for i, v in ipairs(items) do
        v:Remove()
    end
    inst.components.lootdropper:FlingItem(bundle)
end

local function FillItems(items, prefab)
    for i = 1 + #items, math.random(3, 4) do
        table.insert(items, SpawnPrefab(prefab))
    end
end

local function onuseklauskey(inst, key, doer)
    if key:HasTag("trueklaussackkey") then
        inst.AnimState:PlayAnimation("open")
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/klaus/chain_foley")
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/klaus/lock_break")

        if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
            local items =
            {
                SpawnPrefab(GetRandomBasicWinterOrnament()),
                SpawnPrefab(GetRandomBasicWinterOrnament()),
                SpawnPrefab(GetRandomFancyWinterOrnament()),
                SpawnPrefab(GetRandomLightWinterOrnament()),
            }
            DropBundle(inst, items)

            items =
            {
                SpawnPrefab("goatmilk"),
                SpawnPrefab("goatmilk"),
                SpawnPrefab("winter_food"..tostring(math.random(2))),
            }
            items[3].components.stackable.stacksize = 4
            DropBundle(inst, items)
        end

        local items = {}
        table.insert(items, SpawnPrefab("amulet"))
        table.insert(items, SpawnPrefab("goldnugget"))
        FillItems(items, "charcoal")
        DropBundle(inst, items)

        items = {}
        if math.random() < .5 then
            table.insert(items, SpawnPrefab("amulet"))
        end
        table.insert(items, SpawnPrefab("goldnugget"))
        FillItems(items, "charcoal")
        DropBundle(inst, items)

        items = {}
        if math.random() < .1 then
            table.insert(items, SpawnPrefab("krampus_sack"))
        end
        table.insert(items, SpawnPrefab("goldnugget"))
        FillItems(items, "charcoal")
        DropBundle(inst, items)

        local i1 = math.random(#giant_loot3)
        local i2 = math.random(#giant_loot3 - 1)
        DropBundle(inst, {
            SpawnPrefab(giant_loot1[math.random(#giant_loot1)]),
            SpawnPrefab(giant_loot2[math.random(#giant_loot2)]),
            SpawnPrefab(giant_loot3[i1]),
            SpawnPrefab(giant_loot3[i2 == i1 and i2 + 1 or i2]),
        })

        inst.persists = false
        inst:AddTag("NOCLICK")
        inst:DoTaskInTime(1, ErodeAway)

        return true
    elseif key:HasTag("klaussackkey") then
        inst.components.lootdropper:FlingItem(SpawnPrefab("boneshard"), doer:GetPosition())

        inst.AnimState:PlayAnimation("jiggle")
        inst.AnimState:PushAnimation("idle", false)
        inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/chain")

        if inst.components.entitytracker:GetEntity("klaus") ~= nil then
            --klaus is already spawned
            --announce danger?
        elseif inst.components.entitytracker:GetEntity("key") ~= nil then
            --already got the right key
            --announce that this isn't the right key
        else
            local pos = inst:GetPosition()
            local spawnpt = Vector3(pos.x, 0, pos.z)

            -- look for a location around the sack that is offscreen.
            -- if no valid locations, then look for a location off screen, centered on the player who tried to open the sack.
            local result_offset = FindWalkableOffset(spawnpt, math.random() * 2 * PI, (KLAUS_SPAWN_DIST_FROM_PLAYER + 8), 8, true, true, NotNearPlayers) -- +8 because the players arent standing on top of the sack
            if result_offset ~= nil then
                spawnpt.x = spawnpt.x + result_offset.x
                spawnpt.z = spawnpt.z + result_offset.z
            elseif doer ~= nil and doer:IsValid() then
                local doerpos = doer:GetPosition()
                result_offset = FindWalkableOffset(doerpos, math.random() * 2 * PI, (KLAUS_SPAWN_DIST_FROM_PLAYER + 8), 8, true, true, NotNearPlayers)
                if result_offset ~= nil then
                    spawnpt.x = doerpos.x + result_offset.x
                    spawnpt.z = doerpos.z + result_offset.z
                end
            end

            local klaus = SpawnPrefab("klaus")
            klaus.Transform:SetPosition(spawnpt:Get())
            klaus:SpawnDeer()
            -- override the spawn point so klaus comes to his sack
            klaus.components.knownlocations:RememberLocation("spawnpoint", pos, false)

            inst.components.entitytracker:TrackEntity("klaus", klaus)
            inst:ListenForEvent("dropkey", inst.OnDropKey, klaus)
        end
        return true
    end
    return false
end

local function OnLoadPostPass(inst)
    local klaus = inst.components.entitytracker:GetEntity("klaus")
    if klaus ~= nil then
        inst:ListenForEvent("dropkey", inst.OnDropKey, klaus)
    end
end

local function OnDropKey(inst, key, klaus)
    inst.components.entitytracker:ForgetEntity("key")
    inst.components.entitytracker:TrackEntity("key", key)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.AnimState:SetBank("klaus_bag")
    inst.AnimState:SetBuild("klaus_bag")
    inst.AnimState:PlayAnimation("idle")
    if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
        inst.AnimState:OverrideSymbol("swap_chain", "klaus_bag", "swap_chain_winter")
        inst.AnimState:OverrideSymbol("swap_chain_link", "klaus_bag", "swap_chain_link_winter")
        inst.AnimState:OverrideSymbol("swap_chain_lock", "klaus_bag", "swap_chain_lock_winter")
    end

    inst.MiniMapEntity:SetIcon("klaus_sack.png")

    --klaussacklock (from klaussacklock component) added to pristine state for optimization
    inst:AddTag("klaussacklock")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")

    inst:AddComponent("klaussacklock")
    inst.components.klaussacklock:SetOnUseKey(onuseklauskey)

    inst:AddComponent("entitytracker")

    MakeHauntableWork(inst)

    TheWorld:PushEvent("ms_registerklaussack", inst)

    inst.OnDropKey = function(klaus, key) OnDropKey(inst, key, klaus) end
    inst.OnLoadPostPass = OnLoadPostPass

    return inst
end

return Prefab("klaus_sack", fn, assets, prefabs)
