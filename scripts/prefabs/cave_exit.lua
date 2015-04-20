local PopupDialogScreen = require "screens/popupdialog"

local assets =
{
    Asset("ANIM", "anim/cave_exit_rope.zip"),
}

local function GetVerb()
    return STRINGS.ACTIONS.ACTIVATE.CLIMB
end

local function onnear(inst)
    inst.AnimState:PlayAnimation("down")
    inst.AnimState:PushAnimation("idle_loop", true)
    inst.SoundEmitter:PlaySound("dontstarve/cave/rope_down")
end

local function onfar(inst)
    inst.AnimState:PlayAnimation("up")
    inst.SoundEmitter:PlaySound("dontstarve/cave/rope_up")
end

local function OnActivate(inst)
	SetPause(true)
	local level = TheWorld.topology.level_number or 1
	local function head_upwards()
		SaveGameIndex:GetSaveFollowers(GetPlayer())

		local function onsaved()
		    SetPause(false)
		    StartNextInstance({reset_action=RESET_ACTION.LOAD_SLOT, save_slot = SaveGameIndex:GetCurrentSaveSlot()}, true)
		end

		local cave_num =  SaveGameIndex:GetCurrentCaveNum()
		if level == 1 then
			SaveGameIndex:SaveCurrent(function() SaveGameIndex:LeaveCave(onsaved) end, false, "ascend", cave_num)
		else
			-- Ascend
			local level = level - 1
			
			SaveGameIndex:SaveCurrent(function() SaveGameIndex:EnterCave(onsaved,nil, cave_num, level) end, false, "ascend", cave_num)
		end
	end
	ThePlayer.HUD:Hide()
	TheFrontEnd:Fade(false, 2, head_upwards)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter() 
    inst.entity:AddMiniMapEntity()

    --V2C: WARNING:
    --This is not supported for DST, so there is no network
    --component added yet! It just spawns it locally on the
    --server and then removes it on the next frame.
    inst.entity:Hide()
    inst:DoTaskInTime(0, inst.Remove)
    --

    inst.MiniMapEntity:SetIcon("cave_open2.png")

    inst.AnimState:SetBank("exitrope")
    inst.AnimState:SetBuild("cave_exit_rope")

    inst.GetActivateVerb = GetVerb

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(5,7)
    inst.components.playerprox:SetOnPlayerFar(onfar)
    inst.components.playerprox:SetOnPlayerNear(onnear)

    inst:AddComponent("inspectable")

    inst:AddComponent("activatable")
    inst.components.activatable.OnActivate = OnActivate
    inst.components.activatable.inactive = true
    inst.components.activatable.quickaction = true

    return inst
end

return Prefab("common/cave_exit", fn, assets)