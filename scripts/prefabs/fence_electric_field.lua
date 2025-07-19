local assets =
{
	Asset("ANIM", "anim/fence_electric_field_fx.zip"),
}

--TODO refactor detection by using Physics

local WagdroneCommon = require("prefabs/wagdrone_common")

local function CreateSegFx(seg, rot, scale, pos_y)
	local fx = CreateEntity()

	fx:AddTag("FX")
	fx:AddTag("NOCLICK")
	--[[Non-networked entity]]
	fx.entity:SetCanSleep(false)
	fx.persists = false

	fx.entity:AddTransform()
	fx.entity:AddAnimState()
	fx.entity:AddFollower()

	fx.AnimState:SetBuild("fence_electric_field_fx")
	fx.AnimState:SetBank("fence_electric_field_fx")
	fx.AnimState:PlayAnimation("beam", true)
	fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	fx.AnimState:SetScale(scale, 1)
	fx.AnimState:SetMultColour(1, 1, 1, 0.4 + math.random() * 0.1)
	fx.AnimState:UsePointFiltering(true)

	fx.persists = false

	fx.Transform:SetRotation(rot)

	fx.entity:SetParent(seg.entity)
	fx.Follower:FollowSymbol(seg.GUID, "marker", 0, pos_y, 0)

	fx.AnimState:SetFrame(math.random(fx.AnimState:GetCurrentAnimationNumFrames()) - 1)

	fx.persists = false

	return fx
end

local function CreateSegAt(inst, x, z, rot, scale, isend)
	local seg = CreateEntity()

	seg:AddTag("FX")
	seg:AddTag("NOCLICK")
	--[[Non-networked entity]]
	seg.entity:SetCanSleep(false)
	seg.persists = false

	seg.entity:AddTransform()
	seg.entity:AddAnimState()

	seg.entity:SetParent(inst.entity)
	seg.Transform:SetPosition(x, 0, z)

	seg.AnimState:SetBuild("fence_electric_field_fx")
	seg.AnimState:SetBank("fence_electric_field_fx")
	seg.AnimState:PlayAnimation("follow_marker_fence_2")

	seg.persists = false

	--fx will be ground oriented, but raised by following the billboard "follow_marker_fence_2" symbol
	seg.fx = CreateSegFx(seg, rot, scale, 0)
	seg.fx2 = CreateSegFx(seg, rot, scale, 65)

	return seg
end

local function ClearSegs(inst)
	if inst.segs then
		for i, v in ipairs(inst.segs) do
			v:Remove()
		end
		inst.segs = nil
	end

	inst.Physics:SetActive(true) --We're unloaded, activate our physics!

	--[[if not TheWorld.ismastersim then
		return
	end]] --it's fine to run the cleanup code on clients anyway

	inst.SoundEmitter:KillSound("linked_lp")

	if inst.targettask then
		inst.targettask:Cancel()
		inst.targettask = nil
	end
end
--local OnEntitySleep = ClearSegs --this is set in prefab constructor

local MAX_LEN = 15
local SEG_LEN = 2.15 -- Bolt is 324 pixels long in file, 324 / 150 = 2.15~
local TARGET_SPACING = 4
local TARGET_RADIUS = TARGET_SPACING * 1.5
local TARGET_RANGE = 0.1 --distance from beam
local SLOW_PERIOD = 1
local FAST_PERIOD = 2 * FRAMES
local MIN_PHYS_RAD = 0.5 --NOTE (Omar): Any lower and we risk the mob gliding on through 
-- ^ NEVERMIND SMALLBIRDS ARE SOMEHOW JUMPING THE FENCE

local SHOCK_COOLDOWNS = {
	--SMALLCREATURE = 0.5,
	DEFAULT = 1,
	CHARACTER = 2,
	EPIC = 3,
}

local function ObjectNonPermanence(inst)
	inst:RemoveEventCallback("onremove", ObjectNonPermanence, inst.panic_electric_field)
    inst.panic_electric_field = nil
end

local function ClearForgetTask(inst)
	if inst.forget_field_task then
		inst.forget_field_task:Cancel()
		inst.forget_field_task = nil
	end
