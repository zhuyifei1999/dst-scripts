require("stategraphs/commonstates")
local SGWX78Common = require("stategraphs/SGwx78_common")
local WX78Common = require("prefabs/wx78_common")

local function GetIceStaffProjectileSound(inst, equip)
    if equip.icestaff_coldness then
        if equip.icestaff_coldness > 2 then
            return "dontstarve/wilson/attack_deepfreezestaff_lvl2"
        elseif equip.icestaff_coldness > 1 then
            return "dontstarve/wilson/attack_deepfreezestaff"
        end
    end
    return "dontstarve/wilson/attack_icestaff"
end

local function DropAllItemsForDeath(inst)
    inst.components.inventory:DropEverything(true)
    if inst.components.socketholder then
        local items = inst.components.socketholder:UnsocketEverything()
        for _, item in ipairs(items) do
            Launch2(item, inst, 1, 1, 0.2, 0, 4)
        end
    end
end

local function GetLeader(inst)
    return inst.components.follower ~= nil and inst.components.follower:GetLeader() or nil
end

local function GetLeaderAction(inst)
	local target
    local act = inst:GetBufferedAction() or inst.sg.statemem.action
	if act then
		target = act.target
		act = act.action
    elseif inst.sg:HasStateTag("spinning") and inst._lastspintime and GetTime() - inst._lastspintime < 1 then
        act, target = inst._lastspinaction, inst._lastspintarget
	elseif inst.components.playercontroller then
		act, target = inst.components.playercontroller:GetRemoteInteraction()
	end

    return act, target
end

local function TryRepeatAction(inst, buffaction, right)
    local leader = GetLeader(inst)
    if not leader then
        return
    end

    local leaderact, leadertarget = GetLeaderAction(leader)
	if buffaction ~= nil and
		buffaction:IsValid() and
		buffaction.target ~= nil and
		buffaction.target.components.workable ~= nil and
		buffaction.target.components.workable:CanBeWorked() and
		buffaction.target:IsActionValid(buffaction.action, right)
		then

        if leaderact == buffaction.action and leadertarget == buffaction.target then
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            inst:PushBufferedAction(buffaction)
            return true
        end
    end

	return false
end

local function GetUnequipState(inst, data)
    return (inst:HasTag("wereplayer") and "item_in")
        or (data.eslot ~= EQUIPSLOTS.HANDS and "item_hat")
        or (not data.slip and "item_in")
        or (data.item ~= nil and data.item:IsValid() and "tool_slip")
        or "toolbroke"
        , data.item
end

local function ConfigureRunState(inst)
    inst.sg.statemem.normal = true -- stub if we want to change run state
end

local function DoEquipmentFoleySounds(inst)
    for k, v in pairs(inst.components.inventory.equipslots) do
        if v.foleysound ~= nil then
            inst.SoundEmitter:PlaySound(v.foleysound, nil, nil, true)
        end
    end
end

local function DoFoleySounds(inst)
    DoEquipmentFoleySounds(inst)
	if inst.foleyoverridefn and inst:foleyoverridefn(nil, true) then
		return
	elseif inst.foleysound then
        inst.SoundEmitter:PlaySound(inst.foleysound, nil, nil, true)
    end
end

local DoRunSounds = function(inst)
    if inst.sg.mem.footsteps > 3 then
        PlayFootstep(inst, .6, true)
    else
        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
        PlayFootstep(inst, 1, true)
    end
end

local function DoHurtSound(inst)
    if inst.hurtsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride, nil, inst.hurtsoundvolume)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/hurt", nil, inst.hurtsoundvolume)
    end
end

local function DoEatSound(inst, overrideexisting)
    if inst.sg.statemem.doeatingsfx and (overrideexisting or not inst.SoundEmitter:PlayingSound("eating")) then
        inst.SoundEmitter:PlaySound(inst.sg.statemem.isdrink and "dontstarve/wilson/sip" or "dontstarve/wilson/eat", "eating")
    end
end

local function TryReturnItemToFeeder(inst)
	local feed = inst.sg.statemem.feed
	if feed and not feed.persists and feed:IsValid() and feed.components.inventoryitem then
		--restore config from ACTIONS.FEEDPLAYER that assumes item is deleted when eaten
		inst:RemoveChild(feed)
		if feed:IsInLimbo() then
			feed:ReturnToScene()
		end
		feed.components.inventoryitem:WakeLivingItem()
		feed.persists = true
		--
		local range = TUNING.RETURN_ITEM_TO_FEEDER_RANGE
		local feeder = inst.sg.statemem.feeder
		local pos = inst:GetPosition()
		if feeder and feeder:IsValid() and
			feeder.components.inventory and
			feeder.components.inventory.isopen and
			feeder:GetDistanceSqToPoint(pos) < range * range
		then
			if inst.sg.statemem.feedwasactiveitem and
				feeder.components.inventory:GetActiveItem() == nil and
				feeder.components.inventory.isvisible
			then
				feeder.components.inventory:GiveActiveItem(feed)
			else
				feeder.components.inventory:GiveItem(feed, nil, pos)
			end
		else
			inst.components.inventory:GiveItem(feed, nil, pos)
		end
	end
end

