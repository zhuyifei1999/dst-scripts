local TIMEOUT = 2

local function DoEquipmentFoleySounds(inst)
    local inventory = inst.replica.inventory
    if inventory ~= nil then
        for k, v in pairs(inventory:GetEquips()) do
            if v.foleysound ~= nil then
                inst.SoundEmitter:PlaySound(v.foleysound, nil, nil, true)
            end
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
    local rider = inst.replica.rider
    local saddle = rider ~= nil and rider:GetSaddle() or nil
    if saddle ~= nil and saddle.mounted_foleysound ~= nil then
        inst.SoundEmitter:PlaySound(saddle.mounted_foleysound, nil, nil, true)
    end
end

local function DoRunSounds(inst)
    if inst.sg.mem.footsteps > 3 then
        PlayFootstep(inst, .6, true)
    else
        inst.sg.mem.footsteps = inst.sg.mem.footsteps + 1
        PlayFootstep(inst, 1, true)
    end
end

local function DoMountSound(inst, mount, sound)
    if mount ~= nil and mount.sounds ~= nil then
        inst.SoundEmitter:PlaySound(mount.sounds[sound], nil, nil, true)
    end
end

local function ConfigureRunState(inst)
    if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
        inst.sg.statemem.riding = true
        inst.sg.statemem.groggy = inst:HasTag("groggy")
    elseif inst.replica.inventory:IsHeavyLifting() then
        inst.sg.statemem.heavy = true
    elseif inst:HasTag("beaver") then
        if inst:HasTag("groggy") then
            inst.sg.statemem.groggy = true
        else
            inst.sg.statemem.normal = true
        end
    elseif inst:GetSandstormLevel() >= TUNING.SANDSTORM_FULL_LEVEL and not inst.components.playervision:HasGoggleVision() then
        inst.sg.statemem.sandstorm = true
    elseif inst:HasTag("groggy") then
        inst.sg.statemem.groggy = true
    elseif inst:IsCarefulWalking() then
        inst.sg.statemem.careful = true
    else
        inst.sg.statemem.normal = true
    end
end

local function GetRunStateAnim(inst)
    return (inst.sg.statemem.heavy and "heavy_walk")
        or (inst.sg.statemem.sandstorm and "sand_walk")
        or (inst.sg.statemem.groggy and "idle_walk")
        or (inst.sg.statemem.careful and "careful_walk")
        or "run"
end

