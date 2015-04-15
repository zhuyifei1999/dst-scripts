local groundtiles = require "worldtiledefs"
require "components/map" --extends Map component

local assets =
{
    Asset("SOUND", "sound/sanity.fsb"),
    Asset("SHADER", "shaders/uifade.ksh"),
    Asset("ATLAS", "images/selectscreen_portraits.xml"), -- we need all these frontend assets in the world prefab so we can show the character select screen from the death screen
    Asset("IMAGE", "images/selectscreen_portraits.tex"),
    Asset("ATLAS", "bigportraits/locked.xml"),
    Asset("IMAGE", "bigportraits/locked.tex"),
    Asset("ANIM", "anim/portrait_frame.zip"),
}

-- Add all the characters by name
local charlist = GetActiveCharacterList and GetActiveCharacterList() or MAIN_CHARACTERLIST
for i, char in ipairs(charlist) do
    table.insert(assets, Asset("ATLAS", "bigportraits/"..char..".xml"))
    table.insert(assets, Asset("IMAGE", "bigportraits/"..char..".tex"))
    --table.insert(assets, Asset("IMAGE", "images/selectscreen_portraits/"..char..".tex"))
    --table.insert(assets, Asset("IMAGE", "images/selectscreen_portraits/"..char.."_silho.tex"))
end

for k, v in pairs(groundtiles.assets) do
    table.insert(assets, v)
end

local prefabs =
{
    "minimap",
    "evergreen",
    "evergreen_normal",
    "evergreen_short",
    "evergreen_tall",
    "evergreen_sparse",
    "evergreen_sparse_normal",
    "evergreen_sparse_short",
    "evergreen_sparse_tall",
    "evergreen_burnt",
    "evergreen_stump",

    "sapling",
    "berrybush",
    "berrybush2",
    "grass",
    "rock1",
    "rock2",
    "rock_flintless",
    "rock_moon",

    "tallbirdnest",
    "hound",
    "firehound",
    "icehound",
    "krampus",
    "mound",

    "pigman",
    "pighouse",
    "pigking",
    "mandrake",
    "chester",
    "rook",
    "bishop",
    "knight",

    "goldnugget",
    "crow",
    "robin",
    "robin_winter",
    "butterfly",
    "flint",
    "log",
    "spiderden",
    "spawnpoint",
    "fireflies",

    "turf_road",
    "turf_rocky",
    "turf_marsh",
    "turf_savanna",
    "turf_dirt",
    "turf_forest",
    "turf_grass",
    "turf_cave",
    "turf_fungus",
    "turf_sinkhole",
    "turf_underrock",
    "turf_mud",

    "skeleton",
    "insanityrock",
    "sanityrock",
    "basalt",
    "basalt_pillar",
    "houndmound",
    "houndbone",
    "pigtorch",
    "red_mushroom",
    "green_mushroom",
    "blue_mushroom",
    "mermhouse",
    "flower_evil",
    "blueprint",
    "lockedwes",
    "wormhole_limited_1",
    "diviningrod",
    "diviningrodbase",
    "splash_ocean",
    "maxwell_smoke",
    "chessjunk1",
    "chessjunk2",
    "chessjunk3",
    "statue_transition_2",
    "statue_transition",
}

local function PostInit(inst)
    if inst.net then
        inst.net:PostInit()
    end

    inst:LongUpdate(0)

    for k, v in pairs(inst.components) do
        if v.OnPostInit then
            v:OnPostInit()
        end
    end

end

local function OnRemoveEntity(inst)
    inst.minimap:Remove()

    assert(TheWorld == inst)
    TheWorld = nil

    assert(TheFocalPoint ~= nil)
    TheFocalPoint:Remove()
    TheFocalPoint = nil
end

local function OnUpdateServerListing(inst)
    SaveServerListingGameData({
        season = inst.state.season,
        day = inst.state.cycles + 1,
        daysleftinseason = inst.state.remainingdaysinseason,
        dayselapsedinseason = inst.state.elapseddaysinseason,
        worldgenoptions = SaveGameIndex:GetSlotGenOptions() or {},
    })
end

local function fn()
    local inst = CreateEntity()

    assert(TheWorld == nil)
    TheWorld = inst
    inst.net = nil

    inst.ismastersim = TheNet:GetIsMasterSimulation()

    inst:AddTag("NOCLICK")
    inst:AddTag("CLASSIFIED")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    --Add core components
    inst.entity:AddTransform()
    inst.entity:AddMap()
    inst.entity:AddPathfinder()
    inst.entity:AddGroundCreep()
    inst.entity:AddSoundEmitter()

    --Initialize map
    for i, data in ipairs(groundtiles.ground) do
        local tile_type, props = unpack(data)
        local layer_name = props.name
        local handle = MapLayerManager:CreateRenderLayer(
            tile_type, --embedded map array value
            resolvefilepath(GroundAtlas(layer_name)),
            resolvefilepath(GroundImage(layer_name)),
            resolvefilepath(props.noise_texture)
        )
        inst.Map:AddRenderLayer(handle)
        --TODO: When this object is destroyed, these handles really should be freed. At this time,
        --this is not an issue because the map lifetime matches the game lifetime but if this were
        --to ever change, we would have to clean up properly or we leak memory.
    end

    for i, data in ipairs(groundtiles.creep) do
        local tile_type, props = unpack(data)
        local handle = MapLayerManager:CreateRenderLayer(
            tile_type,
            resolvefilepath(GroundAtlas(props.name)),
            resolvefilepath(GroundImage(props.name)),
            resolvefilepath(props.noise_texture)
        )
        inst.GroundCreep:AddRenderLayer(handle)
    end

    local underground_layer = groundtiles.underground[1][2]
    local underground_handle = MapLayerManager:CreateRenderLayer(
        GROUND.UNDERGROUND,
        resolvefilepath(GroundAtlas(underground_layer.name)),
        resolvefilepath(GroundImage(underground_layer.name)),
        resolvefilepath(underground_layer.noise_texture)
    )
    inst.Map:SetUndergroundRenderLayer(underground_handle)

    inst.Map:SetImpassableType(GROUND.IMPASSABLE)

    --Initialize lua world state
    inst:AddComponent("worldstate")
    inst.state = inst.components.worldstate.data

    --Initialize lua components
    inst:AddComponent("groundcreep")

    --Public member functions
    inst.PostInit = PostInit
    inst.OnRemoveEntity = OnRemoveEntity

    --Initialize minimap
    inst.minimap = SpawnPrefab("minimap")

    --Initialize local focal point
    assert(TheFocalPoint == nil)
    TheFocalPoint = SpawnPrefab("focalpoint")
    TheCamera:SetTarget(TheFocalPoint)

    if inst.ismastersim then
        inst:AddComponent("playerspawner")

        --Give the game a couple of seconds to finish init and then
        --start periodically updating our listing every few minutes
        inst:DoPeriodicTask(5 * 60, OnUpdateServerListing, 2)
    end

    return inst
end

return Prefab("world", fn, assets, prefabs, true)