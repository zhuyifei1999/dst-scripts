local assets =
{
	Asset("ANIM", "anim/wagboss_lunar.zip"),
}

local prefabs =
{
	"lunar_seed",
}

local brain = require("brains/alterguardian_phase4_lunarriftbrain")

local TRANSPARENCY = 0.2

--------------------------------------------------------------------------
--Client follow symbol functions

local function AddFollowFx(inst, anim, symbol, frame, alpha, usefacings)
	local fx = CreateEntity()

	fx:AddTag("FX")
	--[[Non-networked entity]]
	--inst.entity:SetCanSleep(false)
	fx.persists = false

	fx.entity:AddTransform()
	fx.entity:AddAnimState()
	fx.entity:AddFollower()

	if usefacings then
		fx.Transform:SetFourFaced()
	end

	fx.AnimState:SetBank("wagboss_lunar")
	fx.AnimState:SetBuild("wagboss_lunar")

	if frame then
		--V2C: -not bothering with AnimState:SetPercent's weird math under the hood.
		--     -it's safe enough to use Pause(), just be mindful of that conflicting with RemoveFromScene/ReturnToScene.
		fx.AnimState:PlayAnimation(anim)
		fx.AnimState:SetFrame(frame - 1)
		fx.AnimState:Pause()
		fx.Follower:FollowSymbol(inst.GUID, symbol, nil, nil, nil, true, nil, frame - 1)
	else
		fx.AnimState:PlayAnimation(anim, true)
		fx.AnimState:SetFrame(math.random(fx.AnimState:GetCurrentAnimationNumFrames()) - 1)
		fx.Follower:FollowSymbol(inst.GUID, symbol, nil, nil, nil, true)
	end

	if alpha then
		fx.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
		fx.AnimState:SetMultColour(1, 1, 1, alpha)
	end

	fx.entity:SetParent(inst.entity)

	table.insert(inst.followfx, fx)
	table.insert(inst.highlightchildren, fx)
end

local function OnAddColourChanged(inst, r, g, b, a)
	for i, v in ipairs(inst.followfx) do
		v.AnimState:SetAddColour(r, g, b, a)
	end
end

--------------------------------------------------------------------------

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.Transform:SetFourFaced()

	inst.AnimState:SetBank("wagboss_lunar")
	inst.AnimState:SetBuild("wagboss_lunar")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetMultColour(1, 1, 1, TRANSPARENCY)
	inst.AnimState:UsePointFiltering(true)

	MakeGiantCharacterPhysics(inst, 1000, 2)

	inst:AddTag("brightmareboss")
	inst:AddTag("epic")
	inst:AddTag("hostile")
	inst:AddTag("largecreature")
	inst:AddTag("mech")
	inst:AddTag("monster")
	inst:AddTag("noepicmusic")
	inst:AddTag("scarytoprey")
	inst:AddTag("soulless")
	inst:AddTag("lunar_aligned")

	inst:AddComponent("colouraddersync")

	--Dedicated server does not need to spawn the local fx
	if not TheNet:IsDedicated() then
		inst.followfx = {}
		inst.highlightchildren = {}

		--body wires and floating bits (solid)
		AddFollowFx(inst, "wire_loop", "lb_wire_follow", nil, nil, false)
		AddFollowFx(inst, "float_fr_loop", "lb_float_fr_follow", nil, nil, true)
		AddFollowFx(inst, "float_bk_loop", "lb_float_bk_follow", nil, nil, true)

		--leg wires (solid)
		for i = 1, 2 do
			AddFollowFx(inst, "leg_wire", "lb_leg_wire_follow", i, nil, false)
		end
		for i = 1, 2 do
			AddFollowFx(inst, "feet_wire", "lb_feet_wire_follow", i, nil, false)
		end

		--body transparent parts
		for i = 1, 4 do
			AddFollowFx(inst, "body_loop", "lb_head_loop_follow_"..tostring(i), nil, TRANSPARENCY, false)
		end
		for i = 1, 3 do
			AddFollowFx(inst, "flame_loop", "lb_flame_loop_follow_"..tostring(i), nil, TRANSPARENCY, false)
		end

		inst.components.colouraddersync:SetColourChangedFn(OnAddColourChanged)
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("inspectable")

	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = TUNING.ALTERGUARDIAN_PHASE4_LUNARRIFT_WALKSPEED

	inst:AddComponent("colouradder")

	inst:SetStateGraph("SGalterguardian_phase4_lunarrift")
	inst:SetBrain(brain)

	return inst
end

return Prefab("alterguardian_phase4_lunarrift", fn, assets, prefabs)
