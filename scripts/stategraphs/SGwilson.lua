local function DoEquipmentFoleySounds(inst)
    for k, v in pairs(inst.components.inventory.equipslots) do
        if v.foleysound ~= nil then
            inst.SoundEmitter:PlaySound(v.foleysound, nil, nil, true)
        end
    end
end

local function DoFoleySounds(inst)
    DoEquipmentFoleySounds(inst)
    if inst.foleysound ~= nil then
        inst.SoundEmitter:PlaySound(inst.foleysound, nil, nil, true)
    end
end

local function DoMountedFoleySounds(inst)
    DoEquipmentFoleySounds(inst)
    local saddle = inst.components.rider ~= nil and inst.components.rider:GetSaddle() or nil
    if saddle ~= nil and saddle.mounted_foleysound ~= nil then
        inst.SoundEmitter:PlaySound(saddle.mounted_foleysound, nil, nil, true)
    end
end

local function DoHurtSound(inst)
    if inst.hurtsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/hurt")
    end
end

local function DoYawnSound(inst)
    if inst.yawnsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.yawnsoundoverride)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/yawn")
    end
end

local function DoTalkSound(inst)
    if inst.talksoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.talksoundoverride, "talk")
        return true
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/talk_LP", "talk")
        return true
    end
end

local function DoMountSound(inst, mount, sound, ispredicted)
    if mount ~= nil and mount.sounds ~= nil then
        inst.SoundEmitter:PlaySound(mount.sounds[sound], nil, nil, ispredicted)
    end
end

local function IsNearDanger(inst)
    local hounded = TheWorld.components.hounded
    if hounded ~= nil and (hounded:GetWarning() or hounded:GetAttacking()) then
        return true
    end
    local burnable = inst.components.burnable
    if burnable ~= nil and (burnable:IsBurning() or burnable:IsSmoldering()) then
        return true
    end
    -- See entityreplica.lua (for _combat tag usage)
    if inst:HasTag("spiderwhisperer") then
        --Danger if:
        -- being targetted
        -- OR near monster or pig that is neither player nor spider
        return FindEntity(inst, 10,
                function(target)
                    return (target.components.combat ~= nil and target.components.combat.target == inst)
                        or (not (target:HasTag("player") or target:HasTag("spider"))
                            and (target:HasTag("monster") or target:HasTag("pig")))
                end,
                nil, nil, { "monster", "pig", "_combat" }) ~= nil
    end
    --Danger if:
    -- being targetted
    -- OR near monster that is not player
    return FindEntity(inst, 10,
            function(target)
                return (target.components.combat ~= nil and target.components.combat.target == inst)
                    or (target:HasTag("monster") and not target:HasTag("player"))
            end,
            nil, nil, { "monster", "_combat" }) ~= nil
end

--V2C: This is for cleaning up interrupted states with legacy stuff, like
--     freeze and pinnable, that aren't consistently controlled by either
--     the stategraph or the component.
local function ClearStatusAilments(inst)
    if inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() then
        inst.components.freezable:Unfreeze()
    end
    if inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck() then
        inst.components.pinnable:Unstick()
    end
end

local function SetSleeperSleepState(inst)
    if inst.components.grue ~= nil then
        inst.components.grue:AddImmunity("sleeping")
    end
    if inst.components.talker ~= nil then
        inst.components.talker:IgnoreAll("sleeping")
    end
    if inst.components.firebug ~= nil then
        inst.components.firebug:Disable()
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(false)
        inst.components.playercontroller:Enable(false)
    end
    inst:OnSleepIn()
    inst.components.inventory:Hide()
    inst:PushEvent("ms_closepopups")
    inst:ShowActions(false)
end

local function SetSleeperAwakeState(inst)
    if inst.components.grue ~= nil then
        inst.components.grue:RemoveImmunity("sleeping")
    end
    if inst.components.talker ~= nil then
        inst.components.talker:StopIgnoringAll("sleeping")
    end
    if inst.components.firebug ~= nil then
        inst.components.firebug:Enable()
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:EnableMapControls(true)
        inst.components.playercontroller:Enable(true)
    end
    inst:OnWakeUp()
    inst.components.inventory:Show()
    inst:ShowActions(true)
end

local function DoEmoteFX(inst, prefab)
    local fx = SpawnPrefab(prefab)
    if fx ~= nil then
        if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
            fx.Transform:SetSixFaced()
        end
        fx.entity:SetParent(inst.entity)
        fx.entity:AddFollower()
        fx.Follower:FollowSymbol(inst.GUID, "emotefx", 0, 0, 0)
    end
end

local function DoEmoteSound(inst, soundname)
    inst.SoundEmitter:PlaySound(soundname, "emotesound")
end


local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end

local function GetUnequipState(inst, data)
    return (inst:HasTag("beaver") and "item_in")
        or (data.eslot ~= EQUIPSLOTS.HANDS and "item_hat")
        or (data.slip and "tool_slip")
        or "item_in"
end

local actionhandlers =
{
    ActionHandler(ACTIONS.CHOP,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end
            return not inst.sg:HasStateTag("prechop")
                and (inst.sg:HasStateTag("chopping") and
                    "chop" or
                    "chop_start")
                or nil
        end),
    ActionHandler(ACTIONS.MINE,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end
            return not inst.sg:HasStateTag("premine")
                and (inst.sg:HasStateTag("mining") and
                    "mine" or
                    "mine_start")
                or nil
        end),
    ActionHandler(ACTIONS.HAMMER,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end
            return not inst.sg:HasStateTag("prehammer")
                and (inst.sg:HasStateTag("hammering") and
                    "hammer" or
                    "hammer_start")
                or nil
        end),
    ActionHandler(ACTIONS.TERRAFORM, "terraform"),
    ActionHandler(ACTIONS.DIG,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end
            return not inst.sg:HasStateTag("predig")
                and (inst.sg:HasStateTag("digging") and
                    "dig" or
                    "dig_start")
                or nil
        end),
    ActionHandler(ACTIONS.NET,
        function(inst)
            return not inst.sg:HasStateTag("prenet")
                and (inst.sg:HasStateTag("netting") and
                    "bugnet" or
                    "bugnet_start")
                or nil
        end),
    ActionHandler(ACTIONS.FISH, "fishing_pre"),

    ActionHandler(ACTIONS.FERTILIZE, "doshortaction"),
    ActionHandler(ACTIONS.SMOTHER, "dolongaction"),
    ActionHandler(ACTIONS.MANUALEXTINGUISH, "dolongaction"),
    ActionHandler(ACTIONS.TRAVEL, "doshortaction"),
    ActionHandler(ACTIONS.LIGHT, "give"),
    ActionHandler(ACTIONS.UNLOCK, "give"),
    ActionHandler(ACTIONS.TURNOFF, "give"),
    ActionHandler(ACTIONS.TURNON, "give"),
    ActionHandler(ACTIONS.ADDFUEL, "doshortaction"),
    ActionHandler(ACTIONS.ADDWETFUEL, "doshortaction"),
    ActionHandler(ACTIONS.REPAIR, "dolongaction"),

    ActionHandler(ACTIONS.READ, "book"),

    ActionHandler(ACTIONS.MAKEBALLOON, "makeballoon"),
    ActionHandler(ACTIONS.DEPLOY, "doshortaction"),
    ActionHandler(ACTIONS.STORE, "doshortaction"),
    ActionHandler(ACTIONS.DROP, "doshortaction"),
    ActionHandler(ACTIONS.MURDER, "dolongaction"),
    ActionHandler(ACTIONS.UPGRADE, "dolongaction"),
    ActionHandler(ACTIONS.ACTIVATE,
        function(inst, action)
            return action.target.components.activatable ~= nil
                and (action.target.components.activatable.quickaction and
                    "doshortaction" or
                    "dolongaction")
                or nil
        end),
    ActionHandler(ACTIONS.PICK,
        function(inst, action)
            return action.target ~= nil
                and action.target.components.pickable ~= nil
                and (   (action.target.components.pickable.jostlepick and "dojostleaction") or
                        (action.target.components.pickable.quickpick and "doshortaction") or
                        "dolongaction"  )
                or nil
        end),

    ActionHandler(ACTIONS.SLEEPIN,
        function(inst, action)
            if action.invobject ~= nil then
                if action.invobject.onuse ~= nil then
                    action.invobject:onuse(inst)
                end
                return "bedroll"
            else
                return "tent"
            end
        end),

    ActionHandler(ACTIONS.TAKEITEM, "dolongaction"),

    ActionHandler(ACTIONS.BUILD, "dolongaction"),
    ActionHandler(ACTIONS.SHAVE, "shave"),
    ActionHandler(ACTIONS.COOK, "dolongaction"),
    ActionHandler(ACTIONS.FILL, "dolongaction"),
    ActionHandler(ACTIONS.PICKUP, "doshortaction"),
    ActionHandler(ACTIONS.CHECKTRAP, "doshortaction"),
    ActionHandler(ACTIONS.RUMMAGE, "doshortaction"),
    ActionHandler(ACTIONS.BAIT, "doshortaction"),
    ActionHandler(ACTIONS.HEAL, "dolongaction"),
    ActionHandler(ACTIONS.SEW, "dolongaction"),
    ActionHandler(ACTIONS.TEACH, "dolongaction"),
    ActionHandler(ACTIONS.RESETMINE, "dolongaction"),
    ActionHandler(ACTIONS.EAT,
        function(inst, action)
            if inst.sg:HasStateTag("busy") then
                return
            end
            local obj = action.target or action.invobject
            if obj == nil or obj.components.edible == nil then
                return
            elseif not inst.components.eater:PrefersToEat(obj) then
                inst:PushEvent("wonteatfood", { food = obj })
                return
            end
            return (inst:HasTag("beaver") and "beavereat")
                or (obj.components.edible.foodtype == FOODTYPE.MEAT and "eat")
                or "quickeat"
        end),
    ActionHandler(ACTIONS.GIVE, "give"),
    ActionHandler(ACTIONS.GIVETOPLAYER, "give"),
    ActionHandler(ACTIONS.GIVEALLTOPLAYER, "give"),
    ActionHandler(ACTIONS.FEEDPLAYER, "give"),
    ActionHandler(ACTIONS.PLANT, "doshortaction"),
    ActionHandler(ACTIONS.HARVEST, "dolongaction"),
    ActionHandler(ACTIONS.PLAY,
        function(inst, action)
            if action.invobject ~= nil then
                return (action.invobject:HasTag("flute") and "play_flute")
                    or (action.invobject:HasTag("horn") and "play_horn")
                    or (action.invobject:HasTag("bell") and "play_bell")
                    or nil
            end
        end),
    ActionHandler(ACTIONS.FAN, "use_fan"),
    ActionHandler(ACTIONS.JUMPIN, "jumpin_pre"),
    ActionHandler(ACTIONS.DRY, "doshortaction"),
    ActionHandler(ACTIONS.CASTSPELL,
        function(inst, action)
            return action.invobject ~= nil
                and action.invobject.components.spellcaster ~= nil
                and action.invobject.components.spellcaster.quickcast
                and "quickcastspell"
                or "castspell"
        end),
    ActionHandler(ACTIONS.BLINK, "quicktele"),
    ActionHandler(ACTIONS.COMBINESTACK, "doshortaction"),
    ActionHandler(ACTIONS.FEED, "dolongaction"),
    ActionHandler(ACTIONS.ATTACK,
        function(inst, action)
            inst.sg.mem.localchainattack = not action.forced or nil
            if not inst.components.health:IsDead() and not inst.sg:HasStateTag("attack") then
                local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil
                return (weapon == nil and "attack")
                    or (weapon:HasTag("blowdart") and "blowdart")
                    or (weapon:HasTag("thrown") and "throw")
                    or "attack"
            end
        end),
    ActionHandler(ACTIONS.TOSS, "throw"),
    ActionHandler(ACTIONS.UNPIN, "doshortaction"),
    ActionHandler(ACTIONS.CATCH, "catch_pre"),

    ActionHandler(ACTIONS.CHANGEIN, "usewardrobe"),
    ActionHandler(ACTIONS.WRITE, "doshortaction"),
    ActionHandler(ACTIONS.ATTUNE, "dolongaction"),
    ActionHandler(ACTIONS.MIGRATE, "migrate"),
    ActionHandler(ACTIONS.MOUNT, "doshortaction"),
    ActionHandler(ACTIONS.SADDLE, "doshortaction"),
    ActionHandler(ACTIONS.UNSADDLE, "unsaddle"),
    ActionHandler(ACTIONS.BRUSH, "dolongaction"),
}

