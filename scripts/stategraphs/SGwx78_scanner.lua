require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnLocomote(false, true),

    EventHandler("deployed", function(inst)
        inst.sg:GoToState("turn_on")
    end),

    EventHandler("turn_off", function(inst, data)
        inst.sg:GoToState("turn_off", data)
    end),

    EventHandler("scan_success", function(inst)
        inst.sg:GoToState("scan_success")
    end)
}

local function return_to_idle(inst)
    inst.sg:GoToState("idle")
end

local function targetinrange(inst)
    local scandist = inst:GetScannerScanDistance()
    local scandist_sq = scandist * scandist
    local scantarget = inst.components.entitytracker:GetEntity("scantarget")
    return scantarget ~= nil and inst:GetDistanceSqToInst(scantarget) < scandist_sq or nil
end

local function SetShadowScale(inst, scale)
    inst.DynamicShadow:SetSize(1.2 * scale, 0.75 * scale)
end

local states =
{
    State {
        name = "idle",
        tags = {"idle"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.components.locomotor:Clear()

            inst.AnimState:PlayAnimation(targetinrange(inst) and "scan_loop" or "idle", true)
        end,

        events =
        {
            EventHandler("animover", return_to_idle),
        },
    },

    State {
        name = "turn_on",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("turn_on", false)
            SetShadowScale(inst, 0)

            if not POPULATING then
                inst:PushEvent("on_landed")
            end
        end,

        timeline =
        {
            FrameEvent(9, function(inst)
                inst:PushEvent("on_no_longer_landed")
            end),
            FrameEvent(5, function(inst) SetShadowScale(inst, 0.1) end),
            FrameEvent(6, function(inst) SetShadowScale(inst, 0.2) end),
            FrameEvent(7, function(inst) SetShadowScale(inst, 0.5) end),
            FrameEvent(8, function(inst) SetShadowScale(inst, 0.7) end),
            FrameEvent(9, function(inst) SetShadowScale(inst, 0.9) end),
            FrameEvent(10, function(inst) SetShadowScale(inst, 1) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst:PushEvent("turn_on_finished")
                inst.sg:GoToState("idle")
            end),
        },
    },

    State {
        name = "turn_off",
        tags = {"busy", "scanned"},

        onenter = function(inst, data)
            if data then
                if data.changetoitem then
                    inst.sg.statemem.changetoitem = true
                elseif data.changetosuccess then
                    inst.sg.statemem.changetosuccess = true
                end

                if data.hit then
                    inst.sg.statemem.washit = true
                end
            end

            if inst.DoTurnOff then
                inst:DoTurnOff()
            end

            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation(inst.sg.statemem.washit and "hit_turn_off_pre" or "turn_off_pre")
            inst.SoundEmitter:PlaySound(inst.skin_sound and inst.skin_sound.deactivate or "WX_rework/scanner/deactivate")

            -- Stuff that might be on due to scanning
            inst:StopScanFX()
            inst.AnimState:Hide("bottom_light")
        end,

        timeline =
        {
            FrameEvent(6, function(inst) SetShadowScale(inst, 0.9) end),
            FrameEvent(7, function(inst) SetShadowScale(inst, 0.7) end),
            FrameEvent(8, function(inst) SetShadowScale(inst, 0.5) end),
            FrameEvent(9, function(inst) SetShadowScale(inst, 0.2) end),
            FrameEvent(10, function(inst) SetShadowScale(inst, 0) end),
            FrameEvent(14, function(inst)
                inst:PushEvent("on_landed")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.sg.statemem.changetoitem then
                    local scanner_item = SpawnPrefab("wx78_scanner_item", inst.linked_skinname, inst.skin_id)
                    scanner_item.Transform:SetPosition(inst.Transform:GetWorldPosition())
                    scanner_item.Transform:SetRotation(inst.Transform:GetRotation())
                    scanner_item.AnimState:MakeFacingDirty() --not needed for clients

                    -- Avoid splash on replacement since we already splashed from landing
                    scanner_item.components.floater.splash = false
                    scanner_item.components.inventoryitem:SetLanded(true, false)
                    scanner_item.components.floater.splash = true

                    inst:Remove()

                elseif inst.sg.statemem.changetosuccess then
                    local success_item = SpawnPrefab("wx78_scanner_succeeded", inst.linked_skinname, inst.skin_id)
                    success_item:SetUpFromScanner(inst)

                    success_item.components.floater.splash = false
                    success_item:PushEvent("on_landed") -- Success scanner has no inventoryitem
                    success_item.components.floater.splash = true

                    inst:Remove()

                else
                    inst.sg:GoToState("turn_off_idle")
                    inst.sg.statemem.going_to_idle = true
                end
            end),
        },

        onexit = function(inst)
            if not inst.sg.statemem.going_to_idle then
                inst:startloopingsound()
                inst:PushEvent("on_no_longer_landed")
            end
        end,
    },

    State {
        name = "turn_off_idle",
        tags = {"busy","scanned"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("turn_off_idle", true)

            inst:stoploopingsound()
        end,

        timeline =
        {
            FrameEvent(0, function(inst)
                inst:PushEvent("on_landed") -- For float FX.
            end),
        },

        onexit = function(inst)
            inst.sg.statemem.flashon = nil
            inst:startloopingsound()
            inst:PushEvent("on_no_longer_landed")
        end,
    },

    State {
        name = "scan_success",
        tags = {"busy","scanned"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("success")
        end,

        timeline =
        {
            FrameEvent(7, function(inst)
                inst.SoundEmitter:PlaySound("WX_rework/scanner/print")
            end),
            FrameEvent(21, function(inst)
                inst:SpawnData()
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("turn_off", {changetosuccess = true})
            end),
        },
    },
}

--states, timelines, anims, softstop, delaystart, fns
CommonStates.AddWalkStates(states, nil,
{
    startwalk = function(inst)
        if targetinrange(inst) then
            return "scan_loop"
        else
            return "walk_pre"
        end
    end,
    walk = function(inst)
        if targetinrange(inst) then
            return "scan_loop"
        else
            return "walk_loop"
        end
    end,
    stopwalk = function(inst)
        if targetinrange(inst) then
            return "scan_loop"
        else
            return "walk_pst"
        end
    end,
})

return StateGraph("wx78_scanner", states, events, "idle")