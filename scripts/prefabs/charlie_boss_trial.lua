local TEXTURE = "fx/sparkle.tex"
local SHADER = "shaders/vfx_particle_add.ksh"

local assets =
{
	Asset("ANIM", "anim/atrium_charlie_arena_ground.zip"),
	Asset("ANIM", "anim/atrium_charlie_arena_ground_portal.zip"),

    Asset("IMAGE", TEXTURE),
    Asset("SHADER", SHADER),
}

local prefabs =
{
	"charlie_boss",
	--"shrouden",

	"charliearena_lightray",
	"miasma_cloud_visual",
    "shadowhand_shrouded",
    "charlie_boss_runner",
}

local TILE_SCALE = TILE_SCALE
local ARENA_DIST_TO_SQUARE_EDGE = 3.5 * TILE_SCALE

--------------------------------------------------------------------------

local SHROUDED_HAND_TARGETS = {} -- Intentionally for only hands spawned by a charlie_boss_trial.

local function _dbg_print(...)
	print("[charlie_boss_trial.lua]:", ...)
end

local function TrackCharlieBoss(inst, boss)
	inst:ListenForEvent("death", inst._oncharliebossdied, boss)
	inst:ListenForEvent("ms_charliearena_shadowrunners_setenabled", inst._onshadowrunnersenabled, boss)
	inst:ListenForEvent("ms_charliearena_shadowhands_setenabled", inst._onshadowhandsenabled, boss)
end

local function SpawnTrackedPrefabAtXZ(inst, id, prefab, x, z)
	local ent = SpawnPrefab(prefab)
	ent.Transform:SetPosition(x, 0, z)
	inst.components.entitytracker:TrackEntity(id, ent)
	return ent
end

local function SpawnPrefabAtXZ(prefab, x, z)
	local ent = SpawnPrefab(prefab)
	ent.Transform:SetPosition(x, 0, z)
	return ent
end

local INNER_MINX, INNER_MAXX, INNER_MINY, INNER_MAXY = -3 - 1, 3 + 1, -3 - 1, 3 + 1 -- 1 extra length to take into account overhang

local function GetBorderTiles(otx, oty, padding)
    padding = padding or 0
    local exits = {}

    for xx = INNER_MINX - padding, INNER_MAXX + padding do
        local tx, ty = otx + xx, oty + INNER_MINY - padding
        table.insert(exits, { x = tx, y = ty })

        tx, ty = otx + xx, oty + INNER_MAXY + padding
        table.insert(exits, { x = tx, y = ty })
    end

    for yy = INNER_MINY - padding, INNER_MAXY + padding do
        local tx, ty = otx + INNER_MINX - padding, oty + yy
        table.insert(exits, { x = tx, y = ty })

        tx, ty = otx + INNER_MAXX + padding, oty + yy
        table.insert(exits, { x = tx, y = ty })
    end

    return exits
end

local function SpawnBorder(inst)
	local x, _, z = inst.Transform:GetWorldPosition()
	local otx, oty = TheWorld.Map:GetTileCoordsAtPoint(x, 0, z)
	local exits = GetBorderTiles(otx, oty)
    for i, v in ipairs(exits) do
		local tx, ty, tz = TheWorld.Map:GetTileCenterPoint(v.x, v.y)
        local cloud = SpawnPrefab("miasma_cloud_arenabordervisual")
		cloud.entity:SetParent(inst.entity)
		cloud.Transform:SetPosition(x - tx, 0, z - tz)
    end
end

