local events =
{

}

local states =
{
    State
    {
        name = "open",
        onenter = function(inst)
            inst.widget.badge:Show()
            inst.widget.leak_anim:Show()
        end,

        onupdate = function(inst)
            inst.widget:UpdateLeak()
        end,

        events =
        {
            EventHandler("close_meter", function(inst) inst.sg:GoToState("close_pre") end),
        },
    },

    State
    {
        name = "open_pre",
        onenter = function(inst)
            inst.widget.anim:GetAnimState():PlayAnimation("open_pre")
        end,

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("open_pst") end),
            EventHandler("close_meter", function(inst) inst.sg:GoToState("close_pre") end),
        },
    },

    State
    {
        name = "open_pst",
        onenter = function(inst)
            inst.widget.anim:GetAnimState():PlayAnimation("open_pst")
            inst.widget.badge:Show()
            inst.widget.leak_anim:Show()
        end,

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("open") end),
            EventHandler("close_meter", function(inst) inst.sg:GoToState("close_pre") end),
        },
    },

    State
    {
        name = "close_pre",
        onenter = function(inst)
            inst.widget.anim:GetAnimState():PlayAnimation("close_pre")
        end,

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("close_pst") end),
            EventHandler("open_meter", function(inst) inst.sg:GoToState("open_pre") end),
        },
    },

    State
    {
        name = "close_pst",
        onenter = function(inst)
            inst.widget.anim:GetAnimState():PlayAnimation("close_pst")
            inst.widget.badge:Hide()
            inst.widget.leak_anim:Hide()
        end,

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("closed") end),
            EventHandler("open_meter", function(inst) inst.sg:GoToState("open_pre") end),
        },
    },

    State
    {
        name = "closed",
        onenter = function(inst)
            inst.widget.badge:Hide()
            inst.widget.leak_anim:Hide()
        end,

        events =
        {
            EventHandler("open_meter", function(inst) inst.sg:GoToState("open_pre") end),
        },
    },
}

return StateGraph("boatmeter", states, events, "closed")