local actionhandlers =
{
    ActionHandler(ACTIONS.CHOP,
        function(inst)
            if inst.GetModuleTypeCount and inst:GetModuleTypeCount("spin") > 0 then
				return not inst.sg:HasStateTag("prespin")
					and (inst.sg:HasStateTag("spinning") and
						"wx_spin" or
						"wx_spin_start")
					or nil
            end
            return not inst.sg:HasStateTag("prechop")
                and (inst.sg:HasStateTag("chopping") and
                    "chop" or
                    "chop_start")
                or nil
        end),
    ActionHandler(ACTIONS.MINE,
        function(inst)
			if inst.GetModuleTypeCount and inst:GetModuleTypeCount("spin") > 0 then
				return not inst.sg:HasStateTag("prespin")
					and (inst.sg:HasStateTag("spinning") and
						"wx_spin" or
						"wx_spin_start")
					or nil
			end
            return not inst.sg:HasStateTag("premine")
                and (inst.sg:HasStateTag("mining") and
                    "mine" or
                    "mine_start")
                or nil
        end),
    ActionHandler(ACTIONS.HAMMER,
        function(inst)
            return not inst.sg:HasStateTag("prehammer")
                and (inst.sg:HasStateTag("hammering") and
                    "hammer" or
                    "hammer_start")
                or nil
        end),
    ActionHandler(ACTIONS.REMOVELUNARBUILDUP, -- Copy of ACTIONS.MINE
        function(inst)
			if inst.GetModuleTypeCount and inst:GetModuleTypeCount("spin") > 0 then
				return not inst.sg:HasStateTag("prespin")
					and (inst.sg:HasStateTag("spinning") and
						"wx_spin" or
						"wx_spin_start")
					or nil
			end
            return not inst.sg:HasStateTag("premine")
                and (inst.sg:HasStateTag("mining") and
                    "mine" or
                    "mine_start")
                or nil
        end),
    ActionHandler(ACTIONS.DIG,
        function(inst)
            return not inst.sg:HasStateTag("predig")
                and (inst.sg:HasStateTag("digging") and
                    "dig" or
                    "dig_start")
                or nil
        end),
    ActionHandler(ACTIONS.TILL, "till_start"),
    ActionHandler(ACTIONS.GIVE, "give"),
    ActionHandler(ACTIONS.GIVEALLTOPLAYER, "give"),
    ActionHandler(ACTIONS.DROP, "give"),
    ActionHandler(ACTIONS.PICKUP, "take"),
    ActionHandler(ACTIONS.CHECKTRAP, "take"),
    ActionHandler(ACTIONS.PICK,
		function(inst, action)
			if action.target:HasTag("noquickpick") then
				return "dolongaction"
			elseif action.target.components.pickable then
				if inst.GetModuleTypeCount and
					inst:GetModuleTypeCount("spin") > 0 and
					not action.target.components.pickable.quickpick and
					action.target:HasAnyTag(SGWX78Common.WX_SPIN_PICKABLE_TAGS)
				then
					--wx skill
					local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
					if WX78Common.CanSpinUsingItem(item) then
						return not inst.sg:HasStateTag("prespin")
							and (inst.sg:HasStateTag("spinning") and
								"wx_spin" or
								"wx_spin_start")
							or nil
					end
				end
				return (action.target.components.pickable.jostlepick and "dojostleaction")
					or (action.target.components.pickable.quickpick and "doshortaction")
					or (inst:HasTag("fastpicker") and "doshortaction")
					or (inst:HasTag("quagmire_fasthands") and "domediumaction")
					or "dolongaction"
			elseif action.target.components.searchable then
				return (action.target.components.searchable.jostlesearch and "dojostleaction")
					or (action.target.components.searchable.quicksearch and "doshortaction")
					or "dolongaction"
			end
			--failed if reached here!
        end),
    ActionHandler(ACTIONS.EAT,
        function(inst, action)
            if inst.sg:HasStateTag("busy") then
                return
            end
            local obj = action.target or action.invobject
            if obj == nil then
                return
            elseif obj.components.edible ~= nil then
                if not inst.components.eater:PrefersToEat(obj) then
                    inst:PushEvent("wonteatfood", { food = obj })
                    return
                end
            elseif obj.components.soul ~= nil then
                if inst.components.souleater == nil then
                    inst:PushEvent("wonteatfood", { food = obj })
                    return
                end
            else
                return
            end

			--NOTE: Keep states in sync with ACTIONS.FEEDPLAYER.fn
			local state =
				(obj:HasTag("quickeat") and "quickeat") or
				(obj:HasTag("sloweat") and "eat") or
				((obj.components.edible.foodtype == FOODTYPE.MEAT and not obj:HasTag("fooddrink")) and "eat") or -- #EGGNOG_HACK, eggnog is the one meat drink, we don't have a long drink, so exclude from eat state
				"quickeat"

			return state
        end),

    ActionHandler(ACTIONS.TOGGLEWXSCREECH, function(inst)
        return inst:HasTag("wx_screeching") and "wx_screech_pst" or "wx_screech_pre"
    end),

    ActionHandler(ACTIONS.TOGGLEWXSHIELDING, function(inst)
        return inst:HasTag("wx_shielding") and "wx_shield_pst" or "wx_shield_pre"
    end),
}

local BLOWDART_TAGS = {"blowdart", "blowpipe"}
local events =
{
    EventHandler("locomote", function(inst, data)
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")
        local is_idling = inst.sg:HasStateTag("idle")

        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()

        if is_moving and not should_move then
            inst.sg:GoToState(is_running and "run_stop")
        elseif (is_idling and should_move) or (is_moving and should_move and is_running ~= should_run) then
            if data and data.dir then
                inst.components.locomotor:SetMoveDir(data.dir)
            end
            inst.sg:GoToState("run_start")
        end
    end),

    EventHandler("death", function(inst, data)
    	if not inst.sg:HasStateTag("dead") then
            inst.sg:GoToState("death", data)
    	end
    end),

    CommonHandlers.OnSink(),
    CommonHandlers.OnFallInVoid(),
    CommonHandlers.OnHop(),

    EventHandler("freeze",
        function(inst)
            if inst.components.health ~= nil and not inst.components.health:IsDead() then
                inst.sg:GoToState("frozen")
            end
        end),

    EventHandler("equip", function(inst, data)
        if data.eslot == EQUIPSLOTS.BEARD then
            return nil
        elseif data.eslot == EQUIPSLOTS.BODY and data.item ~= nil and data.item:HasTag("heavy") then
            inst.sg:GoToState("heavylifting_start")
		elseif inst.components.inventory:IsHeavyLifting() then
            if inst.sg:HasAnyStateTag("idle", "moving") then
                inst.sg:GoToState("heavylifting_item_hat")
            end
        elseif inst.sg:HasAnyStateTag("idle", "channeling") then
            inst.sg:GoToState(
                (data.item ~= nil and data.item.projectileowner ~= nil and "catch_equip") or
                (data.eslot == EQUIPSLOTS.HANDS and "item_out") or
                "item_hat"
            )
        end
    end),
    EventHandler("unequip", function(inst, data)
        if data.eslot == EQUIPSLOTS.BODY and data.item ~= nil and data.item:HasTag("heavy") then
            if not inst.sg:HasStateTag("busy") then
                inst.sg:GoToState("heavylifting_stop")
            end
        elseif inst.components.inventory:IsHeavyLifting() then
            if inst.sg:HasAnyStateTag("idle", "moving") then
                inst.sg:GoToState("heavylifting_item_hat")
            end
        elseif inst.sg:HasAnyStateTag("idle", "channeling") then
            inst.sg:GoToState(GetUnequipState(inst, data))
        end
    end),

	EventHandler("attacked", function(inst, data)
		if not (inst.components.health:IsDead() or inst.components.health:IsInvincible()) then
			inst.sg:GoToState("hit")
		end
	end),
	EventHandler("doattack", function(inst, data)
		if inst.components.health ~= nil and not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
            local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil
            if inst.GetModuleTypeCount and
				inst:GetModuleTypeCount("spin") > 0 and
				WX78Common.CanSpinUsingItem(weapon) and
				data ~= nil and data.target
			then
				if not inst.sg:HasStateTag("prespin") then
                    inst.sg:GoToState(inst.sg:HasStateTag("spinning") and "wx_spin" or "wx_spin_start", {
                        target = data.target,
                    })
                end
            else
                inst.sg:GoToState(
                    (weapon ~= nil
                        and (weapon:HasOneOfTags(BLOWDART_TAGS) and "blowdart"))
                    or "attack", data ~= nil and data.target or nil)
            end
		end
	end),
    EventHandler("dance", function(inst)
        if not inst.sg:HasStateTag("busy") and (inst._brain_dancedata ~= nil or not inst.sg:HasStateTag("dancing")) then
            inst.sg:GoToState("dance")
        end
    end),

    EventHandler("possessed", function(inst, data)
        inst.sg:GoToState("spawn", data)
    end),

    EventHandler("become_dormant", function(inst, data)
        inst.sg:GoToState("despawn")
    end),

    EventHandler("toolbroke",
        function(inst, data)
			if not inst.sg:HasStateTag("nointerrupt") then
				inst.sg:GoToState("toolbroke", data.tool)
			end
        end),

    EventHandler("armorbroke",
        function(inst)
			if not inst.sg:HasStateTag("nointerrupt") then
				inst.sg:GoToState("armorbroke")
			end
        end),
}