local function InitializeLayout(inst, virtualroomset)
	local x, _, z = inst.Transform:GetWorldPosition()
    -- local otx, oty = virtualroomset:GetOriginInTiles()

	local charlie = SpawnTrackedPrefabAtXZ(inst, "charlie_boss", "charlie_boss", x, z)
	charlie.sg:GoToState("spawn")
	TrackCharlieBoss(inst, charlie)

	--light rays
	local halftile = 0.5 * TILE_SCALE
	local base_r = 2 * TILE_SCALE
	local lx, lz = x + GetRandomWithVariance(base_r, halftile), z + math.random() * halftile
	SpawnTrackedPrefabAtXZ(inst, "light1", "charliearena_lightray", lx, lz)
	SpawnPrefabAtXZ("miasma_cloud_visual", lx, lz)
	lx, lz = x - GetRandomWithVariance(base_r, halftile), z + math.random() * halftile
	SpawnTrackedPrefabAtXZ(inst, "light2", "charliearena_lightray", lx, lz)
	SpawnPrefabAtXZ("miasma_cloud_visual", lx, lz)
	lx, lz = x + math.random() * halftile, z + GetRandomWithVariance(base_r, halftile)
	SpawnTrackedPrefabAtXZ(inst, "light1", "charliearena_lightray", lx, lz)
	SpawnPrefabAtXZ("miasma_cloud_visual", lx, lz)
	lx, lz = x + math.random() * halftile, z - GetRandomWithVariance(base_r, halftile)
	SpawnTrackedPrefabAtXZ(inst, "light1", "charliearena_lightray", lx, lz)
	SpawnPrefabAtXZ("miasma_cloud_visual", lx, lz)

	SpawnBorder(inst)
end

local function OnLoadPostPass(inst, ents, data)
	local ent = inst.components.entitytracker:GetEntity("charlie_boss")
	if ent then
		TrackCharlieBoss(inst, ent)
	end

	SpawnBorder(inst)
end

local function DissipateAllShadowHands(inst)
    for hand, _ in pairs(inst.shadowhandsdata.hands) do
        hand:Dissipate()
    end
end

local function TryToFindSpawnPointForHand(inst, target)
    -- NOTES(JBK): For this we will find a point along the square permiter closest to the target and then add a jiggle offset so the hand approaches not always tangentially.
    -- This adds some predictability to the engagement but also makes all hands immediate threats to light sources since they travel as minimal as possible.
    local cx, cy, cz = inst.Transform:GetWorldPosition()
    local tx, ty, tz = target.Transform:GetWorldPosition()
    local dx, dz = tx - cx, tz - cz

    local minx = cx - ARENA_DIST_TO_SQUARE_EDGE
    local maxx = cx + ARENA_DIST_TO_SQUARE_EDGE
    local minz = cz - ARENA_DIST_TO_SQUARE_EDGE
    local maxz = cz + ARENA_DIST_TO_SQUARE_EDGE

    local x, z = tx, tz
    if -ARENA_DIST_TO_SQUARE_EDGE < dx and dx < ARENA_DIST_TO_SQUARE_EDGE and -ARENA_DIST_TO_SQUARE_EDGE < dz and dz < ARENA_DIST_TO_SQUARE_EDGE then
        -- Target is inside the square must find the closest edge.
        local distleft = dx + ARENA_DIST_TO_SQUARE_EDGE
        local distright = ARENA_DIST_TO_SQUARE_EDGE - dx
        local distdown = dz + ARENA_DIST_TO_SQUARE_EDGE
        local distup = ARENA_DIST_TO_SQUARE_EDGE - dz

        local mindist = math.min(distleft, distright, distdown, distup)

        if mindist == distleft then
            x = minx
            z = GetRandomWithVariance(z, TILE_SCALE)
        elseif mindist == distright then
            x = maxx
            z = GetRandomWithVariance(z, TILE_SCALE)
        elseif mindist == distdown then
            x = GetRandomWithVariance(x, TILE_SCALE)
            z = minz
        else--if mindist == distup then
            x = GetRandomWithVariance(x, TILE_SCALE)
            z = maxz
        end
    end

    -- Always clamp to force being on an edge.
    x = math.clamp(x, minx, maxx)
    z = math.clamp(z, minz, maxz)

    return x, 0, z
end

local HANDTARGET_ONEOF_TAGS = { "fire", "light", "staffstar", }
local HANDTARGET_CANT_TAGS = { "INLIMBO", "shadow_fire" }