local actionhandlers =
{
    ActionHandler(ACTIONS.CHOP,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end
            return not inst.sg:HasStateTag("prechop") and "chop_start" or nil
        end),
    ActionHandler(ACTIONS.MINE,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end
            return not inst.sg:HasStateTag("premine") and "mine_start" or nil
        end),
    ActionHandler(ACTIONS.HAMMER,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end
            return not inst.sg:HasStateTag("prehammer") and "hammer_start" or nil
        end),
    ActionHandler(ACTIONS.TERRAFORM, "terraform"),
    ActionHandler(ACTIONS.DIG,
        function(inst)
            if inst:HasTag("beaver") then
                return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
            end
            return not inst.sg:HasStateTag("predig") and "dig_start" or nil
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
    ActionHandler(ACTIONS.REEL,
        function(inst, action)
            if inst:HasTag("fishing") and inst.sg:HasStateTag("fishing") then
                local fishingrod = action.invobject ~= nil and action.invobject.replica.fishingrod or nil
                if fishingrod ~= nil then
                    return fishingrod:HasHookedFish() and "catchfish" or "fishing"
                end
            end
        end),
    ActionHandler(ACTIONS.FERTILIZE, "doshortaction"),
    ActionHandler(ACTIONS.SMOTHER,
        function(inst)
            return inst:HasTag("pyromaniac") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.MANUALEXTINGUISH,
        function(inst)
            return inst:HasTag("pyromaniac") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.TRAVEL, "doshortaction"),
    ActionHandler(ACTIONS.LIGHT, "give"),
    ActionHandler(ACTIONS.UNLOCK, "give"),
    ActionHandler(ACTIONS.USEKLAUSSACKKEY,
        function(inst)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.TURNOFF, "give"),
    ActionHandler(ACTIONS.TURNON, "give"),
    ActionHandler(ACTIONS.ADDFUEL, "doshortaction"),
    ActionHandler(ACTIONS.ADDWETFUEL, "doshortaction"),
    ActionHandler(ACTIONS.REPAIR, "dolongaction"),
    ActionHandler(ACTIONS.READ, "book"),
    ActionHandler(ACTIONS.MAKEBALLOON, "makeballoon"),
    ActionHandler(ACTIONS.DEPLOY, "doshortaction"),
    ActionHandler(ACTIONS.STORE, "doshortaction"),
    ActionHandler(ACTIONS.DROP,
        function(inst)
            return inst.replica.inventory:IsHeavyLifting()
                and not (inst.replica.rider ~= nil and inst.replica.rider:IsRiding())
                and "heavylifting_drop"
                or "doshortaction"
        end),
    ActionHandler(ACTIONS.MURDER,
        function(inst)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.UPGRADE, "dolongaction"),
    ActionHandler(ACTIONS.ACTIVATE,
        function(inst, action)
            return (action.target:HasTag("standingactivation") and "dostandingaction")
                or (action.target:HasTag("quickactivation") and "doshortaction")
                or "dolongaction"
        end),
    ActionHandler(ACTIONS.PICK,
        function(inst, action)
            return (action.target:HasTag("jostlepick") and "dojostleaction")
                or (action.target:HasTag("quickpick") and "doshortaction")
                or (inst:HasTag("fastpicker") and "doshortaction")
                or (inst:HasTag("quagmire_fasthands") and "domediumaction")
                or "dolongaction"
        end),
    ActionHandler(ACTIONS.SLEEPIN,
        function(inst, action)
            return action.invobject ~= nil and "bedroll" or "tent"
        end),
    ActionHandler(ACTIONS.TAKEITEM,
        function(inst, action)
            return action.target ~= nil
                and action.target.takeitem ~= nil --added for quagmire
                and "give"
                or "dolongaction"
        end),
    ActionHandler(ACTIONS.BUILD,
        function(inst, action)
            local rec = GetValidRecipe(action.recipe)
            return (rec ~= nil and rec.tab.shop and "give")
                or (inst:HasTag("hungrybuilder") and "dohungrybuild")
                or (inst:HasTag("fastbuilder") and "domediumaction")
                or "dolongaction"
        end),
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
            if inst.sg:HasStateTag("busy") or inst:HasTag("busy") then
                return
            end
            local obj = action.target or action.invobject
            if obj == nil then
                return
            elseif obj:HasTag("soul") then
                return inst:HasTag("beaver") and "beavereat" or "eat"
            end
            for k, v in pairs(FOODTYPE) do
                if obj:HasTag("edible_"..v) then
                    return (inst:HasTag("beaver") and "beavereat")
                        or (v == FOODTYPE.MEAT and "eat")
                        or "quickeat"
                end
            end
        end),
    ActionHandler(ACTIONS.GIVE,
        function(inst, action)
            return action.invobject ~= nil
                and action.target ~= nil
                and (   (action.target:HasTag("moonportal") and action.invobject:HasTag("moonportalkey") and "dochannelaction") or
                        (action.invobject.prefab == "quagmire_portal_key" and action.target:HasTag("quagmire_altar") and "dolongaction")
                    )
                or "give"
        end),
    ActionHandler(ACTIONS.GIVETOPLAYER, "give"),
    ActionHandler(ACTIONS.GIVEALLTOPLAYER, "give"),
    ActionHandler(ACTIONS.FEEDPLAYER, "give"),
    ActionHandler(ACTIONS.DECORATEVASE, "dolongaction"),
    ActionHandler(ACTIONS.PLANT, "doshortaction"),
    ActionHandler(ACTIONS.HARVEST,
        function(inst)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.PLAY, "play"),
    ActionHandler(ACTIONS.JUMPIN, "jumpin"),
    ActionHandler(ACTIONS.TELEPORT,
        function(inst, action)
            return action.invobject ~= nil and "dolongaction" or "give"
        end),
    ActionHandler(ACTIONS.FAN, "use_fan"),
    ActionHandler(ACTIONS.DRY, "doshortaction"),
    ActionHandler(ACTIONS.CASTSPELL,
        function(inst, action)
            return action.invobject ~= nil
                and action.invobject:HasTag("quickcast")
                and "quickcastspell"
                or "castspell"
        end),
    ActionHandler(ACTIONS.CASTAOE,
        function(inst, action)
            return action.invobject ~= nil
                and (   (action.invobject:HasTag("aoeweapon_lunge") and "combat_lunge_start") or
                        (action.invobject:HasTag("aoeweapon_leap") and (action.invobject:HasTag("superjump") and "combat_superjump_start" or "combat_leap_start")) or
                        (action.invobject:HasTag("blowdart") and "blowdart_special") or
                        (action.invobject:HasTag("throw_line") and "throw_line") or
                        (action.invobject:HasTag("book") and "book") or
                        (action.invobject:HasTag("parryweapon") and "parry_pre")
                    )
                or "castspell"
        end),
    ActionHandler(ACTIONS.BLINK,
        function(inst, action)
            return action.invobject == nil and inst:HasTag("soulstealer") and "portal_jumpin_pre" or "quicktele"
        end),
    ActionHandler(ACTIONS.COMBINESTACK, "doshortaction"),
    ActionHandler(ACTIONS.FEED, "dolongaction"),
    ActionHandler(ACTIONS.ATTACK,
        function(inst, action)
            if not (inst.sg:HasStateTag("attack") and action.target == inst.sg.statemem.attacktarget or inst.replica.health:IsDead()) then
                local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                if equip == nil then
                    return "attack"
                end
                local inventoryitem = equip.replica.inventoryitem
                return (not (inventoryitem ~= nil and inventoryitem:IsWeapon()) and "attack")
                    or (equip:HasTag("blowdart") and "blowdart")
                    or (equip:HasTag("thrown") and "throw")
                    or (equip:HasTag("propweapon") and "attack_prop_pre")
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
    ActionHandler(ACTIONS.ABANDON, "dolongaction"),
    ActionHandler(ACTIONS.PET, "dolongaction"),
    ActionHandler(ACTIONS.DRAW, "dolongaction"),
    ActionHandler(ACTIONS.BUNDLE, "bundle"),
    ActionHandler(ACTIONS.UNWRAP,
        function(inst, action)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.CONSTRUCT,
        function(inst, action)
            return (action.target == nil or not action.target:HasTag("constructionsite")) and "startconstruct" or "construct"
        end),
    ActionHandler(ACTIONS.STARTCHANNELING, "startchanneling"),
    ActionHandler(ACTIONS.REVIVE_CORPSE, "dolongaction"),

    --Quagmire
    ActionHandler(ACTIONS.TILL, "till_start"),
    ActionHandler(ACTIONS.PLANTSOIL,
        function(inst, action)
            return (inst:HasTag("quagmire_farmhand") and "doshortaction")
                or (inst:HasTag("quagmire_fasthands") and "domediumaction")
                or "dolongaction"
        end),
    ActionHandler(ACTIONS.INSTALL,
        function(inst, action)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.TAPTREE,
        function(inst, action)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.SLAUGHTER,
        function(inst, action)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.REPLATE,
        function(inst, action)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
    ActionHandler(ACTIONS.SALT,
        function(inst, action)
            return inst:HasTag("quagmire_fasthands") and "domediumaction" or "dolongaction"
        end),
}

local events =
{
    EventHandler("locomote", function(inst)
        if inst.sg:HasStateTag("busy") or inst:HasTag("busy") then
            return
        end
        local is_moving = inst.sg:HasStateTag("moving")
        local should_move = inst.components.locomotor:WantsToMoveForward()

        if inst:HasTag("sleeping") then
            if should_move and not inst.sg:HasStateTag("waking") then
                inst.sg:GoToState("wakeup")
            end
        elseif not inst.entity:CanPredictMovement() then
            if not inst.sg:HasStateTag("idle") then
                inst.sg:GoToState("idle")
            end
        elseif is_moving and not should_move then
            inst.sg:GoToState("run_stop")
        elseif not is_moving and should_move then
            inst.sg:GoToState("run_start")
        end
    end),
}

local states =
{
    State
    {
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst, pushanim)
            inst.entity:SetIsPredictingMovement(false)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()

            if pushanim == "cancel" then
                return
            elseif inst:HasTag("nopredict") or inst:HasTag("pausepredict") then
                inst:ClearBufferedAction()
                return
            elseif pushanim == "noanim" then
                inst.sg:SetTimeout(TIMEOUT)
                return
            end

            --V2C: Only predict looped anims. For idles with a pre, stick with
            --     "idle_loop" and wait for server to trigger the custom anims
            local anim =
                (inst.replica.rider ~= nil and inst.replica.rider:IsRiding() and "idle_loop") or
                (inst:HasTag("beaver") and "idle_loop") or
                (inst.replica.inventory ~= nil and inst.replica.inventory:IsHeavyLifting() and "heavy_idle") or
                (   inst:GetSandstormLevel() >= TUNING.SANDSTORM_FULL_LEVEL and
                    not inst.components.playervision:HasGoggleVision() and
                    (   inst.AnimState:IsCurrentAnimation("sand_walk_pst") or
                        inst.AnimState:IsCurrentAnimation("sand_walk") or
                        inst.AnimState:IsCurrentAnimation("sand_walk_pre")
                    ) and
                    "sand_idle_loop"
                ) or
                "idle_loop"

            if pushanim then
                inst.AnimState:PushAnimation(anim, true)
            else
                inst.AnimState:PlayAnimation(anim, true)
            end
        end,

        ontimeout = function(inst)
            if inst.bufferedaction ~= nil and inst.bufferedaction.ispreviewing then
                inst:ClearBufferedAction()
            end
        end,

        onexit = function(inst)
            inst.entity:SetIsPredictingMovement(true)
        end,
    },

    State
    {
        name = "run_start",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
            ConfigureRunState(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PlayAnimation(GetRunStateAnim(inst).."_pre")
            inst.sg.mem.footsteps = 0
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

            --heavy lifting
            TimeEvent(1 * FRAMES, function(inst)
                if inst.sg.statemem.heavy then
                    PlayFootstep(inst, nil, true)
                    DoFoleySounds(inst)
                end
            end),

            --unmounted
            TimeEvent(4 * FRAMES, function(inst)
                if inst.sg.statemem.normal then
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

    State
    {
        name = "run",
        tags = { "moving", "running", "canrotate" },

        onenter = function(inst)
            ConfigureRunState(inst)
            inst.components.locomotor:RunForward()

            local anim = GetRunStateAnim(inst)
            if anim == "run" then
                anim = "run_loop"
            end
            if not inst.AnimState:IsCurrentAnimation(anim) then
                inst.AnimState:PlayAnimation(anim, true)
            end

            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            --unmounted
            TimeEvent(7 * FRAMES, function(inst)
                if inst.sg.statemem.normal then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),
            TimeEvent(15 * FRAMES, function(inst)
                if inst.sg.statemem.normal then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),

            --careful
            --Frame 11 shared with heavy lifting below
            --[[TimeEvent(11 * FRAMES, function(inst)
                if inst.sg.statemem.careful then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),]]
            TimeEvent(26 * FRAMES, function(inst)
                if inst.sg.statemem.careful then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),

            --sandstorm
            --Frame 12 shared with groggy below
            --[[TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.sandstorm then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),]]
            TimeEvent(23 * FRAMES, function(inst)
                if inst.sg.statemem.sandstorm then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),

            --groggy
            TimeEvent(1 * FRAMES, function(inst)
                if inst.sg.statemem.groggy then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),
            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.groggy or
                    inst.sg.statemem.sandstorm then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),

            --heavy lifting
            TimeEvent(11 * FRAMES, function(inst)
                if inst.sg.statemem.heavy or
                    inst.sg.statemem.sandstorm or
                    inst.sg.statemem.careful then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),
            TimeEvent(36 * FRAMES, function(inst)
                if inst.sg.statemem.heavy or
                    inst.sg.statemem.sandstorm or
                    inst.sg.statemem.careful then
                    DoRunSounds(inst)
                    DoFoleySounds(inst)
                end
            end),

            --mounted
            TimeEvent(0, function(inst)
                if inst.sg.statemem.riding then
                    DoMountedFoleySounds(inst)
                end
            end),
            TimeEvent(5 * FRAMES, function(inst)
                if inst.sg.statemem.riding then
                    DoRunSounds(inst)
                end
            end),
        },

        events =
        {
            EventHandler("gogglevision", function(inst, data)
                if data.enabled then
                    if inst.sg.statemem.sandstorm then
                        inst.sg:GoToState("run")
                    end
                elseif not (inst.sg.statemem.riding or
                            inst.sg.statemem.heavy or
                            inst.sg.statemem.sandstorm or
                            inst:GetSandstormLevel() < TUNING.SANDSTORM_FULL_LEVEL) then
                    inst.sg:GoToState("run")
                end
            end),
            EventHandler("sandstormlevel", function(inst, data)
                if data.level < TUNING.SANDSTORM_FULL_LEVEL then
                    if inst.sg.statemem.sandstorm then
                        inst.sg:GoToState("run")
                    end
                elseif not (inst.sg.statemem.riding or
                            inst.sg.statemem.heavy or
                            inst.sg.statemem.sandstorm or
                            inst.components.playervision:HasGoggleVision()) then
                    inst.sg:GoToState("run")
                end
            end),
            EventHandler("carefulwalking", function(inst, data)
                if not data.careful then
                    if inst.sg.statemem.careful then
                        inst.sg:GoToState("run")
                    end
                elseif not (inst.sg.statemem.riding or
                            inst.sg.statemem.heavy or
                            inst.sg.statemem.sandstorm or
                            inst.sg.statemem.groggy or
                            inst.sg.statemem.careful) then
                    inst.sg:GoToState("run")
                end
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("run")
        end,
    },

    State
    {
        name = "run_stop",
        tags = { "canrotate", "idle" },

        onenter = function(inst)
            ConfigureRunState(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation(GetRunStateAnim(inst).."_pst")
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

    State
    {
        name = "previewaction",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst.AnimState:IsCurrentAnimation("idle_loop") then
                inst.AnimState:PlayAnimation("idle_loop", true)
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst.bufferedaction == nil then
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "chop_start",
        tags = { "prechop", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst:HasTag("working") then
                if inst:HasTag("woodcutter") then
                    inst.AnimState:PlayAnimation("woodie_chop_pre")
                    inst.AnimState:PushAnimation("woodie_chop_lag", false)
                else
                    inst.AnimState:PlayAnimation("chop_pre")
                    inst.AnimState:PushAnimation("chop_lag", false)
                end
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("working") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "mine_start",
        tags = { "premine", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst:HasTag("working") then
                inst.AnimState:PlayAnimation("pickaxe_pre")
                inst.AnimState:PushAnimation("pickaxe_lag", false)
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("working") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("pickaxe_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("pickaxe_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "hammer_start",
        tags = { "prehammer", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst:HasTag("working") then
                inst.AnimState:PlayAnimation("pickaxe_pre")
                inst.AnimState:PushAnimation("pickaxe_lag", false)
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("working") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("pickaxe_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("pickaxe_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "gnaw",
        tags = { "gnawing", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst:HasTag("working") then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk_lag", false)
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("working") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "parry_pre",
        tags = { "preparrying", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("parry_pre")
            inst.AnimState:PushAnimation("parry_loop", true)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("parry_pst")
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("parry_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "terraform",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("shovel_pre")
            inst.AnimState:PushAnimation("shovel_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("shovel_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("shovel_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "dig_start",
        tags = { "predig", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst:HasTag("working") then
                inst.AnimState:PlayAnimation("shovel_pre")
                inst.AnimState:PushAnimation("shovel_lag", false)
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("working") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("shovel_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("shovel_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "bugnet_start",
        tags = { "prenet", "working" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("bugnet_pre")

            inst:PerformPreviewBufferedAction()
            inst:ClearBufferedAction()
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

    State
    {
        name = "bugnet",
        tags = { "prenet", "netting", "working" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("bugnet")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/use_bugnet", nil, nil, true)
        end,

        timeline =
        {
            TimeEvent(10 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("prenet")
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

    State
    {
        name = "fishing_pre",
        tags = { "prefish", "fishing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("fishing_pre")
            inst.AnimState:PushAnimation("fishing_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("fishing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("fishing")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "fishing",
        tags = { "fishing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:PerformPreviewBufferedAction()
            inst.entity:FlattenMovementPrediction()
            inst.entity:SetIsPredictingMovement(false)
        end,

        onupdate = function(inst)
            if not inst:HasTag("fishing") then
                inst:ClearBufferedAction()
                inst.sg:GoToState("idle", "noanim")
            end
        end,

        onexit = function(inst)
            inst.entity:SetIsPredictingMovement(true)
        end,
    },

    State
    {
        name = "catchfish",
        tags = { "fishing", "catchfish", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:PerformPreviewBufferedAction()
            inst.entity:FlattenMovementPrediction()
            inst.entity:SetIsPredictingMovement(false)
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") or
                not inst:HasTag("fishing") or
                inst.bufferedaction == nil then
                inst.sg:GoToState("idle", inst.entity:FlattenMovementPrediction() and "noanim" or nil)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle", inst.entity:FlattenMovementPrediction() and "noanim" or nil)
        end,

        onexit = function(inst)
            inst.entity:SetIsPredictingMovement(true)
        end,
    },

    State
    {
        name = "give",
        tags = { "giving" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst:HasTag("giving") then
                inst.AnimState:PlayAnimation("give")
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("giving") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("give_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("give_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "bedroll",
        tags = { "bedroll", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("action_uniqueitem_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") or inst:HasTag("sleeping") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "tent",
        tags = { "tent", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickup")
            inst.AnimState:PushAnimation("pickup_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") or inst:HasTag("sleeping") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("pickup_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("pickup_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "wakeup",
        tags = { "busy", "waking" },

        onenter = function(inst)
            inst.entity:SetIsPredictingMovement(false)
            inst.entity:FlattenMovementPrediction()
            SendRPCToServer(RPC.WakeUp)
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") and
                inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("idle", "noanim")
        end,

        onexit = function(inst)
            inst.entity:SetIsPredictingMovement(true)
        end,
    },

    State
    {
        name = "eat",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("eat_pre")
            inst.AnimState:PushAnimation("eat_lag", false)
            
            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "quickeat",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("quick_eat_pre")
            inst.AnimState:PushAnimation("quick_eat_lag", false)
 
            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "beavereat",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("eat_pre")
            inst.AnimState:PushAnimation("eat_lag", false)
 
            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "usewardrobe",
        tags = { "doing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst:HasTag("doing") then
                inst.AnimState:PlayAnimation("give")
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("give_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("give_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "unsaddle",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("unsaddle_pre")
            inst.AnimState:PushAnimation("unsaddle_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("unsaddle")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("unsaddle")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "heavylifting_drop",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("heavy_item_hat")
            inst.AnimState:PushAnimation("heavy_item_hat_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("heavy_item_hat_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("heavy_item_hat_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "dostandingaction",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("give")

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("give_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("give_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "doshortaction",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pickup")
            inst.AnimState:PushAnimation("pickup_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("pickup_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("pickup_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "dohungrybuild",

        onenter = function(inst)
            inst.sg:GoToState("dolongaction")
        end,
    },

    State
    {
        name = "domediumaction",

        onenter = function(inst)
            inst.sg:GoToState("dolongaction")
        end,
    },

    State
    {
        name = "dolongaction",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make_preview")
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("build_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("build_pst")
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("make_preview")
        end,
    },

    State
    {
        name = "dojostleaction",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            local rider = inst.replica.rider
            if rider ~= nil and rider:IsRiding() then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk_lag", false)
            elseif equip ~= nil and equip:HasTag("whip") then
                inst.AnimState:PlayAnimation("whip_pre")
                inst.AnimState:PushAnimation("whip_lag", false)
                inst.sg.statemem.iswhip = true
            elseif equip ~= nil and
                equip.replica.inventoryitem ~= nil and
                equip.replica.inventoryitem:IsWeapon() and
                not equip:HasTag("punch") then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk_lag", false)
            elseif equip ~= nil and
                (equip:HasTag("light") or
                equip:HasTag("nopunch")) then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk_lag", false)
            elseif inst:HasTag("beaver") then
                inst.sg.statemem.isbeaver = true
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk_lag", false)
            else
                inst.AnimState:PlayAnimation("punch")
            end

            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                inst:PerformPreviewBufferedAction()

                if buffaction.target ~= nil and buffaction.target:IsValid() then
                    inst:FacePoint(buffaction.target:GetPosition())
                end
            end

            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                if inst.sg.statemem.isbeaver then
                    inst.sg:RemoveStateTag("busy")
                end
            end),
            TimeEvent(6 * FRAMES, function(inst)
                if not (inst.sg.statemem.isbeaver or
                        inst.sg.statemem.iswhip) then
                    inst.sg:RemoveStateTag("busy")
                end
            end),
            TimeEvent(8 * FRAMES, function(inst)
                if inst.sg.statemem.iswhip then
                    inst.sg:RemoveStateTag("busy")
                end
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "dochannelaction",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("channel_pre")
            inst.AnimState:PushAnimation("channel_loop", true)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("channel_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("channel_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "makeballoon",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make_preview")
            inst.AnimState:PlayAnimation("build_pre")
            inst.AnimState:PushAnimation("build_loop", true)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("build_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("build_pst")
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("make_preview")
        end,
    },

    State
    {
        name = "shave",
        tags = { "doing", "shaving" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            --TODO: need a shave_pre animation
            if not inst.AnimState:IsCurrentAnimation("idle_loop") then
                inst.AnimState:PlayAnimation("idle_loop", true)
            end
            --HACK: Let server animate since we don't have shave_pre
            inst.entity:SetIsPredictingMovement(false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,

        onexit = function(inst)
            inst.entity:SetIsPredictingMovement(true)
        end,
    },

    State
    {
        name = "play",
        tags = { "doing", "playing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("action_uniqueitem_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "use_fan",
        tags = { "doing" },

        onenter = function(inst)
            local invobject = nil
            if inst.bufferedaction ~= nil and
                inst.bufferedaction.invobject ~= nil and
                inst.bufferedaction.invobject:HasTag("channelingfan") then
                inst.sg:AddStateTag("busy")
            end
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("action_uniqueitem_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "book",
        tags = { "doing" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("action_uniqueitem_lag", false)

            local item = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if item ~= nil and item.components.aoetargeting ~= nil then
                inst.sg:AddStateTag("busy")
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "jumpin",
        tags = { "doing", "busy", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            local heavy = inst.replica.inventory:IsHeavyLifting()
            inst.AnimState:PlayAnimation(heavy and "heavy_jump_pre" or "jump_pre")
            inst.AnimState:PushAnimation(heavy and "heavy_jump_lag" or "jump_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "castspell",
        tags = { "doing", "busy", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("staff_pre")
            inst.AnimState:PushAnimation("staff_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "quickcastspell",
        tags = { "doing", "busy", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
                inst.AnimState:PlayAnimation("player_atk_pre")
                inst.AnimState:PushAnimation("player_atk_lag", false)
            else
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk_lag", false)
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "quicktele",
        tags = { "doing", "busy", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if inst.replica.rider ~= nil and inst.replica.rider:IsRiding() then
                inst.AnimState:PlayAnimation("player_atk_pre")
                inst.AnimState:PushAnimation("player_atk_lag", false)
            else
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk_lag", false)
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "combat_lunge_start",
        tags = { "doing", "busy", "nointerrupt" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("lunge_pre")
            inst.AnimState:PushAnimation("lunge_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                inst.sg.statemem.twirled = true
                inst.SoundEmitter:PlaySound("dontstarve/common/twirl", nil, nil, true)
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    if not inst.sg.statemem.twirled then
                        inst.SoundEmitter:PlaySound("dontstarve/common/twirl", nil, nil, true)
                    end
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "combat_leap_start",
        tags = { "doing", "busy", "nointerrupt" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_leap_pre")
            inst.AnimState:PlayAnimation("atk_leap_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "combat_superjump_start",
        tags = { "doing", "busy", "nointerrupt" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("superjump_pre")
            inst.AnimState:PushAnimation("superjump_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "blowdart_special",
        tags = { "doing", "busy", "nointerrupt" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("dart_pre")
            inst.AnimState:PushAnimation("dart_lag", false)

            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                inst:PerformPreviewBufferedAction()

                if buffaction.pos ~= nil then
                    inst:ForceFacePoint(buffaction.pos:Get())
                end
            end

            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "throw_line",
        tags = { "doing", "busy", "nointerrupt" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk_lag", false)

            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                inst:PerformPreviewBufferedAction()

                if buffaction.pos ~= nil then
                    inst:ForceFacePoint(buffaction.pos:Get())
                end
            end

            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "catch_pre",
        tags = { "notalking", "readytocatch" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            if not inst.AnimState:IsCurrentAnimation("catch_pre") then
                inst.AnimState:PlayAnimation("catch_pre")
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(3 + TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "attack",
        tags = { "attack", "notalking", "abouttoattack" },

        onenter = function(inst)
            local cooldown = 0
            if inst.replica.combat ~= nil then
                inst.replica.combat:StartAttack()
                cooldown = inst.replica.combat:MinAttackPeriod() + .5 * FRAMES
            end
            inst.components.locomotor:Stop()
            local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            local rider = inst.replica.rider
            if rider ~= nil and rider:IsRiding() then
                if equip ~= nil and (equip:HasTag("rangedweapon") or equip:HasTag("projectile")) then
                    inst.AnimState:PlayAnimation("player_atk_pre")
                    inst.AnimState:PushAnimation("player_atk", false)
                    if (equip.projectiledelay or 0) > 0 then
                        --V2C: Projectiles don't show in the initial delayed frames so that
                        --     when they do appear, they're already in front of the player.
                        --     Start the attack early to keep animation in sync.
                        inst.sg.statemem.projectiledelay = 8 * FRAMES - equip.projectiledelay
                        if inst.sg.statemem.projectiledelay > FRAMES then
                            inst.sg.statemem.projectilesound =
                                (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                                (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                                "dontstarve/wilson/attack_weapon"
                        elseif inst.sg.statemem.projectiledelay <= 0 then
                            inst.sg.statemem.projectiledelay = nil
                        end
                    end
                    if inst.sg.statemem.projectilesound == nil then
                        inst.SoundEmitter:PlaySound(
                            (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                            (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                            "dontstarve/wilson/attack_weapon",
                            nil, nil, true
                        )
                    end
                    if cooldown > 0 then
                        cooldown = math.max(cooldown, 13 * FRAMES)
                    end
                else
                    inst.AnimState:PlayAnimation("atk_pre")
                    inst.AnimState:PushAnimation("atk", false)
                    DoMountSound(inst, rider:GetMount(), "angry")
                    if cooldown > 0 then
                        cooldown = math.max(cooldown, 16 * FRAMES)
                    end
                end
            elseif equip ~= nil and equip:HasTag("whip") then
                inst.AnimState:PlayAnimation("whip_pre")
                inst.AnimState:PushAnimation("whip", false)
                inst.sg.statemem.iswhip = true
                inst.SoundEmitter:PlaySound("dontstarve/common/whip_pre", nil, nil, true)
                if cooldown > 0 then
                    cooldown = math.max(cooldown, 17 * FRAMES)
                end
            elseif equip ~= nil and equip:HasTag("book") then
                inst.AnimState:PlayAnimation("attack_book")
                inst.sg.statemem.isbook = true
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                if cooldown > 0 then
                    cooldown = math.max(cooldown, 19 * FRAMES)
                end
            elseif equip ~= nil and equip:HasTag("chop_attack") and inst:HasTag("woodcutter") then
                inst.AnimState:PlayAnimation(inst.AnimState:IsCurrentAnimation("woodie_chop_loop") and inst.AnimState:GetCurrentAnimationTime() < 7.1 * FRAMES and "woodie_chop_atk_pre" or "woodie_chop_pre")
                inst.AnimState:PushAnimation("woodie_chop_loop", false)
                inst.sg.statemem.ischop = true
                cooldown = math.max(cooldown, 11 * FRAMES)
            elseif equip ~= nil and
                equip.replica.inventoryitem ~= nil and
                equip.replica.inventoryitem:IsWeapon() and
                not equip:HasTag("punch") then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                if (equip.projectiledelay or 0) > 0 then
                    --V2C: Projectiles don't show in the initial delayed frames so that
                    --     when they do appear, they're already in front of the player.
                    --     Start the attack early to keep animation in sync.
                    inst.sg.statemem.projectiledelay = 8 * FRAMES - equip.projectiledelay
                    if inst.sg.statemem.projectiledelay > FRAMES then
                        inst.sg.statemem.projectilesound =
                            (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                            (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                            "dontstarve/wilson/attack_weapon"
                    elseif inst.sg.statemem.projectiledelay <= 0 then
                        inst.sg.statemem.projectiledelay = nil
                    end
                end
                if inst.sg.statemem.projectilesound == nil then
                    inst.SoundEmitter:PlaySound(
                        (equip:HasTag("icestaff") and "dontstarve/wilson/attack_icestaff") or
                        (equip:HasTag("shadow") and "dontstarve/wilson/attack_nightsword") or
                        (equip:HasTag("firestaff") and "dontstarve/wilson/attack_firestaff") or
                        "dontstarve/wilson/attack_weapon",
                        nil, nil, true
                    )
                end
                if cooldown > 0 then
                    cooldown = math.max(cooldown, 13 * FRAMES)
                end
            elseif equip ~= nil and
                (equip:HasTag("light") or
                equip:HasTag("nopunch")) then
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                if cooldown > 0 then
                    cooldown = math.max(cooldown, 13 * FRAMES)
                end
            elseif inst:HasTag("beaver") then
                inst.sg.statemem.isbeaver = true
                inst.AnimState:PlayAnimation("atk_pre")
                inst.AnimState:PushAnimation("atk", false)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                if cooldown > 0 then
                    cooldown = math.max(cooldown, 8 * FRAMES)
                end
            else
                inst.AnimState:PlayAnimation("punch")
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, nil, true)
                if cooldown > 0 then
                    cooldown = math.max(cooldown, 24 * FRAMES)
                end
            end

            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                inst:PerformPreviewBufferedAction()

                if buffaction.target ~= nil and buffaction.target:IsValid() then
                    inst:FacePoint(buffaction.target:GetPosition())
                    inst.sg.statemem.attacktarget = buffaction.target
                end
            end

            if cooldown > 0 then
                inst.sg:SetTimeout(cooldown)
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
                        inst:ClearBufferedAction()
                        inst.sg:RemoveStateTag("abouttoattack")
                    end
                end
            end
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
                if inst.sg.statemem.isbeaver then
                    inst:ClearBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                elseif inst.sg.statemem.ischop then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
                end
            end),
            TimeEvent(8 * FRAMES, function(inst)
                if not (inst.sg.statemem.isbeaver or
                        inst.sg.statemem.iswhip or
                        inst.sg.statemem.isbook) and
                    inst.sg.statemem.projectiledelay == nil then
                    inst:ClearBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(10 * FRAMES, function(inst)
                if inst.sg.statemem.iswhip or inst.sg.statemem.isbook then
                    inst:ClearBufferedAction()
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
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
                inst.replica.combat:CancelAttack()
            end
        end,
    },

    State
    {
        name = "attack_prop_pre",
        tags = { "propattack", "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_prop_pre")
            inst.AnimState:PushAnimation("atk_prop_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },

    State
    {
        name = "throw",
        tags = { "attack", "notalking", "abouttoattack" },

        onenter = function(inst)
            if inst.replica.combat ~= nil then
                inst.replica.combat:StartAttack()
                inst.sg:SetTimeout(math.max(11 * FRAMES, inst.replica.combat:MinAttackPeriod() + .5 * FRAMES))
            end
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("throw")

            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                inst:PerformPreviewBufferedAction()

                if buffaction.target ~= nil and buffaction.target:IsValid() then
                    inst:FacePoint(buffaction.target:GetPosition())
                    inst.sg.statemem.attacktarget = buffaction.target
                end
            end
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst:ClearBufferedAction()
                inst.sg:RemoveStateTag("abouttoattack")
            end),
        },

        ontimeout = function(inst)
            inst.sg:RemoveStateTag("attack")
            inst.sg:AddStateTag("idle")
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
            if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
                inst.replica.combat:CancelAttack()
            end
        end,
    },

    State
    {
        name = "blowdart",
        tags = { "attack", "notalking", "abouttoattack" },

        onenter = function(inst)
            local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("dart_pre")
            if inst.sg.prevstate == inst.sg.currentstate then
                inst.sg.statemem.chained = true
                inst.AnimState:SetTime(5 * FRAMES)
            end
            inst.AnimState:PushAnimation("dart", false)

            if inst.replica.combat ~= nil then
                inst.replica.combat:StartAttack()
                inst.sg:SetTimeout(math.max((inst.sg.statemem.chained and 14 or 18) * FRAMES, inst.replica.combat:MinAttackPeriod() + .5 * FRAMES))
            end

            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                inst:PerformPreviewBufferedAction()

                if buffaction.target ~= nil and buffaction.target:IsValid() then
                    inst:FacePoint(buffaction.target:GetPosition())
                    inst.sg.statemem.attacktarget = buffaction.target
                end
            end

            if (equip.projectiledelay or 0) > 0 then
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
                    inst:ClearBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, function(inst)
                if inst.sg.statemem.chained then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot", nil, nil, true)
                end
            end),
            TimeEvent(9 * FRAMES, function(inst)
                if inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:ClearBufferedAction()
                    inst.sg:RemoveStateTag("abouttoattack")
                end
            end),
            TimeEvent(13 * FRAMES, function(inst)
                if not inst.sg.statemem.chained then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/blowdart_shoot", nil, nil, true)
                end
            end),
            TimeEvent(14 * FRAMES, function(inst)
                if not inst.sg.statemem.chained and inst.sg.statemem.projectiledelay == nil then
                    inst:ClearBufferedAction()
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
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            if inst.sg:HasStateTag("abouttoattack") and inst.replica.combat ~= nil then
                inst.replica.combat:CancelAttack()
            end
        end,
    },

    State
    {
        name = "migrate",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.sg.statemem.heavy = inst.replica.inventory:IsHeavyLifting()
            inst.components.locomotor:Stop()
            if inst.sg.statemem.heavy then
                inst.AnimState:PlayAnimation("heavy_item_hat")
                inst.AnimState:PushAnimation("heavy_item_hat_lag", false)
            else
                inst.AnimState:PlayAnimation("pickup")
                inst.AnimState:PushAnimation("pickup_lag", false)
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation(inst.sg.statemem.heavy and "heavy_item_hat_pst" or "pickup_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation(inst.sg.statemem.heavy and "heavy_item_hat_pst" or "pickup_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "bundle",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make_preview")
            inst.AnimState:PlayAnimation("wrap_pre")
            inst.AnimState:PushAnimation("wrap_loop", true)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("wrap_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("wrap_pst")
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("make_preview")
        end,
    },

    State
    {
        name = "startconstruct",

        onenter = function(inst)
            inst.sg:GoToState("construct", true)
        end,
    },

    State
    {
        name = "construct",
        tags = { "doing", "busy" },

        onenter = function(inst, start)
            inst.components.locomotor:Stop()
            inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make_preview")
            if start then
                inst.sg.statemem.start = true
                inst.AnimState:PlayAnimation("build_pre")
                inst.AnimState:PushAnimation("build_loop", true)
            else
                inst.AnimState:PlayAnimation("construct_pre")
                inst.AnimState:PushAnimation("construct_loop", true)
            end

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(4 * FRAMES, function(inst)
                if inst.sg.statemem.start then
                    inst.sg:RemoveStateTag("busy")
                end
            end),
            TimeEvent(10 * FRAMES, function(inst)
                if not inst.sg.statemem.start then
                    inst.sg:RemoveStateTag("busy")
                end
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation(inst.sg.statemem.start and "build_pst" or "construct_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation(inst.sg.statemem.start and "build_pst" or "construct_pst")
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            inst.SoundEmitter:KillSound("make_preview")
        end,
    },

    State
    {
        name = "startchanneling",
        tags = { "doing", "busy", "prechanneling" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("channel_pre")
            inst.AnimState:PushAnimation("channel_loop", true)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
            end),
        },

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("channel_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("channel_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "till_start",
        tags = { "doing", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("till_pre")
            inst.AnimState:PushAnimation("till_lag", false)

            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("doing") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.AnimState:PlayAnimation("till_pst")
                inst.sg:GoToState("idle", true)
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("till_pst")
            inst.sg:GoToState("idle", true)
        end,
    },

    State
    {
        name = "portal_jumpin_pre",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("wortox_portal_jumpin_pre")
            inst.AnimState:PushAnimation("wortox_portal_jumpin_lag", false)

            local buffaction = inst:GetBufferedAction()
            if buffaction ~= nil then
                inst:PerformPreviewBufferedAction()

                if buffaction.pos ~= nil then
                    inst:ForceFacePoint(buffaction.pos:Get())
                end
            end

            inst.sg:SetTimeout(TIMEOUT)
        end,

        onupdate = function(inst)
            if inst:HasTag("busy") then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

        ontimeout = function(inst)
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle")
        end,
    },
}

return StateGraph("wilson_client", states, events, "idle", actionhandlers)
