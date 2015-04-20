--[[
    Prefabs for 3 different mushtrees
--]]

local prefabs =
{
	"log",
	"blue_cap",
    "charcoal",
	"ash",
}

local function onburntanimover(inst)
    inst.components.lootdropper:SpawnLootPrefab("ash")
    if math.random() < 0.5 then
        inst.components.lootdropper:SpawnLootPrefab("charcoal")
    end
    inst:Remove()
end

local function tree_burnt(inst)
	inst.persists = false
	inst.AnimState:PlayAnimation("chop_burnt")
	inst.SoundEmitter:PlaySound("dontstarve/forest/treeCrumble")          
	inst:ListenForEvent("animover", onburntanimover)
end

local function stump_burnt(inst)
	inst.components.lootdropper:SpawnLootPrefab("ash") 
	inst:Remove() 	
end

local function dig_up_stump(inst)
	inst.components.lootdropper:SpawnLootPrefab("log")
	inst:Remove()
end

local function inspect_tree(inst)
    if inst:HasTag("burnt") then
        return "BURNT"
    elseif inst:HasTag("stump") then
        return "CHOPPED"
    end
end

local function makestump(inst)
    inst:RemoveComponent("burnable")
    inst:RemoveComponent("propagator")
    inst:RemoveComponent("workable")
	RemovePhysicsColliders(inst) 
	inst:AddTag("stump")
	MakeSmallPropagator(inst)
	MakeSmallBurnable(inst)
	inst.components.burnable:SetOnBurntFn(stump_burnt)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up_stump)
	inst.components.workable:SetWorkLeft(1)
	inst.AnimState:PlayAnimation("idle_stump")
	inst.AnimState:ClearBloomEffectHandle()

	inst.Light:Enable(false)
end

local function workcallback(inst, worker, workleft)
    if not worker or (worker and not worker:HasTag("playerghost")) then
        inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_mushroom")     
    end     
	if workleft <= 0 then
		inst.SoundEmitter:PlaySound("dontstarve/forest/treefall")
		makestump(inst)
	    
        inst.AnimState:PlayAnimation("fall")

		inst.components.lootdropper:DropLoot(inst:GetPosition())
		inst.AnimState:PushAnimation("idle_stump")

	else			
		inst.AnimState:PlayAnimation("chop")
		inst.AnimState:PushAnimation("idle_loop", true)
	end
end

local data =
{
    small = {
        bank = "mushroom_tree_small",
        build = "mushroom_tree_small",
        icon = "mushroom_tree_small.png",
        loot = {"log", "green_cap"},
        work = TUNING.MUSHTREE_CHOPS_SMALL,
        lightradius = 1.0,
        lightcolour = {146/255, 225/255, 146/255},
    },
    medium = {
        bank = "mushroom_tree_med",
        build = "mushroom_tree_med",
        icon = "mushroom_tree_med.png",
        loot = {"log", "red_cap"},
        work = TUNING.MUSHTREE_CHOPS_MEDIUM,
        lightradius = 1.25,
        lightcolour = {197/255, 126/255, 126/255},
    },
    tall = {
        bank = "mushroom_tree",
        build = "mushroom_tree_tall",
        icon = "mushroom_tree.png",
        loot = {"log", "log", "blue_cap"},
        work = TUNING.MUSHTREE_CHOPS_TALL,
        lightradius = 1.5,
        lightcolour = {111/255, 111/255, 227/255},
    },
}

local function onsave(inst, data)
    if inst:HasTag("burnt") or inst:HasTag("fire") then
        data.burnt = true
    end

    if inst:HasTag("stump") then
        data.stump = true
    end
end

local function onload(inst, data)
    if data then

        if data.burnt then
            if data.stump then
            	stump_burnt(inst)
            else
            	tree_burnt(inst)
            end
        elseif data.stump then
        	makestump(inst)
        end
    end
end        

local function maketree(data)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddMiniMapEntity()
        inst.entity:AddLight()
        inst.entity:AddNetwork()

        MakeObstaclePhysics(inst, 1)

        if not TheWorld.ismastersim then
            return inst
        end

        MakeMediumPropagator(inst)
        MakeLargeBurnable(inst)
        inst.components.burnable:SetFXLevel(5)
        inst.components.burnable:SetOnBurntFn(tree_burnt)

        inst.MiniMapEntity:SetIcon(data.icon)

        inst.AnimState:SetBuild(data.build)
        inst.AnimState:SetBank(data.bank)
        inst.AnimState:PlayAnimation("idle_loop", true)
        inst.AnimState:SetTime(math.random() * 2)

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot(data.loot)

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = inspect_tree

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.CHOP)
        inst.components.workable:SetWorkLeft(data.chops)
        inst.components.workable:SetOnWorkCallback(workcallback)

        inst:AddComponent("transformer")

        --inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

        inst.Light:SetFalloff(0.5)
        inst.Light:SetIntensity(.8)
        inst.Light:SetRadius(data.lightradius)
        inst.Light:SetColour(unpack(data.lightcolour))
        inst.Light:Enable(true)

        inst.OnSave = onsave
        inst.OnLoad = onload
        return inst
    end
    return fn
end

return Prefab("cave/objects/mushtree_tall", maketree(data.tall), { Asset("ANIM", "anim/mushroom_tree_tall.zip") }, prefabs),
       Prefab("cave/objects/mushtree_medium", maketree(data.medium), { Asset("ANIM", "anim/mushroom_tree_med.zip") }, prefabs),
       Prefab("cave/objects/mushtree_small", maketree(data.small), { Asset("ANIM", "anim/mushroom_tree_small.zip") }, prefabs)