local FUEL_TAGS = nil -- Cached once.
local function TryToFindHandTargetForPlayer(inst, player)
    if not FUEL_TAGS then
        FUEL_TAGS = {}
        for _, v in pairs(FUELTYPE) do
            if v ~= FUELTYPE.USAGE then --Not a real fuel
                table.insert(FUEL_TAGS, v.."_fueled")
            end
        end
    end

    local x, y, z = player.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, TUNING.SHADOWHAND_SHROUDED_FINDLIGHT_RADIUS, nil, HANDTARGET_CANT_TAGS, HANDTARGET_ONEOF_TAGS)
    for _, ent in ipairs(ents) do
        if not SHROUDED_HAND_TARGETS[ent] then
            if ent:HasTag("fire") then
                if ent:HasAnyTag(FUEL_TAGS) then
                    return ent
                end
            elseif ent:HasTag("light") then
                if ent:HasTag("turnedon") then
                    return ent
                end
            else--if ent:HasTag("staffstar") then
                return ent
            end
        end
    end

    return nil
end

local function TryToMakeHandForPlayer(inst, player)
    local totalhandscount = inst.shadowhandsdata.totalhandscount
    if totalhandscount >= TUNING.SHADOWHAND_SHROUDED_MAX_OUTATONCE then
        return false
    end

    local target = inst:TryToFindHandTargetForPlayer(player)
    if not target then
        return false
    end

    local x, y, z = inst:TryToFindSpawnPointForHand(target)
    if not x then
        return false
    end

    local hand = SpawnPrefab("shadowhand_shrouded")
    inst.shadowhandsdata.totalhandscount = totalhandscount + 1
    inst.shadowhandsdata.hands[hand] = target
    SHROUDED_HAND_TARGETS[target] = true
    hand:ListenForEvent("onremove", inst._onremove_shadowhand)
    hand.Transform:SetPosition(x, y, z)
    local actionoverride = target.components.machine and ACTIONS.TURNOFF or nil
    hand:SetTargetFire(target, actionoverride)
end

local function OnShadowHandsTick(inst)
    if inst.shadowhandsdata.totalhandscount < TUNING.SHADOWHAND_SHROUDED_MAX_OUTATONCE then
        local players, numberplayers = GetPlayersInfoForVirtualRoomSetName(VIRTUALROOMSETS.ATRIUM)
        if players then
            for player, _ in pairs(players) do
                if not inst:TryToMakeHandForPlayer(player) then
                    if inst.shadowhandsdata.totalhandscount >= TUNING.SHADOWHAND_SHROUDED_MAX_OUTATONCE then
                        break
                    end
                end
            end
        end
    end
end

local function OnShadowHandsEnabled(inst, enabled)
    if enabled then
        if not inst.shadowhandsdata.task then
            inst.shadowhandsdata.task = inst:DoPeriodicTask(1, OnShadowHandsTick)
        end
    else
        if inst.shadowhandsdata.task then
            inst.shadowhandsdata.task:Cancel()
            inst.shadowhandsdata.task = nil
        end
        inst:DissipateAllShadowHands()
    end
end

local function TryToFindSpawnPointForRunner(inst)
    local cx, cy, cz = inst.Transform:GetWorldPosition()

    local minx = cx - ARENA_DIST_TO_SQUARE_EDGE
    local maxx = cx + ARENA_DIST_TO_SQUARE_EDGE
    local minz = cz - ARENA_DIST_TO_SQUARE_EDGE
    local maxz = cz + ARENA_DIST_TO_SQUARE_EDGE

    local x, z
    local r = math.random(4)
    if r == 1 then
        x = minx
        z = GetRandomWithVariance(cz, ARENA_DIST_TO_SQUARE_EDGE)
    elseif r == 2 then
        x = maxx
        z = GetRandomWithVariance(cz, ARENA_DIST_TO_SQUARE_EDGE)
    elseif r == 3 then
        x = GetRandomWithVariance(cx, ARENA_DIST_TO_SQUARE_EDGE)
        z = minz
    elseif r == 4 then
        x = GetRandomWithVariance(cx, ARENA_DIST_TO_SQUARE_EDGE)
        z = maxz
    end

    return x, 0, z