end

local function GetShockCooldown(inst)
	return (inst:HasTag("character") and SHOCK_COOLDOWNS.CHARACTER
		or inst:HasTag("epic") and SHOCK_COOLDOWNS.EPIC
		or SHOCK_COOLDOWNS.DEFAULT)
		+
		(inst._electrocute_resist or 0)
end

local function UpdateTargets(inst, p1, p2, pv, targets)
	local t = GetTime()
	local nextperiod = SLOW_PERIOD
	for i, x in ipairs(inst.targetx) do
		local z = inst.targetz[i]
		for _, v in ipairs(WagdroneCommon.FindShockTargets(x, z, TARGET_RADIUS)) do
			if (targets[v] or -math.huge) < t and
				v:IsValid() and not v:IsInLimbo()
			then
				pv.x, _, pv.y = v.Transform:GetWorldPosition()
				local range = TARGET_RANGE + math.max(v:GetPhysicsRadius(0), MIN_PHYS_RAD)
				if DistPointToSegmentXYSq(pv, p1, p2) < range * range then
					if not (v.components.health and v.components.health:IsDead()) and
						v.components.combat and inst.components.combat:CanTarget(v)
					then
						if not IsEntityElectricImmune(v) then
							ClearForgetTask(v)

							--TODO MORE WHEN WET?
							if v.panic_electric_field ~= inst then
								v:PushEvent("shocked_by_new_field", inst)

                            	v.panic_electric_field = inst
								v:ListenForEvent("onremove", ObjectNonPermanence, inst) --Just in case?
							end
						
                            v:PushEventImmediate("electrocute", {duration=TUNING.ELECTROCUTE_SHORT_DURATION, noburn=true})

							v.forget_field_task = v:DoTaskInTime(TUNING.ELECTRIC_FIELD_MOB_PANICTIME, ObjectNonPermanence)
						end
					end
					targets[v] = t + GetShockCooldown(v)
				end
			end
			nextperiod = FAST_PERIOD
		end
	end

	if inst.targettask then
		if inst.targettask.period == nextperiod then
			return
		end
		inst.targettask:Cancel()
	end
	local initialperiod = nextperiod ~= FAST_PERIOD and (0.5 + 0.5 * math.random()) * nextperiod or nil
	inst.targettask = inst:DoPeriodicTask(nextperiod, UpdateTargets, initialperiod, p1, p2, pv, targets)
end

local function AddPlane(triangles, x0, y0, z0, x1, y1, z1)
    table.insert(triangles, x0)
    table.insert(triangles, y0)
    table.insert(triangles, z0)

    table.insert(triangles, x0)
    table.insert(triangles, y1)
    table.insert(triangles, z0)

    table.insert(triangles, x1)
    table.insert(triangles, y0)
    table.insert(triangles, z1)

    table.insert(triangles, x1)
    table.insert(triangles, y0)
    table.insert(triangles, z1)

    table.insert(triangles, x0)
    table.insert(triangles, y1)
    table.insert(triangles, z0)

    table.insert(triangles, x1)
    table.insert(triangles, y1)
    table.insert(triangles, z1)
end

local function BuildFenceMesh(halflen, rot)
    local triangles = {}
	local x0, z0 = halflen * math.cos(rot), halflen * -math.sin(rot)
	local x1, z1 = -halflen * math.cos(rot), -halflen * -math.sin(rot)

	AddPlane(triangles, x0, 0, z0, x1, 7, z1)

    return triangles
end