local events =
{
    EventHandler("locomote", function(inst, data)
        if inst.sg:HasStateTag("busy") then
            return
        end
        local is_moving = inst.sg:HasStateTag("moving")
        local should_move = inst.components.locomotor:WantsToMoveForward()

        if inst.sg:HasStateTag("bedroll") or inst.sg:HasStateTag("tent") or inst.sg:HasStateTag("waking") then -- wakeup on locomote
            if inst.sleepingbag ~= nil and inst.sg:HasStateTag("sleeping") then
                inst.sleepingbag.components.sleepingbag:DoWakeUp()
                inst.sleepingbag = nil
            end
        elseif is_moving and not should_move then
            inst.sg:GoToState("run_stop")
        elseif not is_moving and should_move then
            inst.sg:GoToState("run_start")
        elseif data.force_idle_state and not (is_moving or should_move or inst.sg:HasStateTag("idle")) then
            inst.sg:GoToState("idle")
        end
    end),

    EventHandler("blocked", function(inst, data)
        if not inst.components.health:IsDead() then
            if inst.sg:HasStateTag("shell") then
                inst.sg:GoToState("shell_hit")
            end
        end
    end),

    EventHandler("attacked", function(inst, data)
        if not inst.components.health:IsDead() then
            if data.weapon ~= nil and data.weapon:HasTag("tranquilizer") and (inst.sg:HasStateTag("bedroll") or inst.sg:HasStateTag("knockout")) then
                return --Do nothing
            elseif inst.sg:HasStateTag("transform") or inst.sg:HasStateTag("dismounting") then
                -- don't interrupt transform or when bucked in the air
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                DoHurtSound(inst)
            elseif inst.sg:HasStateTag("sleeping") then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                DoHurtSound(inst)
                if inst.sleepingbag ~= nil then
                    inst.sleepingbag.components.sleepingbag:DoWakeUp()
                    inst.sleepingbag = nil
                else
                    inst.sg.statemem.iswaking = true
                    inst.sg:GoToState("wakeup")
                end
            elseif inst.sg:HasStateTag("shell") then
                inst.sg:GoToState("shell_hit")
            elseif inst:HasTag("pinned") then
                inst.sg:GoToState("pinned_hit")
            elseif data.stimuli == "darkness" then
                inst.sg:GoToState("hit_darkness")
            elseif data.stimuli == "electric" and not inst.components.inventory:IsInsulated() then
                inst.sg:GoToState("electrocute")
            else
                local stunlock = data.attacker ~= nil and data.attacker.components.combat
                        and data.attacker.components.combat.playerstunlock
                local stunoffset = inst.laststuntime and GetTime() - inst.laststuntime or 999
                if stunlock ~= nil
                    and (stunlock == PLAYERSTUNLOCK.NEVER
                         or (stunlock == PLAYERSTUNLOCK.RARELY and stunoffset < TUNING.STUNLOCK_TIMES.RARELY)
                         or (stunlock == PLAYERSTUNLOCK.SOMETIMES and stunoffset < TUNING.STUNLOCK_TIMES.SOMETIMES)
                         or (stunlock == PLAYERSTUNLOCK.OFTEN and stunoffset < TUNING.STUNLOCK_TIMES.OFTEN))
                    and (not inst.sg:HasStateTag("idle") or inst.sg.timeinstate == 0) then -- gjans: we transition to idle for 1 frame after being hit, hence the timeinstate check

                    -- don't go to full hit state, just play sounds
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                    DoHurtSound(inst)
                else
                    inst.laststuntime = GetTime()
                    inst.sg:GoToState("hit")
                end
            end
        end
    end),

    --For crafting, attunement cost, etc... Just go directly to hit.
    EventHandler("consumehealthcost", function(inst, data)
        if not inst.components.health:IsDead() then
            inst.sg:GoToState("hit")
        end
    end),

    EventHandler("equip", function(inst, data)
        if inst.sg:HasStateTag("idle") and not inst:HasTag("beaver") then
            inst.sg:GoToState(data.eslot == EQUIPSLOTS.HANDS and "item_out" or "item_hat")
        end
    end),

    EventHandler("unequip", function(inst, data)
        if inst.sg:HasStateTag("idle") then
            inst.sg:GoToState(GetUnequipState(inst, data))
        end
    end),

    EventHandler("death", function(inst)
        if inst.sleepingbag ~= nil and (inst.sg:HasStateTag("bedroll") or inst.sg:HasStateTag("tent")) then -- wakeup on death to "consume" sleeping bag first
            inst.sleepingbag.components.sleepingbag:DoWakeUp()
            inst.sleepingbag = nil
        end

        inst.sg:GoToState("death")
    end),

    EventHandler("ontalk", function(inst, data)
        if inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("notalking") then
            if inst:HasTag("mime") then
                inst.sg:GoToState("mime")
            else
                inst.sg:GoToState("talk", data.noanim)
            end
        end
    end),

    EventHandler("powerup",
        function(inst)
            inst.sg:GoToState("powerup")
        end),

    EventHandler("powerdown",
        function(inst)
            inst.sg:GoToState("powerdown")
        end),

    EventHandler("transform_werebeaver",
        function(inst, data)
            if inst.TransformBeaver ~= nil and not inst:HasTag("beaver") then
                inst.sg:GoToState("transform_werebeaver")
            end
        end),

    EventHandler("transform_person",
        function(inst, data)
            if inst.TransformBeaver ~= nil and inst:HasTag("beaver") then
                inst.sg:GoToState("transform_person")
            end
        end),

    EventHandler("toolbroke",
        function(inst, data)
            inst.sg:GoToState("toolbroke", data.tool)
        end),

    EventHandler("umbrellaranout",
        function(inst, data)
            if inst.components.inventory:GetEquippedItem(data.equipslot) == nil then
                local sameTool = inst.components.inventory:FindItem(function(item)
                    return item:HasTag("umbrella") and
                        item.components.equippable ~= nil and
                        item.components.equippable.equipslot == data.equipslot
                end)
                if sameTool ~= nil then
                    inst.components.inventory:Equip(sameTool)
                end
            end
        end),

    EventHandler("itemranout",
        function(inst, data)
            if inst.components.inventory:GetEquippedItem(data.equipslot) == nil then
                local sameTool = inst.components.inventory:FindItem(function(item)
                    return item.prefab == data.prefab and
                        item.components.equippable ~= nil and
                        item.components.equippable.equipslot == data.equipslot
                end)
                if sameTool ~= nil then
                    inst.components.inventory:Equip(sameTool)
                end
            end
        end),

    EventHandler("armorbroke",
        function(inst, data)
            inst.sg:GoToState("armorbroke", data.armor)
        end),

    EventHandler("fishingcancel",
        function(inst)
            if inst.sg:HasStateTag("fishing") then
                inst.sg:GoToState("fishing_pst")
            end
        end),
    EventHandler("knockedout",
        function(inst)
            if inst.sg:HasStateTag("knockout") then
                inst.sg.statemem.cometo = nil
            elseif not (inst.sg:HasStateTag("sleeping") or inst.sg:HasStateTag("bedroll") or inst.sg:HasStateTag("tent") or inst.sg:HasStateTag("waking")) then
                inst.sg:GoToState("knockout")
            end
        end),
    EventHandler("yawn", 
        function(inst, data)
            --NOTE: yawns DO knock you out of shell/bush hat
            --      yawns do NOT affect:
            --       sleeping
            --       frozen
            --       pinned
            if not (inst.components.health:IsDead() or
                    inst.sg:HasStateTag("sleeping") or
                    inst.sg:HasStateTag("frozen") or
                    inst:HasTag("pinned")) then
                inst.sg:GoToState("yawn", data)
            end
        end),
    EventHandler("emote",
        function(inst, data)
            if not (inst.sg:HasStateTag("busy") or
                    inst.sg:HasStateTag("nopredict") or
                    inst.sg:HasStateTag("sleeping"))
                and (data.mounted or not (inst.components.rider ~= nil and inst.components.rider:IsRiding()))
                and (data.beaver or not inst:HasTag("beaver")) then
                inst.sg:GoToState("emote", data)
            end
        end),
    EventHandler("pinned",
        function(inst, data)
            if inst.components.health ~= nil and not inst.components.health:IsDead() and inst.components.pinnable ~= nil then
                if inst.components.pinnable.canbepinned then
                    inst.sg:GoToState("pinned_pre", data)
                elseif inst.components.pinnable:IsStuck() then
                    --V2C: Since sg events are queued, it's possible we're no longer pinnable
                    inst.components.pinnable:Unstick()
                end
            end
        end),
    EventHandler("freeze",
        function(inst)
            if inst.components.health ~= nil and not inst.components.health:IsDead() then
                inst.sg:GoToState("frozen")
            end
        end),
    EventHandler("wonteatfood",
        function(inst)
            if inst.components.health ~= nil and not inst.components.health:IsDead() then
                inst.sg:GoToState("refuseeat")
            end
        end),
    EventHandler("ms_opengift",
        function(inst)
            if not inst.sg:HasStateTag("busy") then
                inst.sg:GoToState("opengift")
            end
        end),
    EventHandler("dismount",
        function(inst)
            if not inst.sg:HasStateTag("dismounting") and inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.sg:GoToState("dismount")
            end
        end),
    EventHandler("bucked",
        function(inst, data)
            if not inst.sg:HasStateTag("dismounting") and inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.sg:GoToState(data.gentle and "falloff" or "bucked")
            end
        end),
}

local statue_symbols =
{
    "ww_head",
    "ww_limb",
    "ww_meathand",
    "ww_shadow",
    "ww_torso",
    "frame",
    "rope_joints",
    "swap_grown"
}