end

local function OnShadowRunnersTick(inst)
    local totalrunnerscount = inst.shadowrunnersdata.totalrunnerscount
    if totalrunnerscount >= TUNING.CHARLIE_BOSS_RUNNER_MAXCOUNT then
        return false
    end

    local num_runners = TUNING.CHARLIE_BOSS_RUNNER_BASE_AMOUNT
    local num_players = 0
    for _, v in ipairs(AllPlayers) do
        if not IsEntityDeadOrGhost(v) and v.entity:IsVisible() then
			local x1, y1, z1 = v.Transform:GetWorldPosition()
			if TheWorld.Map:IsPointInCharlieBossArena(x1, y1, z1) then
                num_players = num_players + 1
            end
        end
    end
    num_runners = num_runners + RoundBiasedDown(num_players*TUNING.CHARLIE_BOSS_RUNNER_AMOUNT_PER_PLAYER)

    local charlieboss = inst.components.entitytracker:GetEntity("charlie_boss")
    for i = 1, num_runners do
        local totalrunnerscount = inst.shadowrunnersdata.totalrunnerscount
        if totalrunnerscount >= TUNING.CHARLIE_BOSS_RUNNER_MAXCOUNT then
            return false
        end

        local x, y, z = TryToFindSpawnPointForRunner(inst)
        local angle = ReduceAngle(inst:GetAngleToPoint(x, y, z) - 180)

        local runner = SpawnPrefab("charlie_boss_runner")
        runner.Transform:SetPosition(x, y, z)
        runner.Transform:SetRotation(angle)
        runner:PushEventImmediate("spawn")
        runner.caster = charlieboss

        inst.shadowrunnersdata.totalrunnerscount = totalrunnerscount + 1
        inst.shadowrunnersdata.runners[runner] = true
        runner:ListenForEvent("onremove", inst._onremove_shadowrunner)
    end
end

local function OnShadowRunnersEnabled(inst, enabled)
    if enabled then
        if not inst.shadowrunnersdata.task then
            inst.SoundEmitter:PlaySound("rifts8/shadow_insanity_player/horde_warning_LP", "horde_lp")
            inst.shadowrunnersdata.task = inst:DoPeriodicTask(4, OnShadowRunnersTick, 0.3 + math.random() * 0.2)
        end
    elseif inst.shadowrunnersdata.task then
        inst.SoundEmitter:KillSound("horde_lp")
        inst.shadowrunnersdata.task:Cancel()
        inst.shadowrunnersdata.task = nil
    end
end

local function AddPortalLayer(inst, layer, height)
	local fx = CreateEntity()

	fx:AddTag("FX")
	fx:AddTag("NOCLICK")
	--[[Non-networked entity]]
	fx.entity:SetCanSleep(TheWorld.ismastersim)
	fx.persists = false

	fx.entity:AddTransform()
	fx.entity:AddAnimState()

	fx.AnimState:SetBuild("atrium_charlie_arena_ground_portal")
	fx.AnimState:SetBank("atrium_charlie_arena_ground_portal")
	fx.AnimState:PlayAnimation("idle", true)
	fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	fx.AnimState:SetLayer(LAYER_BACKGROUND)
	fx.AnimState:Hide("edge")
	fx.AnimState:Hide(layer == "deep" and "mid" or "deep")
	fx.AnimState:SetSortOrder(-2)

	fx.entity:SetParent(inst.entity)
	fx.Transform:SetPosition(0, height, 0)

	return fx
end

