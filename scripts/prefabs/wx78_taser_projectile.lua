local assets =
{
	Asset("ANIM", "anim/wx78_taser_blast_fx.zip"),
}

local easing = require("easing")

local function FxPostUpdate(fx)
	fx.AnimState:SetFrame(fx.entity:GetParent().AnimState:GetCurrentAnimationFrame())
	-- It's generally NOT OK to modify updatelooper during PostUpdate loop,
	--  but we'll do it here because we know that nothing external should be
	--  affecting or interacting with this client fx entity.
	fx:RemoveComponent("updatelooper")
end

local CIRCLE_RADIUS_SCALE = 650 / 150 / 2 -- Source art size / anim_scale / 2 (halved to get radius).

local function OnShowBase(inst, radius)
	if not inst.showbase:value() then
		return
	end

	radius = radius or inst.baseradius:value()

	local fx = CreateEntity()

	--[[Non-networked entity]]
	--fx.entity:SetCanSleep(false)
	fx.persists = false

	fx.entity:AddTransform()
	fx.entity:AddAnimState()

	fx:AddTag("FX")
	fx:AddTag("NOCLICK")

	fx.AnimState:SetBank("wx78_taser_blast_fx")
	fx.AnimState:SetBuild("wx78_taser_blast_fx")
	fx.AnimState:PlayAnimation("crackle_projection")
	fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	fx.AnimState:SetLightOverride(1)
	fx.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	fx.AnimState:SetLayer(LAYER_BACKGROUND)
	fx.AnimState:SetSortOrder(3)

	fx.entity:SetParent(inst.entity)
	fx:ListenForEvent("animover", fx.Remove)

	local scale = radius / CIRCLE_RADIUS_SCALE
	fx.AnimState:SetScale(scale, scale)

	if not TheWorld.ismastersim then
		if inst.AnimState:IsCurrentAnimation("crackle_hit") then
			fx.AnimState:SetFrame(inst.AnimState:GetCurrentAnimationFrame())
		else
			fx:AddComponent("updatelooper")
			fx.components.updatelooper:AddPostUpdateFn(FxPostUpdate)
		end
	end
end

local function DisableHits(inst, OnUpdate)
	inst.showbase:set_local(false)
	inst.components.updatelooper:RemoveOnUpdateFn(OnUpdate)
end

local PADDING = 3
local COMBAT_TAGS = { "_combat", "_health" }
local CANT_TAGS = { "INLIMBO", "notarget", "noattack", "wall", "playerghost"  }
local HIT_DURATION = 18 * FRAMES

local function OnUpdate(inst, dt)
	local x, y, z = inst.Transform:GetWorldPosition()

	if dt > 0 then
		inst.fadet = inst.fadet + dt
		inst.fadeflicker = (inst.fadeflicker + 1) % 4
	end

	local radius = inst.radius
	for i, v in ipairs(TheSim:FindEntities(x, y, z, radius + PADDING, COMBAT_TAGS, CANT_TAGS)) do
		if inst.targets[v] == nil and
			v:IsValid() and not v:IsInLimbo() and
			not (v.components.health and v.components.health:IsDead())
		then
			local range = radius + v:GetPhysicsRadius(0)
			if v:GetDistanceSqToPoint(x, 0, z) < range * range then
                if inst.owner ~= nil and not inst.owner:IsValid() then
                    inst.owner = nil
                end

				local damage_mult = IsEntityElectricImmune(v) and 1
                    or TUNING.ELECTRIC_DAMAGE_MULT + TUNING.ELECTRIC_WET_DAMAGE_MULT * v:GetWetMultiplier()
				local damage = inst.damage * damage_mult

				if inst.owner ~= nil then
					if inst.owner.components.combat ~= nil and
						inst.owner.components.combat:CanTarget(v) and
						not inst.owner.components.combat:IsAlly(v)
					then
                        inst.targets[v] = true
						local attacker = v.components.follower and v.components.follower:GetLeader() == nil and inst
							or inst.owner
						v.components.combat:GetAttacked(attacker, damage, nil, "electric", inst.spdmg)
						v:PushEventImmediate("electrocute", { attacker = attacker, stimuli = "electric", noresist = true })
                    end
				elseif v.components.combat:CanBeAttacked() then
					-- NOTES: inst.owner is nil here so this is for non worn things like the bramble trap.
					local isally = false
					if not inst.canhitplayers then
						--non-pvp, so don't hit any player followers (unless they are targeting a player!)
						local leader = v.components.follower ~= nil and v.components.follower:GetLeader() or nil
						isally = leader ~= nil and leader.isplayer and
							not (v.components.combat ~= nil and
								v.components.combat.target ~= nil and
								v.components.combat.target.isplayer)
					end
					if not isally then
						inst.targets[v] = true
						v.components.combat:GetAttacked(inst, damage, nil, "electric", inst.spdmg)
						v:PushEventImmediate("electrocute", { stimuli = "electric", noresist = true })
					end
				end
			end
		end
	end
end

local function Flash_OnUpdate(inst, dt)
	local delta = dt
	if inst.flash > delta then
		inst.flash = inst.flash - delta
		if dt > 0 then
			inst.blink = (inst.blink % 4) + 1
		end
		local c = math.min(1, inst.flash * (inst.blink > 2 and 0.6 or 2))
		inst.owner.components.colouradder:PushColour(inst, c, c, c / 2, 0)
	else
		inst.flash = 0
		inst.owner.components.colouradder:PopColour(inst)
		inst.components.updatelooper:RemoveOnUpdateFn(Flash_OnUpdate)
	end