local states = 
{
    State{
        name = "wakeup",
        tags = { "busy", "waking", "nomorph" },

        onenter = function(inst)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            if inst.AnimState:IsCurrentAnimation("bedroll") or
                inst.AnimState:IsCurrentAnimation("bedroll_sleep_loop") then
                inst.AnimState:PlayAnimation("bedroll_wakeup")
            elseif not (inst.AnimState:IsCurrentAnimation("bedroll_wakeup") or
                        inst.AnimState:IsCurrentAnimation("wakeup")) then
                inst.AnimState:PlayAnimation("wakeup")
            end
            if not inst:IsHUDVisible() then
                --Touch stone rez
                inst.sg.statemem.isresurrection = true
                inst.sg:AddStateTag("nopredict")
                inst.sg:AddStateTag("silentmorph")
                inst.sg:RemoveStateTag("nomorph")
                inst.components.health:SetInvincible(false)
                inst:ShowHUD(false)
                inst:SetCameraDistance(12)
            end
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
            SetSleeperAwakeState(inst)
            if inst.sg.statemem.isresurrection then
                --Touch stone rez
                inst:ShowHUD(true)
                inst:SetCameraDistance()
                SerializeUserSession(inst)
            end
        end,
    },

    State{
        name = "powerup",
        tags = { "busy", "pausepredict", "nomorph" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("powerup")

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
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
        name = "powerdown",
        tags = { "busy", "pausepredict", "nomorph" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("powerdown")

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
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
        name = "transform_werebeaver",
        tags = { "busy", "pausepredict", "transform", "nomorph" },

        onenter = function(inst)
            inst.Physics:Stop()

            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.sg:AddStateTag("dismounting")
                inst.AnimState:PlayAnimation("fall_off")
                inst.SoundEmitter:PlaySound("dontstarve/beefalo/saddle/dismount")
            else
                inst:SetCameraDistance(14)
                inst.AnimState:PlayAnimation("transform_pre")
                inst.components.inventory:DropEquipped(true)
            end

            inst.components.inventory:Close()
            inst:PushEvent("ms_closepopups")

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
                inst.components.playercontroller:Enable(false)
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.sg:HasStateTag("dismounting") then
                        inst.sg:RemoveStateTag("dismounting")
                        if inst.components.rider ~= nil then
                            inst.components.rider:ActualDismount()
                        end
                        inst:SetCameraDistance(14)
                        inst.AnimState:PlayAnimation("transform_pre")
                        inst.components.inventory:DropEquipped(true)
                    elseif inst.TransformBeaver == nil or inst:HasTag("beaver") then
                        inst.sg:GoToState("idle")
                    else
                        inst:TransformBeaver(true)
                        inst.AnimState:PlayAnimation("transform_pst")
                        SpawnPrefab("werebeaver_transform_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
                        inst:SetCameraDistance()
                        inst.sg:RemoveStateTag("transform")
                    end
                end
            end),
        },

        onexit = function(inst)
            if inst.sg:HasStateTag("dismounting") then
                --interrupted
                if inst.components.rider ~= nil then
                    inst.components.rider:ActualDismount()
                end
            elseif inst.sg:HasStateTag("transform") then
                --interrupted
                inst:SetCameraDistance()
            end
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
        end,
    },

    State{
        name = "transform_person",
        tags = { "busy", "pausepredict", "transform", "nomorph" },

        onenter = function(inst)
            inst:SetCameraDistance(14)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("transform_pre")

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
                inst.components.playercontroller:Enable(false)
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.TransformBeaver ~= nil and inst:HasTag("beaver") then
                        inst:TransformBeaver(false)
                        inst.AnimState:PlayAnimation("transform_pst")
                        SpawnPrefab("werebeaver_transform_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
                        inst.components.inventory:Open()
                        inst:SetCameraDistance()
                        inst.sg:RemoveStateTag("transform")
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end),
        },

        onexit = function(inst)
            inst.components.inventory:Open()
            inst:SetCameraDistance()
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
        end,
    },

    State{
        name = "electrocute",
        tags = { "busy", "pausepredict" },

        onenter = function(inst)
            ClearStatusAilments(inst)

            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.fx = SpawnPrefab("shock_fx")
            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.fx.Transform:SetSixFaced()
            end
            inst.fx.entity:SetParent(inst.entity)
            inst.fx.entity:AddFollower()
            inst.fx.Follower:FollowSymbol(inst.GUID, "swap_shock_fx", 0, 0, 0)

            if not inst:HasTag("electricdamageimmune") then
                inst.components.bloomer:PushBloom("electrocute", "shaders/anim.ksh", -2)
                inst.Light:Enable(true)
            end

            inst.AnimState:PlayAnimation("shock")
            inst.AnimState:PushAnimation("shock_pst", false)

            DoHurtSound(inst)

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
            inst.sg:SetTimeout(8 * FRAMES + inst.AnimState:GetCurrentAnimationLength())
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.fx ~= nil then
                    if not inst:HasTag("electricdamageimmune") then
                        inst.Light:Enable(false)
                        inst.components.bloomer:PopBloom("electrocute")
                    end
                    inst.fx:Remove()
                    inst.fx = nil
                end
            end),

            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            if inst.fx ~= nil then
                if not inst:HasTag("electricdamageimmune") then
                    inst.Light:Enable(false)
                    inst.components.bloomer:PopBloom("electrocute")
                end
                inst.fx:Remove()
                inst.fx = nil
            end
        end,
    },

    State{
        name = "rebirth",
        tags = { "nopredict", "silentmorph" },

        onenter = function(inst)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            inst.AnimState:PlayAnimation("rebirth")
            
            for k,v in pairs(statue_symbols) do
                inst.AnimState:OverrideSymbol(v, "wilsonstatue", v)
            end

            inst.components.health:SetInvincible(true)
            inst:ShowHUD(false)
            inst:SetCameraDistance(12)
        end,

        timeline =
        {
            TimeEvent(16*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/common/dropwood")
            end),
            TimeEvent(45*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/common/dropwood")
            end),
            TimeEvent(92*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/common/rebirth")
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
            for k, v in pairs(statue_symbols) do
                inst.AnimState:ClearOverrideSymbol(v)
            end

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end

            inst.components.health:SetInvincible(false)
            inst:ShowHUD(true)
            inst:SetCameraDistance()

            SerializeUserSession(inst)
        end,
    },

    State{
        name = "death",
        tags = { "busy", "pausepredict", "nomorph" },

        onenter = function(inst)
            assert(inst.deathcause ~= nil, "Entered death state without cause.")

            ClearStatusAilments(inst)

            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                DoMountSound(inst, inst.components.rider:GetMount(), "yell")
                inst.AnimState:PlayAnimation("fall_off")
                inst.sg:AddStateTag("dismounting")
            else
                inst.SoundEmitter:PlaySound("dontstarve/wilson/death")

                if not inst:HasTag("mime") then
                    inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/death_voice")
                end

                if HUMAN_MEAT_ENABLED then
                    inst.components.inventory:GiveItem(SpawnPrefab("humanmeat")) -- Drop some player meat!
                end
                inst.components.inventory:DropEverything(true)

                inst.AnimState:Hide("swap_arm_carry")
                inst.AnimState:PlayAnimation("death")
            end

            inst.components.burnable:Extinguish()

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
                inst.components.playercontroller:Enable(false)
            end

            --Don't process other queued events if we died this frame
            inst.sg:ClearBufferedEvents()
        end,

        onexit = function(inst)
            --You should never leave this state once you enter it!
            assert(false, "Left death state.")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.sg:HasStateTag("dismounting") then
                        inst.sg:RemoveStateTag("dismounting")
                        if inst.components.rider ~= nil then
                            inst.components.rider:ActualDismount()
                        end

                        inst.SoundEmitter:PlaySound("dontstarve/wilson/death")

                        if not inst:HasTag("mime") then
                            inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/death_voice")
                        end

                        if HUMAN_MEAT_ENABLED then
                            inst.components.inventory:GiveItem(SpawnPrefab("humanmeat")) -- Drop some player meat!
                        end
                        inst.components.inventory:DropEverything(true)

                        inst.AnimState:Hide("swap_arm_carry")
                        inst.AnimState:PlayAnimation("death")
                    else
                        inst:PushEvent(inst.ghostenabled and "makeplayerghost" or "playerdied", { skeleton = true })
                    end
                end
            end),
        },
    },

    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst, pushanim)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()

            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.sg:GoToState("mounted_idle", pushanim)
                return
            end

            local equippedArmor = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
            if equippedArmor ~= nil and equippedArmor:HasTag("band") then
                inst.sg:GoToState("enter_onemanband", pushanim)
                return
            end

            local anims = {}
            local dofunny = true

            if inst:HasTag("beaver") then
                if inst:HasTag("groggy") then
                    table.insert(anims, "idle_groggy_pre")
                    table.insert(anims, "idle_groggy")
                else
                    table.insert(anims, "idle_loop")
                end
                dofunny = false
            elseif not inst.components.sanity:IsSane() then
                table.insert(anims, "idle_sanity_pre")
                table.insert(anims, "idle_sanity_loop")
            elseif inst.components.temperature:IsFreezing() then
                table.insert(anims, "idle_shiver_pre")
                table.insert(anims, "idle_shiver_loop")
            elseif inst.components.temperature:IsOverheating() then
                table.insert(anims, "idle_hot_pre")
                table.insert(anims, "idle_hot_loop")
                dofunny = false
            elseif inst:HasTag("groggy") then
                table.insert(anims, "idle_groggy_pre")
                table.insert(anims, "idle_groggy")
            else
                table.insert(anims, "idle_loop")
            end

            if pushanim then
                for k, v in pairs(anims) do
                    inst.AnimState:PushAnimation(v, k == #anims)
                end
            else
                inst.AnimState:PlayAnimation(anims[1], #anims == 1)
                for k, v in pairs(anims) do
                    if k > 1 then
                        inst.AnimState:PushAnimation(v, k == #anims)
                    end
                end
            end

            if dofunny then
                inst.sg:SetTimeout(math.random() * 4 + 2)
            end
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("funnyidle")
        end,
    },

    State{
        name = "funnyidle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            if inst.components.temperature:GetCurrent() < 5 then
                inst.AnimState:PlayAnimation("idle_shiver_pre")
                inst.AnimState:PushAnimation("idle_shiver_loop")
                inst.AnimState:PushAnimation("idle_shiver_pst", false)
            elseif inst.components.temperature:GetCurrent() > TUNING.OVERHEAT_TEMP - 10 then
                inst.AnimState:PlayAnimation("idle_hot_pre")
                inst.AnimState:PushAnimation("idle_hot_loop")
                inst.AnimState:PushAnimation("idle_hot_pst", false)
            elseif inst.components.hunger:GetPercent() < TUNING.HUNGRY_THRESH then
                inst.AnimState:PlayAnimation("hungry")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hungry")    
            elseif inst.components.sanity:GetPercent() < .5 then
                inst.AnimState:PlayAnimation("idle_inaction_sanity")
            elseif inst:HasTag("groggy") then
                inst.AnimState:PlayAnimation("idle_groggy01_pre")
                inst.AnimState:PushAnimation("idle_groggy01_loop")
                inst.AnimState:PushAnimation("idle_groggy01_pst", false)
            else
                inst.AnimState:PlayAnimation("idle_inaction")
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
        name = "mounted_idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst, pushanim)
            local equippedArmor = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
            if equippedArmor ~= nil and equippedArmor:HasTag("band") then
                inst.sg:GoToState("enter_onemanband", pushanim)
                return
            end

            if pushanim then
                inst.AnimState:PushAnimation("idle_loop", true)
            else
                inst.AnimState:PlayAnimation("idle_loop", true)
            end

            inst.sg:SetTimeout(2 + math.random() * 8)
        end,

        ontimeout = function(inst)
            local mount = inst.components.rider ~= nil and inst.components.rider:GetMount() or nil
            if mount == nil then
                inst.sg:GoToState("idle")
            elseif mount.components.hunger == nil then
                inst.sg:GoToState(math.random() < .5 and "shake" or "bellow")
            else
                local rand = math.random()
                inst.sg:GoToState(
                    (rand < .25 and "shake") or
                    (rand < .5 and "bellow") or
                    (inst.components.hunger:IsStarving() and "graze_empty" or "graze")
                )
            end
        end,
    },

    State{
        name = "graze",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("graze_loop", true)
            inst.sg:SetTimeout(1 + math.random() * 5)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("mounted_idle")
        end,
    },

    State{
        name = "graze_empty",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("graze2_pre")
            inst.AnimState:PushAnimation("graze2_loop")
            inst.sg:SetTimeout(1 + math.random() * 5)
        end,

        ontimeout = function(inst)
            inst.AnimState:PlayAnimation("graze2_pst")
            inst.sg:GoToState("mounted_idle", true)
        end,
    },

    State{
        name = "bellow",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("bellow")
            if inst.components.rider ~= nil then
                DoMountSound(inst, inst.components.rider:GetMount(), "grunt")
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("mounted_idle")
                end
            end),
        },
    },

    State{
        name = "shake",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("shake")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("mounted_idle")
                end
            end),
        },
    },

    State{
        name = "chop_start",
        tags = { "prechop", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation(inst:HasTag("woodcutter") and "woodie_chop_pre" or "chop_pre")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("chop")
                end
            end),
        },
    },

    State{
        name = "chop",
        tags = { "prechop", "chopping", "working" },

        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.sg.statemem.iswoodcutter = inst:HasTag("woodcutter")
            inst.AnimState:PlayAnimation(inst.sg.statemem.iswoodcutter and "woodie_chop_loop" or "chop_loop")
        end,

        timeline =
        {
            ----------------------------------------------
            --Woodcutter chop

            TimeEvent(2 * FRAMES, function(inst) 
                if inst.sg.statemem.iswoodcutter then
                    inst:PerformBufferedAction() 
                end
            end),

            TimeEvent(5 * FRAMES, function(inst)
                if inst.sg.statemem.iswoodcutter then
                    inst.sg:RemoveStateTag("prechop")
                end
            end),

            TimeEvent(10 * FRAMES, function(inst)
                if inst.sg.statemem.iswoodcutter and
                    inst.components.playercontroller ~= nil and
                    inst.components.playercontroller:IsAnyOfControlsPressed(
                        CONTROL_PRIMARY,
                        CONTROL_ACTION,
                        CONTROL_CONTROLLER_ACTION) and
                    inst.sg.statemem.action ~= nil and
                    inst.sg.statemem.action:IsValid() and
                    inst.sg.statemem.action.target ~= nil and
                    inst.sg.statemem.action.target.components.workable ~= nil and
                    inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                    inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) then
                    inst:ClearBufferedAction()
                    inst:PushBufferedAction(inst.sg.statemem.action)
                end
            end),

            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.iswoodcutter then
                    inst.sg:RemoveStateTag("chopping")
                end
            end),

            ----------------------------------------------
            --Normal chop

            TimeEvent(2 * FRAMES, function(inst)
                if not inst.sg.statemem.iswoodcutter then
                    inst:PerformBufferedAction()
                end
            end),

            TimeEvent(9 * FRAMES, function(inst)
                if not inst.sg.statemem.iswoodcutter then
                    inst.sg:RemoveStateTag("prechop")
                end
            end),

            TimeEvent(14 * FRAMES, function(inst)
                if not inst.sg.statemem.iswoodcutter and
                    inst.components.playercontroller ~= nil and
                    inst.components.playercontroller:IsAnyOfControlsPressed(
                        CONTROL_PRIMARY,
                        CONTROL_ACTION,
                        CONTROL_CONTROLLER_ACTION) and
                    inst.sg.statemem.action ~= nil and
                    inst.sg.statemem.action:IsValid() and
                    inst.sg.statemem.action.target ~= nil and
                    inst.sg.statemem.action.target.components.workable ~= nil and
                    inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                    inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) then
                    inst:ClearBufferedAction()
                    inst:PushBufferedAction(inst.sg.statemem.action)
                end
            end),

            TimeEvent(16 * FRAMES, function(inst) 
                if not inst.sg.statemem.iswoodcutter then
                    inst.sg:RemoveStateTag("chopping")
                end
            end),
        },

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    --We don't have a chop_pst animation
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "mine_start",
        tags = { "premine", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickaxe_pre")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("mine")
                end
            end),
        },
    },

    State{
        name = "mine",
        tags = { "premine", "mining", "working" },

        onenter = function(inst)
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("pickaxe_loop")
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                if inst.sg.statemem.action ~= nil then
                    local target = inst.sg.statemem.action.target
                    if target ~= nil and target:IsValid() then
                        local frozen = target:HasTag("frozen")
                        if target.Transform ~= nil then
                            SpawnPrefab(frozen and "mining_ice_fx" or "mining_fx").Transform:SetPosition(target.Transform:GetWorldPosition())
                        end
                        inst.SoundEmitter:PlaySound(frozen and "dontstarve_DLC001/common/iceboulder_hit" or "dontstarve/wilson/use_pick_rock")
                    end
                end
                inst:PerformBufferedAction()
            end),

            TimeEvent(9 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("premine")
            end),

            TimeEvent(14 * FRAMES, function(inst)
                if inst.components.playercontroller ~= nil and
                    inst.components.playercontroller:IsAnyOfControlsPressed(
                        CONTROL_PRIMARY,
                        CONTROL_ACTION,
                        CONTROL_CONTROLLER_ACTION) and
                    inst.sg.statemem.action ~= nil and
                    inst.sg.statemem.action:IsValid() and
                    inst.sg.statemem.action.target ~= nil and
                    inst.sg.statemem.action.target.components.workable ~= nil and
                    inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                    inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action) then
                    inst:ClearBufferedAction()
                    inst:PushBufferedAction(inst.sg.statemem.action)
                end
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
            TimeEvent(7 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("prehammer")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
            end),

            TimeEvent(9 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("prehammer")
            end),

            TimeEvent(14 * FRAMES, function(inst)
                if inst.components.playercontroller ~= nil and
                    inst.components.playercontroller:IsAnyOfControlsPressed(
                        CONTROL_SECONDARY,
                        CONTROL_ACTION,
                        CONTROL_CONTROLLER_ALTACTION) and
                    inst.sg.statemem.action ~= nil and
                    inst.sg.statemem.action:IsValid() and
                    inst.sg.statemem.action.target ~= nil and
                    inst.sg.statemem.action.target.components.workable ~= nil and
                    inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                    inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action, true) then
                    inst:ClearBufferedAction()
                    inst:PushBufferedAction(inst.sg.statemem.action)
                end
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
        name = "gnaw",
        tags = { "gnawing", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.sg.statemem.action = inst:GetBufferedAction()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
                if inst.sg.statemem.action ~= nil then
                    local target = inst.sg.statemem.action.target
                    if target ~= nil and target:IsValid() then
                        if inst.sg.statemem.action.action == ACTIONS.MINE then
                            SpawnPrefab("mining_fx").Transform:SetPosition(target.Transform:GetWorldPosition())
                            inst.SoundEmitter:PlaySound(target:HasTag("frozen") and "dontstarve_DLC001/common/iceboulder_hit" or "dontstarve/wilson/use_pick_rock")
                        elseif inst.sg.statemem.action.action == ACTIONS.HAMMER then
                            inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                        elseif inst.sg.statemem.action.action == ACTIONS.DIG then
                            SpawnPrefab("shovel_dirt").Transform:SetPosition(target.Transform:GetWorldPosition())
                        end
                    end
                end
                inst:PerformBufferedAction()
            end),

            TimeEvent(7 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("gnawing")
            end),
            
            TimeEvent(8 * FRAMES, function(inst)
                if inst.sg.statemem.action == nil or
                    inst.sg.statemem.action.action == nil or
                    inst.components.playercontroller == nil then
                    return
                end
                local rmb = inst.sg.statemem.action.action == ACTIONS.HAMMER
                if rmb then
                    if not inst.components.playercontroller:IsAnyOfControlsPressed(
                            CONTROL_SECONDARY,
                            CONTROL_CONTROLLER_ALTACTION) then
                        return
                    end
                elseif not inst.components.playercontroller:IsAnyOfControlsPressed(
                            CONTROL_PRIMARY,
                            CONTROL_ACTION,
                            CONTROL_CONTROLLER_ACTION) then
                    return
                end
                if inst.sg.statemem.action:IsValid() and
                    inst.sg.statemem.action.target ~= nil and
                    inst.sg.statemem.action.target.components.workable ~= nil and
                    inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                    inst.sg.statemem.action.target.components.workable:GetWorkAction() == inst.sg.statemem.action.action then
                    inst:ClearBufferedAction()
                    inst:PushBufferedAction(inst.sg.statemem.action)
                end
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
        name = "hide",
        tags = { "hiding", "notalking", "notarget", "nomorph", "busy", "nopredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("hide")
            inst.AnimState:PushAnimation("hide_idle", false)
            inst.SoundEmitter:PlaySound("dontstarve/movement/foley/hidebush")
        end,

        timeline =
        {
            TimeEvent(24 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("nopredict")
                inst.sg:AddStateTag("idle")
            end),
        },

        events =
        {
            EventHandler("ontalk", function(inst)
                inst.AnimState:PushAnimation("hide_idle", false)

                if inst.sg.statemem.talktask ~= nil then
                    inst.sg.statemem.talktask:Cancel()
                    inst.sg.statemem.talktask = nil
                    inst.SoundEmitter:KillSound("talk")
                end
                if DoTalkSound(inst) then
                    inst.sg.statemem.talktask =
                        inst:DoTaskInTime(1.5 + math.random() * .5,
                            function()
                                inst.SoundEmitter:KillSound("talk")
                                inst.sg.statemem.talktask = nil
                            end)
                end
            end),
            EventHandler("donetalking", function(inst)
                if inst.sg.statemem.talktalk ~= nil then
                    inst.sg.statemem.talktask:Cancel()
                    inst.sg.statemem.talktask = nil
                    inst.SoundEmitter:KillSound("talk")
                end
            end),
            EventHandler("unequip", function(inst, data)
                -- We need to handle this during the initial "busy" frames
                if not inst.sg:HasStateTag("idle") then
                    inst.sg:GoToState(GetUnequipState(inst, data))
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.talktask ~= nil then
                inst.sg.statemem.talktask:Cancel()
                inst.sg.statemem.talktask = nil
                inst.SoundEmitter:KillSound("talk")
            end
        end,
    },

    State{
        name = "shell_enter",
        tags = { "hiding", "notalking", "shell", "nomorph", "busy", "nopredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("hideshell")

            inst.sg:SetTimeout(23 * FRAMES)
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/movement/foley/hideshell")
            end),
        },

        events =
        {
            EventHandler("ontalk", function(inst)
                if inst.sg.statemem.talktask ~= nil then
                    inst.sg.statemem.talktask:Cancel()
                    inst.sg.statemem.talktask = nil
                    inst.SoundEmitter:KillSound("talk")
                end
                if DoTalkSound(inst) then
                    inst.sg.statemem.talktask =
                        inst:DoTaskInTime(1.5 + math.random() * .5,
                            function()
                                inst.SoundEmitter:KillSound("talk")
                                inst.sg.statemem.talktask = nil
                            end)
                end
            end),
            EventHandler("donetalking", function(inst)
                if inst.sg.statemem.talktalk ~= nil then
                    inst.sg.statemem.talktask:Cancel()
                    inst.sg.statemem.talktask = nil
                    inst.SoundEmitter:KillSound("talk")
                end
            end),
            EventHandler("unequip", function(inst, data)
                -- We need to handle this because the default unequip
                -- handler is ignored while we are in a "busy" state.
                inst.sg:GoToState(GetUnequipState(inst, data))
            end),
        },

        ontimeout = function(inst)
            --Transfer talk task to shell_idle state
            local talktask = inst.sg.statemem.talktask
            inst.sg.statemem.talktask = nil
            inst.sg:GoToState("shell_idle", talktask)
        end,

        onexit = function(inst)
            if inst.sg.statemem.talktask ~= nil then
                inst.sg.statemem.talktask:Cancel()
                inst.sg.statemem.talktask = nil
                inst.SoundEmitter:KillSound("talk")
            end
        end,
    },

    State{
        name = "shell_idle",
        tags = { "hiding", "notalking", "shell", "nomorph", "idle" },

        onenter = function(inst, talktask)
            inst.components.locomotor:Stop()
            inst.AnimState:PushAnimation("hideshell_idle", false)

            --Transferred over from shell_idle so it doesn't cut off abrubtly
            inst.sg.statemem.talktask = talktask
        end,

        events =
        {
            EventHandler("ontalk", function(inst)
                inst.AnimState:PushAnimation("hitshell")
                inst.AnimState:PushAnimation("hideshell_idle", false)

                if inst.sg.statemem.talktask ~= nil then
                    inst.sg.statemem.talktask:Cancel()
                    inst.sg.statemem.talktask = nil
                    inst.SoundEmitter:KillSound("talk")
                end
                if DoTalkSound(inst) then
                    inst.sg.statemem.talktask =
                        inst:DoTaskInTime(1.5 + math.random() * .5,
                            function()
                                inst.SoundEmitter:KillSound("talk")
                                inst.sg.statemem.talktask = nil
                            end)
                end
            end),
            EventHandler("donetalking", function(inst)
                if inst.sg.statemem.talktalk ~= nil then
                    inst.sg.statemem.talktask:Cancel()
                    inst.sg.statemem.talktask = nil
                    inst.SoundEmitter:KillSound("talk")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.talktask ~= nil then
                inst.sg.statemem.talktask:Cancel()
                inst.sg.statemem.talktask = nil
                inst.SoundEmitter:KillSound("talk")
            end
        end,
    },

    State{
        name = "shell_hit",
        tags = { "hiding", "shell", "nomorph", "busy", "pausepredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:PlayAnimation("hitshell")

            inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")

            local stun_frames = 3
            if inst.components.playercontroller ~= nil then
                --Specify min frames of pause since "busy" tag may be
                --removed too fast for our network update interval.
                inst.components.playercontroller:RemotePausePrediction(stun_frames)
            end
            inst.sg:SetTimeout(stun_frames * FRAMES)
        end,

        events =
        {
            EventHandler("unequip", function(inst, data)
                -- We need to handle this because the default unequip
                -- handler is ignored while we are in a "busy" state.
                inst.sg.statemem.unequipped = true
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState(inst.sg.statemem.unequipped and "idle" or "shell_idle")
        end,
    },

    State
    {
        name = "terraform",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("shovel_pre")
            inst.AnimState:PushAnimation("shovel_loop", false)
        end,

        timeline =
        {
            TimeEvent(25 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("busy")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
            end),
        },

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("shovel_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },

    State{
        name = "dig_start",
        tags = { "predig", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("shovel_pre")
        end,

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
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
            inst.AnimState:PlayAnimation("shovel_loop")
            inst.sg.statemem.action = inst:GetBufferedAction()
        end,

        timeline =
        {
            TimeEvent(15 * FRAMES, function(inst)
                inst:PerformBufferedAction() 
                inst.sg:RemoveStateTag("predig") 
                inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
            end),

            TimeEvent(35 * FRAMES, function(inst)
                if inst.components.playercontroller ~= nil and
                    inst.components.playercontroller:IsAnyOfControlsPressed(
                        CONTROL_SECONDARY,
                        CONTROL_ACTION,
                        CONTROL_CONTROLLER_ACTION) and
                    inst.sg.statemem.action ~= nil and
                    inst.sg.statemem.action:IsValid() and
                    inst.sg.statemem.action.target ~= nil and
                    inst.sg.statemem.action.target.components.workable ~= nil and
                    inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                    inst.sg.statemem.action.target:IsActionValid(inst.sg.statemem.action.action, true) then
                    inst:ClearBufferedAction()
                    inst:PushBufferedAction(inst.sg.statemem.action)
                end
            end),
        },

        events =
        {
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.AnimState:PlayAnimation("shovel_pst") 
                    inst.sg:GoToState("idle", true)
                end
            end),
        },
    },

    State{
        name = "bugnet_start",
        tags = { "prenet", "working", "autopredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("bugnet_pre")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("bugnet")
                end
            end),
        },
    },

    State{
        name = "bugnet",
        tags = { "prenet", "netting", "working", "autopredict" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("bugnet")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_bugnet", nil, nil, true)
        end,

        timeline =
        {
            TimeEvent(10*FRAMES, function(inst) 
                inst:PerformBufferedAction() 
                inst.sg:RemoveStateTag("prenet") 
                inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
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
        name = "fishing_pre",
        tags = { "prefish", "fishing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("fishing_pre")
            inst.AnimState:PushAnimation("fishing_cast", false)
        end,

        timeline =
        {
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_cast") end),
            TimeEvent(15*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_baitsplash")
                    inst.sg:GoToState("fishing")
                end
            end),
        },
    },

    State{
        name = "fishing",
        tags = { "fishing" },

        onenter = function(inst, pushanim)
            if pushanim then
                if type(pushanim) == "string" then
                    inst.AnimState:PlayAnimation(pushanim)
                end
                inst.AnimState:PushAnimation("fishing_idle", true)
            else
                inst.AnimState:PlayAnimation("fishing_idle", true)
            end
            local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equippedTool and equippedTool.components.fishingrod then
                equippedTool.components.fishingrod:WaitForFish()
            end
        end,

        events =
        {
            EventHandler("fishingnibble", function(inst) inst.sg:GoToState("fishing_nibble") end),
        },
    },

    State{
        name = "fishing_pst",
        tags = {},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("fishing_pst")
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
        name = "fishing_nibble",
        tags = { "fishing", "nibble" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("bite_light_pre")
            inst.AnimState:PushAnimation("bite_light_loop", true)
            inst.sg:SetTimeout(1 + math.random())
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishinwater", "splash")
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("fishing", "bite_light_pst")
        end,

        events =
        {
            EventHandler("fishingstrain", function(inst) inst.sg:GoToState("fishing_strain") end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("splash")
        end,
    },

    State{
        name = "fishing_strain",
        tags = { "fishing" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("bite_heavy_pre")
            inst.AnimState:PushAnimation("bite_heavy_loop", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishinwater", "splash")
            inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_strain", "strain")
        end,

        events =
        {
            EventHandler("fishingcatch", function(inst, data)
                inst.sg:GoToState("catchfish", data.build)
            end),
            EventHandler("fishingloserod", function(inst)
                inst.sg:GoToState("loserod")
            end),

        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("splash")
            inst.SoundEmitter:KillSound("strain")
        end,
    },

    State{
        name = "catchfish",
        tags = { "fishing", "catchfish", "busy" },

        onenter = function(inst, build)
            inst.AnimState:PlayAnimation("fish_catch")
            --print("Using ", build, " to swap out fish01")
            inst.AnimState:OverrideSymbol("fish01", build, "fish01")
            
            -- inst.AnimState:OverrideSymbol("fish_body", build, "fish_body")
            -- inst.AnimState:OverrideSymbol("fish_eye", build, "fish_eye")
            -- inst.AnimState:OverrideSymbol("fish_fin", build, "fish_fin")
            -- inst.AnimState:OverrideSymbol("fish_head", build, "fish_head")
            -- inst.AnimState:OverrideSymbol("fish_mouth", build, "fish_mouth")
            -- inst.AnimState:OverrideSymbol("fish_tail", build, "fish_tail")
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishcaught") end),
            TimeEvent(10*FRAMES, function(inst) inst.sg:RemoveStateTag("fishing") end),
            TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_fishland") end),
            TimeEvent(24*FRAMES, function(inst)
                local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if equippedTool and equippedTool.components.fishingrod then
                    equippedTool.components.fishingrod:Collect()
                end
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
            inst.AnimState:ClearOverrideSymbol("fish01")
            -- inst.AnimState:ClearOverrideSymbol("fish_body")
            -- inst.AnimState:ClearOverrideSymbol("fish_eye")
            -- inst.AnimState:ClearOverrideSymbol("fish_fin")
            -- inst.AnimState:ClearOverrideSymbol("fish_head")
            -- inst.AnimState:ClearOverrideSymbol("fish_mouth")
            -- inst.AnimState:ClearOverrideSymbol("fish_tail")
        end,
    },

    State{
        name = "loserod",
        tags = { "busy", "nopredict" },

        onenter = function(inst)
            local equippedTool = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equippedTool and equippedTool.components.fishingrod then
                equippedTool.components.fishingrod:Release()
                equippedTool:Remove()
            end
            inst.AnimState:PlayAnimation("fish_nocatch")
        end,

        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_lostrod") end),
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
        name = "eat",
        tags = { "busy" },

        onenter = function(inst, foodinfo)
            inst.components.locomotor:Stop()

            local feed = foodinfo and foodinfo.feed
            if feed ~= nil then
                inst.components.locomotor:Clear()
                inst:ClearBufferedAction()
                inst.sg.statemem.feed = foodinfo.feed
                inst.sg.statemem.feeder = foodinfo.feeder
                inst.sg:AddStateTag("pausepredict")
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
            elseif inst:GetBufferedAction() then
                feed = inst:GetBufferedAction().invobject
            end

            if feed == nil or
                feed.components.edible == nil or
                feed.components.edible.foodtype ~= FOODTYPE.GEARS then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/eat", "eating")
            end
            
            inst.AnimState:PlayAnimation("eat_pre")
            inst.AnimState:PushAnimation("eat", false)

            inst.components.hunger:Pause()
        end,

        timeline =
        {
            TimeEvent(28 * FRAMES, function(inst)
                if inst.sg.statemem.feed ~= nil then
                    inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                else
                    inst:PerformBufferedAction() 
                end
            end),

            TimeEvent(30 * FRAMES, function(inst) 
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("pausepredict")
            end),

            TimeEvent(70 * FRAMES, function(inst) 
                inst.SoundEmitter:KillSound("eating")    
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("eating")
            inst.components.hunger:Resume()
            if inst.sg.statemem.feed ~= nil and inst.sg.statemem.feed:IsValid() then
                inst.sg.statemem.feed:Remove()
            end
        end,
    },

    State{
        name = "quickeat",
        tags = { "busy" },

        onenter = function(inst, foodinfo)
            inst.components.locomotor:Stop()

            local feed = foodinfo and foodinfo.feed
            if feed ~= nil then
                inst.components.locomotor:Clear()
                inst:ClearBufferedAction()
                inst.sg.statemem.feed = foodinfo.feed
                inst.sg.statemem.feeder = foodinfo.feeder
                inst.sg:AddStateTag("pausepredict")
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
            elseif inst:GetBufferedAction() then
                feed = inst:GetBufferedAction().invobject
            end

            if feed == nil or
                feed.components.edible == nil or
                feed.components.edible.foodtype ~= FOODTYPE.GEARS then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/eat", "eating")
            end

            inst.AnimState:PlayAnimation("quick_eat_pre")
            inst.AnimState:PushAnimation("quick_eat", false)

            inst.components.hunger:Pause()
        end,

        timeline =
        {
            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.feed ~= nil then
                    inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                else
                    inst:PerformBufferedAction()
                end
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("pausepredict")
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("eating")
            inst.components.hunger:Resume()
            if inst.sg.statemem.feed ~= nil and inst.sg.statemem.feed:IsValid() then
                inst.sg.statemem.feed:Remove()
            end
        end,
    },

    State{
        name = "beavereat",
        tags = { "busy" },

        onenter = function(inst, foodinfo)
            inst.components.locomotor:Stop()

            local feed = foodinfo and foodinfo.feed
            if feed ~= nil then
                inst.components.locomotor:Clear()
                inst:ClearBufferedAction()
                inst.sg.statemem.feed = foodinfo.feed
                inst.sg.statemem.feeder = foodinfo.feeder
                inst.sg:AddStateTag("pausepredict")
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                end
            end

            inst.SoundEmitter:PlaySound("dontstarve/characters/woodie/eat_beaver")

            inst.AnimState:PlayAnimation("eat_pre")
            inst.AnimState:PushAnimation("eat", false)
        end,

        timeline =
        {
            TimeEvent(9 * FRAMES, function(inst)
                if inst.sg.statemem.feed ~= nil then
                    inst.components.eater:Eat(inst.sg.statemem.feed, inst.sg.statemem.feeder)
                else
                    inst:PerformBufferedAction()
                end
            end),
            TimeEvent(12 * FRAMES, function(inst)
                inst.sg:GoToState("idle", true)
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.feed ~= nil and inst.sg.statemem.feed:IsValid() then
                inst.sg.statemem.feed:Remove()
            end
        end,
    },

    State{
        name = "refuseeat",
        tags = { "busy", "pausepredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            inst.AnimState:PlayAnimation("refuseeat")

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
            inst.sg:SetTimeout(22 * FRAMES)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,
    },

    State{
        name = "opengift",
        tags = { "busy", "pausepredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            local failstr =
                (IsNearDanger(inst) and "ANNOUNCE_NODANGERGIFT") or
                (inst.components.rider ~= nil and inst.components.rider:IsRiding() and "ANNOUNCE_NOMOUNTEDGIFT") or
                nil

            if failstr ~= nil then
                inst.sg.statemem.isfailed = true
                inst.sg:GoToState("idle")
                if inst.components.talker ~= nil then
                    inst.components.talker:Say(GetString(inst, failstr))
                end
                return
            end

            inst.SoundEmitter:PlaySound("dontstarve/common/player_receives_gift")
            inst.AnimState:PlayAnimation("gift_pre")
            inst.AnimState:PushAnimation("giift_loop", true)
            -- NOTE: the previously used ripping paper anim is called "giift_loop"

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
                inst.components.playercontroller:EnableMapControls(false)
                inst.components.playercontroller:Enable(false)
            end
            inst.components.inventory:Hide()
            inst:PushEvent("ms_closepopups")
            inst:ShowActions(false)
            inst:ShowGiftItemPopUp(true)

            if inst.components.giftreceiver ~= nil then
                inst.components.giftreceiver:OnStartOpenGift()
            end
        end,

        timeline =
        {
            -- Timing of the gift box opening animation on giftitempopup.lua
            TimeEvent(155 * FRAMES, function(inst)
                inst.AnimState:PlayAnimation("gift_open_pre")
                inst.AnimState:PushAnimation("gift_open_loop", true)
            end),
        },

        events =
        {
            EventHandler("firedamage", function(inst)
                inst.AnimState:PlayAnimation("gift_open_pst")
                inst.sg:GoToState("idle", true)
                if inst.components.talker ~= nil then
                    inst.components.talker:Say(GetString(inst, "ANNOUNCE_NODANGERGIFT"))
                end
            end),
            EventHandler("ms_doneopengift", function(inst, data)
                if data.wardrobe == nil or
                    data.wardrobe.components.wardrobe == nil or
                    not (data.wardrobe.components.wardrobe:CanBeginChanging(inst) and
                        CanEntitySeeTarget(inst, data.wardrobe) and
                        data.wardrobe.components.wardrobe:BeginChanging(inst)) then
                    inst.AnimState:PlayAnimation("gift_open_pst")
                    inst.sg:GoToState("idle", true)
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.isfailed then
                return
            elseif not inst.sg.statemem.isopeningwardrobe then
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end
                inst.components.inventory:Show()
                inst:ShowActions(true)
            end
            inst:ShowGiftItemPopUp(false)
        end,
    },

    State{
        name = "usewardrobe",
        tags = { "doing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("give")
            inst.AnimState:PushAnimation("give_pst", false)
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

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
        name = "openwardrobe",
        tags = { "inwardrobe", "busy", "pausepredict" },

        onenter = function(inst, isopeninggift)
            inst.sg.statemem.isopeninggift = isopeninggift
            if not isopeninggift then
                inst.components.locomotor:Stop()
                inst.components.locomotor:Clear()
                inst:ClearBufferedAction()

                inst.AnimState:PlayAnimation("idle_wardrobe1_pre")
                inst.AnimState:PushAnimation("idle_wardrobe1_loop", true)

                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:RemotePausePrediction()
                    inst.components.playercontroller:EnableMapControls(false)
                    inst.components.playercontroller:Enable(false)
                end
                inst.components.inventory:Hide()
                inst:PushEvent("ms_closepopups")
                inst:ShowActions(false)
            elseif inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
            inst:ShowWardrobePopUp(true)
        end,

        events =
        {
            EventHandler("firedamage", function(inst)
                if inst.sg.statemem.isopeninggift then
                    inst.AnimState:PlayAnimation("gift_open_pst")
                    inst.sg:GoToState("idle", true)
                else
                    inst.sg:GoToState("idle")
                end
                if inst.components.talker ~= nil then
                    inst.components.talker:Say(GetString(inst, "ANNOUNCE_NOWARDROBEONFIRE"))
                end
            end),
        },

        onexit = function(inst)
            inst:ShowWardrobePopUp(false)
            if not inst.sg.statemem.ischanging then
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end
                inst.components.inventory:Show()
                inst:ShowActions(true)
                if not inst.sg.statemem.isclosingwardrobe then
                    inst.sg.statemem.isclosingwardrobe = true
                    inst:PushEvent("ms_closewardrobe")
                end
            end
        end,
    },

    State{
        name = "changeinwardrobe",
        tags = { "inwardrobe", "busy", "nopredict", "silentmorph" },

        onenter = function(inst, delay)
            --This state is only valid as a substate of openwardrobe
            inst:Hide()
            inst.DynamicShadow:Enable(false)
            inst.sg.statemem.isplayerhidden = true

            inst.sg:SetTimeout(delay)
        end,

        ontimeout = function(inst)
            inst.AnimState:PlayAnimation("jumpout_wardrobe")
            inst:Show()
            inst.DynamicShadow:Enable(true)
            inst.sg.statemem.isplayerhidden = nil
            inst.sg.statemem.task = inst:DoTaskInTime(4.5 * FRAMES, function()
                inst.sg.statemem.task = nil
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
            end)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if not inst.sg.statemem.isplayerhidden and inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.task ~= nil then
                inst.sg.statemem.task:Cancel()
                inst.sg.statemem.task = nil
            end
            if inst.sg.statemem.isplayerhidden then
                inst:Show()
                inst.DynamicShadow:Enable(true)
                inst.sg.statemem.isplayerhidden = nil
            end
            --Cleanup from openwardobe state
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(true)
                inst.components.playercontroller:Enable(true)
            end
            inst.components.inventory:Show()
            inst:ShowActions(true)
            if not inst.sg.statemem.isclosingwardrobe then
                inst.sg.statemem.isclosingwardrobe = true
                inst:PushEvent("ms_closewardrobe")
            end
        end,
    },

    State{
        name = "changeoutsidewardrobe",
        tags = { "busy", "pausepredict", "nomorph" },

        onenter = function(inst, cb)
            inst.sg.statemem.cb = cb

            --This state is only valid as a substate of openwardrobe
            inst.AnimState:OverrideSymbol("shadow_hands", "shadow_skinchangefx", "shadow_hands")
            inst.AnimState:OverrideSymbol("shadow_ball", "shadow_skinchangefx", "shadow_ball")
            inst.AnimState:OverrideSymbol("splode", "shadow_skinchangefx", "splode")

            inst.AnimState:PlayAnimation("gift_pst", false)
            inst.AnimState:PushAnimation("skin_change", false)

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
        end,

        timeline =
        {
            -- gift_pst plays first and it is 20 frames long
            TimeEvent(20 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/HUD/Together_HUD/skin_change")
            end),
            -- frame 42 of skin_change is where the character is completely hidden
            TimeEvent(62 * FRAMES, function(inst)
                if inst.sg.statemem.cb ~= nil then
                    inst.sg.statemem.cb()
                    inst.sg.statemem.cb = nil
                end
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.cb ~= nil then
                -- in case of interruption
                inst.sg.statemem.cb()
                inst.sg.statemem.cb = nil
            end
            inst.AnimState:OverrideSymbol("shadow_hands", "shadow_hands", "shadow_hands")
            --Cleanup from openwardobe state
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(true)
                inst.components.playercontroller:Enable(true)
            end
            inst.components.inventory:Show()
            inst:ShowActions(true)
            if not inst.sg.statemem.isclosingwardrobe then
                inst.sg.statemem.isclosingwardrobe = true
                inst:PushEvent("ms_closewardrobe")
            end
        end,
    },

    State{
        name = "talk",
        tags = { "idle", "talking" },

        onenter = function(inst, noanim)
            if not noanim then
                inst.AnimState:PlayAnimation("dial_loop", true)
            end
            DoTalkSound(inst)
            inst.sg:SetTimeout(1.5 + math.random() * .5)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,

        events =
        {
            EventHandler("donetalking", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("talk")
        end,
    },

    State{
        name = "mime",
        tags = { "idle", "talking" },

        onenter = function(inst)
            for k = 1, math.random(2, 3) do
                local aname = "mime" .. tostring(math.random(8))
                if k == 1 then
                    inst.AnimState:PlayAnimation(aname, false)
                else
                    inst.AnimState:PushAnimation(aname, false)
                end
            end
            DoTalkSound(inst)
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),

            EventHandler("donetalking", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("talk")
        end,
    },

    State
    {
        name = "unsaddle",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("unsaddle_pre")
            inst.AnimState:PushAnimation("unsaddle", false)

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg:SetTimeout(21 * FRAMES)
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
            TimeEvent(15 * FRAMES, function(inst)
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

    State
    {
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

    State
    {
        name = "dolongaction",
        tags = { "doing", "busy" },

        onenter = function(inst, timeout)
            local targ = inst:GetBufferedAction() and inst:GetBufferedAction().target or nil
            if targ then targ:PushEvent("startlongaction") end

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg:SetTimeout(timeout or 1)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make")
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        ontimeout = function(inst)
            inst.SoundEmitter:KillSound("make")
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
            inst.SoundEmitter:KillSound("make")
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State{
        --Alternative to doshortaction but animated with your held tool
        --Animation mirrors attack action, but are not "auto" predicted
        --by clients (also no sound prediction)
        name = "dojostleaction",
        tags = { "doing", "busy" },

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.locomotor:Stop()
            local cooldown
            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                DoMountSound(inst, inst.components.rider:GetMount(), "angry")
                cooldown = 16 * FRAMES
            elseif equip ~= nil and equip:HasTag("whip") then
                inst.AnimState:PlayAnimation("whip_pre")
                inst.AnimState:PushAnimation("whip", false)
                inst.sg.statemem.iswhip = true
                inst.SoundEmitter:PlaySound("dontstarve/common/whip_pre")
                cooldown = 17 * FRAMES
            elseif equip ~= nil and equip.components.weapon ~= nil and not equip:HasTag("punch") then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
                cooldown = 13 * FRAMES
            elseif equip ~= nil and (equip:HasTag("light") or equip:HasTag("nopunch")) then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
                cooldown = 13 * FRAMES
            elseif inst:HasTag("beaver") then
                inst.sg.statemem.isbeaver = true
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                cooldown = 13 * FRAMES
            else
                inst.AnimState:PlayAnimation("punch")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                cooldown = 24 * FRAMES
            end

            if target ~= nil and target:IsValid() then
                inst:FacePoint(target:GetPosition())
            end

            inst.sg.statemem.action = buffaction
            inst.sg:SetTimeout(cooldown)
        end,

        timeline =
        {
            --beaver: frame 4 remove busy, frame 6 action
            --whip: frame 8 remove busy, frame 10 action
            --other: frame 6 remove busy, frame 8 action
            TimeEvent(4 * FRAMES, function(inst)
                if inst.sg.statemem.isbeaver then
                    inst.sg:RemoveStateTag("busy")
                end
            end),
            TimeEvent(6 * FRAMES, function(inst)
                if inst.sg.statemem.isbeaver then
                    inst:PerformBufferedAction()
                elseif not inst.sg.statemem.iswhip then
                    inst.sg:RemoveStateTag("busy")
                end
            end),
            TimeEvent(8 * FRAMES, function(inst)
                if inst.sg.statemem.iswhip then
                    inst.sg:RemoveStateTag("busy")
                elseif not inst.sg.statemem.isbeaver then
                    inst:PerformBufferedAction()
                end
            end),
            TimeEvent(10 * FRAMES, function(inst)
                if inst.sg.statemem.iswhip then
                    inst:PerformBufferedAction()
                end
            end),
        },

        ontimeout = function(inst)
            --anim pst should still be playing
            inst.sg:GoToState("idle", true)
        end,

        events =
        {
            EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        },

        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },    

    State{
        name = "makeballoon",
        tags = { "doing", "busy" },

        onenter = function(inst, timeout)
            inst.sg.statemem.action = inst.bufferedaction
            inst.sg:SetTimeout(timeout or 1)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/common/balloon_make", "make")
            inst.SoundEmitter:PlaySound("dontstarve/common/balloon_blowup")
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        ontimeout = function(inst)
            inst.SoundEmitter:KillSound("make")
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
            inst.SoundEmitter:KillSound("make")
            if inst.bufferedaction == inst.sg.statemem.action then
                inst:ClearBufferedAction()
            end
        end,
    },

    State{
        name = "shave",
        tags = { "doing", "shaving" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            local pass = false
            local reason = nil

            if inst.bufferedaction ~= nil and
                inst.bufferedaction.invobject ~= nil and
                inst.bufferedaction.invobject.components.shaver ~= nil then
                local shavee = inst.bufferedaction.target or inst.bufferedaction.doer
                if shavee ~= nil and shavee.components.beard ~= nil then
                    pass, reason = shavee.components.beard:ShouldTryToShave(inst.bufferedaction.doer, inst.bufferedaction.invobject)
                end
            end

            if not pass then
                inst:PushEvent("actionfailed", { action = inst.bufferedaction, reason = reason })
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
                return
            end

            inst.SoundEmitter:PlaySound("dontstarve/wilson/shave_LP", "shave")
            
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)

            inst.sg:SetTimeout(1)
        end,

        ontimeout = function(inst)
            inst:PerformBufferedAction()
            inst.AnimState:PlayAnimation("build_pst")
            inst.sg:GoToState("idle", false)
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("shave")
        end,
    },

    State{
        name = "enter_onemanband",
        tags = { "playing", "idle" },

        onenter = function(inst, pushanim)
            inst.components.locomotor:Stop()

            if pushanim then
                inst.AnimState:PushAnimation("idle_onemanband1_pre", false)
            else
                inst.AnimState:PlayAnimation("idle_onemanband1_pre")
            end

            if inst.AnimState:IsCurrentAnimation("idle_onemanband1_pre") then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")
                inst.sg.statemem.soundplayed = true
            end
        end,

        onupdate = function(inst)
            if not inst.sg.statemem.soundplayed and inst.AnimState:IsCurrentAnimation("idle_onemanband1_pre") then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")
                inst.sg.statemem.soundplayed = true
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() and inst.AnimState:IsCurrentAnimation("idle_onemanband1_pre") then
                    inst.sg:GoToState("play_onemanband")
                end
            end),
        },
    },

    State{
        name = "play_onemanband",
        tags = { "playing", "idle" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            --inst.AnimState:PlayAnimation("idle_onemanband1_pre")
            inst.AnimState:PlayAnimation("idle_onemanband1_loop")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState(math.random() <= 0.15 and "play_onemanband_stomp" or "play_onemanband")
                end
            end),
        },
    },

    State{
        name = "play_onemanband_stomp",
        tags = { "playing", "idle" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("idle_onemanband1_pst")
            inst.AnimState:PushAnimation("idle_onemanband2_pre")
            inst.AnimState:PushAnimation("idle_onemanband2_loop")
            inst.AnimState:PushAnimation("idle_onemanband2_pst", false)  
            inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband") 
        end,

        timeline =
        {
            TimeEvent(20*FRAMES, function( inst )
                inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")                
            end),

            TimeEvent(25*FRAMES, function( inst )
                inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")                
            end),

            TimeEvent(30*FRAMES, function( inst )
                inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")                
            end),

            TimeEvent(35*FRAMES, function( inst )
                inst.SoundEmitter:PlaySound("dontstarve/wilson/onemanband")                
            end),
        },

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
        name = "play_flute",
        tags = { "doing", "playing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("flute", false)
            inst.AnimState:OverrideSymbol("pan_flute01", "pan_flute", "pan_flute01")
            inst.AnimState:Hide("ARM_carry") 
            inst.AnimState:Show("ARM_normal")
            inst.components.inventory:ReturnActiveActionItem(inst.bufferedaction ~= nil and inst.bufferedaction.invobject or nil)
        end,

        timeline =
        {
            TimeEvent(30*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/flute_LP", "flute")
                inst:PerformBufferedAction()
            end),
            TimeEvent(85*FRAMES, function(inst)
                inst.SoundEmitter:KillSound("flute")
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("flute")
            if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                inst.AnimState:Show("ARM_carry") 
                inst.AnimState:Hide("ARM_normal")
            end
        end,
    },

    State{
        name = "play_horn",
        tags = { "doing", "playing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("horn", false)
            inst.AnimState:OverrideSymbol("horn01", "horn", "horn01")
            --inst.AnimState:Hide("ARM_carry") 
            inst.AnimState:Show("ARM_normal")
            inst.components.inventory:ReturnActiveActionItem(inst.bufferedaction ~= nil and inst.bufferedaction.invobject or nil)
        end,

        timeline =
        {
            TimeEvent(21*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/horn_beefalo")
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                inst.AnimState:Show("ARM_carry") 
                inst.AnimState:Hide("ARM_normal")
            end
        end,
    },

    State{
        name = "play_bell",
        tags = { "doing", "playing" },
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("bell")
            inst.AnimState:OverrideSymbol("bell01", "bell", "bell01")
            --inst.AnimState:Hide("ARM_carry") 
            inst.AnimState:Show("ARM_normal")
            inst.components.inventory:ReturnActiveActionItem(inst.bufferedaction ~= nil and inst.bufferedaction.invobject or nil)
        end,

        timeline =
        {
            TimeEvent(15*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/glommer_bell")
            end),

            TimeEvent(60*FRAMES, function(inst)
                inst:PerformBufferedAction()
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
            if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                inst.AnimState:Show("ARM_carry") 
                inst.AnimState:Hide("ARM_normal")
            end
        end,
    },

    State{
        name = "book",
        tags = { "doing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("book", false)
            --Moved to player_common because these symbols are never cleared
            --inst.AnimState:OverrideSymbol("book_open", "player_actions_uniqueitem", "book_open")
            --inst.AnimState:OverrideSymbol("book_closed", "player_actions_uniqueitem", "book_closed")
            --inst.AnimState:OverrideSymbol("book_open_pages", "player_actions_uniqueitem", "book_open_pages")
            --inst.AnimState:Hide("ARM_carry") 
            inst.AnimState:Show("ARM_normal")
            inst.components.inventory:ReturnActiveActionItem(inst.bufferedaction ~= nil and (inst.bufferedaction.target or inst.bufferedaction.invobject) or nil)
        end,

        timeline =
        {
            TimeEvent(0, function(inst)
                local fxtoplay = inst.components.rider ~= nil and inst.components.rider:IsRiding() and "book_fx_mount" or "book_fx"
                local fx = SpawnPrefab(fxtoplay)
                fx.entity:SetParent(inst.entity)
                fx.Transform:SetPosition(0, 0.2, 0)
                inst.sg.statemem.book_fx = fx
            end),

            TimeEvent(28 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/use_book_light")
            end),

            TimeEvent(54 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/use_book_close")
            end),

            TimeEvent(58 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/book_spell")
                inst:PerformBufferedAction()
                inst.sg.statemem.book_fx = nil
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                inst.AnimState:Show("ARM_carry") 
                inst.AnimState:Hide("ARM_normal")
            end
            if inst.sg.statemem.book_fx then
                inst.sg.statemem.book_fx:Remove()
                inst.sg.statemem.book_fx = nil
            end
        end,
    },    

    State{
        name = "blowdart",
        tags = { "attack", "notalking", "abouttoattack", "autopredict" },

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            local cooldown = math.max(inst.components.combat.min_attack_period + .5 * FRAMES, 20 * FRAMES)

            inst.AnimState:PlayAnimation("dart")

            inst.sg:SetTimeout(cooldown)

            if target ~= nil and target:IsValid() then
                inst:FacePoint(target.Transform:GetWorldPosition())
                inst.sg.statemem.attacktarget = target
            end
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot", nil, nil, true)
            end),
            TimeEvent(10 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot", nil, nil, true)
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
            EventHandler("animover", function(inst)
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
        name = "throw",
        tags = { "attack", "notalking", "abouttoattack", "autopredict" },

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            local cooldown = math.max(inst.components.combat.min_attack_period + .5 * FRAMES, 11 * FRAMES)

            inst.AnimState:PlayAnimation("throw")

            inst.sg:SetTimeout(cooldown)

            if target ~= nil and target:IsValid() then
                inst:FacePoint(target.Transform:GetWorldPosition())
                inst.sg.statemem.attacktarget = target
            end
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst:PerformBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
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
            EventHandler("animover", function(inst)
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
        name = "catch_pre",
        tags = { "notalking", "readytocatch" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst.AnimState:IsCurrentAnimation("catch_pre") then
                inst.AnimState:PlayAnimation("catch_pre")
            end

            inst.sg:SetTimeout(3)
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,

        events =
        {
            EventHandler("catch", function(inst)
                inst:ClearBufferedAction()
                inst.sg:GoToState("catch")
            end),
            EventHandler("cancelcatch", function(inst)
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "catch",
        tags = { "busy", "notalking", "pausepredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("catch")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/boomerang_catch")

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
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
        tags = { "attack", "notalking", "abouttoattack", "autopredict" },

        onenter = function(inst)
            local buffaction = inst:GetBufferedAction()
            local target = buffaction ~= nil and buffaction.target or nil
            local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.combat:SetTarget(target)
            inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
            local cooldown = inst.components.combat.min_attack_period + .5 * FRAMES
            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                DoMountSound(inst, inst.components.rider:GetMount(), "angry", true)
                cooldown = math.max(cooldown, 16 * FRAMES)
            elseif equip ~= nil and equip:HasTag("whip") then
                inst.AnimState:PlayAnimation("whip_pre")
                inst.AnimState:PushAnimation("whip", false)
                inst.sg.statemem.iswhip = true
                inst.SoundEmitter:PlaySound("dontstarve/common/whip_pre", nil, nil, true)
                cooldown = math.max(cooldown, 17 * FRAMES)
            elseif equip ~= nil and equip.components.weapon ~= nil and not equip:HasTag("punch") then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound(
                    (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                    (equip:HasTag("shadow") and "dontstarve/wilson/attack_nightsword") or
                    (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                    "dontstarve/wilson/attack_weapon",
                    nil, nil, true
                )
                cooldown = math.max(cooldown, 13 * FRAMES)
            elseif equip ~= nil and (equip:HasTag("light") or equip:HasTag("nopunch")) then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                cooldown = math.max(cooldown, 13 * FRAMES)
            elseif inst:HasTag("beaver") then
                inst.sg.statemem.isbeaver = true
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
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
                end
            end
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
                if inst.sg.statemem.isbeaver then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(8 * FRAMES, function(inst)
                if not (inst.sg.statemem.isbeaver or
                        inst.sg.statemem.iswhip) then
                    inst:PerformBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(10 * FRAMES, function(inst)
                if inst.sg.statemem.iswhip then
                    inst:PerformBufferedAction()
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
        name = "run_start",
        tags = { "moving", "running", "canrotate", "autopredict" },

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation(inst:HasTag("groggy") and "idle_walk_pre" or "run_pre")
            inst.sg.mem.footsteps = 0
            inst.sg.statemem.riding = inst.components.rider ~= nil and inst.components.rider:IsRiding()
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            --mounted
            TimeEvent(0, function(inst)
                if inst.sg.statemem.riding then
                    DoMountedFoleySounds(inst)
                end
            end),

            --unmounted
            TimeEvent(4 * FRAMES, function(inst)
                if not inst.sg.statemem.riding then
                    PlayFootstep(inst, nil, true)
                    DoFoleySounds(inst)
                end
            end),

            --mounted
            TimeEvent(5 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    PlayFootstep(inst, nil, true)
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
        tags = { "moving", "running", "canrotate", "autopredict" },

        onenter = function(inst) 
            inst.components.locomotor:RunForward()
            local anim = inst:HasTag("groggy") and "idle_walk" or "run_loop"
            if not inst.AnimState:IsCurrentAnimation(anim) then
                inst.AnimState:PlayAnimation(anim, true)
            end
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            inst.sg.statemem.riding = inst.components.rider ~= nil and inst.components.rider:IsRiding()
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            --unmounted
            TimeEvent(7 * FRAMES, function(inst)
                if not inst.sg.statemem.riding then
                    if inst.sg.mem.footsteps > 3 then
                        PlayFootstep(inst, .6, true)
                    else
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                        PlayFootstep(inst, 1, true)
                    end
                    DoFoleySounds(inst)
                end
            end),
            TimeEvent(15 * FRAMES, function(inst)
                if not inst.sg.statemem.riding then
                    if inst.sg.mem.footsteps > 3 then
                        PlayFootstep(inst, .6, true)
                    else
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                        PlayFootstep(inst, 1, true)
                    end
                    DoFoleySounds(inst)
                end
            end),

            --mounted
            TimeEvent(0 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    DoMountedFoleySounds(inst)
                end
            end),
            TimeEvent(5 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    if inst.sg.mem.footsteps > 3 then
                        PlayFootstep(inst, .6, true)
                    else
                        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
                        PlayFootstep(inst, 1, true)
                    end
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("run")
        end,
    },

    State{
        name = "run_stop",
        tags = { "canrotate", "idle", "autopredict" },

        onenter = function(inst) 
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation(inst:HasTag("groggy") and "idle_walk_pst" or "run_pst")
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
        tags = { "idle" },

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
        tags = { "idle" },

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
        tags = { "idle" },

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
        name = "give",
        tags = { "giving" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("give")
            inst.AnimState:PushAnimation("give_pst", false)
        end,

        timeline =
        {
            TimeEvent(13*FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

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
        name = "bedroll",
        tags = { "bedroll", "busy", "nomorph" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            local failreason =
                (TheWorld.state.isday and
                    (TheWorld:HasTag("cave") and "ANNOUNCE_NODAYSLEEP_CAVE" or "ANNOUNCE_NODAYSLEEP")
                )
                or (IsNearDanger(inst) and "ANNOUNCE_NODANGERSLEEP")
                -- you can still sleep if your hunger will bottom out, but not absolutely
                or (inst.components.hunger.current < TUNING.CALORIES_MED and "ANNOUNCE_NOHUNGERSLEEP")
                or (inst.components.beaverness ~= nil and inst.components.beaverness:IsStarving() and "ANNOUNCE_NOHUNGERSLEEP")
                or nil

            if failreason ~= nil then
                inst:PushEvent("performaction", { action = inst.bufferedaction })
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
                if inst.components.talker ~= nil then
                    inst.components.talker:Say(GetString(inst, failreason))
                end
                return
            end

            inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("bedroll", false)

            SetSleeperSleepState(inst)
        end,

        timeline =
        {
            TimeEvent(20 * FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/wilson/use_bedroll")
            end),
        },

        events =
        {
            EventHandler("firedamage", function(inst)
                if inst.sg:HasStateTag("sleeping") then
                    inst.sg.statemem.iswaking = true
                    inst.sg:GoToState("wakeup")
                end
            end),
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    if TheWorld.state.isday or
                        (inst.components.health ~= nil and inst.components.health.takingfiredamage) or
                        (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) then
                        inst:PushEvent("performaction", { action = inst.bufferedaction })
                        inst:ClearBufferedAction()
                        inst.sg.statemem.iswaking = true
                        inst.sg:GoToState("wakeup")
                    elseif inst:GetBufferedAction() then
                        inst:PerformBufferedAction() 
                        if inst.components.playercontroller ~= nil then
                            inst.components.playercontroller:Enable(true)
                        end
                        inst.sg:AddStateTag("sleeping")
                        inst.sg:AddStateTag("silentmorph")
                        inst.sg:RemoveStateTag("nomorph")
                        inst.sg:RemoveStateTag("busy")
                        inst.AnimState:PlayAnimation("bedroll_sleep_loop", true)
                    else
                        inst.sg.statemem.iswaking = true
                        inst.sg:GoToState("wakeup")
                    end
                end
            end),
        },

        onexit = function(inst)
            if inst.sleepingbag ~= nil then
                --Interrupted while we are "sleeping"
                inst.sleepingbag.components.sleepingbag:DoWakeUp(true)
                inst.sleepingbag = nil
                SetSleeperAwakeState(inst)
            elseif not inst.sg.statemem.iswaking then
                --Interrupted before we are "sleeping"
                SetSleeperAwakeState(inst)
            end
        end,
    },

    State{
        name = "tent",
        tags = { "tent", "busy", "silentmorph" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            local target = inst:GetBufferedAction().target
            local siesta = target:HasTag("siestahut")
            local failreason =
                (siesta ~= TheWorld.state.isday and
                    (siesta
                    and (TheWorld:HasTag("cave") and "ANNOUNCE_NONIGHTSIESTA_CAVE" or "ANNOUNCE_NONIGHTSIESTA")
                    or (TheWorld:HasTag("cave") and "ANNOUNCE_NODAYSLEEP_CAVE" or "ANNOUNCE_NODAYSLEEP"))
                )
                or (target.components.burnable ~= nil and
                    target.components.burnable:IsBurning() and
                    "ANNOUNCE_NOSLEEPONFIRE")
                or (IsNearDanger(inst) and "ANNOUNCE_NODANGERSLEEP")
                -- you can still sleep if your hunger will bottom out, but not absolutely
                or (inst.components.hunger.current < TUNING.CALORIES_MED and "ANNOUNCE_NOHUNGERSLEEP")
                or (inst.components.beaverness ~= nil and inst.components.beaverness:IsStarving() and "ANNOUNCE_NOHUNGERSLEEP")
                or nil

            if failreason ~= nil then
                inst:PushEvent("performaction", { action = inst.bufferedaction })
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle")
                if inst.components.talker ~= nil then
                    inst.components.talker:Say(GetString(inst, failreason))
                end
                return
            end

            inst.AnimState:PlayAnimation("pickup")
            inst.sg:SetTimeout(6 * FRAMES)

            SetSleeperSleepState(inst)
        end,

        ontimeout = function(inst)
            local bufferedaction = inst:GetBufferedAction()
            if bufferedaction == nil then
                inst.AnimState:PlayAnimation("pickup_pst")
                inst.sg:GoToState("idle", true)
                return
            end
            local tent = bufferedaction.target
            if tent == nil or
                not tent:HasTag("tent") or
                tent:HasTag("hassleeper") or
                tent:HasTag("siestahut") ~= TheWorld.state.isday or
                (tent.components.burnable ~= nil and tent.components.burnable:IsBurning()) then
                --Edge cases, don't bother with fail dialogue
                --Also, think I will let smolderig pass this one
                inst:PushEvent("performaction", { action = inst.bufferedaction })
                inst:ClearBufferedAction()
                inst.AnimState:PlayAnimation("pickup_pst")
                inst.sg:GoToState("idle", true)
            else
                inst:PerformBufferedAction()
                inst.components.health:SetInvincible(true)
                inst:Hide()
                if inst.Physics ~= nil then
                    inst.Physics:Teleport(inst.Transform:GetWorldPosition())
                end
                if inst.DynamicShadow ~= nil then
                    inst.DynamicShadow:Enable(false)
                end
                inst.sg:AddStateTag("sleeping")
                inst.sg:RemoveStateTag("busy")
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end
            end
        end,

        onexit = function(inst)
            inst.components.health:SetInvincible(false)
            inst:Show()
            if inst.DynamicShadow ~= nil then
                inst.DynamicShadow:Enable(true)
            end
            if inst.sleepingbag ~= nil then
                --Interrupted while we are "sleeping"
                inst.sleepingbag.components.sleepingbag:DoWakeUp(true)
                inst.sleepingbag = nil
                SetSleeperAwakeState(inst)
            elseif not inst.sg.statemem.iswaking then
                --Interrupted before we are "sleeping"
                SetSleeperAwakeState(inst)
            end
        end,
    },

    State{
        name = "knockout",
        tags = { "busy", "knockout", "nopredict", "nomorph" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.sg.statemem.isinsomniac = inst:HasTag("insomniac")

            if inst.components.rider ~= nil and inst.components.rider:IsRiding() then
                inst.sg:AddStateTag("dismounting")
                inst.AnimState:PlayAnimation("fall_off")
                inst.SoundEmitter:PlaySound("dontstarve/beefalo/saddle/dismount")
            else
                inst.AnimState:PlayAnimation(inst.sg.statemem.isinsomniac and "insomniac_dozy" or "dozy")
            end

            SetSleeperSleepState(inst)

            inst.sg:SetTimeout(TUNING.KNOCKOUT_SLEEP_TIME)
        end,

        ontimeout = function(inst)
            if inst.components.grogginess == nil then
                inst.sg.statemem.iswaking = true
                inst.sg:GoToState("wakeup")
            end
        end,

        events =
        {
            EventHandler("firedamage", function(inst)
                if inst.sg:HasStateTag("sleeping") then
                    inst.sg.statemem.iswaking = true
                    inst.sg:GoToState("wakeup")
                else
                    inst.sg.statemem.cometo = true
                end
            end),
            EventHandler("cometo", function(inst)
                if inst.sg:HasStateTag("sleeping") then
                    inst.sg.statemem.iswaking = true
                    inst.sg:GoToState("wakeup")
                else
                    inst.sg.statemem.cometo = true
                end
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.sg:HasStateTag("dismounting") then
                        inst.sg:RemoveStateTag("dismounting")
                        if inst.components.rider ~= nil then
                            inst.components.rider:ActualDismount()
                        end
                        inst.AnimState:PlayAnimation(inst.sg.statemem.isinsomniac and "insomniac_dozy" or "dozy")
                    elseif inst.sg.statemem.cometo then
                        inst.sg.statemem.iswaking = true
                        inst.sg:GoToState("wakeup")
                    else
                        inst.AnimState:PlayAnimation(inst.sg.statemem.isinsomniac and "insomniac_sleep_loop" or "sleep_loop", true)
                        inst.sg:AddStateTag("sleeping")
                    end
                end
            end),
        },

        onexit = function(inst)
            if inst.sg:HasStateTag("dismounting") and inst.components.rider ~= nil then
                --Interrupted
                inst.components.rider:ActualDismount()
            end
            if not inst.sg.statemem.iswaking then
                --Interrupted
                SetSleeperAwakeState(inst)
            end
        end,
    },

    State{
        name = "hit",
        tags = { "busy", "pausepredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:PlayAnimation("hit")

            inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
            DoHurtSound(inst)

            local stun_frames = 6
            if inst.components.playercontroller ~= nil then
                --Specify min frames of pause since "busy" tag may be
                --removed too fast for our network update interval.
                inst.components.playercontroller:RemotePausePrediction(stun_frames)
            end
            inst.sg:SetTimeout(stun_frames * FRAMES)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,
    },

    State{
        name = "hit_darkness",
        tags = { "busy", "pausepredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            --V2C: Moved to pristine state in player_common
            --     since we never clear these extra symbols
            --inst.AnimState:AddOverrideBuild("player_hit_darkness")
            inst.AnimState:PlayAnimation("hit_darkness")

            inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
            DoHurtSound(inst)

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end

            inst.sg:SetTimeout(24 * FRAMES)
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
        end,
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
            SpawnPrefab("brokentool").Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.sg.statemem.tool = tool

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
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
            local sameTool = inst.components.inventory:FindItem(function(item)
                return item.prefab == inst.sg.statemem.tool.prefab
            end)
            if sameTool then
                inst.components.inventory:Equip(sameTool)
            end

            if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                inst.AnimState:Show("ARM_carry") 
                inst.AnimState:Hide("ARM_normal")
            end
        end,
    },

    State{
        name = "tool_slip",
        tags = { "busy", "pausepredict" },
        onenter = function(inst, tool)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/common/tool_slip")
            inst.AnimState:Hide("ARM_carry") 
            inst.AnimState:Show("ARM_normal") 
            local splash = SpawnPrefab("splash")
            splash.entity:SetParent(inst.entity)
            splash.entity:AddFollower()
            splash.Follower:FollowSymbol(inst.GUID, "swap_object", 0, 0, 0)

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
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
        name = "armorbroke",
        tags = { "busy", "pausepredict" },

        onenter = function(inst, armor)
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_armour_break")
            inst.sg.statemem.armor = armor

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
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
            local sameArmor = inst.components.inventory:FindItem(function(item)
                return item.prefab == inst.sg.statemem.armor.prefab
            end)
            if sameArmor then
                inst.components.inventory:Equip(sameArmor)
            end
        end,
    },

    State{
        name = "teleportato_teleport",
        tags = { "busy", "nopredict", "nomorph" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            inst.components.health:SetInvincible(true)
            inst.AnimState:PlayAnimation("teleport")
            inst:ShowHUD(false)
            inst:SetCameraDistance(20)
        end,

        timeline =
        {
            TimeEvent(0, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_pulled")
            end),
            TimeEvent(82*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/teleportato/teleportato_under")
            end),
        },

        onexit = function(inst)
            inst:ShowHUD(true)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
            inst.components.health:SetInvincible(false)
        end,
    },

    State{
        name = "amulet_rebirth",
        tags = { "busy", "nopredict", "silentmorph" },

        onenter = function(inst)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            inst.AnimState:PlayAnimation("amulet_rebirth")
            inst.AnimState:OverrideSymbol("FX", "player_amulet_resurrect", "FX")
            inst.components.health:SetInvincible(true)
            inst:ShowHUD(false)
            inst:SetCameraDistance(14)
        end,

        timeline =
        {
            TimeEvent(0, function(inst)
                local stafflight = SpawnPrefab("staff_castinglight")
                stafflight.Transform:SetPosition(inst.Transform:GetWorldPosition())
                stafflight:SetUp({ 150 / 255, 46 / 255, 46 / 255 }, 1.7, 1)
                inst.SoundEmitter:PlaySound("dontstarve/common/rebirth_amulet_raise")
            end),
            TimeEvent(60 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/rebirth_amulet_poof")
            end),
            TimeEvent(80 * FRAMES, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, y, z, 10)
                for k, v in pairs(ents) do
                    if v ~= inst and v.components.sleeper ~= nil then
                        v.components.sleeper:GoToSleep(20)
                    end
                end
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
            local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
            if item ~= nil and item.prefab == "amulet" then
                item = inst.components.inventory:RemoveItem(item)
                if item ~= nil then
                    item:Remove()
                end
            end
            inst:ShowHUD(true)
            inst:SetCameraDistance()
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
            inst.components.health:SetInvincible(false)
            inst.AnimState:ClearOverrideSymbol("FX")

            SerializeUserSession(inst)
        end,
    },

    State{
        name = "portal_rez",
        tags = { "busy", "nopredict", "silentmorph" },

        onenter = function(inst)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            inst.AnimState:PlayAnimation("idle_loop", true)
            inst:ShowHUD(false)
            inst:SetCameraDistance(14)
            inst.AnimState:SetMultColour(0, 0, 0, 1)
            inst:Hide()
            inst.DynamicShadow:Enable(false)
        end,

        timeline =
        {
            TimeEvent(12 * FRAMES, function(inst)
                inst:Show()
                inst.DynamicShadow:Enable(true)
            end),
            TimeEvent(72 * FRAMES, function(inst)
                inst.components.colourtweener:StartTween(
                    { 1, 1, 1, 1 },
                    14 * FRAMES,
                    function(inst)
                        if inst.sg.currentstate.name == "portal_rez" then
                            inst.sg.statemem.istweencomplete = true
                            inst.sg:GoToState("idle")
                        end
                    end)
            end),
        },

        onexit = function(inst)
            --In case of interruptions
            inst:Show()
            inst.DynamicShadow:Enable(true)
            --
            inst:ShowHUD(true)
            inst:SetCameraDistance()
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
            inst.components.health:SetInvincible(false)

            SerializeUserSession(inst)

            --In case of interruptions
            if not inst.sg.statemem.istweencomplete then
                if inst.components.colourtweener:IsTweening() then
                    inst.components.colourtweener:EndTween()
                else
                    inst.AnimState:SetMultColour(1, 1, 1, 1)
                end

            end
        end,
    },

    State{
        name = "reviver_rebirth",
        tags = { "busy", "reviver_rebirth", "pausepredict", "silentmorph" },

        onenter = function(inst)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
                inst.components.playercontroller:RemotePausePrediction()
            end
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()
            inst:ClearBufferedAction()

            SpawnPrefab("ghost_transform_overlay_fx").entity:SetParent(inst.entity)

            inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_get_bloodpump")
            inst.AnimState:SetBank("ghost")
            if inst:HasTag("beaver") then
				inst.components.skinner:SetSkinMode("ghost_werebeaver_skin")
			else
				inst.components.skinner:SetSkinMode("ghost_skin")
			end
            inst.AnimState:PlayAnimation("shudder")
            inst.AnimState:PushAnimation("hit", false)
            inst.AnimState:PushAnimation("transform", false)
            inst.components.health:SetInvincible(true)
            inst:ShowHUD(false)
            inst:SetCameraDistance(14)
        end,

        timeline =
        {
            TimeEvent(88 * FRAMES, function(inst)
                inst.DynamicShadow:Enable(true)
                if inst:HasTag("beaver") then
                    inst.AnimState:SetBank("werebeaver")
                    inst.components.skinner:SetSkinMode("werebeaver_skin")
                else
                    inst.AnimState:SetBank("wilson")
                    inst.components.skinner:SetSkinMode("normal_skin")
                end
                inst.AnimState:PlayAnimation("transform_end")
                inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_use_bloodpump")
            end),
            TimeEvent(96 * FRAMES, function(inst) 
                inst.components.bloomer:PopBloom("playerghostbloom")
                inst.AnimState:SetLightOverride(0)
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            --In case of interruptions
            inst.DynamicShadow:Enable(true)
            if inst:HasTag("beaver") then
                inst.AnimState:SetBank("werebeaver")
                inst.components.skinner:SetSkinMode("werebeaver_skin")
            else
                inst.AnimState:SetBank("wilson")
                inst.components.skinner:SetSkinMode("normal_skin")
            end
            inst.components.bloomer:PopBloom("playerghostbloom")
            inst.AnimState:SetLightOverride(0)
            --
            inst.components.health:SetInvincible(false)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end

            inst:ShowHUD(true)
            inst:SetCameraDistance()

            SerializeUserSession(inst)
        end,
    },

    State{
        name = "jumpin_pre",
        tags = { "doing", "busy", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("jump_pre", false)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.bufferedaction ~= nil then
                        inst:PerformBufferedAction()
                    else
                        inst.sg:GoToState("idle")
                    end
                end
            end),
        },
    },

    State{
        name = "jumpin",
        tags = { "doing", "busy", "canrotate", "nopredict", "nomorph" },

        onenter = function(inst, data)
            ToggleOffPhysics(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("jump", false)

            inst.sg.statemem.target = data.teleporter

            local pos = data ~= nil and data.teleporter and data.teleporter:GetPosition() or nil

            local MAX_JUMPIN_DIST = 3
            local MAX_JUMPIN_DIST_SQ = MAX_JUMPIN_DIST*MAX_JUMPIN_DIST
            local MAX_JUMPIN_SPEED = 6

            local dist
            if pos ~= nil then
                inst:ForceFacePoint(pos:Get())
                local distsq = inst:GetDistanceSqToPoint(pos:Get())
                if distsq <= 0.25*0.25 then
                    dist = 0
                    inst.sg.statemem.speed = 0
                elseif distsq >= MAX_JUMPIN_DIST_SQ then
                    dist = MAX_JUMPIN_DIST
                    inst.sg.statemem.speed = MAX_JUMPIN_SPEED
                else
                    dist = math.sqrt(distsq)
                    inst.sg.statemem.speed = MAX_JUMPIN_SPEED * dist / MAX_JUMPIN_DIST
                end
            else
                inst.sg.statemem.speed = 0
                dist = 0
            end

            inst.Physics:SetMotorVel(inst.sg.statemem.speed * .5, 0, 0)
        end,

        timeline =
        {
            TimeEvent(.5 * FRAMES, function(inst)
                inst.Physics:SetMotorVel(inst.sg.statemem.speed * .75, 0, 0)
            end),
            TimeEvent(1 * FRAMES, function(inst)
                inst.Physics:SetMotorVel(inst.sg.statemem.speed, 0, 0)
            end),
            -- this is just hacked in here to make the sound play BEFORE the player hits the wormhole
            TimeEvent(15 * FRAMES, function(inst)
                inst.Physics:Stop()
                if inst.sg.statemem.target ~= nil then
                    inst.sg.statemem.target:PushEvent("starttravelsound", inst)
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    if inst.sg.statemem.target ~= nil and inst.sg.statemem.target.components.teleporter ~= nil
                        and inst.sg.statemem.target.components.teleporter:Activate(inst) then
                        inst.sg.statemem.isteleporting = true
                        inst.components.health:SetInvincible(true)
                        if inst.components.playercontroller ~= nil then
                            inst.components.playercontroller:Enable(false)
                        end
                        inst:Hide()
                        inst.DynamicShadow:Enable(false)
                    else
                        inst.sg:GoToState("jumpout")
                    end
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.isphysicstoggle then
                ToggleOnPhysics(inst)
            end

            if inst.sg.statemem.isteleporting then
                inst.components.health:SetInvincible(false)
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:Enable(true)
                end
                inst:Show()
                inst.DynamicShadow:Enable(true)
            end
        end,
    },

    State{
        name = "jumpout",
        tags = { "doing", "busy", "canrotate", "nopredict", "nomorph" },

        onenter = function(inst)
            ToggleOffPhysics(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("jumpout")

            inst.Physics:SetMotorVel(4, 0, 0)
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                inst.Physics:SetMotorVel(3, 0, 0)
            end),
            TimeEvent(15 * FRAMES, function(inst)
                inst.Physics:SetMotorVel(2, 0, 0)
            end),
            TimeEvent(15.2 * FRAMES, function(inst)
                if inst.sg.statemem.isphysicstoggle then
                    ToggleOnPhysics(inst)
                end
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
            end),
            TimeEvent(17 * FRAMES, function(inst)
                inst.Physics:SetMotorVel(1, 0, 0)
            end),
            TimeEvent(18 * FRAMES, function(inst)
                inst.Physics:Stop()
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
            if inst.sg.statemem.isphysicstoggle then
                ToggleOnPhysics(inst)
            end
        end,
    },

    State{
        name = "castspell",
        tags = { "doing", "busy", "canrotate" },

        onenter = function(inst)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            inst.AnimState:PlayAnimation("staff_pre")
            inst.AnimState:PushAnimation("staff", false)
            inst.components.locomotor:Stop()

            --Spawn an effect on the player's location
            local staff = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            local colour = staff ~= nil and staff.fxcolour or { 1, 1, 1 }

            inst.stafffx = SpawnPrefab(inst.components.rider ~= nil and inst.components.rider:IsRiding() and "staffcastfx_mount" or "staffcastfx")
            inst.stafffx.entity:SetParent(inst.entity)
            inst.stafffx:SetUp(colour)

            local stafflight = SpawnPrefab("staff_castinglight")
            stafflight.Transform:SetPosition(inst.Transform:GetWorldPosition())
            stafflight:SetUp(colour, 1.9, .33)
        end,

        timeline = 
        {
            TimeEvent(13*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/use_gemstaff") 
            end),
            TimeEvent(53*FRAMES, function(inst)
                --V2C: NOTE! if we're teleporting ourself, we may be forced to exit state here!
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
            if inst.stafffx ~= nil then
                if inst.stafffx:IsValid() then
                    inst.stafffx:Remove()
                end
                inst.stafffx = nil
            end
        end,
    },

    State{
        name = "quickcastspell",
        tags = { "doing", "busy", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_pre") 
            inst.AnimState:PushAnimation("atk", false)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
        end,

        timeline =
        {
            TimeEvent(5 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

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
        name = "quicktele",
        tags = { "doing", "busy", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

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
        name = "forcetele",
        tags = { "busy", "nopredict", "nomorph" },

        onenter = function(inst)
            ClearStatusAilments(inst)

            if inst.components.rider ~= nil then
                inst.components.rider:ActualDismount()
            end

            inst.components.locomotor:Stop()
            inst.components.health:SetInvincible(true)
            inst.DynamicShadow:Enable(false)
            inst:Hide()
            inst:ScreenFade(false, 2)

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
        end,

        onexit = function(inst)
            inst.components.health:SetInvincible(false)
            inst.DynamicShadow:Enable(true)
            inst:Show()

            if inst.sg.statemem.teleport_task ~= nil then
                -- Still have a running teleport_task
                -- Interrupt!
                inst.sg.statemem.teleport_task:Cancel()
                inst.sg.statemem.teleport_task = nil
                inst:ScreenFade(true, .5)
            end

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
        end,
    },

    State{
        name = "emote",
        tags = { "busy", "pausepredict" },

        onenter = function(inst, data)
            inst.components.locomotor:Stop()

            if data.tags ~= nil then
                for i, v in ipairs(data.tags) do
                    inst.sg:AddStateTag(v)
                end
            end

            local anim = data.anim
            local animtype = type(anim)
            if data.randomanim and animtype == "table" then
                anim = anim[math.random(#anim)]
                animtype = type(anim)
            end
            if animtype == "table" and #anim <= 1 then
                anim = anim[1]
                animtype = type(anim)
            end

            if animtype == "string" then
                inst.AnimState:PlayAnimation(anim, data.loop)
            elseif animtype == "table" then
                inst.AnimState:PlayAnimation(anim[1])
                for i = 2, #anim - 1 do
                    inst.AnimState:PushAnimation(anim[i])
                end
                inst.AnimState:PushAnimation(anim[#anim], data.loop == true)
            end

            if data.fx then --fx might be a boolean, so don't do ~= nil
                if data.fxdelay == nil or data.fxdelay == 0 then
                    DoEmoteFX(inst, data.fx)
                else
                    inst.sg.statemem.emotefxtask = inst:DoTaskInTime(data.fxdelay, DoEmoteFX, data.fx)
                end
            elseif data.fx ~= false then
                DoEmoteFX(inst, "emote_fx", nil)
            end

            if data.sound then --sound might be a boolean, so don't do ~= nil
                if data.sounddelay == nil or data.sounddelay == 0 then
                    inst.SoundEmitter:PlaySound(data.sound, "emotesound")
                else
                    inst.sg.statemem.emotesoundtask = inst:DoTaskInTime(data.sounddelay, DoEmoteSound, data.sound)
                end
            elseif data.sound ~= false then
                inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/"..(data.soundoverride or "emote"), "emotesound")
            end

            if data.zoom ~= nil then
                inst.sg.statemem.iszoomed = true
                inst:SetCameraZoomed(true)
                inst:ShowHUD(false)
            end

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
        end,

        timeline =
        {
            TimeEvent(.5, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("pausepredict")
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("emotesound")
            if inst.sg.statemem.emotefxtask ~= nil then
                inst.sg.statemem.emotefxtask:Cancel()
                inst.sg.statemem.emotefxtask = nil
            end
            if inst.sg.statemem.emotesoundtask ~= nil then
                inst.sg.statemem.emotesoundtask:Cancel()
                inst.sg.statemem.emotesoundtask = nil
            end
            if inst.sg.statemem.iszoomed then
                inst:SetCameraZoomed(false)
                inst:ShowHUD(true)
            end
        end,
    },

    State{
        name = "frozen",
        tags = { "busy", "frozen", "nopredict" },
        
        onenter = function(inst)
            if inst.components.pinnable ~= nil and inst.components.pinnable:IsStuck() then
                inst.components.pinnable:Unstick()
            end

            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
            inst.AnimState:PlayAnimation("frozen")
            inst.SoundEmitter:PlaySound("dontstarve/common/freezecreature")

            inst.components.inventory:Hide()
            inst:PushEvent("ms_closepopups")
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(false)
                inst.components.playercontroller:Enable(false)
            end

            --V2C: cuz... freezable component and SG need to match state,
            --     but messages to SG are queued, so it is not great when
            --     when freezable component tries to change state several
            --     times within one frame...
            if inst.components.freezable == nil then
                inst.sg:GoToState("hit")
            elseif inst.components.freezable:IsThawing() then
                inst.sg.statemem.isstillfrozen = true
                inst.sg:GoToState("thaw")
            elseif not inst.components.freezable:IsFrozen() then
                inst.sg:GoToState("hit")
            end
        end,

        events =
        {
            EventHandler("onthaw", function(inst)
                inst.sg.statemem.isstillfrozen = true
                inst.sg:GoToState("thaw")
            end),
            EventHandler("unfreeze", function(inst)
                inst.sg:GoToState("hit")
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.isstillfrozen then
                inst.components.inventory:Show()
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end
            end
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,
    },

    State{
        name = "thaw",
        tags = { "busy", "thawing", "nopredict" },

        onenter = function(inst) 
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:OverrideSymbol("swap_frozen", "frozen", "frozen")
            inst.AnimState:PlayAnimation("frozen_loop_pst", true)
            inst.SoundEmitter:PlaySound("dontstarve/common/freezethaw", "thawing")

            inst.components.inventory:Hide()
            inst:PushEvent("ms_closepopups")
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(false)
                inst.components.playercontroller:Enable(false)
            end
        end,

        events =
        {
            EventHandler("unfreeze", function(inst)
                inst.sg:GoToState("hit")
            end),
        },

        onexit = function(inst)
            inst.components.inventory:Show()
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(true)
                inst.components.playercontroller:Enable(true)
            end
            inst.SoundEmitter:KillSound("thawing")
            inst.AnimState:ClearOverrideSymbol("swap_frozen")
        end,
    },

    State{
        name = "pinned_pre",
        tags = { "busy", "pinned", "nopredict" },
        
        onenter = function(inst)
            if inst.components.freezable ~= nil and inst.components.freezable:IsFrozen() then
                inst.components.freezable:Unfreeze()
            end

            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:OverrideSymbol("swap_goosplat", "goo", "swap_goosplat")
            inst.AnimState:PlayAnimation("hit")

            inst.components.inventory:Hide()
            inst:PushEvent("ms_closepopups")
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(false)
                inst.components.playercontroller:Enable(false)
            end
        end,

        events =
        {
            EventHandler("onunpin", function(inst, data)
                inst.sg:GoToState("breakfree", data)
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.isstillpinned = true
                    inst.sg:GoToState("pinned")
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.isstillpinned then
                inst.components.inventory:Show()
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end
            end
            inst.AnimState:ClearOverrideSymbol("swap_goosplat")
        end,
    },

    State{
        name = "pinned",
        tags = { "busy", "pinned", "nopredict" },
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:PlayAnimation("distress_loop", true)
             -- TODO: struggle sound
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spat/spit_playerstruggle", "struggling")

            inst.components.inventory:Hide()
            inst:PushEvent("ms_closepopups")
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(false)
                inst.components.playercontroller:Enable(false)
            end
        end,

        events =
        {
            EventHandler("onunpin", function(inst, data)
                inst.sg:GoToState("breakfree", data)
            end),
        },

        onexit = function(inst)
            inst.components.inventory:Show()
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(true)
                inst.components.playercontroller:Enable(true)
            end
            inst.SoundEmitter:KillSound("struggling")
        end,
    },

    State{
        name = "pinned_hit",
        tags = { "busy", "pinned", "nopredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:PlayAnimation("hit_goo")

            inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
            DoHurtSound(inst)

            inst.components.inventory:Hide()
            inst:PushEvent("ms_closepopups")
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(false)
                inst.components.playercontroller:Enable(false)
            end
        end,

        events =
        {
            EventHandler("onunpin", function(inst, data)
                inst.sg:GoToState("breakfree", data)
            end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.isstillpinned = true
                    inst.sg:GoToState("pinned")
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.isstillpinned then
                inst.components.inventory:Show()
                if inst.components.playercontroller ~= nil then
                    inst.components.playercontroller:EnableMapControls(true)
                    inst.components.playercontroller:Enable(true)
                end
            end
        end,
    },

    State{
        name = "breakfree",
        tags = { "busy", "nopredict" },
        
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:PlayAnimation("distress_pst")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/spat/spit_playerunstuck")

            inst.components.inventory:Hide()
            inst:PushEvent("ms_closepopups")
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(false)
                inst.components.playercontroller:Enable(false)
            end
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
            inst.components.inventory:Show()
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(true)
                inst.components.playercontroller:Enable(true)
            end
        end,
    },

    State{
        name = "use_fan",
        tags = { "doing", "nopredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("fan")
            inst.AnimState:OverrideSymbol("fan01", "fan", "fan01") 
            inst.AnimState:Show("ARM_normal")
            inst.components.inventory:ReturnActiveActionItem(inst.bufferedaction ~= nil and inst.bufferedaction.invobject or nil)
        end,

        timeline =
        {
            TimeEvent(70*FRAMES, function(inst)
                inst:PerformBufferedAction()
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
            if inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
                inst.AnimState:Show("ARM_carry") 
                inst.AnimState:Hide("ARM_normal")
            end
        end,
    },

    State{
        name = "yawn",
        tags = { "busy", "yawn", "pausepredict" },

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end

            if data ~= nil and
                data.grogginess ~= nil and
                data.grogginess > 0 and
                inst.components.grogginess ~= nil then
                --Because we have the yawn state tag, we will not get
                --knocked out no matter what our grogginess level is.
                inst.sg.statemem.groggy = true
                inst.sg.statemem.knockoutduration = data.knockoutduration
                inst.components.grogginess:AddGrogginess(data.grogginess, data.knockoutduration)
            end

            inst.AnimState:PlayAnimation("yawn")
        end,

        timeline =
        {
            TimeEvent(18 * FRAMES, DoYawnSound),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:RemoveStateTag("yawn")
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.groggy and
                not inst.sg:HasStateTag("yawn") and
                inst.components.grogginess ~= nil then
                --Add a little grogginess to see if it triggers
                --knock out now that we don't have the yawn tag
                inst.components.grogginess:AddGrogginess(.01, inst.sg.statemem.knockoutduration)
            end
        end,
    },

    State
    {
        name = "migrate",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickup")

            inst.sg.statemem.action = inst.bufferedaction
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() and
                    not inst:PerformBufferedAction() then
                    inst.AnimState:PlayAnimation("pickup_pst")
                    inst.sg:GoToState("idle", true)
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
        name = "mount",
        tags = { "doing", "busy", "nomorph", "nopredict" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("mount")

            inst:PushEvent("ms_closepopups")

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
        end,

        timeline =
        {
            TimeEvent(20 * FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/beefalo/saddle/dismount")
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("mounted_idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end
        end,
    },

    State{
        name = "dismount",
        tags = { "doing", "busy", "pausepredict", "nomorph", "dismounting" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("dismount")
            inst.SoundEmitter:PlaySound("dontstarve/beefalo/saddle/dismount")

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
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
            if inst.components.rider ~= nil then
                inst.components.rider:ActualDismount()
            end
        end,
    },

    State{
        name = "falloff",
        tags = { "busy", "pausepredict", "nomorph", "dismounting" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:PlayAnimation("fall_off")
            inst.SoundEmitter:PlaySound("dontstarve/beefalo/saddle/dismount")

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
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
            if inst.components.rider ~= nil then
                inst.components.rider:ActualDismount()
            end
        end,
    },

    State{
        name = "bucked",
        tags = { "busy", "pausepredict", "nomorph", "dismounting" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()

            inst.AnimState:PlayAnimation("buck")

            if inst.components.rider ~= nil then
                DoMountSound(inst, inst.components.rider:GetMount(), "yell")
            end

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
        end,

        timeline =
        {
            TimeEvent(14 * FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/beefalo/saddle/dismount")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("bucked_post")
                end
            end),
        },

        onexit = function(inst)
            if inst.components.rider ~= nil then
                inst.components.rider:ActualDismount()
            end
        end,
    },

    State{
        name = "bucked_post",
        tags = { "busy", "pausepredict", "nomorph" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("bucked")
            inst.AnimState:PushAnimation("buck_pst", false)

            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:RemotePausePrediction()
            end
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
}

return StateGraph("wilson", states, events, "idle", actionhandlers)