local function CreatePortal()
	local inst = CreateEntity()

	inst:AddTag("FX")
	--[[Non-networked entity]]
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.AnimState:SetBank("atrium_charlie_arena_ground_portal")
	inst.AnimState:SetBuild("atrium_charlie_arena_ground_portal")
	inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:Hide("mid")
    inst.AnimState:Hide("deep")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(-1)

	inst.animlayers =
	{
		AddPortalLayer(inst, "mid", -0.25),
		AddPortalLayer(inst, "deep", -0.5),
	}

	return inst
end

----------------------------------------------------------

local ATRIUM_ARENA_SIZE = 14.55
local TERRAFORM_BLOCKER_RADIUS = math.ceil(ATRIUM_ARENA_SIZE / 3)

local function CreateTerraformBlocker(parent)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()

    inst:SetTerraformExtraSpacing(TERRAFORM_BLOCKER_RADIUS + 0.01)

    return inst
end

local function AddTerraformBlockers(inst) -- NOTES(JBK): Keep in sync with atrium_gate. [ARTBES]
    local diameter = 2 * TERRAFORM_BLOCKER_RADIUS
    local rowoffset = 3 * TERRAFORM_BLOCKER_RADIUS
    for row = -rowoffset, rowoffset, diameter do
        for col = -diameter, diameter, diameter do
            local blocker = CreateTerraformBlocker(inst)
            blocker.entity:SetParent(inst.entity)
            blocker.Transform:SetPosition(row, 0, col)

            blocker = CreateTerraformBlocker(inst)
            blocker.entity:SetParent(inst.entity)
            blocker.Transform:SetPosition(col, 0, row)
        end
    end
end

----------------------------------------------------------

local function IntColour(r, g, b, a)
    return { r / 255, g / 255, b / 255, a / 255 }
end

local COLOUR_ENVELOPE_NAME = "charliearenaembercolourenvelope"
local SCALE_ENVELOPE_NAME = "charliearenascaleenvelope"

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {
            { 0,        IntColour(255, 220, 234, 0) },
            { .2,       IntColour(255, 220, 234, 255) },
            { .75,      IntColour(255, 220, 234, 247) },
            { 1,        IntColour(255, 220, 234, 0) },
        }
    )

    local min_scale = .43
    local max_scale = .50
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { min_scale, min_scale } },
            { .5,   { max_scale, max_scale } },
            { 1,    { min_scale, min_scale } },
        }
    )

    InitEnvelope = nil
    IntColour = nil
end

local function InitParticles(inst)
	if InitEnvelope ~= nil then
        InitEnvelope()
    end

	local MAX_LIFETIME = 40
	local MIN_LIFETIME = 25

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)
    effect:SetRenderResources(0, TEXTURE, SHADER)
    effect:SetMaxNumParticles(0, 400)
    effect:SetMaxLifetime(0, MAX_LIFETIME)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    effect:SetBlendMode(0, BLENDMODE.Additive)
    effect:SetSortOrder(0, 0)
    effect:SetLayer(0, LAYER_BELOW_GROUND)
    effect:SetAcceleration(0, 0, .0001, 0)
    effect:SetDragCoefficient(0, .0001)
    effect:EnableDepthTest(0, false)
    effect:SetKillOnEntityDeath(0, true)
    effect:SetUVFrameSize(0, .25, 1)

    local tick_time = TheSim:GetTickTime()

    inst.particles_per_tick = 20 * tick_time
    inst.num_particles_to_emit = inst.particles_per_tick * 2 -- x2 on first tick to populate quickly

    local halfheight = 2
    local emitter_shape = CreateBoxEmitter(0, 0, 0, 35, halfheight, 35)

    -- for discarding
    local minx, maxx, minz, maxz = -4 * TILE_SCALE, 4 * TILE_SCALE, -4 * TILE_SCALE, 4 * TILE_SCALE

    local function emit_fn()
        local px, py, pz = emitter_shape()
        py = py + halfheight -- otherwise the particles appear under the ground

        local vx = .0015 * (math.random() - .5)
        local vy = .0005
        local vz = .0015 * (math.random() - .5)

        local lifetime = MIN_LIFETIME + (MAX_LIFETIME - MIN_LIFETIME) * UnitRand()

        if minx > px or px > maxx or minz > pz or pz > maxz then
            local uv_offset = math.random(0, 3) * .25
            effect:AddParticleUV(
                0,
                lifetime,           -- lifetime
                px, py, pz,         -- position
                vx, vy, vz,         -- velocity
                uv_offset, 0        -- uv offset
            )
        end
    end

    inst.time = 0
    inst.interval = 0
    EmitterManager:AddEmitter(inst, nil, function()
        if not (ThePlayer and TheWorld.Map:IsPointInCharlieBossArena(ThePlayer.Transform:GetWorldPosition())) then
            return
        end
        while inst.num_particles_to_emit > 1 do
            emit_fn()
            inst.num_particles_to_emit = inst.num_particles_to_emit - 1
        end
        inst.num_particles_to_emit = inst.num_particles_to_emit + inst.particles_per_tick

        inst.time = inst.time + tick_time
        inst.interval = inst.interval + 1
        if inst.interval >= 10 then
            inst.interval = 0
            local sin_val = .001 * math.sin(inst.time * .8)
            effect:SetAcceleration(0, 0, sin_val, 0)
        end
    end)
