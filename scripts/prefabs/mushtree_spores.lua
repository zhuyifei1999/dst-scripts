local assets =
{
    Asset("ANIM", "anim/mushroom_spore.zip"),
    Asset("ANIM", "anim/mushroom_spore_red.zip"),
    Asset("ANIM", "anim/mushroom_spore_blue.zip"),
}

local data =
{
    small =
    { --Green
        build = "mushroom_spore",
        lightcolour = {146/255, 225/255, 146/255},
    },
    medium =
    { --Red
        build = "mushroom_spore_red",
        lightcolour = {197/255, 126/255, 126/255},
    },
    tall =
    { --Blue
        build = "mushroom_spore_blue",
        lightcolour = {111/255, 111/255, 227/255},
    },
}

local brain = require "brains/sporebrain"

local function depleted(inst)
    if inst:IsInLimbo() then
        inst:Remove()
    else
        inst.components.workable:SetWorkable(false)
        inst:PushEvent("death")
        inst.persists = false
        -- clean up when offscreen, because the death event is handled by the SG
        inst:DoTaskInTime(3, inst.Remove)
    end
end

local function onpickup(inst)
    --These last longer when held
    inst.components.perishable:SetNewMaxPerishTime(TUNING.PERISH_SLOW)
end

local function ondropped(inst)
    --Disappears faster when floating
    inst.components.perishable:SetNewMaxPerishTime(TUNING.SEG_TIME * 3)

    if inst.components.workable ~= nil then
        inst.components.workable:SetWorkLeft(1)
    end

    if inst.components.stackable ~= nil then
        while inst.components.stackable:StackSize() > 1 do
            local item = inst.components.stackable:Get()
            if item ~= nil then
                if item.components.inventoryitem ~= nil then
                    item.components.inventoryitem:OnDropped()
                end
                item.Physics:Teleport(inst.Transform:GetWorldPosition())
            end
        end
    end
end

local function onload(inst)
    -- If we loaded, then just turn the light on
    inst.Light:Enable(true)
    inst.DynamicShadow:Enable(true)
end

local function makespore(data)

    local function onworked(inst, worker)
        if worker.components.inventory ~= nil then
            worker.components.inventory:GiveItem(inst, nil, inst:GetPosition())
            worker.SoundEmitter:PlaySound("dontstarve/common/butterfly_trap")
        end
    end

	local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
    	inst.entity:AddDynamicShadow()
        inst.entity:AddLight()
        inst.entity:AddNetwork()

    	MakeCharacterPhysics(inst, 1, .5)

        inst.AnimState:SetBuild(data.build)
        inst.AnimState:SetBank("mushroom_spore")
        inst.AnimState:PlayAnimation("flight_cycle", true)

        inst.DynamicShadow:Enable(false)

	    inst.Light:SetColour(unpack(data.lightcolour))
	    inst.Light:SetIntensity(0.75)
	    inst.Light:SetFalloff(0.5)
	    inst.Light:SetRadius(2)
	    inst.Light:Enable(false)

	    inst.DynamicShadow:SetSize(.8, .5)

        inst:AddTag("show_spoilage")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")

        inst:AddComponent("knownlocations")

	    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
	    inst.components.locomotor:SetTriggersCreep(false)
	    inst.components.locomotor.walkspeed = 2

        inst:AddComponent("inventoryitem")

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.NET)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(onworked)

        inst:AddComponent("perishable")
        inst.components.perishable:SetPerishTime(TUNING.SEG_TIME * 3)
        inst.components.perishable:StartPerishing()
        inst.components.perishable:SetOnPerishFn(depleted)

        inst:AddComponent("stackable")

        inst:AddComponent("burnable")
        inst.components.burnable:SetFXLevel(1)
        inst.components.burnable:SetBurnTime(1)
        inst.components.burnable:AddBurnFX("fire", Vector3(0, 0, 0), "spore")
        inst.components.burnable:SetOnIgniteFn(DefaultBurnFn)
        inst.components.burnable:SetOnBurntFn(DefaultBurntFn)
        inst.components.burnable:SetOnExtinguishFn(DefaultExtinguishFn)

        inst:AddComponent("propagator")
        inst.components.propagator.acceptsheat = true
        inst.components.propagator:SetOnFlashPoint(DefaultIgniteFn)
        inst.components.propagator.flashpoint = 1
        inst.components.propagator.decayrate = 0.5
        inst.components.propagator.damages = false

        inst:ListenForEvent("onpickup", onpickup)
        inst:ListenForEvent("ondropped", ondropped)

	    inst:SetStateGraph("SGspore")
	    inst:SetBrain(brain)

        inst.OnLoad = onload

        return inst
	end

	return fn
end

return Prefab("cave/objects/spore_tall", makespore(data.tall), assets),
    Prefab("cave/objects/spore_medium", makespore(data.medium), assets),
    Prefab("cave/objects/spore_small", makespore(data.small), assets)