local states =
{
	State{
		name = "spawn",
        tags = { "busy", "notalking", "noattack", "nointerrupt" },

		onenter = function(inst, data)
			inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("wx_chassis_idle", true)
			if not inst.sg.mem.wx_chassis_build then
				inst.sg.mem.wx_chassis_build = true
				inst.AnimState:AddOverrideBuild("wx_chassis")
			end

            inst.components.health:SetInvincible(true)
			if inst.components.talker then
				inst.components.talker:ShutUp()
				inst.components.talker:IgnoreAll("wx_poweroff")
			end
		end,

		timeline =
		{
			--#SFX
			FrameEvent(15 + 0, function(inst) inst.SoundEmitter:PlaySound("WX_rework/chassis/internal_rumble") end),
			FrameEvent(15 + 24, function(inst) inst.SoundEmitter:PlaySound("WX_rework/chassis/chassis_clunk") end),
            FrameEvent(15 + 27, function(inst) inst.SoundEmitter:PlaySound("rifts5/generic_metal/clunk_big_single") end),
			FrameEvent(15 + 42, function(inst) inst.SoundEmitter:PlaySound("WX_rework/chassis/chassis_clunk") end),
			FrameEvent(15 + 58, function(inst) inst.SoundEmitter:PlaySound("rifts5/generic_metal/ratchet") end),
            FrameEvent(15 + 73, function(inst) inst.SoundEmitter:PlaySound("rifts5/generic_metal/clunk") end),

			FrameEvent(15, function(inst)
				inst.AnimState:PlayAnimation("wx_chassis_poweron")
			end),
			FrameEvent(15 + 60, function(inst)
				if inst.components.talker then
					inst.components.talker:StopIgnoringAll("wx_poweroff")
				end
			end),
			FrameEvent(15 + 67, function(inst)
				inst.sg:RemoveStateTag("nointerrupt")
				inst.sg:RemoveStateTag("noattack")
				inst.components.health:SetInvincible(false)
			end),
			FrameEvent(15 + 76, function(inst)
				inst.sg:GoToState("idle", true)
			end),
		},

		onexit = function(inst)
            inst.AnimState:Hide("trapper")
			inst.sg.mem.wx_chassis_build = nil
			inst.AnimState:ClearOverrideBuild("wx_chassis")

			if inst.sg:HasStateTag("noattack") then
				inst.components.health:SetInvincible(false)
			end

			if inst.components.talker then
				inst.components.talker:StopIgnoringAll("wx_poweroff")
			end
		end,
	},

    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst, pushanim)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()

            if pushanim then
                inst.AnimState:PushAnimation("idle_loop", true)
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
            end

            -- player is usually random * 4 + 2. these ones occur even more frequently to be clearer
            inst.sg:SetTimeout(math.random() * 2 + 1)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("funnyidle")
        end,
    },

    State{
        name = "funnyidle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            if inst.components.hunger:GetPercent() < TUNING.HUNGRY_THRESH then
                inst.AnimState:PlayAnimation("hungry")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hungry")
            elseif inst.components.sanity:IsInsanityMode() and inst.components.sanity:GetPercent() < .5 then
                inst.AnimState:PlayAnimation("idle_inaction_sanity")
            elseif inst.customidleanim == nil and inst.customidlestate == nil then
                inst.AnimState:PlayAnimation("idle_inaction")
			else
                local anim = inst.customidleanim ~= nil and (type(inst.customidleanim) == "string" and inst.customidleanim or inst:customidleanim()) or nil
				local state = anim == nil and (inst.customidlestate ~= nil and (type(inst.customidlestate) == "string" and inst.customidlestate or inst:customidlestate())) or nil
                if anim ~= nil or state ~= nil then
                    if inst.sg.mem.idlerepeats == nil then
                        inst.sg.mem.usecustomidle = math.random() < .5
                        inst.sg.mem.idlerepeats = 0
                    end
                    if inst.sg.mem.idlerepeats > 1 then
                        inst.sg.mem.idlerepeats = inst.sg.mem.idlerepeats - 1
                    else
                        inst.sg.mem.usecustomidle = not inst.sg.mem.usecustomidle
                        inst.sg.mem.idlerepeats = inst.sg.mem.usecustomidle and 1 or math.ceil(math.random(2, 5) * .5)
                    end
					if inst.sg.mem.usecustomidle then
						if anim ~= nil then
		                    inst.AnimState:PlayAnimation(anim)
						else
							inst.sg:GoToState(state)
						end
					else
	                    inst.AnimState:PlayAnimation("idle_inaction")
					end
                else
                    inst.AnimState:PlayAnimation("idle_inaction")
                end
            end
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "run_start",
        tags = {"moving", "running", "canrotate"},

        onenter = function(inst)
            inst.sg.mem.footsteps = 0
            ConfigureRunState(inst)

            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation("run_pre")
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
			FrameEvent(4, function(inst)
                if inst.sg.statemem.normal then
                    PlayFootstep(inst, nil, true)
                    DoFoleySounds(inst)
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("run")
                end
            end),
        },
    },

    State{
        name = "run",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
            ConfigureRunState(inst)

            inst.components.locomotor:RunForward()
            if not inst.AnimState:IsCurrentAnimation("run_loop") then
                inst.AnimState:PlayAnimation("run_loop", true)
            end
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            FrameEvent(7, function(inst)
                if inst.sg.statemem.normal then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),
            FrameEvent(15, function(inst)
                if inst.sg.statemem.normal then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("run")
        end,
    },

    State{
        name = "run_stop",
        tags = { "canrotate", "idle" },

        onenter = function(inst)
            ConfigureRunState(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("run_pst")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "item_hat",
		tags = { "idle", "keepchannelcasting" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("item_hat")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "item_in",
		tags = { "idle", "nodangle", "keepchannelcasting" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("item_in")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.followfx ~= nil then
                for i, v in ipairs(inst.sg.statemem.followfx) do
                    v:Remove()
                end
            end
        end,
    },

    State{
        name = "item_out",
		tags = { "idle", "nodangle", "keepchannelcasting" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("item_out")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },


    State{
        name = "attack",
        tags = { "attack", "notalking", "abouttoattack" },

        onenter = function(inst, target)
            if inst.components.combat:InCooldown() then
                inst.sg:RemoveStateTag("abouttoattack")
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle", true)
                return
            end
            if inst.sg.laststate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
            end
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            local cooldown = inst.components.combat.min_attack_period
            if equip ~= nil and equip:HasTag("toolpunch") then

                -- **** ANIMATION WARNING ****
                -- **** ANIMATION WARNING ****
                -- **** ANIMATION WARNING ****

                --  THIS ANIMATION LAYERS THE LANTERN GLOW UNDER THE ARM IN THE UP POSITION SO CANNOT BE USED IN STANDARD LANTERN GLOW ANIMATIONS.

                inst.AnimState:PlayAnimation("toolpunch")
                inst.sg.statemem.istoolpunch = true
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, inst.sg.statemem.attackvol, true)
                cooldown = math.max(cooldown, 13 * FRAMES)
            elseif equip ~= nil and equip:HasTag("whip") then
                inst.AnimState:PlayAnimation("whip_pre")
                inst.AnimState:PushAnimation("whip", false)
                inst.sg.statemem.iswhip = true
                inst.SoundEmitter:PlaySound("dontstarve/common/whip_pre", nil, nil, true)
                cooldown = math.max(cooldown, 17 * FRAMES)
			elseif equip ~= nil and equip:HasTag("pocketwatch") then
				inst.AnimState:PlayAnimation(inst.sg.statemem.chained and "pocketwatch_atk_pre_2" or "pocketwatch_atk_pre" )
				inst.AnimState:PushAnimation("pocketwatch_atk", false)
				inst.sg.statemem.ispocketwatch = true
				cooldown = math.max(cooldown, 15 * FRAMES)
                if equip:HasTag("shadow_item") then
	                inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/pre_shadow", nil, nil, true)
					inst.AnimState:Show("pocketwatch_weapon_fx")
					inst.sg.statemem.ispocketwatch_fueled = true
                else
	                inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/weapon/pre", nil, nil, true)
					inst.AnimState:Hide("pocketwatch_weapon_fx")
                end
            elseif equip ~= nil and equip:HasTag("book") then
                inst.AnimState:PlayAnimation("attack_book")
                inst.sg.statemem.isbook = true
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 19 * FRAMES)
            elseif equip ~= nil and equip:HasTag("chop_attack") and inst:HasTag("woodcutter") then
				inst.AnimState:PlayAnimation(inst.AnimState:IsCurrentAnimation("woodie_chop_loop") and inst.AnimState:GetCurrentAnimationFrame() <= 7 and "woodie_chop_atk_pre" or "woodie_chop_pre")
                inst.AnimState:PushAnimation("woodie_chop_loop", false)
                inst.sg.statemem.ischop = true
                cooldown = math.max(cooldown, 11 * FRAMES)
            elseif equip ~= nil and equip:HasTag("jab") then
                inst.AnimState:PlayAnimation("spearjab_pre")
                inst.AnimState:PushAnimation("spearjab", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 21 * FRAMES)
            elseif equip ~= nil and equip:HasTag("lancejab") then
                inst.sg.statemem.predictedfacing = true
                inst.Transform:SetPredictedEightFaced()
                inst.AnimState:PlayAnimation("lancejab_pre")
                inst.AnimState:PushAnimation("lancejab", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 21 * FRAMES)
            elseif equip ~= nil and equip.components.weapon ~= nil and not equip:HasTag("punch") then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                if (equip.projectiledelay or 0) > 0 then
                    --V2C: Projectiles don't show in the initial delayed frames so that
                    --     when they do appear, they're already in front of the player.
                    --     Start the attack early to keep animation in sync.
                    inst.sg.statemem.projectiledelay = 8 * FRAMES - equip.projectiledelay
                    if inst.sg.statemem.projectiledelay > FRAMES then
                        inst.sg.statemem.projectilesound =
                            (equip:HasTag("icestaff") and GetIceStaffProjectileSound(inst, equip)) or
                            (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                            (equip:HasTag("firepen") and "wickerbottom_rework/firepen/launch") or
                            "dontstarve/wilson/attack_weapon"
                    elseif inst.sg.statemem.projectiledelay <= 0 then
                        inst.sg.statemem.projectiledelay = nil
                    end
                end
                if inst.sg.statemem.projectilesound == nil then
                    inst.SoundEmitter:PlaySound(
                        (equip:HasTag("icestaff") and GetIceStaffProjectileSound(inst, equip)) or
                        (equip:HasTag("shadow") and "dontstarve/wilson/attack_nightsword") or
                        (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                        (equip:HasTag("firepen") and "wickerbottom_rework/firepen/launch") or
                        "dontstarve/wilson/attack_weapon",
                        nil, nil, true
                    )
                end
                cooldown = math.max(cooldown, 13 * FRAMES)
            elseif equip ~= nil and (equip:HasTag("light") or equip:HasTag("nopunch")) then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                cooldown = math.max(cooldown, 13 * FRAMES)
            else
                inst.AnimState:PlayAnimation("punch")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                cooldown = math.max(cooldown, 24 * FRAMES)
            end

            inst.sg:SetTimeout(cooldown)

            if target ~= nil then
                inst.components.combat:BattleCry()
                if target:IsValid() then
                    inst:FacePoint(target:GetPosition())
                    inst.sg.statemem.attacktarget = target
                    inst.sg.statemem.retarget = target
                end
            end
        end,

        onupdate = function(inst, dt)
            if (inst.sg.statemem.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
                if inst.sg.statemem.projectiledelay <= FRAMES then
                    if inst.sg.statemem.projectilesound ~= nil then
                        inst.SoundEmitter:PlaySound(inst.sg.statemem.projectilesound, nil, nil, true)
                        inst.sg.statemem.projectilesound = nil
                    end
                    if inst.sg.statemem.projectiledelay <= 0 then
                        inst.components.combat:DoAttack(inst.sg.statemem.attacktarget)
                        inst.sg:RemoveStateTag("abouttoattack")
                    end
                end
            end
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                if not (inst.sg.statemem.iswhip or inst.sg.statemem.ispocketwatch or inst.sg.statemem.isbook) and
                    inst.sg.statemem.projectiledelay == nil then
                    inst.sg.statemem.recoilstate = "attack_recoil"
                    inst.components.combat:DoAttack(inst.sg.statemem.attacktarget)
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(10 * FRAMES, function(inst)
                if inst.sg.statemem.iswhip or inst.sg.statemem.isbook or inst.sg.statemem.ispocketwatch then
                    inst.sg.statemem.recoilstate = "attack_recoil"
                    inst.components.combat:DoAttack(inst.sg.statemem.attacktarget)
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(17*FRAMES, function(inst)
				if inst.sg.statemem.ispocketwatch then
                    inst.SoundEmitter:PlaySound(inst.sg.statemem.ispocketwatch_fueled and "wanda2/characters/wanda/watch/weapon/pst_shadow" or "wanda2/characters/wanda/watch/weapon/pst")
                end
            end),
        },


        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,

        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.components.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.components.combat:CancelAttack()
            end
        end,
    },

    State{
        name = "blowdart",
        tags = { "attack", "notalking", "abouttoattack" },

        onenter = function(inst, target)
            if inst.components.combat:InCooldown() then
                inst.sg:RemoveStateTag("abouttoattack")
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle", true)
                return
            end

            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("dart_pre")
            if inst.sg.laststate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
				inst.AnimState:SetFrame(5)
            end
            inst.AnimState:PushAnimation("dart", false)

            inst.sg:SetTimeout(math.max((inst.sg.statemem.chained and 14 or 18) * FRAMES, inst.components.combat.min_attack_period))

            if target ~= nil and target:IsValid() then
                inst:FacePoint(target.Transform:GetWorldPosition())
                inst.sg.statemem.attacktarget = target
                inst.sg.statemem.retarget = target
            end

            if (equip ~= nil and equip.projectiledelay or 0) > 0 then
                --V2C: Projectiles don't show in the initial delayed frames so that
                --     when they do appear, they're already in front of the player.
                --     Start the attack early to keep animation in sync.
                inst.sg.statemem.projectiledelay = (inst.sg.statemem.chained and 9 or 14) * FRAMES - equip.projectiledelay
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst.sg.statemem.projectiledelay = nil
                end
            end
        end,

        onupdate = function(inst, dt)
            if (inst.sg.statemem.projectiledelay or 0) > 0 then
                inst.sg.statemem.projectiledelay = inst.sg.statemem.projectiledelay - dt
                if inst.sg.statemem.projectiledelay <= 0 then
                    inst.components.combat:DoAttack(inst.sg.statemem.attacktarget)
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end
        end,

        timeline =
        {
            FrameEvent(8, function(inst)
                if inst.sg.statemem.chained then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot", nil, nil, true)
                end
            end),
            FrameEvent(9, function(inst)
                if inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst.components.combat:DoAttack(inst.sg.statemem.attacktarget)
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            FrameEvent(13, function(inst)
                if not inst.sg.statemem.chained then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot", nil, nil, true)
                end
            end),
            FrameEvent(14, function(inst)
                if not inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst.components.combat:DoAttack(inst.sg.statemem.attacktarget)
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
        end,

        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.components.combat:SetTarget(nil)
            if inst.sg:HasStateTag("abouttoattack") then
                inst.components.combat:CancelAttack()
            end
        end,
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            inst.components.burnable:Extinguish()

            if inst.deathsoundoverride ~= nil then
                inst.SoundEmitter:PlaySound(inst.deathsoundoverride)
            elseif not inst:HasTag("mime") then
                inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/death_voice")
            end

            if inst.components.sanity:GetPercent() == 0 then
                inst.sg.statemem.gestaltflee = true
                inst.AnimState:Show("gestalt_flee")
            else
                inst.AnimState:Show("gestalt_die")
            end
			inst:SetPlanarFxShown(false)

            inst.AnimState:PlayAnimation("wx_chassis_poweroff")
            if not inst.sg.mem.wx_chassis_build then
                inst.sg.mem.wx_chassis_build = true
                inst.AnimState:AddOverrideBuild("wx_chassis")
            end
        end,

		timeline =
		{
            --#SFX
            -- gestalt is fleeing
            FrameEvent(0, function(inst)
                 if inst.sg.statemem.gestaltflee then
                     inst.SoundEmitter:PlaySound("rifts5/gestalt_evolved/emerge_vocals")
                 end
             end),

            -- gestalt is dead
             FrameEvent(0, function(inst)
                 if not inst.sg.statemem.gestaltflee then
                     inst.SoundEmitter:PlaySound("rifts5/gestalt_evolved/attack_vocals")
                 end
             end),

            --
            FrameEvent(0, function(inst)
                if inst.sg.mem.wx_chassis_build then
                    inst.SoundEmitter:PlaySound("WX_rework/chassis/internal_rumble")
                end
            end),
            FrameEvent(16, function(inst)
                if inst.sg.mem.wx_chassis_build then
                    inst.SoundEmitter:PlaySound("rifts5/generic_metal/ratchet")
                end
            end),
            FrameEvent(22, function(inst)
                if inst.sg.mem.wx_chassis_build then
                    inst.SoundEmitter:PlaySound("rifts5/generic_metal/clunk")
                end
            end),
            FrameEvent(28, function(inst)
                if inst.sg.mem.wx_chassis_build then
                    inst.SoundEmitter:PlaySound("WX_rework/chassis/chassis_clunk")
                end
            end),
		},

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst:TryToReplaceWithBackupBody()
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.mem.wx_chassis_build then
                inst.sg.mem.wx_chassis_build = nil
                inst.AnimState:ClearOverrideBuild("wx_chassis")
            end
			inst:SetPlanarFxShown(true)
		end,
    },

    State{
        name = "despawn",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            inst.components.burnable:Extinguish()

            if inst.deathsoundoverride ~= nil then
                inst.SoundEmitter:PlaySound(inst.deathsoundoverride)
            elseif not inst:HasTag("mime") then
                inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/death_voice")
            end

            inst.AnimState:PlayAnimation("wx_chassis_poweroff")
            if not inst.sg.mem.wx_chassis_build then
                inst.sg.mem.wx_chassis_build = true
                inst.AnimState:AddOverrideBuild("wx_chassis")
            end
        end,

		timeline =
		{
            FrameEvent(0, function(inst)
                if inst.sg.mem.wx_chassis_build then
                    inst.SoundEmitter:PlaySound("WX_rework/chassis/internal_rumble")
                end
            end),
            FrameEvent(16, function(inst)
                if inst.sg.mem.wx_chassis_build then
                    inst.SoundEmitter:PlaySound("rifts5/generic_metal/ratchet")
                end
            end),
            FrameEvent(22, function(inst)
                if inst.sg.mem.wx_chassis_build then
                    inst.SoundEmitter:PlaySound("rifts5/generic_metal/clunk")
                end
            end),
            FrameEvent(28, function(inst)
                if inst.sg.mem.wx_chassis_build then
                    inst.SoundEmitter:PlaySound("WX_rework/chassis/chassis_clunk")
                end
            end),
		},

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst:TryToReplaceWithBackupBody(true)
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.mem.wx_chassis_build then
                inst.sg.mem.wx_chassis_build = nil
                inst.AnimState:ClearOverrideBuild("wx_chassis")
            end
		end,
    },


    State{
        name = "take",
        tags = {"busy"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickup")
            inst.AnimState:PushAnimation("pickup_pst", false)
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        events=
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "give",
        tags = {"busy"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("give")
            inst.AnimState:PushAnimation("give_pst", false)
        end,

        timeline =
        {
            TimeEvent(14 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        events=
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "hit",
        tags = { "busy", "keepchannelcasting" },

        onenter = function(inst, frozen)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:PlayAnimation("hit")

            if frozen == "noimpactsound" then
                frozen = nil
            else
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
            end
            DoHurtSound(inst)

			local stun_frames = math.min(inst.AnimState:GetCurrentAnimationNumFrames(), frozen and 10 or 6)
            inst.sg:SetTimeout(stun_frames * FRAMES)
        end,

        ontimeout = function(inst)
			--V2C: -removing the tag now, since this is actually a supported "channeling_item"
			--      state (i.e. has custom anim)
			--     -the state enters with the tag though, to cheat having to create a separate
			--      hit state for channeling items
			inst.sg:RemoveStateTag("keepchannelcasting")
            inst.sg:GoToState("idle", true)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },


    State{
        name = "frozen",
        tags = { "busy", "frozen", "nodangle" },

        onenter = function(inst)
            if inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck() then
                inst.components.pinnable:Unstick()
            end

            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
            inst.AnimState:PlayAnimation("frozen")
            inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")

            --V2C: cuz... freezable component and SG need to match state,
            --     but messages to SG are queued, so it is not great when
            --     when freezable component tries to change state several
            --     times within one frame...
            if inst.components.freezable == nil then
                inst.sg:GoToState("hit", true)
            elseif inst.components.freezable:IsThawing() then
                inst.sg:GoToState("thaw")
            elseif not inst.components.freezable:IsFrozen() then
                inst.sg:GoToState("hit", true)
            end
        end,

        events =
        {
            EventHandler("onthaw", function(inst)
                inst.sg.statemem.isstillfrozen = true
                inst.sg:GoToState("thaw")
            end),
            EventHandler("unfreeze", function(inst)
                inst.sg:GoToState("hit", true)
            end),
        },

        onexit = function(inst)
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,
    },

    State{
        name = "thaw",
        tags = { "busy", "thawing", "nodangle" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
            inst.AnimState:PlayAnimation("frozen_loop_pst", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")
        end,

        events =
        {
            EventHandler("unfreeze", function(inst)
                inst.sg:GoToState("hit", true)
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("thawing")
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,
    },


    State{
        name = "stunned",
        tags = {"busy", "canrotate"},

        onenter = function(inst)
            inst:ClearBufferedAction()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_sanity_pre")
            inst.AnimState:PushAnimation("idle_sanity_loop", true)
            inst.sg:SetTimeout(5)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "chop_start",
        tags = {"prechop", "working"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("chop_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("chop")
                end
            end),
        },
    },

    State{
        name = "chop",
        tags = {"prechop", "chopping", "working"},

        onenter = function(inst)
			inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("chop_loop")
        end,

        timeline =
        {
            FrameEvent(2, function(inst)
                inst:PerformBufferedAction()
            end),
			FrameEvent(14, function(inst)
                inst.sg:RemoveStateTag("prechop")
				TryRepeatAction(inst, inst.sg.statemem.action)
            end),
            FrameEvent(16, function(inst)
                inst.sg:RemoveStateTag("chopping")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "mine_start",
        tags = {"premine", "working"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("pickaxe_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("mine")
                end
            end),
        },
    },

    State{
        name = "mine",
        tags = {"premine", "mining", "working"},

        onenter = function(inst)
			inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("pickaxe_loop")
        end,

        timeline =
        {
            FrameEvent(7, function(inst)
				if inst.sg.statemem.action ~= nil then
					PlayMiningFX(inst, inst.sg.statemem.action.target)
					inst.sg.statemem.recoilstate = "mine_recoil"
                    inst:PerformBufferedAction()
                end
            end),
            FrameEvent(14, function(inst)
				inst.sg:RemoveStateTag("premine")
				TryRepeatAction(inst, inst.sg.statemem.action)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("pickaxe_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },

	State{
		name = "mine_recoil",
		tags = { "busy", "recoil" },

		onenter = function(inst, data)
			inst.components.locomotor:Stop()
			inst:ClearBufferedAction()

			inst.AnimState:PlayAnimation("pickaxe_recoil")
			if data ~= nil and data.target ~= nil and data.target:IsValid() then
                local pos = data.target:GetPosition()

                if data.target.recoil_effect_offset then
                    pos = pos + data.target.recoil_effect_offset
                end
                
				SpawnPrefab("impact").Transform:SetPosition(pos:Get())
			end
			inst.Physics:SetMotorVelOverride(-6, 0, 0)
		end,

		onupdate = function(inst)
			if inst.sg.statemem.speed ~= nil then
				inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed, 0, 0)
				inst.sg.statemem.speed = inst.sg.statemem.speed * 0.75
			end
		end,

		timeline =
		{
			FrameEvent(4, function(inst)
				inst.sg.statemem.speed = -3
			end),
			FrameEvent(17, function(inst)
				inst.sg.statemem.speed = nil
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
			end),
			FrameEvent(23, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
			FrameEvent(30, function(inst)
				inst.sg:GoToState("idle", true)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:ClearMotorVelOverride()
			inst.Physics:Stop()
		end,
	},

    
    State{
        name = "hammer_start",
        tags = { "prehammer", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickaxe_pre")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("hammer")
                end
            end),
        },
    },

    State{
        name = "hammer",
        tags = { "prehammer", "hammering", "working" },

        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("pickaxe_loop")
        end,

        timeline =
        {
            FrameEvent(7, function(inst)
				inst.SoundEmitter:PlaySound(inst.sg.statemem.action ~= nil and inst.sg.statemem.action.invobject ~= nil and inst.sg.statemem.action.invobject.hit_skin_sound or "dontstarve/wilson/hit")
				inst.sg.statemem.recoilstate = "mine_recoil"
				inst:PerformBufferedAction()
            end),

            FrameEvent(14, function(inst)
                inst.sg:RemoveStateTag("premine")
				TryRepeatAction(inst, inst.sg.statemem.action, true)
            end),
        },

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("pickaxe_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },

	State{
		name = "attack_recoil",
		tags = { "busy", "recoil" },

		onenter = function(inst, data)
			inst.components.locomotor:Stop()
			inst:ClearBufferedAction()

			inst.AnimState:PlayAnimation("atk_recoil")
			if data ~= nil and data.target ~= nil and data.target:IsValid() then
                local pos = data.target:GetPosition()

                if data.target.recoil_effect_offset then
                    pos = pos + data.target.recoil_effect_offset
                end
                
				SpawnPrefab("impact").Transform:SetPosition(pos:Get())
			end
			inst.Physics:SetMotorVelOverride(-6, 0, 0)
		end,

		onupdate = function(inst)
			if inst.sg.statemem.speed ~= nil then
				inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed, 0, 0)
				inst.sg.statemem.speed = inst.sg.statemem.speed * 0.75
			end
		end,

		timeline =
		{
			FrameEvent(4, function(inst)
				inst.sg.statemem.speed = -3
			end),
			FrameEvent(17, function(inst)
				inst.sg.statemem.speed = nil
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
			end),
			FrameEvent(23, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
			FrameEvent(30, function(inst)
				inst.sg:GoToState("idle", true)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:ClearMotorVelOverride()
			inst.Physics:Stop()
		end,
	},

    State{
        name = "dig_start",
        tags = { "predig", "working" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("shovel_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("dig")
                end
            end),
        },
    },

    State{
        name = "dig",
        tags = { "predig", "digging", "working" },

        onenter = function(inst)
			inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("shovel_loop")
        end,

        timeline =
        {
            FrameEvent(15, function(inst)
                inst:PerformBufferedAction()
                inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
            end),
            FrameEvent(35, function(inst)
                inst.sg:RemoveStateTag("predig")
				TryRepeatAction(inst, inst.sg.statemem.action, true)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("shovel_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },

    State{
        name = "till_start",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
			local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if equippedTool ~= nil and equippedTool.components.tool ~= nil and equippedTool.components.tool:CanDoAction(ACTIONS.DIG) then
				--upside down tool build
				inst.AnimState:PlayAnimation("till2_pre")
			else
				inst.AnimState:PlayAnimation("till_pre")
			end
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("till")
                end
            end),
        },
    },

    State{
        name = "till",
        tags = { "doing", "busy", "tilling" },

        onenter = function(inst)
			local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
			if equippedTool ~= nil and equippedTool.components.tool ~= nil and equippedTool.components.tool:CanDoAction(ACTIONS.DIG) then
				--upside down tool build
				inst.sg.statemem.fliptool = true
				inst.AnimState:PlayAnimation("till2_loop")
			else
				inst.AnimState:PlayAnimation("till_loop")
			end
        end,

        timeline =
        {
            FrameEvent(4, function(inst) inst.SoundEmitter:PlaySound("dontstarve/wilson/dig") end),
            FrameEvent(11, function(inst)
                inst:PerformBufferedAction()
            end),
            FrameEvent(12, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mole/emerge") end),
            FrameEvent(22, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
					inst.AnimState:PlayAnimation(inst.sg.statemem.fliptool and "till2_pst" or "till_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },

    State{
        name = "dance",
        tags = {"idle", "dancing"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            local ignoreplay = inst.AnimState:IsCurrentAnimation("run_pst")
            if inst._brain_dancedata and #inst._brain_dancedata > 0 then
                for _, data in ipairs(inst._brain_dancedata) do
                    if data.play and not ignoreplay then
                        inst.AnimState:PlayAnimation(data.anim, data.loop)
                    else
                        inst.AnimState:PushAnimation(data.anim, data.loop)
                    end
                end
            else
                -- NOTES(JBK): No dance data do default dance.
                if ignoreplay then
                    inst.AnimState:PushAnimation("emoteXL_pre_dance0")
                else
                    inst.AnimState:PlayAnimation("emoteXL_pre_dance0")
                end
                inst.AnimState:PushAnimation("emoteXL_loop_dance0", true)
            end
            inst._brain_dancedata = nil -- Remove reference no matter what so garbage collector can pick up the memory.
        end,
    },

    State{
        name = "dolongaction",
        tags = { "doing", "busy", "nodangle" },

        onenter = function(inst, timeout)
            if timeout == nil then
                timeout = 1
            elseif timeout > 1 then
                inst.sg:AddStateTag("slowaction")
            end
            inst.sg:SetTimeout(timeout)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
            if inst.bufferedaction ~= nil then
                inst.sg.statemem.action = inst.bufferedaction
                if inst.bufferedaction.target ~= nil and inst.bufferedaction.target:IsValid() then
					inst.bufferedaction.target:PushEvent("startlongaction", inst)
                end
            end
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        ontimeout = function(inst)
            inst.AnimState:PlayAnimation("build_pst")
            inst:PerformBufferedAction()
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State{
        name = "doshortaction",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("pickup")
			inst.AnimState:PushAnimation("pickup_pst", false)

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg:SetTimeout(10 * FRAMES)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
            TimeEvent(6 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        ontimeout = function(inst)
            --pickup_pst should still be playing
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State{
        name = "eat",
		tags = { "busy", "nodangle", },

        onenter = function(inst, foodinfo)
            inst.components.locomotor:Stop()

            local feed = foodinfo and foodinfo.feed
            if feed ~= nil then
                inst.components.locomotor:Clear()
                inst:ClearBufferedAction()
                inst.sg.statemem.feed = foodinfo.feed
                inst.sg.statemem.feeder = foodinfo.feeder
				inst.sg.statemem.feedwasactiveitem = foodinfo.active
                inst.sg:AddStateTag("pausepredict")
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
            elseif inst:GetBufferedAction() then
                feed = inst:GetBufferedAction().invobject
            end

			inst.sg.statemem.doeatingsfx =
				feed == nil or
				feed.components.edible == nil or
				feed.components.edible.foodtype ~= FOODTYPE.GEARS

            inst.AnimState:PlayAnimation("eat_pre")
            inst.AnimState:PushAnimation("eat", false)

            inst.components.hunger:Pause()
        end,

        timeline =
        {
			FrameEvent(6, DoEatSound),
            TimeEvent(28 * FRAMES, function(inst)
                if inst.sg.statemem.feed == nil then
                    inst:PerformBufferedAction()
                elseif inst.sg.statemem.feed.components.soul == nil then
                    inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                elseif inst.components.souleater ~= nil then
                    inst.components.souleater:EatSoul(inst.sg.statemem.feed)
                end
				--NOTE: "queue_post_eat_state" can be triggered immediately from the eat action
            end),

            TimeEvent(30 * FRAMES, function(inst)
				if inst.sg.statemem.queued_post_eat_state == nil then
					inst.sg:RemoveStateTag("busy")
					inst.sg:RemoveStateTag("pausepredict")
				end
            end),
			FrameEvent(52, function(inst)
				if inst.sg.statemem.queued_post_eat_state ~= nil then
					inst.sg:GoToState(inst.sg.statemem.queued_post_eat_state)
				end
			end),
            TimeEvent(70 * FRAMES, function(inst)
				if inst.sg.statemem.doeatingsfx then
					inst.sg.statemem.doeatingsfx = nil
					inst.SoundEmitter:KillSound("eating")
				end
            end),
        },

        events =
        {
			EventHandler("queue_post_eat_state", function(inst, data)
				--NOTE: this event can trigger instantly instead of buffered
				if data ~= nil then
					inst.sg.statemem.queued_post_eat_state = data.post_eat_state
					if data.nointerrupt then
						inst.sg:AddStateTag("nointerrupt")
					end
				end
			end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
					inst.sg:GoToState(inst.sg.statemem.queued_post_eat_state or "idle")
                end
            end),
        },

        onexit = function(inst)
			if inst.sg.statemem.doeatingsfx then
				inst.SoundEmitter:KillSound("eating")
			end
            if not GetGameModeProperty("no_hunger") then
                inst.components.hunger:Resume()
            end
			TryReturnItemToFeeder(inst)
        end,
    },

    State{
        name = "quickeat",
		tags = { "busy", },

        onenter = function(inst, foodinfo)
            inst.components.locomotor:Stop()

            local feed = foodinfo and foodinfo.feed
            if feed ~= nil then
                inst.components.locomotor:Clear()
                inst:ClearBufferedAction()
                inst.sg.statemem.feed = foodinfo.feed
                inst.sg.statemem.feeder = foodinfo.feeder
				inst.sg.statemem.feedwasactiveitem = foodinfo.active
                inst.sg:AddStateTag("pausepredict")
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
            elseif inst:GetBufferedAction() then
                feed = inst:GetBufferedAction().invobject
            end

            local isdrink = feed and feed:HasTag("fooddrink")
            inst.sg.statemem.isdrink = isdrink

			inst.sg.statemem.doeatingsfx =
				feed == nil or
				feed.components.edible == nil or
				feed.components.edible.foodtype ~= FOODTYPE.GEARS

            if inst.components.inventory:IsHeavyLifting() and
                not inst.components.rider:IsRiding() then
				--V2C: don't think this is used anymore?
                inst.AnimState:PlayAnimation("heavy_quick_eat")
				DoEatSound(inst, true)
            else
                inst.AnimState:PlayAnimation(isdrink and "quick_drink_pre" or "quick_eat_pre")
                inst.AnimState:PushAnimation(isdrink and "quick_drink" or "quick_eat", false)
            end

            inst.components.hunger:Pause()
        end,

        timeline =
        {
			FrameEvent(10, DoEatSound),
            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.feed ~= nil then
                    inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                else
                    inst:PerformBufferedAction()
                end
				--NOTE: "queue_post_eat_state" can be triggered immediately from the eat action
				if inst.sg.statemem.queued_post_eat_state == nil then
					inst.sg:RemoveStateTag("busy")
					inst.sg:RemoveStateTag("pausepredict")
				end
            end),
			FrameEvent(21, function(inst)
				if inst.sg.statemem.queued_post_eat_state ~= nil then
					inst.sg:GoToState(inst.sg.statemem.queued_post_eat_state)
				end
			end),
        },

        events =
        {
			EventHandler("queue_post_eat_state", function(inst, data)
				--NOTE: this event can trigger instantly instead of buffered
				if data ~= nil then
					inst.sg.statemem.queued_post_eat_state = data.post_eat_state
					if data.nointerrupt then
						inst.sg:AddStateTag("nointerrupt")
					end
				end
			end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
					inst.sg:GoToState(inst.sg.statemem.queued_post_eat_state or "idle")
                end
            end),
        },

        onexit = function(inst)
			if inst.sg.statemem.doeatingsfx then
				inst.SoundEmitter:KillSound("eating")
			end
            if not GetGameModeProperty("no_hunger") then
                inst.components.hunger:Resume()
            end
			TryReturnItemToFeeder(inst)
        end,
    },

    State{
        name = "refuseeat",
		tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            -- DoTalkSound(inst)
            inst.AnimState:PlayAnimation(inst.components.inventory:IsHeavyLifting() and "heavy_refuseeat" or "refuseeat")
			inst.sg:SetTimeout(60 * FRAMES)
        end,

        timeline =
        {
            FrameEvent(22, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "toolbroke",
        tags = { "busy", "pausepredict" },

        onenter = function(inst, tool)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_break")
            inst.AnimState:Hide("ARM_carry")
            inst.AnimState:Show("ARM_normal")

            if tool == nil or not tool.nobrokentoolfx then
                SpawnPrefab("brokentool").Transform:SetPosition(inst.Transform:GetWorldPosition())
            end

            inst.sg.statemem.toolname = tool ~= nil and tool.prefab or nil

            inst.sg:SetTimeout(10 * FRAMES)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            if inst.sg.statemem.toolname ~= nil then
                local sameTool = inst.components.inventory:FindItem(function(item)
					return item.prefab == inst.sg.statemem.toolname and item.components.equippable ~= nil
                end)
                if sameTool ~= nil then
                    inst.components.inventory:Equip(sameTool)
                end
            end

            if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                inst.AnimState:Show("ARM_carry")
                inst.AnimState:Hide("ARM_normal")
            end
        end,
    },

    State{
        name = "armorbroke",
        tags = { "busy", "pausepredict" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_armour_break")
            inst.sg:SetTimeout(10 * FRAMES)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,
    },
}

CommonStates.AddInitState(states, "idle")

CommonStates.AddSinkAndWashAshoreStates(states,
{ -- anims
    sink = "sink",
    washashore = "wakeup",
},
{ -- timelines
    sink =
    {
        FrameEvent(14, function(inst)
            inst.AnimState:Show("float_front")
            inst.AnimState:Show("float_back")
        end),
        FrameEvent(16, function(inst)
            inst.components.drownable:DropInventory()
        end),
    },
},
{ -- fns
    sink_onenter = function(inst)
        inst.AnimState:Hide("plank")
        inst.AnimState:Hide("float_front")
        inst.AnimState:Hide("float_back")
        inst.AnimState:SetFrame(60) -- for fast sink
    end,
    sink_onexit = function(inst)
        inst.AnimState:Show("plank")
        inst.AnimState:Show("float_front")
        inst.AnimState:Show("float_back")
    end,
},
{ -- data
    skip_splash = true,
})
CommonStates.AddVoidFallStates(states,
{ -- anims
    fallinvoid = "abyss_fall",
    voiddrop = "fall_high",
},
{ -- timelines
    voiddrop =
    {
		SoundFrameEvent(12, "dontstarve/movement/bodyfall_dirt"),
		FrameEvent(14, function(inst)
			inst.sg:RemoveStateTag("noattack")
			inst.sg:RemoveStateTag("nointerrupt")
			-- ToggleOnPhysics(inst)
		end),
        FrameEvent(22, function(inst)
            inst.AnimState:SetLayer(LAYER_BELOW_GROUND)
        end),
	},
},
nil, -- fns
{ -- data
    skip_vfx = true,
})

local hop_timelines =
{
    hop_pre =
    {
        TimeEvent(0, function(inst)
            inst.components.embarker.embark_speed = math.clamp(inst.components.locomotor:RunSpeed() * inst.components.locomotor:GetSpeedMultiplier() + TUNING.WILSON_EMBARK_SPEED_BOOST, TUNING.WILSON_EMBARK_SPEED_MIN, TUNING.WILSON_EMBARK_SPEED_MAX)
        end),
    },
    hop_loop =
    {
        TimeEvent(0, function(inst)
            inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/jump")
        end),
    },
}

local function landed_in_falling_state(inst)
    if inst.components.drownable == nil then
        return nil
    end

    local fallingreason = inst.components.drownable:GetFallingReason()
    if fallingreason == nil then
        return nil
    end

    if fallingreason == FALLINGREASON.OCEAN then
        return "sink"
    elseif fallingreason == FALLINGREASON.VOID then
        return "abyss_fall"
    end

    return nil -- TODO(JBK): Fallback for unknown falling reason?
end

local hop_anims =
{
	pre = function(inst) return inst.components.inventory:IsHeavyLifting() and "boat_jumpheavy_pre" or "boat_jump_pre" end,
	loop = function(inst) return inst.components.inventory:IsHeavyLifting() and "boat_jumpheavy_loop" or "boat_jump_loop" end,
	pst = function(inst)
		if inst.components.inventory:IsHeavyLifting() then
			return "boat_jumpheavy_pst"
		elseif inst.components.embarker.embarkable and inst.components.embarker.embarkable:HasTag("teeteringplatform") then
			inst.sg:AddStateTag("teetering")
			return "boat_jump_to_teeter"
		end
		return "boat_jump_pst"
	end,
}

local function hop_land_sound(inst)
	return not inst.sg:HasStateTag("teetering") and "turnoftides/common/together/boat/jump_on" or nil
end

CommonStates.AddRowStates(states, false)
CommonStates.AddHopStates(states, true, hop_anims, hop_timelines, hop_land_sound, landed_in_falling_state, {start_embarking_pre_frame = 4*FRAMES})

SGWX78Common.AddWX78SpinStates(states)
SGWX78Common.AddWX78ShieldStates(states)
SGWX78Common.AddWX78ScreechStates(states)
SGWX78Common.AddWX78BakeState(states)

return StateGraph("wx78_possessedbody", states, events, "init", actionhandlers)