end

--------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.AnimState:SetBank("atrium_charlie_arena_ground")
	inst.AnimState:SetBuild("atrium_charlie_arena_ground")
	inst.AnimState:PlayAnimation("idle_active_on")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(0)

	inst:AddComponent("charliearenawatcher")
	inst:AddComponent("temperatureoverrider") -- configured server-side

	--Dedicated server does not need to spawn the markers or local particle fx
	if not TheNet:IsDedicated() then
		InitParticles(inst)

		local portal = CreatePortal()
		portal.entity:SetParent(inst.entity)
	end

    --Dedicated servers need this too
    AddTerraformBlockers(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.temperatureoverrider:SetRadius(TUNING.CHARLIE_ARENA_RADIUS)
	inst.components.temperatureoverrider:SetTemperature(TUNING.CHARLIE_ARENA_TEMPERATURE_OVERRIDE)

	inst:AddComponent("entitytracker")

	inst._oncharliebossdied = function(boss)
		inst.components.entitytracker:ForgetEntity("charlie_boss")
        TheWorld:PushEvent("resetvault") -- this resets atrium room
        Shard_SyncCharlieDefeated(true)
	end

    inst._onshadowrunnersenabled = function(boss, enabled) OnShadowRunnersEnabled(inst, enabled) end
    inst._onshadowhandsenabled = function(boss, enabled) OnShadowHandsEnabled(inst, enabled) end

    inst.shadowrunnersdata = {
        totalrunnerscount = 0,
        runners = {},
    }
    inst._onremove_shadowrunner = function(runner)
        inst.shadowrunnersdata.totalrunnerscount = inst.shadowrunnersdata.totalrunnerscount - 1
        inst.shadowrunnersdata.runners[runner] = nil
    end

    inst.shadowhandsdata = {
        totalhandscount = 0,
        hands = {},
    }
    inst.TryToFindSpawnPointForHand = TryToFindSpawnPointForHand
    inst.TryToFindHandTargetForPlayer = TryToFindHandTargetForPlayer
    inst.TryToMakeHandForPlayer = TryToMakeHandForPlayer
    inst.DissipateAllShadowHands = DissipateAllShadowHands
    inst._onremove_shadowhand = function(hand)
        inst.shadowhandsdata.totalhandscount = inst.shadowhandsdata.totalhandscount - 1
        SHROUDED_HAND_TARGETS[inst.shadowhandsdata.hands[hand]] = nil
        inst.shadowhandsdata.hands[hand] = nil
    end

	inst.InitializeLayout = InitializeLayout
	inst.OnLoadPostPass = OnLoadPostPass

	return inst
end

return Prefab("charlie_boss_trial", fn, assets, prefabs)
