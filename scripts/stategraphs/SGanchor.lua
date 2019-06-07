local events =
{

}

local states =
{
    State
    {
        name = "raised",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("untethered_idle_loop", true)
            inst.components.anchor:SetIsAnchorLowered(false)
        end,

        events =
        {
            EventHandler("lowering_anchor",                 
                function(inst) 
                    local anchor_x, anchor_y, anchor_z = inst.Transform:GetWorldPosition()
                    if TheWorld.Map:GetPlatformAtPoint(anchor_x, anchor_z) ~= nil then
                        inst.sg:GoToState("lowering") 
                    else
                        inst.sg:GoToState("lowering_land") 
                    end
                end),
        },       
    },

    State
    {
        name = "lowered",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("tethered_idle_loop", true)
            inst.components.anchor:SetIsAnchorLowered(true)
        end,

        events =
        {
            EventHandler("raising_anchor", function(inst) inst.sg:GoToState("raising") end),
        },                                
    },    

    State
    {
        name = "lowered_land",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("tether_land_idle")            
            inst.components.anchor:SetIsAnchorLowered(true)
        end,

        events =
        {
            EventHandler("raising_anchor", function(inst) inst.sg:GoToState("raising_land") end),
        },                                
    },      

    State
    {
        name = "raising",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("untethering_pre")
            inst.AnimState:PushAnimation("untethering_loop", true)
            inst.components.anchor:SetIsAnchorLowered(false)            
            inst.sg:SetTimeout(4)
        end,

        timeline =
        {
            TimeEvent(2 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/anchor/LP", "mooring")                 
            end),

        },        

        ontimeout = function(inst)
            inst.sg:GoToState("raising_pst")

        end,
    },    

    State
    {
        name = "raising_pst",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("untethering_pst")           
        end,

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/anchor/up")                 
            end),

            TimeEvent(0 * FRAMES, function(inst) inst.SoundEmitter:KillSound("mooring")
            end),
        },        

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("raised") end),
        },                
    },       

    State
    {
        name = "raising_land",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("tether_land_pst")   
            inst.components.anchor:SetIsAnchorLowered(false)        
        end,

        timeline =
        {

        },        

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("raised") end),
        },                
    },       


    State
    {
        name = "lowering_land",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("tether_land_pre")
        end,

        timeline =
        {

        },        
        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("lowered_land") end),
        }
    },            

    State
    {
        name = "lowering",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("tethering_pre")
            inst.AnimState:PlayAnimation("tethering_loop", true)
            inst.sg:SetTimeout(2)
        end,

        timeline =
        {
            TimeEvent(0 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/anchor/down")                 
            end),
            TimeEvent(0 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/anchor/LP", "mooring")                 
            end),

        },        

        ontimeout = function(inst)
            inst.sg:GoToState("lowering_pst")
        end,
    },            

    State
    {
        name = "lowering_pst",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("tethering_pst")
            inst.components.anchor:SetIsAnchorLowered(true)
        end,

        timeline =
        {
            TimeEvent(2 * FRAMES, function(inst) inst.SoundEmitter:KillSound("mooring")
            end),
        }, 

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("lowered") end),
        },        
    },                
}

return StateGraph("anchor", states, events, "raised")
