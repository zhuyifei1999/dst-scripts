require "prefabutil"

local assets =
{
    Asset("ANIM", "anim/ui_chest_3x2.zip"),
    Asset("ANIM", "anim/sacred_chest.zip"),
}

local prefabs =
{
	"statue_transition",
	"statue_transition_2",
}

local MIN_LOCK_TIME = 2.5

local function UnlockChest(inst, param, doer)
	inst:DoTaskInTime(math.max(0, MIN_LOCK_TIME - (GetTime() - inst.lockstarttime)), function()
	    inst.SoundEmitter:KillSound("loop")

		if param == 1 then
			inst.AnimState:PushAnimation("closed", false)
			inst.components.container.canbeopened = true
			if doer ~= nil and doer:IsValid() and doer.components.talker ~= nil then
				doer.components.talker:Say(GetString(doer, "ANNOUNCE_SACREDCHEST_NO"))
			end
		elseif param == 3 then
			inst.AnimState:PlayAnimation("open") 
		    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
			SpawnPrefab("statue_transition").Transform:SetPosition(inst.Transform:GetWorldPosition())
			SpawnPrefab("statue_transition_2").Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst:DoTaskInTime(0.75, function()
				inst.AnimState:PlayAnimation("close")
			    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
				inst.components.container.canbeopened = true

				if doer ~= nil and doer:IsValid() and doer.components.talker ~= nil then
					doer.components.talker:Say(GetString(doer, "ANNOUNCE_SACREDCHEST_YES"))
				end
				TheNet:Announce(STRINGS.UI.HUD.REPORT_RESULT_ANNOUCEMENT)
			end)
		else
			inst.AnimState:PlayAnimation("open") 
		    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
			inst:DoTaskInTime(.2, function() 
				inst.components.container:DropEverything() 
				inst:DoTaskInTime(0.2, function()
					inst.AnimState:PlayAnimation("close")
				    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
					inst.components.container.canbeopened = true

					if doer ~= nil and doer:IsValid() and doer.components.talker ~= nil then
						doer.components.talker:Say(GetString(doer, "ANNOUNCE_SACREDCHEST_NO"))
					end
				end)
			end)
		end
	end)

	if param == 3 then
		inst.components.container:DestroyContents()
	end
end

local function LockChest(inst)
	inst.components.container.canbeopened = false
	inst.lockstarttime = GetTime()
	inst.AnimState:PlayAnimation("hit", true)
    inst.SoundEmitter:PlaySound("dontstarve/common/together/sacred_chest/shake_LP", "loop")
end 

local function onopen(inst) 
    inst.AnimState:PlayAnimation("open")
    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
end 

local function onclose(inst, doer)
    inst.AnimState:PlayAnimation("close")

	if (not TheNet:IsOnlineMode()) or
		(not inst.components.container:IsFull()) or
		doer == nil or 
		not doer:IsValid() then
	    inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
		return
	end

	LockChest(inst)

	local x, y, z = inst.Transform:GetWorldPosition()
	local players = FindPlayersInRange(x, y, z, 40)
	if #players <= 1 then
		UnlockChest(inst, 2, doer)
		return
	end

	local items = {}
	local counts = {}
	for i, k in ipairs(inst.components.container.slots) do
		if k ~= nil then
			table.insert(items, k.prefab)
			table.insert(counts, k.components.stackable ~= nil and k.components.stackable:StackSize() or 1)
		end
    end

	local userids = {}
	for i,p in ipairs(players) do
		if p ~= doer and p.userid then
			table.insert(userids, p.userid)
		end
	end

	ReportAction(doer.userid, items, counts, userids, function(param) if inst:IsValid() then UnlockChest(inst, param, doer) end end)
end

local function getstatus(inst)
    return (inst.components.container.canbeopened == false and "LOCKED") or
			nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("sacred_chest.png")

    inst:AddTag("chest")
    inst.AnimState:SetBank("sacred_chest")
    inst.AnimState:SetBuild("sacred_chest")
    inst.AnimState:PlayAnimation("closed")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
	inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("sacred_chest")
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose
		
    inst:AddComponent("hauntable")
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_SMALL

    return inst
end

return Prefab("sacred_chest", fn, assets, prefabs)