local function RefreshSegs(inst, instant)
	local len = inst.len:value() / 255 * MAX_LEN
	local rot = inst.rot:value() / 255 * 360
	local theta = rot * DEGREES
	local costheta = math.cos(theta)
	local sintheta = math.sin(theta)

	if inst.segs == nil and not TheNet:IsDedicated() then
		inst.segs = {}
		local num = math.max(1, math.floor(len / SEG_LEN + 0.5))
		local scale = len / (num * SEG_LEN)
		local spacing = len / num
		local dx = spacing * costheta
		local dz = -spacing * sintheta
		local dstart = (1 - num) / 2
		local x = dx * dstart
		local z = dz * dstart
		for i = 1, num do
			inst.segs[i] = CreateSegAt(inst, x, z, rot, scale, i == 1 or i == num)
			x = x + dx
			z = z + dz
		end
	end

	inst.Physics:SetTriangleMesh(BuildFenceMesh(len * 0.5, rot * DEGREES))
	inst.Physics:SetActive(false)

	if not TheWorld.ismastersim then
		return
	end

	if not inst.SoundEmitter:PlayingSound("linked_lp") then
	    inst.SoundEmitter:PlaySound("dontstarve/common/together/electric_fence/linked_lp", "linked_lp")
    end

	if inst.targetx == nil then
		inst.targetx = {}
		inst.targetz = {}
		local num = math.floor(len / TARGET_SPACING) + 1
		local dx = TARGET_SPACING * costheta
		local dz = -TARGET_SPACING * sintheta
		local dstart = (1 - num) / 2
		local x, y, z = inst.Transform:GetWorldPosition()
		local x = x + dx * dstart
		local z = z + dz * dstart
		for i = 1, num do
			inst.targetx[i] = x
			inst.targetz[i] = z
			x = x + dx
			z = z + dz
		end
	end

	if inst.targettask then
		if inst.targettask.period == FAST_PERIOD then
			return
		end
		inst.targettask:Cancel()
	end
	local p1 = { x = inst.targetx[1], y = inst.targetz[1] }
	local p2 = { x = inst.targetx[#inst.targetx], y = inst.targetz[#inst.targetz] }
	local pv = {}
	local targets = {}
	inst.targettask = inst:DoPeriodicTask(SLOW_PERIOD, UpdateTargets, instant and 0 or math.random() * 0.3, p1, p2, pv, targets)
	inst.targettask.period = SLOW_PERIOD
end

local function OnEntityWake(inst)
	RefreshSegs(inst, true)
end

local function OnBeamDirty(inst)
	ClearSegs(inst)
	RefreshSegs(inst)
end

local function SetBeam(inst, len, rot)
	inst.len:set_local(0) --force dirty, because we might be calling this when moved
	inst.len:set(math.min(255, math.floor(len / MAX_LEN * 255 + 0.5)))
	inst.rot:set(math.floor((rot < 0 and rot + 360 or rot) / 360 * 255 + 0.5))

	if not inst:IsAsleep() then
		OnBeamDirty(inst)
	end
end

local function KeepTargetFn(inst)--, target)
	return false
end

local function SetUpPhysics(inst)
	inst.entity:AddPhysics()
    inst.Physics:SetMass(0)
    inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
    inst.Physics:SetCollisionMask(
        --COLLISION.ITEMS,
        COLLISION.CHARACTERS,
		COLLISION.FLYERS,
        COLLISION.GIANTS
    )
	inst.Physics:SetActive(false)
	inst.Physics:SetDontRemoveOnSleep(true)
end

local function CanMouseThrough() -- So that we don't block trying to select other entities.
	return true, false
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	SetUpPhysics(inst)
	--
	inst:AddTag("CLASSIFIED")
	inst:AddTag("notarget")

	inst.len = net_byte(inst.GUID, "fence_electric_field.len", "beamdirty")
	inst.rot = net_byte(inst.GUID, "fence_electric_field.rot", "beamdirty")

	inst:SetPrefabNameOverride("fence_electric_field") --for death announce (Omar) NOTE: Can't die but just in case someone changes/mods it to do damage.
	inst.CanMouseThrough = CanMouseThrough

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("beamdirty", OnBeamDirty)

		return inst
	end

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.ELECTRIC_FENCE_DAMAGE)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	inst.components.combat.ignorehitrange = true

	inst.targettask = nil
	inst.SetBeam = SetBeam
	inst.OnEntitySleep = ClearSegs
	inst.OnEntityWake = OnEntityWake

	inst.persists = false

	return inst
end

return Prefab("fence_electric_field", fn, assets)