end

local function Explode(inst, damage, radius, spdmg)
	inst:Show()
	inst.hidden = false
	local x, y, z = inst.entity:GetParent().Transform:GetWorldPosition()
	inst.entity:SetParent(nil)
	inst.Transform:SetPosition(x, y, z)

	if inst.play_pst_task ~= nil then
		inst.play_pst_task:Cancel()
		inst.play_pst_task = nil
	end

	local scale = radius / CIRCLE_RADIUS_SCALE
	inst.AnimState:SetScale(scale, scale)

	inst.components.updatelooper:AddOnUpdateFn(OnUpdate)
	inst.SoundEmitter:KillSound("charging")
	inst.SoundEmitter:PlaySound("rifts5/wagdrone_flying/electro_ball_explode")
	--
	inst.damage = damage
	inst.radius = radius
	inst.spdmg = spdmg
	inst.AnimState:PlayAnimation("crackle_hit")
	inst:DoTaskInTime(HIT_DURATION, DisableHits, OnUpdate)
	inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, inst.Remove)
	inst.showbase:set(true)
	inst.baseradius:set(radius)
	if not TheNet:IsDedicated() then
		OnShowBase(inst, radius)
	end
	-- inst.targets = {}
	inst.fadet = 0
	inst.fadeflicker = 0
end

local function SetFXOwner(inst, owner)
	inst.entity:SetParent(owner.entity)
	inst.owner = owner
    inst.canhitplayers = not owner:HasTag("player") or TheNet:GetPVPEnabled()
    inst.targets[owner] = true
	-- inst.SoundEmitter:PlaySound("rifts5/wagdrone_rolling/beamlp_a", "charging")
end

local function OnAnimOver(inst)
	if inst.AnimState:IsCurrentAnimation("shock_fx_high_pst") or
		inst.AnimState:IsCurrentAnimation("shock_fx_med_pst") or
		inst.AnimState:IsCurrentAnimation("shock_fx_low_pst")
	then
		inst:Hide()
		inst.hidden = true
	end
end

local function PlayPst(inst, anim)
	inst.AnimState:PlayAnimation(anim.."_pst")
	inst.play_pst_task = nil
end

local function GetShockAnim(builduppercent)
	return builduppercent >= 0.75 and "shock_fx_high"
		or builduppercent >= 0.50 and "shock_fx_med"
		or "shock_fx_low"
end

local function DoFlash(inst, duration, percent)
	local owner = inst.owner
	if not owner then
		return
	end

	local anim = GetShockAnim(percent)

	if not inst.AnimState:IsCurrentAnimation(anim) then
		inst.AnimState:PlayAnimation(anim, true)
		inst.AnimState:SetScale(math.random() < 0.5 and -1 or 1, 1)
	elseif inst.hidden then
		inst.AnimState:SetScale(math.random() < 0.5 and -1 or 1, 1)
	end

	inst.percent = percent

	inst:Show()
	inst.hidden = false

	inst.duration = duration or TUNING.ELECTROCUTE_DEFAULT_DURATION

	if inst.play_pst_task ~= nil then
		inst.play_pst_task:Cancel()
		inst.play_pst_task = nil
	end
	inst.play_pst_task = inst:DoTaskInTime(math.max(0, inst.duration - 0.1 + math.random() * 0.2), PlayPst, anim)
	inst.SoundEmitter:PlaySound("dontstarve/common/together/electricity/electrocute_med_longer")

	if owner.components.colouradder == nil then
		owner:AddComponent("colouradder")
	end

	local add_update = inst.flash == 0
	inst.flash = inst.duration + math.random() * 0.4
	inst.blink = math.random(4)

	if add_update then
		inst.components.updatelooper:AddOnUpdateFn(Flash_OnUpdate)
	end
	Flash_OnUpdate(inst, 0)
end

local function KeepTargetFn(inst)--, target)
	return false
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBuild("wx78_taser_blast_fx")
	inst.AnimState:SetBank("wx78_taser_blast_fx")
	inst.AnimState:PlayAnimation("shock_fx_low", true)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetLightOverride(1)
	inst.AnimState:SetFinalOffset(1)

	inst.showbase = net_bool(inst.GUID, "wx78_taser_projectile_fx.showbase", "showbasedirty")
	inst.baseradius = net_float(inst.GUID, "wx78_taser_projectile_fx.baseradius")

	inst:SetPrefabNameOverride("wx78") --for death announce

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")
	inst:AddTag("notarget")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("showbasedirty", OnShowBase)
		return inst
	end

	inst:Hide()
	inst.hidden = true

	inst:AddComponent("updatelooper")

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.SKILLS.WX78.TASER_BUILDUP_DAMAGE)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	inst.components.combat.ignorehitrange = true

	inst.SetFXOwner = SetFXOwner
	inst.DoFlash = DoFlash
	inst.Explode = Explode

	inst:ListenForEvent("animover", OnAnimOver)

	inst.flash = 0
	inst.persists = false
	inst.targets = {}
	inst.canhitplayers = true

	return inst
end

return Prefab("wx78_taser_projectile_fx", fn, assets)