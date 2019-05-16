local events =
{

}

local states =
{
    State
    {
        name = "retracted",

        onenter = function(inst)
            inst.AnimState:PlayAnimation("plank_idle")
            inst:RemoveTag("plank_extended")
            inst:AddTag("interactable")
        end,

        events =
        {
            EventHandler("start_extending", function(inst) inst.sg:GoToState("extending") end),
        },        
    },


    State
    {
        name = "retracting",
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("plank_deactivate")
            inst:RemoveTag("interactable")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("retracted") end),
        },          
    },   

    State
    {
        name = "extended",
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("plank_activated_idle")
            inst:AddTag("plank_extended")
            inst:AddTag("interactable")
        end,

        events =
        {
            EventHandler("start_retracting", function(inst) inst.sg:GoToState("retracting") end),            
            EventHandler("start_mounting", function(inst) inst.sg:GoToState("mounted") end),
            EventHandler("start_abandoning", function(inst) inst.sg:GoToState("abandon_ship") end),
        },         
    },   

    State
    {
        name = "mounted",
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("plank_activated_idle")
            inst:RemoveTag("interactable")
        end,

        events =
        {
            EventHandler("stop_mounting", function(inst) inst.sg:GoToState("extended") end),            
        },         
    },      

    State
    {
        name = "extending",
        onenter = function(inst)
            inst.AnimState:PlayAnimation("plank_activate")
            inst:RemoveTag("interactable")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("extended") end),
        },        
    },  

    State
    {
        name = "abandon_ship",

        onenter = function(inst)
            local doer = inst.components.walkingplank.doer
            inst:RemoveTag("interactable")
            inst.sg:SetTimeout(2)    
            doer:ScreenFade(false, 2)        
        end,

        ontimeout = function(inst)
            local doer = inst.components.walkingplank.doer

            local hunger_delta = 40
            local min_hunger = 60
            local hunger = doer.components.hunger
            if hunger.current > min_hunger then
                hunger:DoDelta(-math.min( hunger_delta, (hunger.current - min_hunger)))
            end    

            doer.components.moisture:SetPercent(95)

            doer:ScreenFade(true, 2)      
            inst.sg:GoToState("extended")

            local my_x, my_y, my_z = doer.Transform:GetWorldPosition()
            for k,v in pairs(Ents) do            
                if v:IsValid() and v:HasTag("multiplayer_portal") then
                    doer.Transform:SetPosition(v.Transform:GetWorldPosition())
                    doer:SnapCamera()
                    doer:PushEvent("wake_from_abandon_ship")                    
                end
            end

        end,        
    },            
}

return StateGraph("walkingplank", states, events, "retracted")
